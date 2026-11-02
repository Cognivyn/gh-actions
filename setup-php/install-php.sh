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

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  software-properties-common \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

# Ensure a modern PHP repository is available.
sudo add-apt-repository -y ppa:ondrej/php
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
