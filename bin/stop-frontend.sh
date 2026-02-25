#!/usr/bin/env bash
#
# Stop the frontend container.
# Can be fetched and run remotely:
#   curl -fsSL "https://raw.githubusercontent.com/HeliumEdu/frontend/main/bin/stop-frontend.sh" | bash
#

set -euo pipefail

CONTAINER_NAME="helium-frontend-web"

echo "Stopping frontend container..."
docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true
echo "Frontend container stopped"
