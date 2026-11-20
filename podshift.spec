Name: podshift
Version: 0.21.6
Release: 1%{?dist}
Group: PodShift
Summary: Lightweight CD Orchestration
License: AGPL-3.0-or-later
URL: https://github.com/vellamo-dev/podshift
Requires: NetworkManager firewalld cockpit podman openssh-server policycoreutils-python-utils cockpit-selinux cockpit-podman cockpit-files pcp python3-pcp tree nano fail2ban shadow-utils unzip less glow jq
BuildArch: noarch
BuildRequires: systemd-rpm-macros
%global branch stable
Source0: https://github.com/vellamo-dev/podshift/archive/refs/heads/%{branch}.tar.gz
Source1: https://raw.githubusercontent.com/vellamo-dev/podshift/%{branch}/src/server/opt/podshift/rpm/postun.sh

%global debug_package %{nil}

%description
PodShift is a lightweight CD orchestration tool that enables
container orchestration within DevSecOps workflows. It eliminates
the need for Kubernetes expertise by deploying container-based
applications through Quadlets. The tool further simplifies the
configuration of consistent environments for development,
testing, staging, and production.

%prep
%setup -q -c

%build

%install
PATH_CURRENT=$(realpath .)
source "${PATH_CURRENT}/podshift-%{branch}/src/deployment/rpm-install.sh" "%{buildroot}" "${PATH_CURRENT}"
install -D -m 0644 "${PATH_CURRENT}/podshift-%{branch}/LICENSE" "%{buildroot}%{_defaultlicensedir}/%{name}/LICENSE"

%files -f files.list
%defattr(-,root,root,-)
%license %{_defaultlicensedir}/%{name}/LICENSE

%post -p /bin/bash
exec > >(tee >(systemd-cat -t podshift-install)) 2>&1
%tmpfiles_create %{_tmpfilesdir}/podshift-dirs.conf
/opt/podshift/rpm/post.sh "$1" || :
echo -e "\tDuration: ${SECONDS}s"
exec >&- 2>&-
wait

%preun -p /bin/bash
exec > >(tee >(systemd-cat -t podshift-install)) 2>&1
/opt/podshift/rpm/preun.sh "$1" || :
echo -e "\tDuration: ${SECONDS}s"
exec >&- 2>&-
wait

%postun -p /bin/bash -f %{SOURCE1}

%posttrans -p /bin/bash
exec > >(tee >(systemd-cat -t podshift-install)) 2>&1
/opt/podshift/rpm/posttrans.sh "$1" || :
echo -e "\tDuration: ${SECONDS}s"
exec >&- 2>&-
wait


%changelog
* Fri Nov 20 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.21.6
- Health check: new Environment tag check warns when TSV_ENV is not set
- Tests: unit tests cover the Environment tag check when TSV_ENV is set and when it is not

* Fri Nov 20 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.21.5
- Docs: readme has short PodShift CLI and PodShift UI sections (also in Finnish)

* Fri Nov 20 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.21.4
- Tools: precheck no longer has Hetzner-specific checks; the cloud name comes only from cloud-init, and the DHCP warning gives a generic cloud-init note
- Tests: precheck-unit drops the Hetzner checks and covers the cloud-init DHCP note
- Docs: precheck readme drops the Hetzner wording

* Fri Nov 20 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.21.3
- Tools: precheck shows the hardware, the cloud-init state and a hint about user data
- Tools: precheck reads the cloud name from cloud-init's local files first
- Tests: precheck-unit covers the hardware, the cloud-init states, the cloud name sources and the user data hint
- Docs: precheck readme explains the hardware, cloud and cloud-init facts

* Fri Nov 20 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.21.2
- Tools: precheck reads the edition from the identity package, shows the cloud and fixes the login user count
- Tools: precheck adds a Hetzner line to the DHCP warning and fixes the skipped check count
- Tests: precheck-unit covers the edition, the cloud, the Hetzner DHCP line and the counts
- Docs: precheck readme explains the edition and cloud facts

* Fri Nov 20 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.21.1
- Tools: precheck accepts the cloud-init connection name with a space and says when the IPv4 address comes from DHCP
- Tests: precheck-unit covers the connection name with a space, the default nmconnection file and the DHCP wording
- Docs: precheck readme explains the connection name match and the DHCP check

* Fri Nov 20 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.21.0
- Tools: precheck reports the network setup and checks the route, NetworkManager, DHCP and IPv4
- Tests: precheck-unit covers the network checks
- Docs: precheck readme lists the network checks

* Thu Nov 19 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.20.0
- Install: first server install switches SELinux from permissive to enforcing
- Tools: precheck says the install switches SELinux on servers
- Docs: usage says a first server install switches SELinux
- Tests: lint-spec-scriptlets checks the spec calls its install scripts

* Thu Nov 19 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.19.0
- CLI: podshift selinux enforce switches SELinux to enforcing
- Tools: precheck SELinux warning wording fixed and points to the new command
- Docs: usage mentions podshift selinux enforce

* Thu Nov 19 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.18.1
- Docs: Quick Start shows each command in its own copyable block
- Docs: Quick Start explains what the precheck does

* Thu Nov 19 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.18.0
- Tools: utils/portable/precheck.sh, a single-file pre-install check
- Tests: precheck-unit and precheck-vm-clean test the portable precheck
- Docs: precheck in usage, Quick Start and utils/portable in readme project structure
- Tools: precheck documented with bashdoc and checked by the bashdoc lints

* Tue Nov 17 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.17.0
- Tests: builder containers are stopped after use (build-container-stop)
- Tests: install-vm-stop stops the installer VM without removing it
- Tests: install-vm-create split from install-vm-start, which now starts the existing VM

* Tue Nov 17 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.16.2
- Docs: small footprint noted in readme and design choices

* Mon Nov 16 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.16.1
- Illustrations updated

* Mon Nov 16 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.16.0
- Cockpit API: overview info reports the install type (desktop or server)
- Docs: readme intro and "How Your Code Gets to the Server" rewritten for beginners
- Docs: From Push to Production explains PodShift's and Podman's roles

* Sat Nov 14 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.15.4
- Tests: release-version-check compares the stable branch with Copr builds
- Docs: design choices explain the test suite
- Docs: design choices explain the own test runner, the extra lint tests and the guiding idea
- Docs: agents.md starts with Purpose first

* Sat Nov 14 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.15.3
- Documentation: Finnish readme (readme.fi.md)

* Sat Nov 14 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.15.2
- Documentation: security policy (security.md)

* Sat Nov 14 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.15.1
- Documentation: PodShift never installs PodShift UI itself

* Fri Nov 13 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.15.0
- PodShift UI listed in Cockpit Applications as an optional add-on
- Cockpit API modules for the overview, health, resources, services and Quadlets
- Environment tag (TSV_ENV) is empty until set with podshift env
- Documentation for the PodShift UI

* Wed Nov 11 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.14.0
- Cockpit API improvements
- Documentation improvements

* Wed Nov 11 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.13.0
- Cockpit API improvements

* Wed Nov 11 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.12.0
- Cockpit API tests

* Wed Nov 11 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.10.0
- Cockpit API improvements

* Tue Nov 10 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.9.1
- RPM improvements
- Initial version of Cockpit API
- Automated Quadlet install
- PodShift CLI

* Mon Jun 15 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.1.0
- First alpha version
- Rootless Podman
