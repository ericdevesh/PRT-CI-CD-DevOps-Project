# PRT CI/CD DevOps Project

**Title:** CI/CD Automation with Docker and Kubernetes using DevOps Tools

A simplified end-to-end DevOps assignment demonstrating Git, Ansible, Jenkins, Docker, Terraform and a single-node Kubernetes deployment.

## Architecture

| Machine | Responsibility |
|---|---|
| `ci-master` | Jenkins + Java + Ansible control node |
| `ci-agent` | Jenkins SSH agent + Java + Docker |
| `k8s-node` | Terraform-provisioned Ubuntu instance + single-node Kubernetes |

## Repository contents

- `Dockerfile`, `app/index.html`: small web application displaying **PRT – CI/CD Completed Successfully**
- `Jenkinsfile`: checkout, Docker build and smoke test, push to Docker Hub, deploy to Kubernetes over SSH
- `ansible/site.yml`: installs Jenkins and Java on `ci-master`, Docker and Java on `ci-agent`
- `ansible/kubernetes.yml`: configures Kubernetes on `k8s-node`
- `terraform/`: provisions `k8s-node` and outputs its IP
- `k8s/`: Deployment and NodePort Service manifests

> This repository contains starter configuration, not evidence of a completed cloud run. Run the steps below and include genuine screenshots from your own execution in the submitted report.

## Prerequisites

- An AWS account and permission to launch EC2 resources in your chosen region.
- An existing EC2 key pair, a default VPC with a public subnet, and the correct SSH key locally.
- Terraform, AWS CLI and Git on your workstation.
- Three Ubuntu 22.04 EC2 instances in one AWS region/VPC: `ci-master`, `ci-agent`, and the Terraform-created `k8s-node`. A `t3.medium` is configured for Kubernetes to provide 4 GiB RAM.
- A public Docker Hub repository named `prt-cicd` and an access token.

## 1. Terraform: provision k8s-node

Configure AWS credentials using your own IAM identity. Then run:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and set ssh_key_name to the exact EC2 key pair name
terraform init
terraform validate
terraform apply
```

Record the `k8s_node_public_ip` output. Terraform exposes SSH (22) and application NodePort (30080) for a short lab. Restrict SSH source CIDRs to your own IPs where practical. Never commit `terraform.tfvars`, state files, PEM keys, AWS credentials or tokens.

## 2. Ansible: configure the machines

On `ci-master`, install Ansible and Git:

```bash
sudo apt update
sudo apt install -y ansible git
```

Clone this repository and change to the `ansible` folder. Put your lab private key at `/home/ubuntu/.ssh/lab.pem` with permissions `600`. Edit `inventory.ini` to replace the agent and Kubernetes-node placeholders with real public IPs.

```bash
chmod 600 ~/.ssh/lab.pem
cd ~/PRT-CI-CD-DevOps-Project/ansible
ansible all -i inventory.ini -m ping
ansible-playbook -i inventory.ini site.yml
ansible-playbook -i inventory.ini kubernetes.yml
```

The SSH username/key path and network access must match your EC2 instances. Verify the Ansible recap shows no failed hosts.

## 3. Jenkins and Docker agent

Complete Jenkins setup at `http://CI_MASTER_PUBLIC_IP:8080`. Install the suggested plugins and **SSH Build Agents**. Add a permanent SSH agent named `ci-agent`, remote root `/home/ubuntu/jenkins`, launch method SSH, and label `docker`; use the private key for the lab instance. Ensure the agent's Ubuntu user can run Docker without sudo (log out/in after adding it to the docker group).

Create a **public** Docker Hub repository named `prt-cicd`. In Jenkins, add these credentials:

- ID `dockerhub-creds`: Username with password/access-token.
- ID `k8s-ssh`: SSH private key credential with username `ubuntu`.

Edit `Jenkinsfile` and replace `REPLACE_WITH_K8S_NODE_PUBLIC_IP` with the Terraform output; commit and push the change.

Create a Jenkins Pipeline job and configure **Pipeline script from SCM**:

- SCM: Git
- Repository URL: `https://github.com/ericdevesh/PRT-CI-CD-DevOps-Project.git`
- Branch specifier: `*/main`
- Script path: `Jenkinsfile`

Click **Build Now**. All stages should complete before the browser test can be captured.

## 4. Kubernetes verification

SSH to `k8s-node` and verify:

```bash
kubectl get nodes -o wide
kubectl get pods -A
kubectl get deployment,svc
```

Open `http://K8S_NODE_PUBLIC_IP:30080`. The page should display **PRT – CI/CD Completed Successfully**.

## 5. Submission evidence checklist

Capture genuine screenshots of:

1. GitHub repository and required files.
2. Ansible successful playbook recap and service checks.
3. Terraform successful `terraform apply` and IP output.
4. Jenkins agent Online.
5. Jenkins pipeline stage view and console output showing success.
6. Kubernetes node, pod and service status.
7. Application output in the browser.

Place the screenshots in your assignment report PDF. Do not present planned or placeholder results as actual execution evidence.

## Clean up

After your instructor has evaluated the work, stop/delete lab EC2 instances and run `terraform destroy` from the same Terraform directory/state. Check the AWS billing console for any remaining lab resources.
