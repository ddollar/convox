package main

import (
	"os"

	"github.com/convox/convox/pkg/cli"
	"github.com/convox/convox/pkg/rack"
)

var (
	image   = "ddollar/convox"
	version = "dev"
)

func main() {
	if image != "" {
		cli.Image = image
		rack.Image = image
	}

	c := cli.New("convox", version)

	os.Exit(c.Execute(os.Args[1:]))
}
