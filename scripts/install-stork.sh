#!/bin/bash
# Install Stork on debian or rocky
# Requires PostgreSQL for full benefit

set -euo pipefail

source /etc/os-release

if [[ "$ID" != "debian" && "$ID" != "rocky" ]]; then
  echo "[ERROR] OS is not Debian or Rocky. Only Debian and Rocky are supported. Exiting.."
  exit 1
fi

install_pkg() {
  if [[ "$ID" == "debian" ]]; then
    apt-get install -y "$@" >/dev/null
  else
    dnf install -y "$@" >/dev/null
  fi
}

is_installed() {
  if [[ "$ID" == "debian" ]]; then
    dpkg -s "$1" &>/dev/null
  else
    dnf list installed "$1" &>/dev/null
  fi
}

update_pkgs() {
  echo "[INFO] Updating packages.."
  if [[ "$ID" == "debian" ]]; then
    apt-get update >/dev/null
  else
    dnf -y makecache >/dev/null
  fi
}

#######################################
# Install Repo
#######################################
echo "[INFO] Checking for stork repo.."

if [[ "$ID" == "debian" ]]; then
  if [[ ! -f /etc/apt/sources.list.d/isc-stork.list ]]; then
    echo "[INFO] Installing stork repo.."
    curl -1sLf \
      'https://dl.cloudsmith.io/public/isc/stork/setup.deb.sh' |
      sudo -E bash
    echo "[INFO] OK."
  else
    echo "[INFO] Stork repo already installed.. OK"
  fi
fi

if [[ "$ID" == "rocky" ]]; then
  if [[ ! -f /etc/yum.repos.d/isc-stork.repo ]]; then
    echo "[INFO] Installing stork repo.."
    curl -1sLf \
      'https://dl.cloudsmith.io/public/isc/stork/setup.rpm.sh' |
      sudo -E bash
    echo "[INFO] OK."
  else
    echo "[INFO] Stork repo already installed.. OK"
  fi
fi

#######################################
# Install Stork Package
#######################################
echo "[INFO] Checking for stork package.."

if ! is_installed isc-stork-server; then
  echo "[INFO] Installing stork server.."
  install_pkg isc-stork-server
  echo "[INFO] OK."
else
  echo "[INFO] Stork server is already installed.. OK"
fi

#######################################
# Setup Stork Database
#######################################
if ! which psql &>/dev/null; then
  echo "[WARN] PostgreSQL is not installed, cannot continue with setting up stork database. Exiting.."
  exit 1
else
  echo "[INFO] Setting up stork database.."
  # Have to run this as postgres system user since it will use local peer auth to connect to postgres server
  set +e # Turn off the -e option so that the command run in the subshell will report failure. Otherwise it does not
  output=$(sudo -u postgres stork-tool db-create --db-name stork --db-user stork-server)
  exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    echo "[ERR] Stork DB setup failed with exit code $exit_code"
    echo "$output" >&2
    exit 1
  fi
  set -e # Reset the -e option

  if [[ $output =~ password=\"([^\"]+)\" ]]; then
    password=${BASH_REMATCH[1]}
    echo "[INFO] Database password is $password"
  else
    echo "[ERR] Could not extract password from stork-tool command, which is needed for configuring the stork server.env file. Exiting.."
    exit 1
  fi
  echo "[INFO] Configuring /etc/stork/server.env with database info.."
  sed -i 's/^# STORK_DATABASE_USER_NAME=.*/STORK_DATABASE_USER_NAME=stork-server/' /etc/stork/server.env
  sed -i "s#^STORK_DATABASE_PASSWORD=.*#STORK_DATABASE_PASSWORD=$password#" /etc/stork/server.env
  echo "[INFO] Done. Stork env configured. OK."
fi

echo "[INFO] Done. Stork is installed."
