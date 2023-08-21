#!/bin/bash

# Set up proxies and refresh_zscaler_cert function system wise
cat <<EOT >> /etc/bash.bashrc
export HTTP_PROXY=${proxy}
export http_proxy=${proxy}
export HTTPS_PROXY=${proxy}
export https_proxy=${proxy}
export NO_PROXY=${no_proxy}
export no_proxy=${no_proxy}
export CERT_GCS_PATH=gs://${nb_scripts_bucket}/${cert_file}
export CERT_PATH=/usr/local/share/ca-certificates/ZscalerRootCertificate-2048-SHA256.crt
export AUTOSHUTDOWN_GCS_PATH=gs://${nb_scripts_bucket}/autoshutdown
export AUTOSHUTDOWN_GCS_SERVICE_PATH=gs://${nb_scripts_bucket}/autoshutdown.service
export AUTOSHUTDOWN_PATH=/usr/local/bin/autoshutdown
export AUTOSHUTDOWN_SERVICE_PATH=/lib/systemd/system/autoshutdown.service

# this function to allow the user to refresh the zscaler certificate
function refresh_zscaler_cert(){
    sudo gsutil cp \$CERT_GCS_PATH \$CERT_PATH
    sudo update-ca-certificates
    pip config set global.cert /etc/ssl/certs/ca-certificates.crt
}

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

# Set proxies for apt
cat > /etc/apt/apt.conf.d/80proxy << EOF
Acquire::http::proxy "${proxy}";
Acquire::ftp::proxy "${proxy}";
Acquire::https::proxy "${proxy}";
EOF

# Set zscaler certificate
gsutil cp gs://${nb_scripts_bucket}/${cert_file} /usr/local/share/ca-certificates/ZscalerRootCertificate-2048-SHA256.crt
update-ca-certificates
pip config set global.cert /etc/ssl/certs/ca-certificates.crt

# Add autoshutdown service
gsutil cp gs://${nb_scripts_bucket}/autoshutdown /usr/local/bin/autoshutdown
gsutil cp gs://${nb_scripts_bucket}/autoshutdown.service /lib/systemd/system/autoshutdown.service
chmod +x /usr/local/bin/autoshutdown
systemctl daemon-reload
systemctl --no-reload --now enable /lib/systemd/system/autoshutdown.service
systemctl restart autoshutdown.service

# pyenv dependencies
apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python-openssl git

# Set Terraform Enterprise certs (to be able to run install terraform modules from a VM)
# https://richemont.sharepoint.com/sites/GT-ICS-Cloud_RIC-CH/SitePages/Getting-Started-with-GitLab-EE.aspx
for terraform_cert in RI-ICA1.crt RI-RCA1.crt; do
    wget http://crl.richemont.com/CRL/$terraform_cert
    openssl x509 -inform DER -in $terraform_cert -outform PEM -out $terraform_cert
    mv $terraform_cert /usr/local/share/ca-certificates/
done
