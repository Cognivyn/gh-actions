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

  runner_codename="$(. /etc/os-release && printf '%s' "${VERSION_CODENAME:-}")"

  # The PPA does not publish Resolute packages. Sury is its canonical
  # successor for this Ubuntu release and provides matching dependencies.
  if [[ "$runner_codename" == "resolute" ]]; then
    curl -sSLo /tmp/debsuryorg-archive-keyring.deb \
      https://packages.sury.org/debsuryorg-archive-keyring.deb
    sudo dpkg -i /tmp/debsuryorg-archive-keyring.deb
    printf 'deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/php/ %s main\n' \
      "$runner_codename" | sudo tee /etc/apt/sources.list.d/php.list >/dev/null
    return
  fi

  sudo add-apt-repository -y ppa:ondrej/php
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

# Ensure CLI resolves to the intended version before inspecting loaded modules.
sudo update-alternatives --set php "/usr/bin/php${PHP_MAJOR_MINOR}"

extension_package_name() {
  case "$1" in
    pdo_mysql) printf '%s' mysql ;;
    pdo_pgsql) printf '%s' pgsql ;;
    pdo_sqlite) printf '%s' sqlite3 ;;
    *) printf '%s' "$1" ;;
  esac
}

# Install requested extensions. Some modules, such as openssl, are built into
# PHP or shipped with php-common and therefore do not have a separate Ubuntu
# package. PDO driver names also differ from their package names.
IFS=',' read -r -a exts <<< "$PHP_EXTENSIONS"
for ext in "${exts[@]}"; do
  ext="${ext//[[:space:]]/}"
  [[ -n "$ext" ]] || continue

  if php -r 'exit(extension_loaded($argv[1]) ? 0 : 1);' "$ext"; then
    echo "setup-php: extension '$ext' is already enabled"
    continue
  fi

  package_ext="$(extension_package_name "$ext")"
  package="php${PHP_MAJOR_MINOR}-${package_ext}"
  if ! apt-cache show "$package" >/dev/null 2>&1; then
    echo "setup-php: no Ubuntu package found for PHP extension '$ext' (looked for '$package')" >&2
    exit 1
  fi
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$package"
done

# Verify the installed runtime version.
php -v

# Optionally install Composer.
if [[ "$INSTALL_COMPOSER" == "true" ]]; then
  curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
  sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
  composer --version
fi
