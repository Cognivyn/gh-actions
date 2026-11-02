# AI agent guide

This guide gives AI coding agents a safe, repeatable way to use and modify `Cognivyn/gh-actions`.

## Repository purpose

This repository contains reusable GitHub Actions shared across Cognivyn projects:

- `setup-php/` installs supported PHP 8.2 or PHP 8.3 runtimes, requested extensions, and optionally Composer on Linux runners.
- `ftp-deploy/` deploys a local directory to an FTP or FTPS server with retries, exclusions, parallel transfers, timeouts, dry-run support, and deployment statistics.

The validation workflow is `.github/workflows/test-setup-php.yml`.

## Before making changes

1. Start from the latest `main` branch.
2. Inspect the action metadata in `setup-php/action.yml` or `ftp-deploy/action.yml` before changing inputs or outputs.
3. Keep changes scoped to the requested action and preserve backward-compatible input names.
4. Never expose credentials, tokens, or complete secret values in logs, documentation, tests, or commit messages.
5. Prefer small, single-purpose changes. Keep shell logic modular by extracting a named function when a responsibility has its own validation or side effects.

## Using the actions in a calling repository

Reference an action by repository path:

```yaml
uses: Cognivyn/gh-actions/setup-php@<reviewed-ref>
```

or:

```yaml
uses: Cognivyn/gh-actions/ftp-deploy@<reviewed-ref>
```

Use a reviewed commit SHA or release tag for production workflows. Use `@main` only for development or when the caller intentionally tracks the default branch.

For `setup-php`, provide a supported PHP version such as `8.2.x` or `8.3.x`. For `ftp-deploy`, place `ftp_server`, `ftp_username`, `ftp_password`, and any other sensitive connection values in the caller's GitHub Actions secrets. Set `dry_run: 'true'` while validating a new path or server.

## Change and validation workflow

Run these checks after documentation or code changes:

```bash
git diff --check
bash -n setup-php/install-php.sh
```

For installer changes on a Linux runner, exercise the same matrix expectations as the workflow:

```bash
RUNNER_OS=Linux \
PHP_VERSION=8.3.13 \
PHP_EXTENSIONS=mbstring,xml,curl,zip \
INSTALL_COMPOSER=true \
bash setup-php/install-php.sh

php -r 'echo PHP_VERSION . PHP_EOL;'
composer --version
php -m | grep -E 'mbstring|xml|curl|zip'
```

For FTP shell changes, validate required input handling and path checks without contacting a real server. Use a dry-run workflow with test credentials and a disposable target before any live deployment. Never bypass TLS or certificate validation as a shortcut for a failing production connection.

## Pull request expectations

A good pull request should explain the user-facing behavior, list validation performed, and call out compatibility or security implications. If `main` advanced while work was in progress, fetch it and rebase before requesting review. Resolve conflicts in favor of the latest secure behavior, preserve public input contracts, and rerun the relevant workflow matrix after the rebase.

AI agents must not merge pull requests, rotate secrets, publish releases, or perform live FTP deployments unless the user explicitly authorizes that high-impact action.
