# azuredevops-tf-modules

Terraform Azure DevOps modules

## Semantic versioning

This repo use standard semantic versioning according to https://www.conventionalcommits.org.

We use keywords in PR title to determinate next release version.

If first commit it's different from PR title you must add at least a second commit.

Due this issue https://github.com/semantic-release/commit-analyzer/issues/231 use `breaking` keyword to trigger a major change release.

### Precommit checks

Check your code before commit.

https://github.com/antonbabenko/pre-commit-terraform#how-to-install

```sh
pre-commit run -a
```
