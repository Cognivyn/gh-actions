#!/usr/bin/env bash
set -euo pipefail

PHP_VERSION="${PHP_VERSION:-8.3.13}"
PHP_EXTENSIONS="${PHP_EXTENSIONS:-mbstring,xml,curl,zip}"
INSTALL_COMPOSER="${INSTALL_COMPOSER:-true}"

if [[ "$RUNNER_OS" != "Linux" ]]; then
  echo "This action only supports Linux GitHub runners."
  exit 1
fi

case "$PHP_VERSION" in
  8.2.*|8.3.*)
    ;;
  *)
    echo "Unsupported PHP version: ${PHP_VERSION}. Allowed versions: 8.2.x, 8.3.x"
    exit 1
    ;;
esac

PHP_MAJOR_MINOR="${PHP_VERSION%.*}"

configure_php_repository() {
  local runner_codename
  local repository_codename

  runner_codename="$(. /etc/os-release && printf '%s' "${VERSION_CODENAME:-}")"
  repository_codename="$runner_codename"

  # Ondrej's PPA may not publish a suite on the newest GitHub-hosted image.
  # Noble is the closest supported Ubuntu release and its packages are
  # compatible with the newer runner for the PHP versions supported here.
  if [[ "$runner_codename" == "resolute" || -z "$runner_codename" ]]; then
    repository_codename="noble"
  fi

  sudo add-apt-repository -y ppa:ondrej/php

  if [[ "$repository_codename" != "$runner_codename" ]]; then
    while IFS= read -r source_file; do
      sudo sed -i -E \
        "s#(https?://ppa\.launchpadcontent\.net/ondrej/php/ubuntu[[:space:]]+)[^[:space:]]+#\1${repository_codename}#" \
        "$source_file"
      sudo sed -i -E "s/^Suites: .*/Suites: ${repository_codename}/" "$source_file"
    done < <(grep -rl 'ondrej/php' /etc/apt/sources.list.d 2>/dev/null || true)
  fi
}

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  software-properties-common \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

# Ensure a modern PHP repository is available.
configure_php_repository
sudo apt-get update

# Install the exact CLI/runtime version requested.
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  "php${PHP_MAJOR_MINOR}" \
  "php${PHP_MAJOR_MINOR}-cli" \
  "php${PHP_MAJOR_MINOR}-common"

# Install any requested extensions.
IFS=',' read -r -a exts <<< "$PHP_EXTENSIONS"
for ext in "${exts[@]}"; do
  ext="${ext//[[:space:]]/}"
  if [[ -n "$ext" ]]; then
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "php${PHP_MAJOR_MINOR}-${ext}"
  fi
done

# Ensure CLI resolves to the intended version.
sudo update-alternatives --set php "/usr/bin/php${PHP_MAJOR_MINOR}"

# Verify the installed runtime version.
php -v

# Optionally install Composer.
if [[ "$INSTALL_COMPOSER" == "true" ]]; then
  curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
  sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
  composer --version
fi
