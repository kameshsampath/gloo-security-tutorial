ca:
  name: "My Gloo Minikube Demos"
  address: ":8443"
  dns: "${MINIKUBE_IP}.nip.io,*-${MINIKUBE_IP}.nip.io,step-certificates.step-certificates-system.svc.cluster.local,${MINIKUBE_IP}"
  password: "${STEP_CA_PASSWORD}"
  provisioner:
    name: "${STEP_PROVISIONER_NAME}"
    password: "${STEP_CA_PASSWORD}"
service:
  type: NodePort
  targetPort: 8443
