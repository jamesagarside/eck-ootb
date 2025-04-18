#! /bin/bash

# Load configuration variables
source configuration

KUBERNETES_API_ENDPOINT=https://$KUBERNETES_ENDPOINT:$KUBERNETES_API_PORT

# Generate Secrets
talosctl gen secrets -o talos/configurations/secrets.yaml

# Talosconfiguration
# Generate the Talos configuration
talosctl gen config --talos-version $TALOS_VERSION \
                    --with-secrets talos/configurations/secrets.yaml \
                    --config-patch-control-plane @talos/patches/$DEPLOYMENT_TYPE/controlplane.patch.yaml \
                    --output-types talosconfig -o talos/configurations/talosconfig \
                    $KUBERNETES_CLUSTER_NAME \
                    $KUBERNETES_API_ENDPOINT --force

# Control Plane Configuration
# Generate the control plane configuration
talosctl gen config --talos-version $TALOS_VERSION \
                    --with-secrets talos/configurations/secrets.yaml \
                    --config-patch @talos/patches/configuration.patch.yaml \
                    --config-patch @talos/patches/services.patch.yaml  \
                    --config-patch @talos/patches/base.patch.yaml  \
                    --config-patch-control-plane @talos/patches/$DEPLOYMENT_TYPE/controlplane.patch.yaml \
                    --output-types controlplane \
                    -o talos/configurations/controlplane.yaml \
                    $KUBERNETES_CLUSTER_NAME $KUBERNETES_API_ENDPOINT --force

# Worker Node Configuration
# Generate the worker node configuration if deployment type is production
if [ "$DEPLOYMENT_TYPE" == "production" ]; then
    talosctl gen config --talos-version $TALOS_VERSION \
                        --with-secrets talos/configurations/secrets.yaml \
                        --config-patch @talos/patches/configuration.patch.yaml \
                        --config-patch @talos/patches/services.patch.yaml  \
                        --config-patch @talos/patches/base.patch.yaml  \
                        --config-patch-worker @talos/patches/$DEPLOYMENT_TYPE/worker.patch.yaml \
                        --output-types worker \
                        -o talos/configurations/worker.yaml \
                        $KUBERNETES_CLUSTER_NAME $KUBERNETES_API_ENDPOINT --force
fi

talosctl --talosconfig=talos/configurations/talosconfig config endpoint $KUBERNETES_ENDPOINT
talosctl --talosconfig=talos/configurations/talosconfig config node $KUBERNETES_ENDPOINT