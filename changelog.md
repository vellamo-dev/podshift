# Change Log

## Sat Nov 21 2026 - 0.25.0
- Pipeline: every item entering the drop folder gets a UUIDv7 drop ID, from any source (Cockpit, a terminal, scp)
- Pipeline: refused items get a drop ID too
- Pipeline: an accepted Quadlet file gets "# podshift-drop-id: <uuid>" as line 1; any older drop ID line is removed
- Pipeline: the drop ID line is written through a hidden temp file and a rename
- Pipeline: a zip carries the ID in its queued name shop.zip.<uuid>, and every file of the bundle gets the same ID line
- Pipeline: the unchanged check ignores drop ID lines, so a new drop of an installed file is still unchanged
- Pipeline: a file placed in the validation queue or source by hand gets a new drop ID
- Drop history: each record has the drop ID, {id, name, status}; a record without a valid ID is not logged
- Drop history: the statuses uploaded, removing and removed are gone
- Cockpit API: quadlet-drop-history shows one item per drop ID, {id, name, status, time}, newest first, at most 100
- Cockpit API: quadlet-drop-history skips records without an ID
- Cockpit API: quadlet-drop logs "uploaded <name> to the drop folder" with the podshift-qdl-upload tag
- Cockpit API: quadlet-drop no longer writes a drop history record
- Removal: quadlet-remove and podshift quadlet rm log only to podshift-qdl-remove (install log), not to the drop history

## Sat Nov 21 2026 - 0.24.0
- Pipeline: a Quadlet is installed once and never replaced; podman quadlet install runs without --replace
- Pipeline: units are only started, never restarted
- Pipeline: an item installed with the same content (after TSV filling) is logged as unchanged and moved to trash
- Pipeline: a different item with an installed name, or an installed app, is refused and moved to rejected
- Pipeline: the refusal reason is "already installed, remove it first"
- Pipeline: the name key (ContainerName, NetworkName, VolumeName, PodName) must be set and equal the file base name
- Pipeline: a base name must not end with -pod, -network, -volume, -image or -build
- Pipeline: the name must be free in Podman for its type; a pod also needs its infra container name <pod>-infra free
- Pipeline: a container must not use the infra container name of a pod
- Pipeline: every referenced Quadlet file must be installed, waiting in the source or in the same bundle
- Pipeline: every Secret= must exist as a Podman secret
- Pipeline: .pod files install after networks, volumes and images and before containers
- Pipeline: a plain Network= name, Volume= source or Mount= type=volume source counts as a use of an item
- Pipeline: that item is the installed .network or .volume with the same base name
- Pipeline: removing a .network or .volume in such use is refused; install checks are unchanged for plain names
- Pipeline: a bundle with two files of the same name is refused, and unzip no longer overwrites
- CLI: new podshift quadlet rm <file|app> [--volumes] [--yes] stops the units
- CLI: podshift quadlet rm removes the files with podman quadlet rm
- CLI: podshift quadlet rm then removes leftover containers, pods and networks, and keeps volumes unless --volumes
- CLI: podshift quadlet rm is refused while something uses the item
- Cockpit API: new quadlet-remove action (podshift realm) queues a removal
- Cockpit API: new podshift-qdl-remove path and service units handle the removal queue
- Cockpit API: quadlet-install-log also shows the podshift-qdl-remove journal lines
- Cockpit API: overview-status has a new Quadlet remover row for podshift-qdl-remove.path
- Config: new main.conf settings PODSHIFT_QUADLET_REMOVE_QUEUE_DIR and PODSHIFT_QUADLET_STOP_TIMEOUT
- Config: tmpfiles creates /home/podshift/.quadlets/remove-queue
- Drop history: new statuses unchanged, removing and removed
- Cockpit API: containers-list, volumes-list and secrets-list inspect each container alone when the batch inspect fails
- Cockpit API: each failed batch inspect is logged
- Cockpit API: a failed request adds reason= to the podshift-api journal line
- Cockpit API: a failed request also adds detail= with the first module stderr line
- Examples: example-volume.container is now example-volume-container.container
- Examples: example-quadlet.volume sets VolumeName=example-quadlet
- Tests: unit tests for the new pure helpers and a new unit-quadlet-lifecycle suite in quick
- Tests: Cockpit API cases for quadlet-remove, the journal reason and the inspect fallback of the list actions
- Docs: usage, design choices, known issues, roadmap, Cockpit API and quadlet help cover install once and remove

## Fri Nov 20 2026 - 0.23.0
- tmpfiles: new web-upload staging folder /home/podshift/.quadlets/web-upload (0700, podshift)
- tmpfiles: the web-upload folder contents are cleaned after 1 day
- Config: new main.conf setting PODSHIFT_QUADLET_WEB_UPLOAD_DIR for that folder
- Cockpit API: new quadlet-drop action (podshift realm) takes {name, content}, with the content in base64
- Cockpit API: quadlet-drop writes one .container, .volume, .network, .image or .zip file of at most 50 KB
- Cockpit API: the file goes through the web-upload folder into the drop directory, owned by podshift, mode 0644
- Cockpit API: quadlet-drop refuses a name that is still waiting in the drop directory
- Cockpit API: the request bound is 131072 bytes for quadlet-drop and stays 65536 bytes for every other action
- Cockpit API: new quadlet-drop-history action (root realm) shows the latest status of each dropped item
- Cockpit API: new quadlet-install-log action (root realm) shows the last 100 drop, validate and install log lines
- Pipeline: drop-process, qdl-validate and qdl-install also log each item's status as JSON, tag podshift-drop-history
- Pipeline: the existing log lines are unchanged

## Fri Nov 20 2026 - 0.22.0
- CLI: podshift config --unset removes a custom TSV_## key
- CLI: custom key names must be TSV_ plus A-Z, 0-9 or _; names starting with TSV_NW or TSV_ENV are reserved
- CLI: secret names (PASSWORD, TOKEN, API_KEY and similar) and known token formats in values are refused
- CLI: values must not be empty or contain quotes, control characters or a trailing backslash
- Config: new tsv-rules.conf lists the secret words and value formats
- Config: tsv.conf is read as data by read-tsv-conf-lines instead of being sourced, so nothing in it is run
- Config: only TSV_NAME=value lines in tsv.conf are used
- Config: saving or removing a key rewrites tsv.conf in canonical form and drops other lines, with a note
- CLI: podshift config refuses TSV_ENV for set and --unset, root included; set it with podshift env --set
- CLI: PODSHIFT_SYSTEM_CONFIG_KEYS no longer lists TSV_ENV
- CLI: podshift update-self also updates cockpit-podshift in the same transaction if installed and in an enabled repo
- CLI: otherwise update-self skips cockpit-podshift with a note, and it never installs it
- Cockpit API: new config-set, config-unset and env-set actions
- Cockpit API: overview-config rows have an editable flag and the data lists suggested environment tags
- Tests: unit tests for the config rules, new unit-cli-config suite in quick, Cockpit API cases for the new actions
- Docs: config help covers --unset, the name rules and secrets; API docs list the new actions

## Fri Nov 20 2026 - 0.21.6
- Health check: new Environment tag check warns when TSV_ENV is not set
- Tests: unit tests cover the Environment tag check when TSV_ENV is set and when it is not

## Fri Nov 20 2026 - 0.21.5
- Docs: readme has short PodShift CLI and PodShift UI sections (also in Finnish)

## Fri Nov 20 2026 - 0.21.4
- Tools: precheck no longer has Hetzner-specific checks; the cloud name comes only from cloud-init
- Tools: the precheck DHCP warning gives a generic cloud-init note
- Tests: precheck-unit drops the Hetzner checks and covers the cloud-init DHCP note
- Docs: precheck readme drops the Hetzner wording

## Fri Nov 20 2026 - 0.21.3
- Tools: precheck shows the hardware, the cloud-init state and a hint about user data
- Tools: precheck reads the cloud name from cloud-init's local files first
- Tests: precheck-unit covers the hardware, the cloud-init states, the cloud name sources and the user data hint
- Docs: precheck readme explains the hardware, cloud and cloud-init facts

## Fri Nov 20 2026 - 0.21.2
- Tools: precheck reads the edition from the identity package, shows the cloud and fixes the login user count
- Tools: precheck adds a Hetzner line to the DHCP warning and fixes the skipped check count
- Tests: precheck-unit covers the edition, the cloud, the Hetzner DHCP line and the counts
- Docs: precheck readme explains the edition and cloud facts

## Fri Nov 20 2026 - 0.21.1
- Tools: precheck accepts the cloud-init connection name with a space and says when the IPv4 address comes from DHCP
- Tests: precheck-unit covers the connection name with a space, the default nmconnection file and the DHCP wording
- Docs: precheck readme explains the connection name match and the DHCP check

## Fri Nov 20 2026 - 0.21.0
- Tools: precheck reports the network setup and checks the route, NetworkManager, DHCP and IPv4
- Tests: precheck-unit covers the network checks
- Docs: precheck readme lists the network checks

## Thu Nov 19 2026 - 0.20.0
- Install: first server install switches SELinux from permissive to enforcing
- Tools: precheck says the install switches SELinux on servers
- Docs: usage says a first server install switches SELinux
- Tests: lint-spec-scriptlets checks the spec calls its install scripts

## Thu Nov 19 2026 - 0.19.0
- CLI: podshift selinux enforce switches SELinux to enforcing
- Tools: precheck SELinux warning wording fixed and points to the new command
- Docs: usage mentions podshift selinux enforce

## Thu Nov 19 2026 - 0.18.1
- Docs: Quick Start shows each command in its own copyable block
- Docs: Quick Start explains what the precheck does

## Thu Nov 19 2026 - 0.18.0
- Tools: utils/portable/precheck.sh, a single-file pre-install check
- Tests: precheck-unit and precheck-vm-clean test the portable precheck
- Docs: precheck in usage, Quick Start and utils/portable in readme project structure
- Tools: precheck documented with bashdoc and checked by the bashdoc lints

## Tue Nov 17 2026 - 0.17.0
- Tests: builder containers are stopped after use (build-container-stop)
- Tests: install-vm-stop stops the installer VM without removing it
- Tests: install-vm-create split from install-vm-start, which now starts the existing VM

## Tue Nov 17 2026 - 0.16.2
- Docs: small footprint noted in readme and design choices

## Mon Nov 16 2026 - 0.16.1
- Illustrations updated

## Mon Nov 16 2026 - 0.16.0
- Cockpit API: overview info reports the install type (desktop or server)
- Docs: readme intro and "How Your Code Gets to the Server" rewritten for beginners
- Docs: From Push to Production explains PodShift's and Podman's roles

## Sat Nov 14 2026 - 0.15.4
- Tests: release-version-check compares the stable branch with Copr builds
- Docs: design choices explain the test suite
- Docs: design choices explain the own test runner, the extra lint tests and the guiding idea
- Docs: agents.md starts with Purpose first

## Sat Nov 14 2026 - 0.15.3
- Documentation: Finnish readme (readme.fi.md)

## Sat Nov 14 2026 - 0.15.2
- Documentation: security policy (security.md)

## Sat Nov 14 2026 - 0.15.1
- Documentation: PodShift never installs PodShift UI itself

## Fri Nov 13 2026 - 0.15.0
- PodShift UI listed in Cockpit Applications as an optional add-on
- Cockpit API modules for the overview, health, resources, services and Quadlets
- Environment tag (TSV_ENV) is empty until set with podshift env
- Documentation for the PodShift UI

## Wed Nov 11 2026 - 0.14.0
- Cockpit API improvements
- Documentation improvements

## Wed Nov 11 2026 - 0.13.0
- Cockpit API improvements

## Wed Nov 11 2026 - 0.12.0
- Cockpit API tests

## Wed Nov 11 2026 - 0.10.0
- Cockpit API improvements

## Tue Nov 10 2026 - 0.9.1
- RPM improvements
- Initial version of Cockpit API
- Automated Quadlet install
- PodShift CLI

## Mon Jun 15 2026 - 0.1.0
- First alpha version
- Rootless Podman
