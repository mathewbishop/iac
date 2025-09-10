#!/bin/bash
# Install PostgreSQL on Debian or RHEL

set -euo pipefail

update_pkgs() {
  echo "[INFO] Updating packages.."
  if [[ "$ID" == "debian" ]]; then
    apt-get update >/dev/null
  else
    dnf -y makecache >/dev/null
  fi
}

install_pkg() {
  if [[ "$ID" == "debian" ]]; then
    apt-get install -y "$@" >/dev/null
  else
    dnf install -y "$@" >/dev/null
  fi
}

source /etc/os-release

echo "[INFO] Ensure curl and ca-certificates are installed.."
install_pkg curl ca-certificates

echo "[INFO] Postgres repo setup.."
if [[ "$ID" == "debian" ]]; then
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
    sh -c "echo 'deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $VERSION_CODENAME-pgdg main' > /etc/apt/sources.list.d/pgdg.list"
  fi
fi

update_pkgs

if [[ -n "$1" ]]; then
  pg_version="$1"
else
  read -p "Enter the PostgreSQL version you want to install: " pg_version
fi

if [[ ! "$pg_version" =~ ^[0-9]+$ ]]; then
  echo "[ERR] Invalid version number: $pg_version. Exiting.."
  exit 1
fi

####################################
# Postgresql Package Install
####################################
echo "[INFO] Installing PostgreSQL version $pg_version"
install_pkg "postgresql-$pg_version"
echo "[SUCCESS] Done. PostgreSQL $pg_version installed."

