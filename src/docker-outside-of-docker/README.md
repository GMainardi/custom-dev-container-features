# Docker Outside of Docker (DooD)

Re-use the host's Docker socket to run Docker commands inside the container.

## Example Usage

```json
"features": {
    "ghcr.io/guidomainardi/custom-dev-container-features/docker-outside-of-docker:1": {
        "version": "latest"
    }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select version of Docker CLI to install. | string | latest |

## Notes

This feature installs the Docker CLI and configures the container to use the host's Docker socket. It requires the container to be run with the Docker socket mounted.

The feature automatically adds a mount configuration to `devcontainer-feature.json` to bind mount `/var/run/docker.sock`.

