#!/usr/bin/env bash
cp rpie-preservatives.sh /opt/retropie/configs/all/
sudo chmod +x /opt/retropie/configs/all/rpie-preservatives.sh

# replace any existing rpie-preservatives commands with the new one.
sed 's/.\/rpie-preservatives.sh.*//' /opt/retropie/configs/all/runcommand-onend.sh 
sed 's/.\/rpie-preservatives.sh.*//' /opt/retropie/configs/all/runcommand-onstart.sh 

echo "./rpie-preservatives.sh upload $1 $2 $3 $4" >> /opt/retropie/configs/all/runcommand-onend.sh
echo "./rpie-preservatives.sh download $1 $2 $3 $4" >> /opt/retropie/configs/all/runcommand-onstart.sh

# perform initial backup.
/opt/retropie/configs/all/rpie-preservatives.sh upload'