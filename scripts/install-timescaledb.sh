#!/bin/bash

# Install TimescaleDB on Debian

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

echo "Ensuring wget and gpg are present.."

apt-get -y install wget gnupg2 >/dev/null

if [[ -f /etc/apt/sources.list.d/timescaledb.list ]]; then
  echo "TimescaleDB package already added, skipping.."
else
  echo "deb https://packagecloud.io/timescale/timescaledb/debian/ $(lsb_release -c -s) main" | tee /etc/apt/sources.list.d/timescaledb.list
fi

if [[ -f /etc/apt/trusted.gpg.d/timescaledb.gpg ]]; then
  echo "Timescale GPG key already added, skipping.."
else
  wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/timescaledb.gpg
fi

echo "Updating packages.."

apt-get update

read -p "What version of PostgreSQL do you want to install Timescale for? " pg_version

read -p "What version of TimescaleDB do you want to install? " timescale_version

if [[ -z "$pg_version" || ! "$pg_version" =~ ^[0-9]+$ ]]; then
  error "PostgreSQL number must not be empty and must be a number (e.g. 16). Exiting."
  exit 1
fi

echo "Installing timescaledb-2-postgresql-$pg_version='$timescale_version'"

apt-get install -y timescaledb-2-postgresql-"$pg_version=$timescale_version" timescaledb-2-loader-postgresql-"$pg_version=$timescale_version" >/dev/null

echo "Running timescaledb-tune"

timescaledb-tune --quiet --yes

success "Finished installing TimescaleDB"

echo "Restarting postgresql.."

systemctl restart postgresql

success "Done. TimescaleDB installed."

