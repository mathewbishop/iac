#!/bin/bash
# Install Kea 3.0
# Supports Debian and Rocky

set -euo pipefail

# Get the OS info
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

# Ensure dependencies
install_pkg curl ca-certificates

# If Rocky, enable the EPEL, we will need it for Kea install
if [[ "$ID" == 'rocky' ]]; then
  dnf config-manager --set-enabled crb
  dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
fi

# Install Kea repository
if [[ "$ID" == "debian" ]]; then
  if [[ ! -f /etc/apt/sources.list.d/isc-kea-3-0.list ]]; then
    # Kea Repo Setup
    curl -1sLf \
      'https://dl.cloudsmith.io/public/isc/kea-3-0/setup.deb.sh' |
      sudo -E bash
  else
    echo "[INFO] Kea 3.0 repo already installed.."
  fi
fi

if [[ "$ID" == "rocky" ]]; then
  if [[ ! -f /etc/yum.repos.d/isc-kea-3-0.repo ]]; then
    curl -1sLf \
      'https://dl.cloudsmith.io/public/isc/kea-3-0/setup.rpm.sh' |
      sudo -E bash
  else
    echo "[INFO] Kea 3.0 repo already installed.."
  fi
fi

# Install Kea if not already installed
if ! is_installed isc-kea; then
  update_pkgs
  echo "[INFO] Installing isc-kea metapackage.."
  install_pkg isc-kea
else
  echo "[INFO] Kea metapackage already installed.."
fi

# Install kea control agent (still needed for Stork as of Stork 2.3)
if ! is_installed isc-kea-ctrl-agent; then
  echo "[INFO] Installing kea control agent.."
  install_pkg isc-kea-ctrl-agent
else
  echo "[INFO] Kea control agent is already installed.."
fi
