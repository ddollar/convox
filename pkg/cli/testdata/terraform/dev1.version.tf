		module "system" {
			source = "github.com/ddollar/convox//terraform/system/local?ref=otherver"
			kubeconfig = "~/.kube/config"
			name = "dev1"
			release = "otherver"
		}

		output "api" {
			value = module.system.api
		}

		output "provider" {
			value = "local"
		}
