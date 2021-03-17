# Helm Chart for FreeRADIUS NTLM

This is a _very_ basic helm chart implementation for FreeRADIUS. It also includes an option for a Prometheus Exporter.

## TL;DR

```bash
helm install -f myvalues.yaml freeradius ./
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| autoscaling.enabled | bool | `false` |  |
| autoscaling.maxReplicas | int | `100` |  |
| autoscaling.minReplicas | int | `1` |  |
| autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| exporter.enabled | bool | `false` |  |
| exporter.image.pullPolicy | string | `"IfNotPresent"` |  |
| exporter.image.repository | string | `"esutwo/freeradius-exporter"` |  |
| exporter.image.resources | object | `{}` |  |
| exporter.image.tag | string | `"latest"` |  |
| freeradius.AD_DOMAIN | string | `""` |  |
| freeradius.AD_PASSWORD.existingSecret.enabled | bool | `false` |  |
| freeradius.AD_PASSWORD.existingSecret.name | string | `""` |  |
| freeradius.AD_PASSWORD.existingSecret.secretKey | string | `""` |  |
| freeradius.AD_PASSWORD.value | string | `""` |  |
| freeradius.AD_SERVER | string | `""` |  |
| freeradius.AD_USERNAME | string | `""` |  |
| freeradius.AD_WORKGROUP | string | `""` |  |
| freeradius.EDUROAM_ACCTHOST | string | `""` |  |
| freeradius.EDUROAM_AUTHHOST | string | `""` |  |
| freeradius.EDUROAM_CLIENT_SECRET.existingSecret.enabled | bool | `false` |  |
| freeradius.EDUROAM_CLIENT_SECRET.existingSecret.name | string | `""` |  |
| freeradius.EDUROAM_CLIENT_SECRET.existingSecret.secretKey | string | `""` |  |
| freeradius.EDUROAM_CLIENT_SECRET.value | string | `""` |  |
| freeradius.EDUROAM_CLIENT_SERVER | string | `""` |  |
| freeradius.EDUROAM_SECRET.existingSecret.enabled | bool | `false` |  |
| freeradius.EDUROAM_SECRET.existingSecret.name | string | `""` |  |
| freeradius.EDUROAM_SECRET.existingSecret.secretKey | string | `""` |  |
| freeradius.EDUROAM_SECRET.value | string | `""` |  |
| freeradius.FR_ACCESS_ALLOWED_CIDR | string | `""` |  |
| freeradius.FR_DOMAIN | string | `""` |  |
| freeradius.FR_SHARED_SECRET.existingSecret.enabled | bool | `false` |  |
| freeradius.FR_SHARED_SECRET.existingSecret.name | string | `""` |  |
| freeradius.FR_SHARED_SECRET.existingSecret.secretKey | string | `""` |  |
| freeradius.FR_SHARED_SECRET.value | string | `""` |  |
| fullnameOverride | string | `""` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"freeradius/freeradius-server"` |  |
| image.resources | object | `{}` |  |
| image.tag | string | `"3.0.19"` |  |
| imagePullSecrets | list | `[]` |  |
| ingress.annotations | object | `{}` |  |
| ingress.enabled | bool | `false` |  |
| ingress.hosts[0].host | string | `"chart-example.local"` |  |
| ingress.hosts[0].paths | list | `[]` |  |
| ingress.tls | list | `[]` |  |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| podAnnotations | object | `{}` |  |
| podSecurityContext | object | `{}` |  |
| pod_hostname | string | `"k8s-freeradius"` |  |
| replicaCount | int | `1` |  |
| securityContext | object | `{}` |  |
| service.acc_port | int | `1813` |  |
| service.auth_port | int | `1812` |  |
| service.exp_port | int | `9812` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| tolerations | list | `[]` |  |

