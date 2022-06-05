#!/bin/bash
set -e

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
    yum makecache
    yum update -y
    yum install -y rpm-build \
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
                   python3-pip
fi

python3 -m pip install shyaml

# Get golang
echo "Get go"
wget -nc https://go.dev/dl/go1.18.3.linux-amd64.tar.gz
echo "Make sure Go is not installed"
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.18.3.linux-amd64.tar.gz
echo "Add Go to path"
echo "export PATH=$PATH:/usr/local/go/bin" >> /root/profile
source /root/profile
echo "Test Go version"
go version

cat packages.yaml | shyaml get-value custom_packages | shyaml get-values-0 |
    while IFS='' read -r -d '' key; do
        name=$(echo "$key" | shyaml get-value name)
        type=$(echo "$key" | shyaml get-value type)
        version=$(echo "$key" | shyaml get-value version)
        url=$(echo "$key" | shyaml get-value url)
        file=$(echo "$key" | shyaml get-value file)
        buildargs=$(echo "$key" | shyaml get-value buildargs)

        echo $name $type $version $url $file $buildargs

        wget -nc $url$file

        rm -rf ./$name
        mkdir -p ./$name
        tar -xzf $file -C ./$name

        cd ./$name/$(ls -U ./$name/ | head -1)

        if [ $type == "source" ]; then
            echo "Building from source"
            # BUILDTAGS=$buildargs make
            if [[ -x "$(command -v yum)" ]] && [[ $name == "cri-o" ]]; then
                echo "Building cri-o package"
                cd package_helpers/cri-o
                rpmbuild --target x86_64 -bb cri-o.spec
            fi

        else
            echo "Packaging binary files"
        fi

        cd ../../
    done
