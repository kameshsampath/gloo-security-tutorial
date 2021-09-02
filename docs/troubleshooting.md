---
title: Troubleshooting
summary: Troubleshooting any issues with certificates.
authors:
  - Kamesh Sampath
date: 2021-08-19
---

## Certifcate Request failed

When `CertificatRequest` fails, e.g.

```bash
kubectl get certificaterequests.cert-manager.io -n step-certificates-system ${FRUITS_UI_IP}.nip.io -o json | jq '.status.conditions[]'
```

If the command gives an output like,

```json hl_lines="10-12"
{
  "lastTransitionTime": "2021-09-02T04:19:17Z",
  "message": "Certificate request has been approved by cert-manager.io",
  "reason": "cert-manager.io",
  "status": "True",
  "type": "Approved"
}
{
  "lastTransitionTime": "2021-09-02T04:19:17Z",
  "message": "Failed to sign certificate request: The request lacked necessary authorization to be completed. Please see the certificate authority logs for more info.",
  "reason": "Failed",
  "status": "False",
  "type": "Ready"
}
```

Check the **certificate authority** logs for messages in our case the CA `step-ca` and lets check its logs,

```bash
stern -n step-certificates-system step-certificates-0 -i 'level=warning|error'
```

!!! tip
    [stern](https://github.com/wercker/stern) is useful kubernetes log viewer
