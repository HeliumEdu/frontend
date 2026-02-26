#!/usr/bin/env bash
#
# Start the frontend container for integration testing.
# Can be fetched and run remotely:
#   curl -fsSL "https://raw.githubusercontent.com/HeliumEdu/frontend/main/bin/start-frontend.sh" | bash
#
# Environment variables:
#   FRONTEND_IMAGE - Docker image to use (default: public.ecr.aws/heliumedu/helium/frontend-web:amd64-latest)
#   PLATFORM - Platform architecture: arm64 or amd64 (default: arm64, used if FRONTEND_IMAGE not set)
#

set -euo pipefail

# Determine the image to use
# Prefer local images if available, otherwise fall back to ECR Public
PLATFORM="${PLATFORM:-arm64}"
LOCAL_IMAGE="helium/frontend-web:${PLATFORM}-latest"
if docker image inspect "$LOCAL_IMAGE" &>/dev/null; then
    echo "Using local image..."
    FRONTEND_IMAGE="${FRONTEND_IMAGE:-helium/frontend-web:${PLATFORM}-latest}"
else
    echo "Local image not found, will pull from ECR Public..."
    FRONTEND_IMAGE="${FRONTEND_IMAGE:-public.ecr.aws/heliumedu/helium/frontend-web:${PLATFORM}-latest}"
fi

CONTAINER_NAME="helium-frontend-web"

echo "Starting frontend container ..."
echo "  Image: ${FRONTEND_IMAGE}"

# Stop any existing container
docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

# Pull the image if using ECR
if [[ "$FRONTEND_IMAGE" == *"public.ecr.aws"* ]]; then
    echo "Pulling image ..."
    # Logout from ECR to prevent credential helper issues
    docker logout public.ecr.aws 2>/dev/null || true
    docker pull "${FRONTEND_IMAGE}"
fi

# Start the container
echo "Starting container ..."
docker run -d \
    --name "${CONTAINER_NAME}" \
    -p 8080:8080 \
    "${FRONTEND_IMAGE}"

# Wait for the frontend to be ready
echo "Waiting for frontend to be ready ..."
MAX_ATTEMPTS=30
ATTEMPT=0
until curl -sf http://localhost:8080 > /dev/null 2>&1; do
    ATTEMPT=$((ATTEMPT + 1))
    if [ "${ATTEMPT}" -ge "${MAX_ATTEMPTS}" ]; then
        echo "Frontend failed to start within ${MAX_ATTEMPTS} seconds"
        docker logs "${CONTAINER_NAME}"
        exit 1
    fi
    echo "  Waiting... (${ATTEMPT}/${MAX_ATTEMPTS})"
    sleep 1
done

echo "Frontend is ready at http://localhost:8080"
