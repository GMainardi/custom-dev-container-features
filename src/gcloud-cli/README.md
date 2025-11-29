# Google Cloud CLI (gcloud-cli)

Installs the Google Cloud CLI (gcloud)

## Example Usage

```json
"features": {
    "ghcr.io/guidomainardi/custom-dev-container-features/gcloud-cli:1": {
        "version": "latest",
        "projectId": "my-project-id",
        "quotaProjectId": "my-quota-project-id"
    }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select version of gcloud cli to install. | string | latest |
| projectId | The Google Cloud project ID to set as default. | string | - |
| quotaProjectId | The Google Cloud project ID to set as the quota project. | string | - |
