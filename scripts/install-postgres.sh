#!/bin/bash

# Install PostgreSQL on Debian

set -euo pipefail

success() {
        local GREEN='\033[32m'
        local RESET='\033[0m'
        echo -e "${GREEN}$1${RESET}"
}

error() {
        local RED='\033[31m'
        local RESET='\033[0m'
        echo -e "${RED}$1${RESET}"
}

echo "Installing curl and ca-certificates.."
apt-get -y install curl ca-certificates > /dev/null

echo "Ensure /usr/share/postgresql-common/pgdg exists.."
install -d /usr/share/postgresql-common/pgdg

if [[ -f /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc ]]; then
        echo "Postgres signing key already exists, skipping.."
else
        echo "Installing Postgres signing key.."
        curl --fail --show-error \
          -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc \
          https://www.postgresql.org/media/keys/ACCC4CF8.asc
fi

if [[ -s /etc/apt/sources.list.d/pgdg.list ]]; then
        echo "Postgres repo is already added, skipping.."
else
        if [[ ! -f /etc/os-release ]]; then
                error "/etc/os-release not found, cannot determine OS codename"
                exit 1
        fi
        source /etc/os-release
        sh -c "echo 'deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $VERSION_CODENAME-pgdg main' > /etc/apt/sources.list.d/pgdg.list"
fi

echo "Updating packages.."
apt-get update > /dev/null


if [[ -n "$1" ]]; then
        pg_version="$1"
else
        read -p "Enter the PostgreSQL version you want to install: " pg_version
fi

if [[ ! "$pg_version" =~ ^[0-9]+$ ]]; then
        error "Invalid version number: $pg_version"
        exit 1
fi

echo "Installing PostgreSQL version $pg_version"

apt-get install -y "postgresql-$pg_version" > /dev/null

success "Done. PostgreSQL $pg_version installed."