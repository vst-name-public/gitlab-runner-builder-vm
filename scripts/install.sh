#!/bin/bash -eu

echo "==> waiting for cloud-init to finish"
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do
    echo 'Waiting for Cloud-Init...'
    sleep 1
done

DEBIAN_FRONTEND=noninteractive
export HOME=/home/gitlab-runner

# Apt prepare
sudo curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | bash
sudo curl -s "https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh" | bash

# SSH key injection
mkdir -p /home/gitlab-runner/.ssh
touch /home/gitlab-runner/.ssh/authorized_keys
chown -R gitlab-runner:gitlab-runner /home/gitlab-runner/.ssh
chmod -R 0600 /home/gitlab-runner/.ssh

echo "==> updating apt cache"
sudo apt-get update -qq
echo "==> upgrade apt packages"
sudo apt-get upgrade -y -qq
sudo apt-get install -y -qq \
    git-lfs \
    gitlab-runner   


git lfs install --skip-repo --system
# SnapD init
sudo systemctl enable --now snapd


# Tools
## Kubernetes registry
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list
## Docker registry
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# Github registry
(type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
	&& sudo mkdir -p -m 755 /etc/apt/keyrings \
        && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
	&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

sudo apt-get update -qq
    sudo apt-get -y -qq install \
    make \
    kubectl

# Brew
su - gitlab-runner -c 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/gitlab-runner/.bash_profile
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
## Nodejs
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
echo 'export NVM_DIR="$HOME/.nvm"' >> /home/gitlab-runner/.bash_profile
echo '[ -s "/home/gitlab-runner/.nvm/nvm.sh" ] && \. "/home/gitlab-runner/.nvm/nvm.sh"' >> /home/gitlab-runner/.bash_profile
source /home/gitlab-runner/.bash_profile
nvm install 22
corepack enable yarn
corepack enable pnpm
## Bunjs
su - gitlab-runner -c 'brew install oven-sh/bun/bun'
# Python
sudo apt-get install -y -qq \
    python3.12-full python3-pip python-is-python3 pipx
pipx ensurepath
# Ansible
pipx install --include-deps ansible
# Kustomize
su - gitlab-runner -c 'brew install kustomize'
# Terraform
su - gitlab-runner -c 'brew install hashicorp/tap/terraform'
# Packer
su - gitlab-runner -c 'brew install hashicorp/tap/packer'
# Minikube
su - gitlab-runner -c 'brew install minikube'
## Helm
sudo curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
## Golang
sudo snap install go --classic
# Buildah
sudo apt-get install -y -qq buildah

## Docker
sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Gitlab cli
brew install glab
# Github cli
sudo apt-get install  -y -qq gh

# gitlab-runner groups
usermod -a -G docker gitlab-runner
docker ps

# Additional packages
sudo apt-get install -y -qq \
    rsync \
    sqlite3 \
    upx \
    parallel \
    net-tools \
    netcat-openbsd \
    iproute2 \
    dnsutils
sleep 9999

# Grub configuration
sed -E 's/GRUB_CMDLINE_LINUX=\"\"/GRUB_CMDLINE_LINUX=\"net.ifnames=0 biosdevname=0\"/' -i /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
# Network
echo 'auto eth0' | sudo tee -a /etc/network/interfaces
echo 'allow-hotplug eth0' | sudo tee -a /etc/network/interfaces
echo 'iface eth0 inet dhcp' | sudo tee -a /etc/network/interfaces