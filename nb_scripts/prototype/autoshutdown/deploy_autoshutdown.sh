#!/bin/bash

chmod +x autoshutdown
sudo cp autoshutdown.service /lib/systemd/system/autoshutdown.service
sudo cp autoshutdown /usr/local/bin/autoshutdown
sudo systemctl daemon-reload
sudo systemctl --no-reload --now enable /lib/systemd/system/autoshutdown.service
sudo systemctl restart autoshutdown.service