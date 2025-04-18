#!/bin/bash

# Load configuration variables
source configuration
KUBERNETES_API_ENDPOINT=https://$KUBERNETES_ENDPOINT:$KUBERNETES_API_PORT


# Check if the required files exist
if [ ! -f "talos/configurations/talosconfig" ]; then
    echo "Error: talos/configurations/talosconfig does not exist. Have you ran generate-configurations.sh?"
    exit 1
fi
if [ ! -f "talos/configurations/controlplane.yaml" ]; then
    echo "Error: talos/configurations/controlplane.yaml does not exist. Have you ran generate-configurations.sh?"
    exit 1
fi

if [ "$DEPLOYMENT_TYPE" == "production" ]; then
    if [ ! -f "talos/configurations/worker.yaml" ]; then
        echo "Error: talos/configurations/worker.yaml does not exist. Have you ran generate-configurations.sh?"
        exit 1
    fi
fi



# If inital node is in maintaince mode apply configuration and bootstrap
if [ "$(talosctl get machinestatus --insecure --nodes $KUBERNETES_ENDPOINT --endpoints $KUBERNETES_API_ENDPOINT --talosconfig=talos/configurations/talosconfig -o json | jq -r .spec.stage)" == "maintenance" ]; then

    # Apply the Talos configuration to inital control plane node
    echo "Applying the Talos configuration to the control plane node..."
    talosctl apply-config --insecure --nodes $KUBERNETES_ENDPOINT --file talos/configurations/controlplane.yaml



    # Wait for the inital control plane node to bootstrap
    attempt=0
    max_attempts=10
    until talosctl bootstrap --nodes $KUBERNETES_ENDPOINT --endpoints $KUBERNETES_API_ENDPOINT --talosconfig=talos/configurations/talosconfig || [ $attempt -ge $max_attempts ]; do
        echo "Bootstrap attempt $((attempt + 1)) failed. Retrying in 20 seconds..."
        attempt=$((attempt + 1))
        sleep 20
    done

    if [ $attempt -ge $max_attempts ]; then
        echo "Failed to bootstrap after $max_attempts attempts."
        exit 1
    fi
fi



while ! talosctl health --endpoints $KUBERNETES_API_ENDPOINT --nodes $KUBERNETES_ENDPOINT --talosconfig=talos/configurations/talosconfig | grep -q '"health": "true"'; do
    echo "Waiting for $KUBERNETES_API_ENDPOINT to become healthy via RPC..."
    sleep 5
done