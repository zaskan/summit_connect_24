## Red Hat Summit Connect — Event-Driven Ansible / OpenTelemetry Microlab (OpenShift)

Demo showing how Ansible Automation Platform 2.6 and Event-Driven Ansible remediate issues using alerts from Prometheus/Alertmanager, OpenTelemetry, and Kafka, with tickets in the ITSM app.

### Prerequisites

- OpenShift cluster with admin `oc` access
- Ansible Automation Platform **2.6** with Automation Gateway (e.g. namespace `aap`, route `https://ansible-aap.apps.ocp.zaskan.es`)
- Cluster Alertmanager (`alertmanager-main` in `openshift-monitoring`)
- ITSM app deployed (e.g. `https://itsm-app-itsm-app.apps.ocp.zaskan.es/`)
- Ansible 2.16+ and Python 3.11+ on a control node with `oc` CLI logged in

### Configuration

1. Install Ansible collections:

   ```bash
   ansible-galaxy collection install -r casc/requirements.yaml -r collections/requirements.yaml
   ```

   Collections used for CasC: [`ansible.platform`](https://github.com/ansible/ansible.platform) (gateway), `ansible.controller`, `ansible.eda`, `kubernetes.core`.

2. Copy and edit variables:

   ```bash
   cp casc/vars/custom.yaml.template casc/vars/custom.yaml
   ```

   Set **`aap_hostname`** (gateway URL, not per-service Controller/EDA routes), **`aap_username`** / **`aap_password`**, `telemetry_project_url`, ITSM credentials, and OpenShift API token.

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
- Configure AAP via the **Automation Gateway** (`casc/playbooks/configure_aap.yaml`): organizations, Controller/EDA resources, credentials, job templates, workflows, rulebook activation, and RBAC

### Demo flow

1. Open the nginx route: `oc get route nginx -n otel-demo`
2. **Break** the app: `oc scale deployment/nginx --replicas=0 -n otel-demo`
3. Watch firing alert → Kafka → EDA → `[JT] Parse Kafka Payload` → remediation workflow → ITSM ticket
4. Approve the workflow step, then remediation scales nginx back up
5. When the alert resolves, accept the resolution workflow to close the ITSM ticket

### Reset

Run job template **`[JT] Clean Demo Environment`** from the gateway UI (redeploys stack, recreates EDA activation, closes open ITSM incidents).

### Architecture

- **AAP 2.6**: Single gateway URL; CasC and runtime job modules use `aap_hostname` (see [Configuration as Code 2.6](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/html-single/configuration_as_code/index))
- **Monitoring**: Prometheus + blackbox in `otel-demo` → cluster Alertmanager → OTel Collector webhook
- **Events**: Collector → Kafka `otel-events` → EDA rulebook `rulebooks/kafka.yaml`
- **Tickets**: ITSM REST API (`/api/v1/incidents`)
- **Remediation**: `kubernetes.core.k8s_scale` on Deployment `nginx`

### Legacy

- **`main` branch**: Podman on RHEL + ServiceNow + `ansible_automation_platform.casc`
- **`openshift` branch**: OpenShift stack + ITSM + gateway-based CasC with `ansible.platform`

### Lab guide

https://redhat-iberia.github.io/microlab-aap-eda
