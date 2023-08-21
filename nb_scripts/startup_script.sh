#!/bin/bash

# Set up proxies and refresh_zscaler_cert function system wise
cat <<EOT >> /etc/bash.bashrc
export AUTOSHUTDOWN_GCS_PATH=gs://${nb_scripts_bucket}/autoshutdown
export AUTOSHUTDOWN_GCS_SERVICE_PATH=gs://${nb_scripts_bucket}/autoshutdown.service
export AUTOSHUTDOWN_PATH=/usr/local/bin/autoshutdown
export AUTOSHUTDOWN_SERVICE_PATH=/lib/systemd/system/autoshutdown.service

# this function to allow the user to refresh the autoshutdown service
function refresh_autoshutdown(){
    sudo gsutil cp \$AUTOSHUTDOWN_GCS_PATH \$AUTOSHUTDOWN_PATH
    sudo gsutil cp \$AUTOSHUTDOWN_GCS_SERVICE_PATH \$AUTOSHUTDOWN_SERVICE_PATH
    sudo chmod +x /usr/local/bin/autoshutdown
    sudo systemctl daemon-reload
    sudo systemctl --no-reload --now enable /lib/systemd/system/autoshutdown.service
    sudo systemctl restart autoshutdown.service
}
EOT

# Add autoshutdown service
gsutil cp gs://${nb_scripts_bucket}/autoshutdown /usr/local/bin/autoshutdown
gsutil cp gs://${nb_scripts_bucket}/autoshutdown.service /lib/systemd/system/autoshutdown.service
chmod +x /usr/local/bin/autoshutdown
systemctl daemon-reload
systemctl --no-reload --now enable /lib/systemd/system/autoshutdown.service
systemctl restart autoshutdown.service

# pyenv dependencies
apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python-openssl git