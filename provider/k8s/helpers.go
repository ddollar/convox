package k8s

import (
	"archive/tar"
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"io"
	"path"
	"regexp"
	"sort"
	"strconv"
	"strings"

	"github.com/convox/convox/pkg/manifest"
	"github.com/convox/convox/pkg/structs"
	"github.com/pkg/errors"
	ac "k8s.io/api/core/v1"
	ae "k8s.io/apimachinery/pkg/api/errors"
	am "k8s.io/apimachinery/pkg/apis/meta/v1"
)

const (
	ScannerStartSize = 4096
	ScannerMaxSize   = 1024 * 1024
)

var (
	kubernetesNameFilter = regexp.MustCompile(`[^a-z-.]`)
)

type Patch struct {
	Op    string      `json:"op"`
	Path  string      `json:"path"`
	Value interface{} `json:"value"`
}

func (p *Provider) ingressSecrets(a *structs.App, ss manifest.Services) (map[string]string, error) {
	domains := map[string]bool{}

	for _, s := range ss {
		for _, d := range s.Domains {
			domains[d] = false
		}
	}

	cs, err := p.CertificateList()
	if err != nil {
		return nil, errors.WithStack(err)
	}

	sort.Slice(cs, func(i, j int) bool { return cs[i].Expiration.After(cs[i].Expiration) })

	secrets := map[string]string{}

	for _, c := range cs {
		count := 0

		for _, d := range c.Domains {
			if v, ok := domains[d]; ok && !v {
				domains[d] = true
				count++
			}
		}

		if count > 0 {
			for _, d := range c.Domains {
				secrets[d] = c.Id
			}
		}
	}

	for d, matched := range domains {
		if !matched {
			c, err := p.CertificateGenerate([]string{d})
			if err != nil {
				return nil, errors.WithStack(err)
			}

			secrets[d] = c.Id
		}
	}

	ids := map[string]bool{}

	for _, id := range secrets {
		ids[id] = true
	}

	for id := range ids {
		if _, err := p.Cluster.CoreV1().Secrets(p.AppNamespace(a.Name)).Get(context.Background(), id, am.GetOptions{}); ae.IsNotFound(err) {

			kc, err := p.Cluster.CoreV1().Secrets(p.Namespace).Get(context.Background(), id, am.GetOptions{})
			if err != nil {
				return nil, errors.WithStack(err)
			}

			kc.ObjectMeta.Namespace = p.AppNamespace(a.Name)
			kc.ResourceVersion = ""
			kc.UID = ""

			if _, err := p.Cluster.CoreV1().Secrets(p.AppNamespace(a.Name)).Create(context.Background(), kc, am.CreateOptions{}); err != nil {
				return nil, errors.WithStack(err)
			}
		}
	}

	return secrets, nil
}

func (p *Provider) environment(a *structs.App, r *structs.Release, s manifest.Service, e structs.Environment) (map[string]string, error) {
	env := map[string]string{}

	for k, v := range p.systemEnvironment() {
		env[k] = v
	}

	for k, v := range p.appEnvironment(a) {
		env[k] = v
	}

	for k, v := range p.releaseEnvironment(a, r) {
		env[k] = v
	}

	if r.Build != "" {
		b, err := p.BuildGet(a.Name, r.Build)
		if err != nil {
			return nil, errors.WithStack(err)
		}

		for k, v := range p.buildEnvironment(a, b) {
			env[k] = v
		}
	}

	for k, v := range p.serviceEnvironment(a, s) {
		env[k] = v
	}

	for k, v := range s.EnvironmentDefaults() {
		env[k] = v
	}

	for k, v := range e {
		env[k] = v
	}

	return env, nil
}

func (p *Provider) appEnvironment(a *structs.App) map[string]string {
	return map[string]string{
		"APP": a.Name,
	}
}

func (p *Provider) buildEnvironment(a *structs.App, b *structs.Build) map[string]string {
	return map[string]string{
		"BUILD":             b.Id,
		"BUILD_DESCRIPTION": b.Description,
	}
}

func (p *Provider) releaseEnvironment(a *structs.App, r *structs.Release) map[string]string {
	return map[string]string{
		"RELEASE": r.Id,
	}
}

func (p *Provider) serviceEnvironment(a *structs.App, s manifest.Service) map[string]string {
	env := map[string]string{
		"SERVICE": s.Name,
	}

	if s.Port.Port > 0 {
		env["PORT"] = strconv.Itoa(s.Port.Port)
	}

	return env
}

func (p *Provider) systemEnvironment() map[string]string {
	return map[string]string{
		"RACK":     p.Name,
		"RACK_URL": fmt.Sprintf("https://convox:%s@api.%s.svc.cluster.local:5443", p.Password, p.Namespace),
	}
}

func (p *Provider) volumeFrom(app, service, v string) string {
	from := strings.Split(v, ":")[0]

	switch {
	case systemVolume(from):
		return from
	case strings.Contains(v, ":"):
		return path.Join("/mnt/volumes", app, "app", from)
	default:
		return path.Join("/mnt/volumes", app, "service", service, from)
	}
}

func (p *Provider) volumeName(app, v string) string {
	hash := sha256.Sum256([]byte(v))
	name := fmt.Sprintf("%s-%s-%x", p.Name, app, hash[0:20])
	if len(name) > 63 {
		name = name[0:62]
	}
	return name
}

func (p *Provider) volumeSources(app, service string, vs []string) []string {
	vsh := map[string]bool{}

	for _, v := range vs {
		vsh[p.volumeFrom(app, service, v)] = true
	}

	vsu := []string{}

	for v := range vsh {
		vsu = append(vsu, v)
	}

	sort.Strings(vsu)

	return vsu
}

type imageManifest []struct {
	RepoTags []string
}

func extractImageManifest(r io.Reader) (imageManifest, error) {
	mtr := tar.NewReader(r)

	var manifest imageManifest

	for {
		mh, err := mtr.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, errors.WithStack(err)
		}

		if mh.Name == "manifest.json" {
			var mdata bytes.Buffer

			if _, err := io.Copy(&mdata, mtr); err != nil {
				return nil, errors.WithStack(err)
			}

			if err := json.Unmarshal(mdata.Bytes(), &manifest); err != nil {
				return nil, errors.WithStack(err)
			}

			return manifest, nil
		}
	}

	return nil, errors.WithStack(fmt.Errorf("unable to locate manifest"))
}

func nameFilter(name string) string {
	return kubernetesNameFilter.ReplaceAllString(name, "")
}

func primaryContainer(cs []ac.Container, app string) (*ac.Container, error) {
	if len(cs) != 1 {
		return nil, fmt.Errorf("no containers found")
	}

	switch cs[0].Name {
	case app, "main":
	default:
		return nil, fmt.Errorf("unexpected container name")
	}

	return &(cs[0]), nil
}

func systemVolume(v string) bool {
	switch v {
	case "/cgroup/":
		return true
	case "/proc/":
		return true
	case "/sys/fs/cgroup/":
		return true
	case "/sys/kernel/debug/":
		return true
	case "/var/log/audit/":
		return true
	case "/var/run/":
		return true
	case "/var/run/docker.sock":
		return true
	case "/var/snap/microk8s/current/docker.sock":
		return true
	}
	return false
}

func volumeTo(v string) (string, error) {
	switch parts := strings.SplitN(v, ":", 2); len(parts) {
	case 1:
		return parts[0], nil
	case 2:
		return parts[1], nil
	default:
		return "", errors.WithStack(fmt.Errorf("invalid volume %q", v))
	}
}
