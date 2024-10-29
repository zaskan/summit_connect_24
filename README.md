## Red Hat Summit Connect 24 Madrid
## Event-Driven Ansible / Opentelemetry Microlab
### Prerequisites

- 1 x Ansible Automation Platform Controller Host
- 1 x Event-Driven Ansible Controller Host
- 1 x Rhel 9 Machine (to install the Opentelemetry stack)
- 1 x Servicenow test instance

### Installation

- Using ansible-galaxy, install the requirements file located in the *casc* directory
- Copy and rename the file `casc/vars/custom.yaml.template` to a new file `casc/vars/custom.yaml`. Edit and provide the values accordingly.
- Execute the command `ansible-playbook casc/deploy.yaml`

### Lab guide ##

https://redhat-iberia.github.io/microlab-aap-eda
