package k8s

import (
	"context"
	"fmt"
	"io"
	"sort"

	"github.com/convox/convox/pkg/common"
	"github.com/convox/convox/pkg/structs"
	"github.com/pkg/errors"
	am "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func (p *Provider) SystemGet() (*structs.System, error) {
	status := "running"

	// status, err := p.Engine.SystemStatus()
	// if err != nil {
	// 	return nil, err
	// }

	// ss, _, err := p.atom.Status(p.Namespace, "system")
	// if err != nil {
	// 	return nil, err
	// }

	// status = "running"

	// switch status {
	// case "running", "unknown":
	// 	status = common.AtomStatus(ss)
	// }

	s := &structs.System{
		Domain:   fmt.Sprintf("router.%s", p.Domain),
		Name:     p.Name,
		Provider: p.Provider,
		Status:   status,
		Version:  p.Version,
	}

	return s, nil
}

func (p *Provider) SystemInstall(w io.Writer, opts structs.SystemInstallOptions) (string, error) {
	return "", errors.WithStack(fmt.Errorf("unimplemented"))
}

func (p *Provider) SystemLogs(opts structs.LogsOptions) (io.ReadCloser, error) {
	return nil, errors.WithStack(fmt.Errorf("unimplemented"))
}

func (p *Provider) SystemMetrics(opts structs.MetricsOptions) (structs.Metrics, error) {
	return nil, errors.WithStack(fmt.Errorf("unimplemented"))
}

func (p *Provider) SystemProcesses(opts structs.SystemProcessesOptions) (structs.Processes, error) {
	ns := p.Namespace

	if common.DefaultBool(opts.All, false) {
		ns = ""
	}

	pds, err := p.Cluster.CoreV1().Pods(ns).List(context.Background(), am.ListOptions{
		LabelSelector: fmt.Sprintf("system=convox,rack=%s,service", p.Name),
	})
	if err != nil {
		return nil, errors.WithStack(err)
	}

	pss := structs.Processes{}

	for _, pd := range pds.Items {
		ps, err := p.processFromPod(pd)
		if err != nil {
			return nil, errors.WithStack(err)
		}

		pss = append(pss, *ps)
	}

	sort.Slice(pss, pss.Less)

	return pss, nil
}

func (p *Provider) SystemReleases() (structs.Releases, error) {
	return nil, errors.WithStack(fmt.Errorf("release history is unavailable"))
}

func (p *Provider) SystemUninstall(name string, w io.Writer, opts structs.SystemUninstallOptions) error {
	return errors.WithStack(fmt.Errorf("unimplemented"))
}

func (p *Provider) SystemUpdate(opts structs.SystemUpdateOptions) error {
	return errors.WithStack(fmt.Errorf("self update not supported"))
}
