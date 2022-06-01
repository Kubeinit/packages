#!/bin/bash
set -eo pipefail

# Merge all Dockerfile.xx to an all-in-one file
ls Dockerfile.* | xargs -L1 grep -Ev 'FROM scratch|COPY --from=' > Dockerfile
echo "FROM scratch" >> Dockerfile
ls Dockerfile.* | xargs -L1 grep 'COPY --from=' >> Dockerfile

# Export build artifact to local path
DOCKER_BUILDKIT=1 docker build -o type=local,dest=$PWD -f Dockerfile .

git clone https://github.com/kubeinit/packages.git --branch site --single-branch site
cd site

git reflog expire --expire-unreachable=now --all
git gc --prune=now

rm -rf ./*

if [[ -d "../ubuntu" ]]
then
    cp -a ../ubuntu .
fi
if [[ -d "../centos" ]]
then
    cp -a ../centos .
fi
if [[ -d "../debian" ]]
then
    cp -a ../debian .
fi

cat << EOF > ./centos-kubeinit.repo
[kubeinit]
name=kubeinit
baseurl=https://packages.kubeinit.org/centos/$releasever/os/$basearch/
enabled=1
gpgcheck=0
sslverify=0
EOF

cat << EOF > ./fedora-kubeinit.repo
[kubeinit]
name=kubeinit
baseurl=https://packages.kubeinit.org/fedora/$releasever/os/$basearch/
enabled=1
gpgcheck=0
sslverify=0
EOF

echo "deb [trusted=yes] https://packages.kubeinit.org/ubuntu/amd64 focal/" > ./ubuntu-focal-kubeinit.list

echo "deb [trusted=yes] https://packages.kubeinit.org/ubuntu/amd64 jammy/" > ./ubuntu-jammy-kubeinit.list

echo "deb [trusted=yes] https://packages.kubeinit.org/debian/amd64 bullseye/" > ./debian-bullseye-kubeinit.list

echo "deb [trusted=yes] https://packages.kubeinit.org/debian/amd64 bookworm/" > ./debian-bookworm-kubeinit.list

echo "packages.kubeinit.org" > ./CNAME

cat << EOF > ./index.html
This is an index.html page, nothing to show.
EOF

git config --local user.email "bot@kubeinit.org"
git config --local user.name "KubeInit's bot"
git add .
git commit --amend --no-edit || true
