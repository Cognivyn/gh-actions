# Cognivyn GitHub Actions

Reusable GitHub Actions for PHP setup and FTP deployments across Cognivyn repositories.

[![Test setup-php action](https://github.com/Cognivyn/gh-actions/actions/workflows/test-setup-php.yml/badge.svg)](https://github.com/Cognivyn/gh-actions/actions/workflows/test-setup-php.yml)

## Available actions

### Setup PHP

`setup-php` is a repository-owned composite action for installing supported PHP 8.2 or PHP 8.3 runtimes on Linux GitHub-hosted runners. It installs the requested major/minor runtime, optional extensions, and Composer without depending on a third-party setup action.

```yaml
- name: Set up PHP
  uses: Cognivyn/gh-actions/setup-php@main
  with:
    php-version: '8.3.13'
    extensions: 'mbstring,xml,curl,zip'
    install-composer: 'true'
```

The action selects the appropriate PHP package source for the runner. Ubuntu Resolute uses the signed Sury PHP repository; earlier supported Ubuntu releases use the Ondřej PHP PPA.

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
setup-php/                 PHP runtime and Composer setup action
ftp-deploy/                FTP/FTPS deployment action
.github/workflows/         Validation workflows
docs/ai-agents.md          Guidance for AI coding agents using this repository
```

## Validation

The `Test setup-php action` workflow validates PHP 8.2 and PHP 8.3, Composer availability, and the required PHP extensions on `ubuntu-latest`.

## License

See [LICENSE](LICENSE).
