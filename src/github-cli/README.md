# GitHub CLI (github-cli)

Installs the GitHub CLI (gh)

## Example Usage

```json
"features": {
    "ghcr.io/guidomainardi/custom-dev-container-features/github-cli:1": {
        "version": "latest",
        "authSsh": true,
        "installGit": true,
        "configureGit": true
    }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select version of GitHub CLI to install. | string | latest |
| authSsh | Configure the GitHub CLI to use SSH protocol for git operations. | boolean | false |
| installGit | Install git if not already present. | boolean | true |
| configureGit | Configure git user.name and user.email if not set (attempts to use env vars). | boolean | false |
