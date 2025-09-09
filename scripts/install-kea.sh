#!/bin/bash
# Install Kea 3.0
# Supports Debian and Rocky

set -euo pipefail

# Get the OS info
source /etc/os-release

if [[ "$ID" != "debian" && "$ID" != "rocky" ]]; then
  echo "OS is not Debian or Rocky. Only Debian and Rocky are supported. Exiting.."
  exit 1
fi

# Ensure dependencies
if [[ "$ID" == 'debian' ]]; then
  apt-get install -y curl ca-certificates
fi

if [[ "$ID" == 'rocky' ]]; then
  dnf install -y curl ca-certificates
  # Enable EPEL, we will need it later
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
    echo "Kea 3.0 repo already installed.."
  fi
fi

if [[ "$ID" == "rocky" ]]; then
  if [[ ! -f /etc/yum.repos.d/isc-kea-3-0.repo ]]; then
    curl -1sLf \
      'https://dl.cloudsmith.io/public/isc/kea-3-0/setup.rpm.sh' |
      sudo -E bash
  else
    echo "Kea 3.0 repo already installed.."
  fi
fi

# Check if kea metapackage is already installed
if [[ "$ID" == "debian" ]]; then
  if ! dpkg -l | grep -q isc-kea; then
    echo "Installing isc-kea metapackage.."
    apt-get update >/dev/null
    apt-get install -y isc-kea >/dev/null
  else
    echo "isc-kea is already installed.."
  fi
fi

if [[ "$ID" == "rocky" ]]; then
  if ! dnf list installed isc-kea &>/dev/null; then
    echo "Installing isc-kea metapackage.."
    dnf check-update >/dev/null
    dnf install -y isc-kea >/dev/null
  else
    echo "isc-kea is already installed.."
  fi
fi

# Install kea control agent (still needed for Stork as of Stork 2.3)
if [[ "$ID" == "debian" ]]; then
  if ! dpkg -l | grep -q isc-kea-ctrl-agent; then
    echo "Installing Kea Control Agent.."
    apt-get install -y isc-kea-ctrl-agent >/dev/null
  else
    echo "Kea control agent is already installed.."
  fi
fi

if [[ "$ID" == "rocky" ]]; then
  if ! dnf list installed isc-kea-ctrl-agent &>/dev/null; then
    echo "Installing Kea Control Agent.."
    dnf install -y isc-kea-ctrl-agent >/dev/null
  else
    echo "Kea control agent is already installed.."
  fi
fi

echo "Done. isc-kea and isc-kea-ctrl-agent are installed."
