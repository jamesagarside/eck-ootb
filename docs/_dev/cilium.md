# Gateway API

The Cilium GatewayAPI implementation was selected as the default mechanism for exposing resources within Kubernetes because it is tightly coupled with Cilium functionality. The Ingress controller also displayed strange behavior, making GatewayAPI a more reliable choice.

The ECK-OOTB implementation takes advantage of GatewayAPI TLS Passthrough and TLSRoute, as Elastic resources handle TLS themselves. Note that TLSRoute is a feature still under development by the Kubernetes GatewayAPI SIG.

## Install GatewayAPI CRDs

### Standard Channel

To install the GatewayAPI CRDs using the standard channel, run the following command:

```
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml
```

### Experimental Channel

To install the GatewayAPI CRDs using the experimental channel, run the following command:

```
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/experimental-install.yaml
```

## Install Cilium with GatewayAPI Configured

To install or upgrade Cilium with GatewayAPI configured, use the following command:

```
cilium upgrade \
  --set ipam.mode=kubernetes \
  --set kubeProxyReplacement=true \
  --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
  --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
  --set cgroup.autoMount.enabled=false \
  --set cgroup.hostRoot=/sys/fs/cgroup \
  --set k8sServiceHost=localhost \
  --set k8sServicePort=7445 \
  --set l7Proxy=true \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true \
  --set gatewayAPI.enabled=true \
  --set gatewayAPI.hostNetwork.enabled=true \
  --set gatewayAPI.gatewayClass.create=auto \
  --set gatewayAPI.hostNetwork.nodes.matchLabels.ingress=true \
  --set envoy.enabled=true \
  --set envoy.securityContext.capabilities.keepCapNetBindService=true \
  --set envoy.securityContext.capabilities.envoy="{NET_BIND_SERVICE,NET_ADMIN,SYS_ADMIN}"
```

## Ingress Controller

Using the Cilium Ingress controller with `hostNetwork` mode displayed strange behavior when trying to bind multiple listeners. As a result, GatewayAPI was chosen instead for its stability and better integration with Cilium.

If you still wish to use the Ingress controller, you can configure it as follows:

```
# IngressController HostNetwork
cilium upgrade \
  --set ipam.mode=kubernetes \
  --set kubeProxyReplacement=true \
  --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
  --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
  --set cgroup.autoMount.enabled=false \
  --set cgroup.hostRoot=/sys/fs/cgroup \
  --set k8sServiceHost=localhost \
  --set k8sServicePort=7445 \
  --set l7Proxy=true \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true \
  --set ingressController.enabled=true \
  --set ingressController.default=true \
  --set ingressController.enforceHttps=false \
  --set ingressController.hostNetwork.enabled=true \
  --set ingressController.hostNetwork.nodes.matchLabels.ingress=true \
  --set ingressController.loadbalancerMode=dedicated \
  --set ingressController.service.type=ClusterIP \
  --set ingressController.service.externalTrafficPolicy="~" \
  --set ingressController.hostNetwork.sharedListenerPort=443 \
  --set envoy.enabled=true \
  --set envoy.securityContext.capabilities.keepCapNetBindService=true \
  --set envoy.securityContext.capabilities.envoy="{NET_BIND_SERVICE,NET_ADMIN,SYS_ADMIN}"
```
