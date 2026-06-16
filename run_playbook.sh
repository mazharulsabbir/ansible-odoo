#!/usr/bin/env bash
# ============================================================================
# Ansible Playbook Runner
# ============================================================================
#
# Helper script to run the Odoo deployment playbook with password prompts.
#
# Usage:
#   ./run_playbook.sh              # Full deployment
#   ./run_playbook.sh --check      # Dry run (no changes made)
#   ./run_playbook.sh --tags odoo  # Run specific tags only
#
# ============================================================================

set -e

CHECK_FLAG=""
EXTRA_ARGS=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --check)
      CHECK_FLAG="--check"
      shift
      ;;
    *)
      EXTRA_ARGS="$EXTRA_ARGS $1"
      shift
      ;;
  esac
done

# Run playbook with password prompts
# -k = prompt for SSH password
# -K = prompt for sudo/become password
ansible-playbook \
  -i inventory/hosts_password.ini \
  site.yml \
  -u root \
  -k -K \
  $CHECK_FLAG \
  $EXTRA_ARGS

# ============================================================================
# Alternative methods (uncomment as needed):
# ============================================================================
#
# Using SSH key authentication (recommended for production):
# ansible-playbook -i inventory/hosts.ini site.yml
#
# Using Ansible Vault for encrypted passwords:
# ansible-playbook -i inventory/hosts_password.ini site.yml --ask-vault-pass
#
# For automated/CI pipelines with vault password file:
# ansible-playbook -i inventory/hosts.ini site.yml --vault-password-file .vault_pass
#
# ============================================================================
