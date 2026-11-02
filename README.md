# Cognivyn GitHub Actions

Reusable GitHub Actions for PHP setup and FTP deployments across Cognivyn repositories.

[![Test setup-php action](https://github.com/Cognivyn/gh-actions/actions/workflows/test-setup-php.yml/badge.svg)](https://github.com/Cognivyn/gh-actions/actions/workflows/test-setup-php.yml)
[![Build setup-php image](https://github.com/Cognivyn/gh-actions/actions/workflows/build-setup-php-image.yml/badge.svg)](https://github.com/Cognivyn/gh-actions/actions/workflows/build-setup-php-image.yml)

## Available actions

### Setup PHP

`setup-php` is a Docker-based action for installing supported PHP 8.2 or PHP 8.3 runtimes on Linux GitHub-hosted runners. It uses a pre-built Docker image with PHP and common extensions pre-installed, resulting in faster execution compared to runtime installation.

```yaml
- name: Set up PHP
  uses: Cognivyn/gh-actions/setup-php@main
  with:
    php-version: '8.3.13'
    extensions: 'mbstring,xml,curl,zip'
    install-composer: 'true'
```

The Docker image includes PHP 8.2 and 8.3 with common extensions (mbstring, xml, curl, zip, bcmath, gmp, pdo_mysql, pdo_pgsql, pdo_sqlite) and Composer pre-installed. The action switches to the requested PHP version at runtime using `update-alternatives`.

#### Docker Image

The Docker image is built and published to GitHub Container Registry (GHCR) as `ghcr.io/Cognivyn/gh-actions/setup-php`. The image is automatically built and pushed on changes to the `setup-php/` directory via the [build-setup-php-image.yml](.github/workflows/build-setup-php-image.yml) workflow.

Available tags:
- `latest` - Latest stable build from main branch
- `main` - Latest build from main branch
- Semantic version tags (e.g., `v1.0.0`) for releases

### FTP Deploy

`ftp-deploy` is a Docker-based FTP/FTPS deployment action with TLS support, dry-run mode, retries, parallel transfers, exclusions, timeouts, and upload statistics.

```yaml
- name: Deploy over FTPS
  uses: Cognivyn/gh-actions/ftp-deploy@main
  with:
    ftp_server: ${{ secrets.FTP_SERVER }}
    ftp_username: ${{ secrets.FTP_USERNAME }}
    ftp_password: ${{ secrets.FTP_PASSWORD }}
    ftp_port: '21'
    local_dir: './dist'
    remote_dir: '/public_html'
    ssl_enabled: 'true'
    dry_run: 'false'
```

Required FTP inputs are `ftp_server`, `ftp_username`, `ftp_password`, and `ftp_port`. Optional inputs include `local_dir`, `remote_dir`, `ssl_enabled`, `exclude`, `dry_run`, `parallel`, `timeout`, `max_retries`, and `idle_timeout`. The action exposes `files_uploaded` and `transfer_time` outputs.

## Recommended workflow practices

Use a commit SHA or a reviewed release tag instead of `@main` when reproducibility is required. Store FTP credentials in GitHub Actions secrets, never in workflow YAML or command output. Use `dry_run: 'true'` when validating a new deployment target, and restrict workflow permissions to the minimum required by the calling repository.

## Repository layout

```text
setup-php/                 PHP runtime and Composer setup action (Docker-based)
  - Dockerfile             Docker image with PHP 8.2/8.3 pre-installed
  - entrypoint.sh          Version switching script
  - action.yml             Action definition
ftp-deploy/                FTP/FTPS deployment action (Docker-based)
.github/workflows/         CI/CD workflows
  - test-setup-php.yml     Validation workflow for setup-php
  - build-setup-php-image.yml Docker image build and push workflow
docs/ai-agents.md          Guidance for AI coding agents using this repository
```

## Validation

The `Test setup-php action` workflow validates PHP 8.2 and PHP 8.3, Composer availability, and the required PHP extensions on `ubuntu-latest`. The `Build and push setup-php Docker image` workflow builds and publishes the Docker image to GHCR on changes to the setup-php directory.

## License

See [LICENSE](LICENSE).
