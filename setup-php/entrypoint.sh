#!/usr/bin/env bash
set -euo pipefail

PHP_VERSION="${INPUT_PHP_VERSION:-8.3.13}"
PHP_EXTENSIONS="${INPUT_EXTENSIONS:-mbstring,xml,curl,zip}"
INSTALL_COMPOSER="${INPUT_INSTALL_COMPOSER:-true}"

echo "setup-php: Requested PHP version: ${PHP_VERSION}"

# Extract major.minor version
PHP_MAJOR_MINOR="${PHP_VERSION%.*}"

# Validate version
case "$PHP_MAJOR_MINOR" in
  8.2|8.3)
    ;;
  *)
    echo "Error: Unsupported PHP version: ${PHP_VERSION}. Supported versions: 8.2.x, 8.3.x"
    exit 1
    ;;
esac

# Switch to the requested PHP version
echo "setup-php: Switching to PHP ${PHP_MAJOR_MINOR}"
update-alternatives --set php "/usr/bin/php${PHP_MAJOR_MINOR}"

# Verify the version
INSTALLED_VERSION=$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')
echo "setup-php: Active PHP version: ${INSTALLED_VERSION}"

# Verify PHP is working
php -v

# Check requested extensions
IFS=',' read -r -a exts <<< "$PHP_EXTENSIONS"
for ext in "${exts[@]}"; do
  ext="${ext//[[:space:]]/}"
  [[ -n "$ext" ]] || continue

  if php -r 'exit(extension_loaded($argv[1]) ? 0 : 1);' "$ext"; then
    echo "setup-php: Extension '$ext' is enabled"
  else
    echo "Error: Extension '$ext' is not available"
    exit 1
  fi
done

# Composer is pre-installed, just verify it's available
if [[ "$INSTALL_COMPOSER" == "true" ]]; then
  composer --version
  echo "setup-php: Composer is available"
fi

echo "setup-php: Setup complete"
