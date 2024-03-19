#!/bin/sh  

#################
#
# Setup (after One-Click-App configuration)  
# Run this setup script after successfully ran the Hetzner One-Click-App. 
#
#################

APP_PATH=${1:-'/opt/apps/jitsi-meet'}

# be aware that your vars are set and your .env is loaded ..
# remember: the env file is build from your cloud-config.yml  
# remember: set values for vars (for this script) in your env file  
. ${APP_PATH}/.env

# build domain string  
FQDN=${SUBDOMAIN_DOMAIN_TLD:?"Error: Domain (subdomain.domain.tld) string not defined!"}

#################
#
# checkout your repository with your custom files. 
# organizing downloaded files  
#
#################
# after checkout specific files get picked, other files the repo are removed after setup 
# expects the following repo structure:  
# +-- ./
# |   +-- apps
# |   |   +-- jitsi-meet 
# |   |   |   +-- configs
# |   |   |   +-- custom-frontend
# |   |   |   |   +-- subdomain.domain.tld (folder) 
# |   |   |   |   |   +-- css
# |   |   |   |   |   +-- images
# |   |   |   |   |   +-- static
# |   |   |   |   |   |   +-- privacy-policy-jitsi_de.html
# |   |   |   |   |   |   +-- welcome.html
# |   |   |   |   |   |   +-- close3.html
# |   |   |   +-- helper
# |   +-- web
# |   |   +-- default
# |   |   |   +-- css
# |   |   |   |   +-- styles.css
# |   |   |   +-- html  
# |   |   |   |   +-- legal-notice
# |   |   |   |   |   +-- legal-notice_de.html
# |   +-- <other files/folders>

# renames default folder to local customization 
mv -f ${APP_PATH}/custom-frontend/subdomain.domain.tld/ ${APP_PATH}/custom-frontend/${FQDN}/

#################
# 
# modifying and organizing config files
#
#################

# modifying cfg.lua
# extract the password 
# pattern:
# - zero or more blanks at beginning of line
# - followed by 'external_service_secret :"' (note the double quote)
# - followed by undefined number of any char, ends with '";' (double quote and semicolon)  
# - the pattern between the double quotes is catched as group and substituted to stdout 
# - stdout = passwordstring is stored into $EXTERNAL_SERVICE_SECRET  
# expected pattern in <domain>.cfg.lua (NOTE the blanks!): external_service_secret = "<chars>"; 
EXTERNAL_SERVICE_SECRET=$(sed -n 's/ \{0,\}external_service_secret = \"\(.*\)\"\;$/\1/p' /etc/prosody/conf.avail/${FQDN}.cfg.lua)

# parse config files to destination  
sed -e "s~{{SUBDOMAIN.DOMAIN.TLD}}~${FQDN}~g" \
-e "s~{{EXTERNAL_SERVICE_SECRET}}~${EXTERNAL_SERVICE_SECRET}~g" ${APP_PATH}/configs/domain.cfg.lua > /etc/prosody/conf.avail/${FQDN}.cfg.lua

sed "s~{{SUBDOMAIN.DOMAIN.TLD}}~${FQDN}~g" ${APP_PATH}/configs/domain-config.js > /etc/jitsi/meet/${FQDN}-config.js

# modifying jicofo.conf
# extract the password
# pattern:
# - zero or more blanks at beginning of line
# - followed by 'password :"' (note the double quote)
# - followed by undefined number of any char, ends with '"' (double quote)  
# - the pattern between the double quotes is catched as group and substituted to stdout 
# - stdout = passwordstring is stored into $JICOFO_PASSWORD  
# expected pattern in jicofo.conf: password: "<chars>" 
JICOFO_PASSWORD=$(sed -n 's/ \{0,\}password: \"\(.*\)\"$/\1/p' /etc/jitsi/jicofo/jicofo.conf)

sed -e "s~{{JICOFO_PASSWORD}}~${JICOFO_PASSWORD}~g" \
-e "s~{{SUBDOMAIN.DOMAIN.TLD}}~${FQDN}~g" ${APP_PATH}/configs/jicofo-template.conf > /etc/jitsi/jicofo/jicofo.conf

sed -e "s~{{APP_NAME}}~${APP_NAME}~g" \
-e "s~{{JITSI_WATERMARK_LINK}}~${JITSI_WATERMARK_LINK}~g" ${APP_PATH}/configs/interface_config-template.js > ${APP_PATH}/configs/interface_config.js
rm ${APP_PATH}/configs/interface_config-template.js

ln -sf ${APP_PATH}/configs/interface_config.js /usr/share/jitsi-meet/interface_config.js

# language files
ln -sf ${APP_PATH}/configs/main-de.json /usr/share/jitsi-meet/lang/main-de.json
ln -sf ${APP_PATH}/configs/main.json /usr/share/jitsi-meet/lang/main.json

# adds new user (XMPP)
# NOTE: register has no flags (instead ejabberd..) @see man prosodyctl  
prosodyctl register ${PROSODY_USER} ${FQDN} ${PROSODY_PASS}
systemctl restart prosody

# restarts with new configs  
systemctl restart jicofo
systemctl restart jitsi-videobridge2

#################
# 
# setup your custom jitsi frontend 
#
#################

# move files
mkdir -p /var/www/jitsi-meet/${FQDN}
mv -f ${APP_PATH}/custom-frontend/${FQDN}/* /var/www/jitsi-meet/${FQDN}/

# symlink files from directory outside the default installation into the installation paths 

# NOTICE: no blanks in file name allowed!
# iterator separates at blanks
STATIC_FILES="close3.html" 

for FILE in ${STATIC_FILES}
do
    # replace domain-placeholder in current file  
    # NOTE: breaks in ZSH-shell!
    CONTENT_REPLACEMENT=$(sed -e "s~{{FQDN}}~${FQDN}~g" /var/www/jitsi-meet/${FQDN}/static/${FILE})
    # temp file 
    # note: echo with double quotes to keep the line breaks..
    echo "${CONTENT_REPLACEMENT}" > /var/www/jitsi-meet/${FQDN}/static/${FILE}
    # symlink file 
    ln -sf /var/www/jitsi-meet/${FQDN}/static/${FILE} /usr/share/jitsi-meet/static/${FILE}
done

# replace placeholder in welcome page with your custom page
# troubleshooting sed @see: https://www.gnu.org/software/sed/manual/html_node/Multiple-commands-syntax.html 
sed -e "s~{{FQDN}}~${FQDN}~g" \
-e "s~{{NAME_LEGAL_NOTICE}}~${NAME_LEGAL_NOTICE}~g" \
-e "s~{{NAME_PRIVACY_POLICY}}~${NAME_PRIVACY_POLICY}~g" \
-e "s~{{FILENAME_LEGAL_NOTICE}}~${FILENAME_LEGAL_NOTICE}~g" \
-e "s~{{FILENAME_PRIVACY_POLICY}}~${FILENAME_PRIVACY_POLICY}~g" /var/www/jitsi-meet/${FQDN}/static/welcome.html > /var/www/jitsi-meet/${FQDN}/static/welcomePageAdditionalContent.html

rm /var/www/jitsi-meet/${FQDN}/static/welcome.html
ln -sf /var/www/jitsi-meet/${FQDN}/static/welcomePageAdditionalContent.html /usr/share/jitsi-meet/static/welcomePageAdditionalContent.html

# symlink image files  
IMAGE_FILES="watermark.svg header.jpg header.png waving-hand.svg"

for FILE in ${IMAGE_FILES}
do
    # symlink to ../jitsi-meet/images (no changes to filenames)
    ln -sf /var/www/jitsi-meet/${FQDN}/images/${FILE} /usr/share/jitsi-meet/images/${FILE}
done

# symlink single files to ../jitsi-meet
ln -sf /var/www/jitsi-meet/${FQDN}/css/all.css /usr/share/jitsi-meet/css/all.css
ln -sf /var/www/jitsi-meet/${FQDN}/static/css /usr/share/jitsi-meet/static/css
ln -sf /var/www/jitsi-meet/${FQDN}/images/favicon.ico /usr/share/jitsi-meet/favicon.ico

# renaming and parsing template html files to destination folder  
sed -e "s~{{FILENAME_LEGAL_NOTICE}}~${FILENAME_LEGAL_NOTICE}~g" \
-e "s~{{NAME_LEGAL_NOTICE}}~${NAME_LEGAL_NOTICE}~g" \
-e "s~{{NAME_PRIVACY_POLICY}}~${NAME_PRIVACY_POLICY}~g" \
-e "s~{{FILENAME_PRIVACY_POLICY}}~${FILENAME_PRIVACY_POLICY}~g" /var/www/jitsi-meet/${FQDN}/static/legal-notice_de.html.template > /var/www/jitsi-meet/${FQDN}/static/${FILENAME_LEGAL_NOTICE}
ln -sf /var/www/jitsi-meet/${FQDN}/static/${FILENAME_LEGAL_NOTICE} /usr/share/jitsi-meet/static/${FILENAME_LEGAL_NOTICE}
rm /var/www/jitsi-meet/${FQDN}/static/legal-notice_de.html.template

sed -e "s~{{FILENAME_PRIVACY_POLICY}}~${FILENAME_PRIVACY_POLICY}~g" \
-e "s~{{NAME_PRIVACY_POLICY}}~${NAME_PRIVACY_POLICY}~g" /var/www/jitsi-meet/${FQDN}/static/privacy-policy-jitsi_de.html.template > /var/www/jitsi-meet/${FQDN}/static/${FILENAME_PRIVACY_POLICY}
ln -sf /var/www/jitsi-meet/${FQDN}/static/${FILENAME_PRIVACY_POLICY} /usr/share/jitsi-meet/static/${FILENAME_PRIVACY_POLICY}

#################
# 
# ssh hardening
#################

# change settings in /etc/ssh/sshd_config  
# @see: https://community.hetzner.com/tutorials/basic-cloud-config/de  
sed -i -e "/^\(#\|\)PermitRootLogin/s/^.*$/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i -e "/^\(#\|\)PasswordAuthentication/s/^.*$/PasswordAuthentication no/" /etc/ssh/sshd_config
sed -i -e "/^\(#\|\)X11Forwarding/s/^.*$/X11Forwarding no/" /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)KbdInteractiveAuthentication/s/^.*$/KbdInteractiveAuthentication no/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)ChallengeResponseAuthentication/s/^.*$/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sed -i -e "/^\(#\|\)MaxAuthTries/s/^.*$/MaxAuthTries ${SSH_MAX_AUTHTRIES}/" /etc/ssh/sshd_config
sed -i -e "/^\(#\|\)AllowTcpForwarding/s/^.*$/AllowTcpForwarding no/" /etc/ssh/sshd_config
sed -i -e "/^\(#\|\)AllowAgentForwarding/s/^.*$/AllowAgentForwarding no/" /etc/ssh/sshd_config
sed -i -e "/^\(#\|\)Port/s/^.*$/Port ${SSH_PORT}/" /etc/ssh/sshd_config
sed -i -e "/^\(#\|\)AuthorizedKeysFile/s/^.*$/AuthorizedKeysFile .ssh\/authorized_keys/" /etc/ssh/sshd_config

# set allowed users  
# more than one user: user name separated by blanks  
sed -i "\$a AllowUsers ${SSH_USERS}" /etc/ssh/sshd_config

# override firewall settings from cloud-init.yaml  
# close the default ssh port
if [ ${SSH_PORT} -ne 22 ]
then 
    ufw deny 22/tcp 
else 
    :
fi

systemctl restart ufw
systemctl restart sshd
systemctl restart nginx

# housekeeping
rm -R /opt/apps/jitsi-meet/custom-frontend