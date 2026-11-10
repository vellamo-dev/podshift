# Posttrans actions

Post-transaction steps, applied in this order.

| ID | Function | Description |
|---|---|---|
| DRC | `deploy-runtime-conf` | Deploys the runtime configuration templates |
| FWD | `enable-configure-firewalld` | Enables and configures the firewall |
| SEL | `update-selinux` | Imports the SELinux port definitions |
| F2B | `enable-fail2ban` | Enables and starts fail2ban |
| PCP | `enable-pcp` | Enables and starts PCP metrics (pmcd and pmlogger) and Cockpit (cockpit.socket) |
| PRF | `install-rootless-profile` | Creates the shell profiles for the podshift user |
| PAF | `install-rootless-podman-auth-file` | Creates the Podman auth file and auto-update service override |
| LNG | `enable-rootless-linger` | Enables user lingering for the podshift user |
| PMC | `make-podshift-user-podman-compatible` | Makes the podshift user rootless-Podman compatible |
| OVR | `install-podman-auto-update-override` | Installs the Podman auto-update timer override |
| USR | `enable-start-user-services` | Enables and starts the PodShift user services |
| SSP | `configure-ssh-ports` | Makes sshd listen on ports 22 and 1022 |
