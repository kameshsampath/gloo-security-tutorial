ca:
  name: "My Gloo Minikube Demos"
  address: ":8443"
  dns: "${GLOO_GATEWAY_PROXY_IP}.nip.io,*-${GLOO_GATEWAY_PROXY_IP}.nip.io,*.${GLOO_GATEWAY_PROXY_IP}.nip.io,${MINIKUBE_IP}.nip.io,*-${MINIKUBE_IP}.nip.io,step-certificates.step-certificates-system.svc.cluster.local,${GLOO_GATEWAY_PROXY_IP},${MINIKUBE_IP}"
  password: "${STEP_CA_PASSWORD}"
  provisioner:
    name: "${STEP_PROVISIONER_NAME}"
    password: "${STEP_CA_PASSWORD}"
service:
  type: NodePort
  targetPort: 8443
