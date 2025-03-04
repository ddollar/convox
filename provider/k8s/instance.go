package k8s

import (
	"context"
	"fmt"
	"io"

	"github.com/convox/convox/pkg/structs"
	"github.com/pkg/errors"
	ac "k8s.io/api/core/v1"
	am "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func (p *Provider) InstanceKeyroll() error {
	return errors.WithStack(fmt.Errorf("unimplemented"))
}

func (p *Provider) InstanceList() (structs.Instances, error) {
	ns, err := p.Cluster.CoreV1().Nodes().List(context.Background(), am.ListOptions{})
	if err != nil {
		return nil, errors.WithStack(err)
	}

	// ms, err := p.Metrics.Metrics().NodeMetricses().List(am.ListOptions{})
	// if err != nil {
	//   return nil, err
	// }

	// fmt.Printf("ms = %+v\n", ms)

	is := structs.Instances{}

	for _, n := range ns.Items {
		pds, err := p.Cluster.CoreV1().Pods("").List(context.Background(), am.ListOptions{FieldSelector: fmt.Sprintf("spec.nodeName=%s", n.ObjectMeta.Name)})
		if err != nil {
			return nil, errors.WithStack(err)
		}

		status := "pending"

		for _, c := range n.Status.Conditions {
			if c.Type == "Ready" && c.Status == "True" {
				status = "running"
			}
		}

		private := ""
		public := ""

		for _, na := range n.Status.Addresses {
			switch na.Type {
			case ac.NodeExternalIP:
				public = na.Address
			case ac.NodeInternalIP:
				private = na.Address
			}
		}

		is = append(is, structs.Instance{
			Id:        n.ObjectMeta.Name,
			PrivateIp: private,
			Processes: len(pds.Items),
			PublicIp:  public,
			Started:   n.CreationTimestamp.Time,
			Status:    status,
		})
	}

	return is, nil
}

func (p *Provider) InstanceShell(id string, rw io.ReadWriter, opts structs.InstanceShellOptions) (int, error) {
	return 0, errors.WithStack(fmt.Errorf("unimplemented"))
}

func (p *Provider) InstanceTerminate(id string) error {
	return errors.WithStack(fmt.Errorf("unimplemented"))
}
