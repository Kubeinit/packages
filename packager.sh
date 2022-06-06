#!/bin/bash
set -eo pipefail

#############################################################################
#                                                                           #
# Copyright kubeinit contributors.                                          #
#                                                                           #
# Licensed under the Apache License, Version 2.0 (the "License"); you may   #
# not use this file except in compliance with the License. You may obtain   #
# a copy of the License at:                                                 #
#                                                                           #
# http://www.apache.org/licenses/LICENSE-2.0                                #
#                                                                           #
# Unless required by applicable law or agreed to in writing, software       #
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT #
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the  #
# License for the specific language governing permissions and limitations   #
# under the License.                                                        #
#                                                                           #
#############################################################################

# Prepare APT dependencies
if [ -x "$(command -v apt-get)" ]; then
    export DEBIAN_FRONTEND="noninteractive"
    apt update
    apt dist-upgrade -y
    apt install -y libgpgme-dev \
                   git \
                   pkg-config \
                   libseccomp2 \
                   libseccomp-dev \
                   ruby-dev \
                   build-essential \
                   wget \
                   gcc \
                   gnupg \
                   gzip \
                   procps \
                   tar \
                   python3 \
                   python3-pip
fi

# Prepare YUM dependencies
if [ -x "$(command -v yum)" ]; then
    echo "Show and enabling repos based on distros and versions..."
    dnf repolist all
    if [[ $DISTRO == "centos" ]]; then
      echo "Enable EPEL in CentOS"
      yum install epel-release -y
      if [[ $OS_VERSION == "9" ]]; then
        echo "Install crb"
        dnf config-manager --set-enabled crb
      else
        echo "Install powertools"
        dnf config-manager --set-enabled powertools
      fi
    else
      echo "Install additional Fedora repos?"
    fi
    yum makecache
    yum update -y
    yum install -y rpm-build \
                   rpmdevtools \
                   gpgme \
                   git \
                   pkgconfig \
                   libseccomp \
                   libseccomp-devel \
                   ruby-devel \
                   make \
                   automake \
                   gcc-c++ \
                   kernel-devel \
                   wget \
                   gcc \
                   tar \
                   yum-utils \
                   python3 \
                   python3-pip \
                   glib2-devel \
                   glibc-static \
                   gpgme-devel \
                   libassuan-devel \
                   systemd-rpm-macros \
                   device-mapper-devel \
                   bash-completion \
                   containernetworking-plugins \
                   fdupes \
                   criu-devel \
                   libcap-devel \
                   libtool \
                   yajl-devel \
                   golang \
                   gettext \
                   protobuf \
                   python3-libmount \
                   libbpf-devel \
                   protobuf-c-devel

    if [[ $DISTRO == "fedora" ]]; then
      echo "Installing Fedora specific dependencies"
      yum install -y go-rpm-macros \
                     golang-github-cpuguy83-md2man \
                     btrfs-progs-devel

    else
      echo "Installing CentOS specific dependencies"
      yum install -y golang-github-cpuguy83-md2man

     if [[ $OS_VERSION == "9" ]]; then
       echo "Install things in centos stream9"
       yum install -y go-rpm-macros
     else
       echo "Install things in centos stream8"
       yum install -y go-srpm-macros
     fi

    fi
fi

python3 -m pip install shyaml

# Get golang
# echo "Get go"
# wget -nc https://go.dev/dl/go1.18.3.linux-amd64.tar.gz
# echo "Make sure Go is not installed"
# rm -rf /usr/local/go && tar -C /usr/local -xzf go1.18.3.linux-amd64.tar.gz
# echo "Add Go to path"
# echo "export PATH=$PATH:/usr/local/go/bin" >> /root/profile
# source /root/profile
# echo "Test Go version"
# go version

cat packages.yaml | shyaml get-value custom_packages | shyaml get-values-0 |
    while IFS='' read -r -d '' key; do
        name=$(echo "$key" | shyaml get-value name)
        type=$(echo "$key" | shyaml get-value type)
        version=$(echo "$key" | shyaml get-value version)
        url=$(echo "$key" | shyaml get-value url)
        file=$(echo "$key" | shyaml get-value file)
        buildargs=$(echo "$key" | shyaml get-value buildargs)

        echo $name $type $version $url $file $buildargs

        # We dont get the sources 'yet', lets leave the
        # packages builders do this job
        # wget -nc $url$file
        # rm -rf ./$name
        # mkdir -p ./$name
        # tar -xzf $file -C ./$name
        # cd ./$name/$(ls -U ./$name/ | head -1)
        # BUILDTAGS=$buildargs make

        if [[ $type == "source" ]]; then
            if [[ -x "$(command -v yum)" ]]; then
                echo "Building .rpm based packages from source"
                mkdir -p ~/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

                if [[ $name == "crun" ]]; then
                    echo "Building crun rpm packages"
                    echo "    Path:"
                    pwd
                    echo "    Files:"
                    ls -ltah
                    cd /$DISTRO-tmp/crun
                    wget -nc https://github.com/containers/crun/archive/refs/tags/1.4.4.tar.gz -P ~/rpmbuild/SOURCES/
                    mv ~/rpmbuild/SOURCES/1.4.4.tar.gz ~/rpmbuild/SOURCES/crun-1.4.4.tar.gz
                    rpmbuild --target x86_64 -bb crun.spec
                    echo "    New files:"
                    ls -ltah
                fi

                if [[ $name == "cri-o" ]]; then
                    echo "Building cri-o rpm packages"
                    echo "    Path:"
                    pwd
                    echo "    Files:"
                    ls -ltah
                    cd /$DISTRO-tmp/cri-o
                    wget -nc https://github.com/cri-o/cri-o/archive/v1.22.4.tar.gz -P ~/rpmbuild/SOURCES/
                    mv ~/rpmbuild/SOURCES/v1.22.4.tar.gz ~/rpmbuild/SOURCES/cri-o-1.22.4.tar.gz
                    # rpmbuild --target x86_64 -bb cri-o.spec
                    echo "    New files:"
                    ls -ltah
                fi

                if [[ $name == "cni" ]]; then
                    echo "Building cni rpm packages"
                    echo "    Path:"
                    pwd
                    echo "    Files:"
                    ls -ltah
                    cd /$DISTRO-tmp/cni
                    wget -nc https://github.com/containernetworking/cni/archive/refs/tags/v1.0.1.tar.gz -P ~/rpmbuild/SOURCES/
                    mv ~/rpmbuild/SOURCES/v1.0.1.tar.gz ~/rpmbuild/SOURCES/cni-v1.0.1.tar.gz
                    # rpmbuild --target x86_64 -bb cni.spec
                    echo "    New files:"
                    ls -ltah
                fi

                if [[ $name == "podman" ]]; then
                    echo "Building podman rpm packages"
                    echo "    Path:"
                    pwd
                    echo "    Files:"
                    ls -ltah
                    cd /$DISTRO-tmp/podman
                    # rpmdev-setuptree /root/
                    wget -nc https://github.com/containers/podman/archive/refs/tags/v4.0.3.tar.gz -P ~/rpmbuild/SOURCES/
                    mv ~/rpmbuild/SOURCES/v4.0.3.tar.gz ~/rpmbuild/SOURCES/podman-4.0.3.tar.gz
                    # rpmbuild --target x86_64 -bb podman.spec
                    echo "    New files:"
                    ls -ltah
                fi
            else
              echo "Building .deb based packages from source"
            fi
        else
            echo "Packaging binary files"
        fi

        cd ../../
    done
