Name: podshift
Version: 0.9.2
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
* Tue Nov 10 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.9.1
- RPM improvements
- Initial version of Cockpit API
- Automated Quadlet install
- PodShift CLI

* Mon Jun 15 2026 Vellamo Dev <no-email@vellamo.fyi> - 0.1.0
- First alpha version
- Rootless Podman
