#!/bin/bash
set -eo pipefail

# Merge all Dockerfile.xx to an all-in-one file
ls Dockerfile.* | xargs -L1 grep -Ev 'FROM scratch|COPY --from=' > Dockerfile
echo "FROM scratch" >> Dockerfile
ls Dockerfile.* | xargs -L1 grep 'COPY --from=' >> Dockerfile

# Export build artifact to local path
DOCKER_BUILDKIT=1 docker build -o type=local,dest=$PWD -f Dockerfile .

# This is if we would like to push to this same repo but in another branch
# git clone https://github.com/kubeinit/repobuilder.git --branch site --single-branch packages
git clone https://github.com/kubeinit/packages.git --branch main --single-branch packages
cd packages

git reflog expire --expire-unreachable=now --all
git gc --prune=now

rm -rf ./*

if [[ -d "../ubuntu" ]]
then
    cp -a ../ubuntu .
fi
if [[ -d "../debian" ]]
then
    cp -a ../debian .
fi
if [[ -d "../fedora" ]]
then
    cp -a ../fedora .
fi
if [[ -d "../centos" ]]
then
    cp -a ../centos .
fi

cp ../index.html .

cat << EOF > ./fedora-kubeinit.repo
[kubeinit]
name=kubeinit
baseurl=https://packages.kubeinit.org/fedora/$releasever/os/$basearch/
enabled=1
gpgcheck=0
sslverify=0
EOF

cat << EOF > ./centos-kubeinit.repo
[kubeinit]
name=kubeinit
baseurl=https://packages.kubeinit.org/centos/$releasever/os/$basearch/
enabled=1
gpgcheck=0
sslverify=0
EOF

echo "deb [trusted=yes] https://packages.kubeinit.org/ubuntu/focal/os/amd64 /" > ./ubuntu-focal-kubeinit.list

echo "deb [trusted=yes] https://packages.kubeinit.org/ubuntu/jammy/os/amd64 /" > ./ubuntu-jammy-kubeinit.list

echo "deb [trusted=yes] https://packages.kubeinit.org/debian/bullseye/os/amd64 /" > ./debian-bullseye-kubeinit.list

echo "deb [trusted=yes] https://packages.kubeinit.org/debian/bookworm/os/amd64 /" > ./debian-bookworm-kubeinit.list

echo "packages.kubeinit.org" > ./CNAME

git config --local user.email "bot@kubeinit.org"
git config --local user.name "KubeInit's bot"
git add .
git commit --amend --no-edit || true
