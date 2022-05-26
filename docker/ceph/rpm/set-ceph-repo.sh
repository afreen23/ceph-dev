#!/bin/bash

set -e

if [[ "${USE_REPO_FILES}" == 1 ]]; then
    mv /root/*.repo /etc/yum.repos.d
    exit 0
fi

if [[ -z "$REPO_URL" ]]; then
    if [[ -z "$CEPH_RELEASE" ]]; then
        CEPH_RELEASE=main
    fi

    REPO_URL=$(curl -s "https://shaman.ceph.com/api/search/?project=ceph&distros=centos/$CENTOS_VERSION/x86_64&flavor=default&ref=$CEPH_RELEASE&sha1=latest" | jq -r '.[0] | .url')/x86_64/
fi

echo "
[ceph-rpm]
name=Ceph RPM
baseurl=$REPO_URL
enabled=1
gpgcheck=0
" > /etc/yum.repos.d/ceph.repo

readonly REPO_URL_NOARCH=$(echo "$REPO_URL" | sed -e 's/x86_64/noarch/')
readonly REPO_URL_NOARCH_STATUS_CODE=$(curl -LIfs "$REPO_URL_NOARCH" | head -1 | awk '{print $2}')

if [[ "$REPO_URL_NOARCH_STATUS_CODE" == 200 ]]; then
    echo "
[ceph-rpm-noarch]
name=Ceph RPM noarch
baseurl=$REPO_URL_NOARCH
enabled=1
gpgcheck=0
" >> /etc/yum.repos.d/ceph.repo
fi
