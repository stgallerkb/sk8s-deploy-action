# SK8s Deploy Action

An action to conveniently deploy docker images to SK8s.

## Usage

```yml
name: CI

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Deploy to SK8s
        uses: stgallerkb/sk8s-deploy-action@v1
        with:
          ssh-known-hosts: ${{ secrets.YOUR_KNOWN_HOST }}
          ssh-key: ${{ secrets.YOUR_SSH_KEY }}
          git-host-name: github.com
          git-project: project-name
          git-repo-name: repo-name
          replacement: ${{ github.run_id }}
          tag: repo-name-${{ github.run_id }}
          line-identificator: image-tag
          branch-main: main
          main-branch-name: main
```

## Customizing

| Name               | Required | Default Value      | Description                                      |
| ------------------ | -------- | ------------------ | ------------------------------------------------ |
| ssh-key            | Yes      |                    | SSH key                                          |
| ssh-known-hosts    | Yes      |                    | SSH known hosts                                  |
| git-host-name      | Yes      |                    | Host of the git repo                             |
| git-ssh-port       | No       | 22                 | SSH port of the git host                         |
| git-project        | Yes      |                    | Git project                                      |
| git-repo-name      | Yes      |                    | Name of the repo to clone                        |
| replacement        | Yes      |                    | New string to replace                            |
| file-name          | No       | kustomization.yaml | In which file to replace                         |
| line-identificator | Yes      |                    | Line marker to look for                          |
| tag                | Yes      |                    | Tag name to use, no tagging if not provided      |
| branch-name        | No       |                    | Branch name to use, no branching if not provided |
| main-branch-name   | No       |                    | Main branch name to use                          |
