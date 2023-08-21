#!/bin/bash

# AT EVERY BOOT IT EXECUTES

# Check if /etc/bash.bashrc has source command
if ! grep -q "startup_script.sh" "/etc/bash.bashrc"; then
cat >> /etc/bash.bashrc << EOF
source /usr/local/bin/bashrc_nb_updates.sh
EOF
fi

# Get bashrc_nb_updates
gsutil cp gs://${nb_scripts_bucket}/bashrc_nb_updates.sh /usr/local/bin/bashrc_nb_updates.sh
chmod -x /usr/local/bin/bashrc_nb_updates.sh

# Get zscaler certificate
gsutil cp gs://${nb_scripts_bucket}/${cert_file} /usr/local/share/ca-certificates/ZscalerRootCertificate-2048-SHA256.crt
update-ca-certificates
pip config set global.cert /etc/ssl/certs/ca-certificates.crt

# Get autoshutdown service
gsutil cp gs://${nb_scripts_bucket}/autoshutdown /usr/local/bin/autoshutdown
gsutil cp gs://${nb_scripts_bucket}/autoshutdown.service /lib/systemd/system/autoshutdown.service
chmod +x /usr/local/bin/autoshutdown
systemctl daemon-reload
systemctl --no-reload --now enable /lib/systemd/system/autoshutdown.service
systemctl restart autoshutdown.service