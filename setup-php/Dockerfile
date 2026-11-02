FROM ubuntu:22.04

LABEL org.opencontainers.image.authors="S Saha"
LABEL org.opencontainers.image.source="https://github.com/Cognivyn/gh-actions"
LABEL org.opencontainers.image.description="Setup PHP Action Container with PHP 8.2 and 8.3"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install base dependencies
RUN apt-get update && apt-get install -y \
    software-properties-common \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Add Ondřej PHP PPA for PHP packages
RUN add-apt-repository -y ppa:ondrej/php

# Install PHP 8.2 with common extensions
RUN apt-get update && apt-get install -y \
    php8.2 \
    php8.2-cli \
    php8.2-common \
    php8.2-mbstring \
    php8.2-xml \
    php8.2-curl \
    php8.2-zip \
    php8.2-bcmath \
    php8.2-gmp \
    php8.2-mysql \
    php8.2-pgsql \
    php8.2-sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# Install PHP 8.3 with common extensions
RUN apt-get update && apt-get install -y \
    php8.3 \
    php8.3-cli \
    php8.3-common \
    php8.3-mbstring \
    php8.3-xml \
    php8.3-curl \
    php8.3-zip \
    php8.3-bcmath \
    php8.3-gmp \
    php8.3-mysql \
    php8.3-pgsql \
    php8.3-sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# Set PHP 8.3 as default
RUN update-alternatives --set php /usr/bin/php8.3

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php \
    && php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && rm /tmp/composer-setup.php

# Copy the entrypoint script
COPY --chmod=755 entrypoint.sh /usr/local/bin/setup-php-entrypoint

# Set working directory
WORKDIR /github/workspace

ENTRYPOINT ["setup-php-entrypoint"]
