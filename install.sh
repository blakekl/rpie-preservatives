#!/usr/bin/env bash
cp ./rpie-preservatives.sh /opt/retropie/configs/all/
cp ./rpie-settings.cfg.example /opt/retropie/configs/all/
sudo chmod +x /opt/retropie/configs/all/rpie-preservatives.sh

# replace any existing rpie-preservatives commands with the new one.
sed -in "s|/opt/retropie/configs/all/rpie-preservatives.sh.*||" /opt/retropie/configs/all/runcommand-onend.sh 
sed -in "s|/opt/retropie/configs/all/rpie-preservatives.sh.*||" /opt/retropie/configs/all/runcommand-onstart.sh 

echo "/opt/retropie/configs/all/rpie-preservatives.sh upload $1 $2 $3 $4" >> /opt/retropie/configs/all/runcommand-onend.sh
echo "/opt/retropie/configs/all/rpie-preservatives.sh download $1 $2 $3 $4" >> /opt/retropie/configs/all/runcommand-onstart.sh
