#!/bin/bash
# Install PostgreSQL on Debian or RHEL

set -euo pipefail

pg_version="${1:-}"

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

####################################
# Ensure dependencies
####################################
echo "[INFO] Ensure curl and ca-certificates are installed.."
install_pkg curl ca-certificates

####################################
# Repo setup
####################################
echo "[INFO] Setting up postgres repo.. checking.."
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

if [[ "$ID" == "rocky" ]]; then
  dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
  # Disable the built-in PostgreSQL module per the PostgreSQL docs
  dnf -qy module disable postgresql
fi

####################################
# Update pkgs and get version
####################################
update_pkgs
if [[ -n "$pg_version" ]]; then
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
if [[ "$ID" == "debian" ]]; then
  install_pkg "postgresql-$pg_version"
else
  # postgresql-contrib contains supporting packages like pgcrypto that are needed for stork db tool. This lib is installed along with postgresql main package in debian, but must be installed separately on rhel distros
  install_pkg "postgresql$pg_version-server" "postgresql$pg_version-contrib"
  # Run initdb for initial setup
  echo "[INFO] Running initdb.."
  /usr/pgsql-$pg_version/bin/postgresql-$pg_version-setup initdb
  echo "[INFO] initdb OK."
fi

echo "[SUCCESS] Done. PostgreSQL $pg_version installed."

