#!/bin/bash

set -e

mkdir -p /tmp/basic-config
ls -al /
tar -xvf /basic-config.tar.gz -C /tmp/basic-config/
ls -al /tmp/basic-config/
cd /tmp/basic-config/modulejson

#admin password
##had to run on php because linux sha1 doesn't use ASCII encoding for this, giving different results
ADMIN_PASS_SHA1=$(php /generate-sha1.php "$ADMIN_PASSWORD")
sed -i 's/"password_sha1": "d033e22ae348aeb5660fc2140aec35850c4da997"/"password_sha1": "'$ADMIN_PASS_SHA1'"/' Core.json
# echo "Core.json"
# cat Core.json

if [ "$USE_CHAN_SIP" == "true" ]; then
  sed -i 's/"ASTSIPDRIVER": "chan_pjsip"/"ASTSIPDRIVER": "chan_sip"/' Framework.json
fi
if [ "$DISABLE_SIGNATURE_CHECK" == "true" ]; then
  sed -i 's/"SIGNATURECHECK": "1"/"SIGNATURECHECK": "0"/' Framework.json
fi
# echo "Framework.json"
# cat Framework.json



#RTP port range
sed -i 's/"rtpstart": "10000"/"rtpstart": "'$RTP_START'"/' Sipsettings.json
sed -i 's/"rtpend": "20000"/"rtpend": "'$RTP_FINISH'"/' Sipsettings.json
#Public IP
if [ "$SIP_NAT_IP" == "" ]; then
  SIP_NAT_IP=$(curl ifconfig.me)
fi
sed -i 's/"externip": "186.195.33.54"/"externip": "'$SIP_NAT_IP'"/' Sipsettings.json
# echo "Sipsettings.json"
# cat Sipsettings.json

echo "Assembling updated backup archive..."

cd /tmp/basic-config
mv modulejson /tmp/
mkdir modulejson
mv /tmp/modulejson/Framework.json modulejson/
mv /tmp/modulejson/Core.json modulejson/
mv /tmp/modulejson/Filestore.json modulejson/
mv /tmp/modulejson/Backup.json modulejson/
mv /tmp/modulejson/Sipsettings.json modulejson/

tar -czvf /tmp/updated-config.tar.gz .

echo "Restoring backup contents with initial configurations..."
fwconsole backup --restore /tmp/updated-config.tar.gz

echo "Restored backup with initial configurations successfully"
