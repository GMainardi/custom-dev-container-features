
# GitHub CLI (github-cli)

Installs the GitHub CLI

## Example Usage

```json
"features": {
    "ghcr.io/GMainardi/custom-dev-container-features/github-cli:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select version of GitHub CLI to install. | string | latest |
| authSsh | Configure the GitHub CLI to use SSH protocol for git operations. | boolean | false |
| installGit | Install git if not already present. | boolean | true |
| configureGit | Configure git user.name and user.email if not set. | boolean | true |
| install1PasswordCli | Install the 1Password CLI (op) to support 1Password integration. | boolean | false |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/GMainardi/custom-dev-container-features/blob/main/src/github-cli/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
