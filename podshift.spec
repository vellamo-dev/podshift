Name: podshift
Version: 0.26.1
Release: 1%{?dist}
Group: PodShift
Summary: Lightweight CD Orchestration
License: AGPL-3.0-or-later
URL: https://github.com/vellamo-dev/podshift
Requires: podman NetworkManager firewalld openssh-server shadow-utils policycoreutils-python-utils fail2ban jq unzip
Requires: cockpit cockpit-podman cockpit-selinux cockpit-files pcp python3-pcp tree nano less glow
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
* Mon Nov 23 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.26.1
- Quadlet removal: reset the failed state of removed units, so a unit killed on stop no longer shows as failed
- Tests: remove-item checks that reset-failed runs for each removed unit after podman quadlet rm

* Sat Nov 21 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.26.0
- Code improvements: Cockpit API args go on stdin, static module dispatch, faster lists with one systemctl call
- Code improvements: drop bundle size and file count limits, health check timeouts stop their unit
- Fixes: no double removal of a quadlet, drop-process skips vanished files and has no fallbacks, help pages
- Syntax fixes: local variables, one function per file, bashdoc tags
- Docs and tests: lint-local-variables, new bats tests, readme updates
- Pods: .pod files and Pod= keys are refused, alone and in bundles, until pod support lands (see the roadmap)
- Login shells: helpers and PODSHIFT_*/TSV_* variables load only for root, podshift and wheel members
- podshift secret prints Saved, Replaced or Removed secret <name> instead of the Podman ID
- One function per file: user service start, step printers and Cockpit module helpers split
- Requires split into two lines; the portable precheck is smaller with the same output
- Cockpit: the containers list skips CPU and memory when its 8 second budget runs short
- CLI: podshift <command> --help shows that command's help instead of running it
- CLI: podshift secret refuses names starting with -, so --help or a typo no longer saves a secret
- CLI: shortcuts such as update and containers refuse arguments instead of ignoring them
- CLI: podshift --help nw and --help hc show the network and health-check pages, like nw --help
- Packaging: /home/podshift is owned by podshift with mode 0700, so bash history and hcl work
- Tests: Cockpit API cases split into per-area files; a Mac stat stub no longer makes a drop case flaky
- Refactor: podshift network is split into one function per file, with new bats tests; behaviour unchanged
- Drop: a file whose time is in the future gets the time now instead of waiting until the clock catches up
- CLI: podshift nw check tests the hosts in PODSHIFT_REGISTRIES, the same as the registries health check
- CLI: help pages shown with glow always wrap at 80 columns, also on the first call before glow has a config

* Sat Nov 21 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.25.3
- Cockpit API: quadlet-install-log shows systemd and Podman lines only for units PodShift started or removed
- Cockpit API: a unit counts when a "queued start of <unit>" line or a podshift-qdl-remove line names it
- Cockpit API: quadlet-install-log leaves out the user manager start, libpod scopes and the example units
- Removal: remove-item logs "stopping <unit>" for each unit, so the install log also shows the units of an app
- Cockpit API: containers-list, volumes-list and networks-list add quadlet {name, app} for installed Quadlet items
- Cockpit API: name is the installed Quadlet file and app its bundle; the UI uses it to offer Uninstall

* Sat Nov 21 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.25.2
- Cockpit API: fix containers-list and volumes-list failing with "Argument list too long" when there are many containers
- Cockpit API: large Podman, request and response JSON now reaches jq through files, not as one command-line argument
- Cockpit API: covers the list helpers, inspect, contract checks, health-check groups and the response envelope
- Tests: containers-list and volumes-list are checked with over 1 MB of Podman JSON

* Sat Nov 21 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.25.1
- Cockpit API: quadlet-install-log also shows systemd lines of the podshift user's Quadlet units, such as a failed start
- Cockpit API: quadlet-install-log also shows the Podman container events of those units
- Cockpit API: quadlet-install-log leaves out podshift-* and run-* units, health checks, unit-less lines and image pulls
- Cockpit API: quadlet-install-log reads the last 2000 matching journal lines and returns the newest 100 kept entries