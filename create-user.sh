#!/bin/bash
set -e

SYNAPSE_CONTAINER_NAME="matrix-synapse"
HOMESERVER_CONFIG_PATH="/data/homeserver.yaml"
SYNAPSE_API_URL="http://localhost:8008"
SYNAPSE_UID=991
SYNAPSE_GID=991
USERNAME="$1"
PASSWORD="$2"
IS_ADMIN="${3:-no}"

if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    echo "Usage: $0 <username> <password> [admin|no_admin]"
    echo "  <username>      : The desired Matrix username (e.g., alice)"
    echo "  <password>      : A strong password for the user"
    echo "  [admin|no_admin]: Optional. Set to 'admin' or 'yes' to make the user an administrator. Defaults to 'no_admin'."
    echo ""
    echo "Example: $0 alice MyStrongP@ssw0rd admin"
    echo "Example: $0 bob SecurePassword123 no_admin"
    exit 1
fi

echo "Checking if Synapse container '$SYNAPSE_CONTAINER_NAME' is running and healthy..."
CONTAINER_STATUS=$(docker inspect -f '{{.State.Status}}' "$SYNAPSE_CONTAINER_NAME" 2>/dev/null || true)
HEALTH_STATUS=$(docker inspect -f '{{.State.Health.Status}}' "$SYNAPSE_CONTAINER_NAME" 2>/dev/null || true)

if [ "$CONTAINER_STATUS" != "running" ]; then
    echo "Error: Synapse container '$SYNAPSE_CONTAINER_NAME' is not running. Current status: '$CONTAINER_STATUS'."
    echo "Please ensure your Matrix homeserver is started with 'docker-compose up -d' before running this script."
    exit 1
fi

if [ "$HEALTH_STATUS" != "healthy" ]; then
    echo "Synapse container is running but not yet healthy. Current health status: '$HEALTH_STATUS'."
    echo "Please wait a moment for Synapse to fully start and become healthy, then try again."
    exit 1
fi
echo "Synapse container is healthy and ready."
REGISTER_CMD_ARGS="-c ${HOMESERVER_CONFIG_PATH} ${SYNAPSE_API_URL} -u ${USERNAME} -p ${PASSWORD}"
if [ "${IS_ADMIN,,}" = "admin" ] || [ "${IS_ADMIN,,}" = "yes" ] || [ "${IS_ADMIN,,}" = "true" ]; then
    REGISTER_CMD_ARGS="${REGISTER_CMD_ARGS} -a"
    echo "Attempting to create user '$USERNAME' as an ADMINISTRATOR."
else
    echo "Attempting to create user '$USERNAME' (non-admin)."
fi
echo "Executing user creation command inside the container..."
docker exec -it "$SYNAPSE_CONTAINER_NAME" gosu "$SYNAPSE_UID":"$SYNAPSE_GID" register_new_matrix_user $REGISTER_CMD_ARGS
if [ $? -eq 0 ]; then
    echo "User '$USERNAME' created successfully!"
else
    echo "Failed to create user '$USERNAME'."
    echo "Please check the logs of your Synapse container for more details (e.g., 'docker-compose logs synapse')."
    exit 1
fi