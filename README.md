## Red Hat Summit Connect — Event-Driven Ansible / OpenTelemetry Microlab (OpenShift)

Demo showing how Ansible Automation Platform and Event-Driven Ansible remediate issues using alerts from Prometheus/Alertmanager, OpenTelemetry, and Kafka, with tickets in the ITSM app.

### Prerequisites

- OpenShift cluster with admin `oc` access
- Ansible Automation Platform 2.6 (Controller + EDA) already installed (e.g. namespace `aap`)
- Cluster Alertmanager (`alertmanager-main` in `openshift-monitoring`)
- ITSM app deployed (e.g. `https://itsm-app-itsm-app.apps.ocp.zaskan.es/`)
- Ansible 2.14+ on a control node with `oc` CLI logged in

### Configuration

1. Install Ansible collections:

   ```bash
   ansible-galaxy collection install -r casc/requirements.yaml -r collections/requirements.yaml
   ```

2. Copy and edit variables:

   ```bash
   cp casc/vars/custom.yaml.template casc/vars/custom.yaml
   ```

   Set Controller/EDA passwords, `telemetry_project_url`, ITSM credentials, and OpenShift API token.

   **ITSM credentials** (bootstrap admin):

   ```bash
   oc get secret itsm-secrets -n itsm-app -o jsonpath='{.data.bootstrap-admin-user}' | base64 -d; echo
   oc get secret itsm-secrets -n itsm-app -o jsonpath='{.data.bootstrap-admin-password}' | base64 -d; echo
   ```

   **OpenShift API token** for remediation (after first stack deploy):

   ```bash
   oc create token demo-remediator -n otel-demo --duration=8760h
   ```

3. Push the `openshift` branch to GitHub (AAP project sync uses branch `openshift`):

   ```bash
   git push -u origin openshift
   ```

### Installation

From the repository root:

```bash
ansible-playbook casc/deploy.yaml
```

This will:

- Create project `otel-demo` and deploy Kafka, OpenTelemetry Collector, Prometheus, blackbox exporter, and nginx
- Configure `AlertmanagerConfig` to send `NginxDown` webhooks to the collector
- Apply CasC to Controller and EDA (job templates, workflows, credentials, rulebook activation)

### Demo flow

1. Open the nginx route: `oc get route nginx -n otel-demo`
2. **Break** the app: `oc scale deployment/nginx --replicas=0 -n otel-demo`
3. Watch firing alert → Kafka → EDA → `[JT] Parse Kafka Payload` → remediation workflow → ITSM ticket
4. Approve the workflow step, then remediation scales nginx back up
5. When the alert resolves, accept the resolution workflow to close the ITSM ticket

### Reset

Run job template **`[JT] Clean Demo Environment`** from Controller (redeploys stack, recreates EDA activation, closes open ITSM incidents).

### Architecture

- **Monitoring**: Prometheus + blackbox in `otel-demo` send alerts to cluster Alertmanager; `AlertmanagerConfig` forwards to OTel Collector webhook
- **Events**: Collector exports to Kafka topic `otel-events`; EDA rulebook `rulebooks/kafka.yaml` triggers Controller jobs
- **Tickets**: REST API against ITSM (`/api/v1/incidents`)
- **Remediation**: `kubernetes.core.k8s_scale` on Deployment `nginx` via OpenShift API token

### Legacy (Podman / ServiceNow)

The `main` branch and playbooks `casc/playbooks/opentelemetry.yaml`, `playbooks/podman.yaml` target the original RHEL 9 Podman + ServiceNow lab. Use branch **`openshift`** for this deployment.

### Lab guide

https://redhat-iberia.github.io/microlab-aap-eda
