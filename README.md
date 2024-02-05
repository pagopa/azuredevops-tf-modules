# azuredevops-tf-modules

Terraform Azure DevOps modules

## Semantic versioning

This repo use standard semantic versioning according to <https://www.conventionalcommits.org>.

We use keywords in PR title to determinate next release version.

If first commit it's different from PR title you must add at least a second commit.

Due this issue <https://github.com/semantic-release/commit-analyzer/issues/231> use `breaking` keyword to trigger a major change release.

### Precommit checks

Check your code before commit.

<https://github.com/antonbabenko/pre-commit-terraform#how-to-install>

```sh
# for terraform modules we need to initialize them with
bash .utils/terraform_run_all.sh init local
pre-commit run -a
```

## Terraform lock.hcl

We have both developers who work with your Terraform configuration on their Linux, macOS or Windows workstations and automated systems that apply the configuration while running on Linux.
<https://www.terraform.io/docs/cli/commands/providers/lock.html#specifying-target-platforms>

So we need to specify this in terraform lock providers:

```sh
terraform init

rm .terraform.lock.hcl

terraform providers lock \
  -platform=windows_amd64 \
  -platform=darwin_amd64 \
  -platform=darwin_arm64 \
  -platform=linux_amd64
```
