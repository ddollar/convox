package aws

import (
	"context"
	"os"

	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ecr"
	"github.com/aws/aws-sdk-go/service/ecr/ecriface"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/s3/s3iface"
	"github.com/convox/convox/pkg/loki"
	"github.com/convox/convox/pkg/structs"
	"github.com/convox/convox/provider/k8s"
)

type Provider struct {
	*k8s.Provider

	Bucket string
	Region string

	ECR ecriface.ECRAPI
	S3  s3iface.S3API

	loki *loki.Client
}

func FromEnv() (*Provider, error) {
	k, err := k8s.FromEnv()
	if err != nil {
		return nil, err
	}

	p := &Provider{
		Provider: k,
		Bucket:   os.Getenv("BUCKET"),
		Region:   os.Getenv("AWS_REGION"),
	}

	k.Engine = p

	return p, nil
}

func (p *Provider) Initialize(opts structs.ProviderOptions) error {
	if err := p.initializeAwsServices(); err != nil {
		return err
	}

	if err := p.Provider.Initialize(opts); err != nil {
		return err
	}

	return nil
}

func (p *Provider) WithContext(ctx context.Context) structs.Provider {
	pp := *p
	pp.Provider = pp.Provider.WithContext(ctx).(*k8s.Provider)
	return &pp
}

func (p *Provider) initializeAwsServices() error {
	s, err := session.NewSession()
	if err != nil {
		return err
	}

	p.ECR = ecr.New(s)
	p.S3 = s3.New(s)

	lc, err := loki.New(os.Getenv("LOKI_URL"))
	if err != nil {
		return err
	}

	p.loki = lc

	return nil
}
