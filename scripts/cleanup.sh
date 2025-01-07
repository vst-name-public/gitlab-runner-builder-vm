#!/bin/bash -eux
echo "==> remove SSH keys used for building"
sudo rm -f /home/ubuntu/.ssh/authorized_keys
sudo rm -f /root/.ssh/authorized_keys
if yarn --version > /dev/null; then
    yarn cache clean
fi

if npm --version; then
    npm cache clean --force
fi
# Expire ubuntu user password
sudo chage -E 0 gitlab-runner

echo "==> Clear out machine id"
sudo truncate -s 0 /etc/machine-id

echo "==> Remove the contents of /tmp and /var/tmp"
sudo rm -rf /tmp/* /var/tmp/*

echo "==> Truncate any logs that have built up during the install"
sudo find /var/log -type f -exec truncate --size=0 {} \;

echo "==> Cleanup bash history"
sudo rm -f ~/.bash_history

echo "remove /usr/share/doc/"
sudo rm -rf /usr/share/doc/*

echo "==> remove /var/cache"
sudo find /var/cache -type f -exec rm -rf {} \;

echo "==> Cleanup apt"
sudo apt-get -y autoremove
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

echo "==> force a new random seed to be generated"
sudo rm -f /var/lib/systemd/random-seed

echo "==> Clear the history so our install isn't there"
sudo rm -f /root/.wget-hsts

export HISTSIZE=0