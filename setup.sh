#!/usr/bin/env bash

set -ex

apt-get update

# Don't install recommend and suggest packages
if [[ ! -f "/etc/apt/apt.conf.d/01norecommend" ]]; then
  cat > /etc/apt/apt.conf.d/01norecommend << EOF
APT::Install-Recommends "0";
APT::Install-Suggests "0";
EOF
fi

# Install docker-ce
if ! which docker >/dev/null 2>&1; then
  apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  apt-key fingerprint 0EBFCD88
  add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
  apt-get update
  apt-get install -y docker-ce
  groupadd -G docker vagrant
fi

# Install golang
if ! which go >/dev/null 2>&1; then
  add-apt-repository -y ppa:longsleep/golang-backports
  apt-get update
  apt-get -y install golang-go
fi

# Install kind
if ! which kind >/dev/null 2>&1; then
  go get sigs.k8s.io/kind
  mv $HOME/go/bin/kind /usr/local/bin/
fi

# Install kubectl
if ! which kubectl >/dev/null 2>&1; then
  curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
  chmod +x ./kubectl
  mv ./kubectl /usr/local/bin/
fi

# Setup a kubernetes cluster
if [[ -z "$(kind get clusters)" ]]; then
  kind create cluster
fi

export KUBECONFIG="$(kind get kubeconfig-path)"
kubectl version
