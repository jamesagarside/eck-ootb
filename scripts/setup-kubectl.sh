#! /bin/bash 

# Load configuration variables
source configuration

talosctl --talosconfig=talos/configurations/talosconfig config endpoint $KUBERNETES_ENDPOINT
talosctl --talosconfig=talos/configurations/talosconfig config node $KUBERNETES_ENDPOINT
talosctl --talosconfig=talos/configurations/talosconfig kubeconfig talos/configurations/kubeconfig --force
