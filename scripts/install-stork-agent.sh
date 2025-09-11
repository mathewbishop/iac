#!/bin/bash
# Install stork agent on debian or RHEL

set -euo pipefail

source /etc/os-release

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
# Install Stork Agent Package
#######################################
echo "[INFO] Checking for stork agent package.."

if ! is_installed isc-stork-agent; then
  echo "[INFO] Installing stork agent.."
  install_pkg isc-stork-agent
  echo "[INFO] OK."
else
  echo "[INFO] Stork agent is already installed.. OK"
fi

echo "[INFO] Done. Stork agent is installed."
echo "[IMPORTANT] To complete setup, you must register stork agent with the stork server. To do this, run: sudo su stork-agent -s /bin/sh -c 'stork-agent register --server-url http://<stork-server-ip>:8080'"
