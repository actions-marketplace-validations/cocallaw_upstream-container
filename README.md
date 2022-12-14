# Upstream-Container Action

This action checks Docker Hub for an updated version of a specified container image, returning true/false if there is change and the most recent tag.

## Prerequisites

### Docker Hub Personal Access Token (PAT)
- This action requires a Docker Hub Personal Access Token (PAT) to be used for authentication when checking for the latest tag on Docker Hub.
- The PAT requires the `Read-only` scope and no other permissions.
- The PAT should be stored as a [GitHub Workflow Secret](https://docs.github.com/en/actions/security-guides/encrypted-secrets), and passed to the action as an input.
- Instructions for creating a PAT can be found [here](https://docs.docker.com/docker-hub/access-tokens/#create-an-access-token).
### Regex Filter String

## Inputs

### `docker-username`

**Required** The username of the Docker Hub account to be used.

Example `cocallaw`.

### `docker-pat`

**Required** The personal access token of the Docker Hub account to be used.

Example `dckr_pat_ABCDEFghIJkLmnO1PqRsTUVwXy2Z`.

### `upstream-image`

**Required** The name of the upstream container on Docker Hub

Example `ubuntu/nginx` or `library/postgres`.

### `current-tag`

**Required** The tag of the upstream container image that was used in the last successful build process.

Example `bionic-20220829`.

### `tag-regex`

**Required** The regex to be used to filter for the format of the tags to be checked.

Example `bionic-[0-9]+`



## Outputs

### `changed`

The value returned will be `true` if there is a change in the upstream container image, `false` if there is no change.
- This value is a string, not a boolean.

### `tag`

The most recent tag found on Docker Hub for the specified container image.
- If there is no change, the value returned will be the same as the `current-tag` input.
- If there are no tags found that match the `tag-regex` input, the value returned will be `regexfiltererror`.


## Example usage
```yaml
name: Upstream Container Check

on:
  workflow_dispatch:

jobs:
  upstream-check:
    runs-on: ubuntu-latest
    name: Check for Upstream Container Changes
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      - name: Upstream Check
        uses: cocallaw/upstream-container@v0.1
        id: upstream
        with:
          docker-username: ${{ secrets.DOCKER_USERNAME }}
          docker-pat: ${{ secrets.DOCKER_PAT }}
          upstream-image: "library/ubuntu"
          current-tag: "bionic-20220829"
          tag-regex: "bionic-[0-9]+"
      # Use the output from the `upstream` step
      - name: Get change result
        run: echo "change = ${{ steps.upstream.outputs.changed }}"
      - name: Get tag result
        run: echo "tag = ${{ steps.upstream.outputs.tag }}"
```