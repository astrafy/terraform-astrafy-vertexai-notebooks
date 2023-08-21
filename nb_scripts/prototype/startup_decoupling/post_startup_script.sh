#!/bin/bash

# ONLY ON FIRST BOOT IT EXECUTES

# Set proxies for apt
cat > /etc/apt/apt.conf.d/80proxy << EOF
Acquire::http::proxy "${proxy}";
Acquire::ftp::proxy "${proxy}";
Acquire::https::proxy "${proxy}";
EOF

gsutil cp gs://${nb_scripts_bucket}/startup_script.sh /usr/local/bin/startup_script.sh
chmod +x /usr/local/bin/startup_script.sh
source /usr/local/bin/startup_script.sh