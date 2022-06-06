%global debug_package %{nil}

Name: crun
Epoch: 100
Version: 1.4.4
Release: 1%{?dist}
Summary: OCI runtime written in C
License: GPLv2
URL: https://github.com/containers/crun/tags
Source0: %{name}-%{version}.tar.gz
%if 0%{?suse_version} > 1500 || 0%{?sle_version} > 150000
BuildRequires: libyajl-devel
%else
BuildRequires: yajl-devel
%endif
BuildRequires: autoconf
BuildRequires: automake
BuildRequires: gcc
BuildRequires: glibc-static
BuildRequires: libcap-devel
BuildRequires: libseccomp-devel
BuildRequires: libtool
BuildRequires: pkgconfig
BuildRequires: python3
BuildRequires: systemd-devel
Requires: libcap.so.2()(64bit)
Requires: libseccomp.so.2()(64bit)
Requires: libsystemd.so.0()(64bit)
Requires: libyajl.so.2()(64bit)
Requires: systemd
Provides: oci-runtime

%description
crun is a runtime for running OCI containers.

%prep
%autosetup -T -c -n %{name}_%{version}-%{release}
tar -zx -f %{S:0} --strip-components=1 -C .

%build
autoreconf -i
%if 0%{?suse_version} > 1500 || 0%{?sle_version} > 150000
export CFLAGS='-I /usr/include/libseccomp'
%endif

# %configure \
# %if 0%{?centos_version} == 700
#     --disable-systemd \
# %endif
#     --disable-shared \
#     --disable-static
# %make_build

# %install
# %make_install
# rm -rf %{buildroot}/%{_libdir}/*
# rm -rf %{buildroot}/%{_mandir}/man1/*

# %files
# %license COPYING
# %{_bindir}/crun

# %changelog
