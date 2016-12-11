#!/bin/bash
###############################################################
### Ghost Install Script by: Nick Reichley nick@reichley.co ###
###############################################################
# Please remember to "chmod u+x script" the script to make it executable.


echo "This install script will install ghost on your *CLEAN* Ubuntu 14.04 64-bit server."
echo "(It will also boot ghost on start.)"
echo
echo "Remember to navigate to http://DOMAIN/ghost/setup to create an account and get started."
echo
echo "WARNING: THIS SCRIPT WILL OVERWRITE/CHANGE PREEXISTING SERVER CONFIGURATIONS. PLEASE USE A CLEAN IMAGE/MACHINE."
echo
echo "The only input required is your domain name (no http:// or https://) and"
echo "a 'y' or 'n' at the completion of the install to restart your server."
echo
echo "NOTE: Not all output is \"supressed\" so the screen may be a little noisy for a minute."
echo
# grab your domain name to insert into nginx and ghost configs
echo "enter your hostname: (i.e. example.com) "
read ghosthost
echo 
echo "updating system..."
apt-get -qq update
apt-get -qq dist-upgrade
echo 
echo "installing node.js and npm"
apt-get install -qq unzip wget nodejs-legacy npm
mkdir -p /var/www/; cd /var/www/; wget https://ghost.org/zip/ghost-latest.zip
sleep 1
unzip -d ghost ghost-latest.zip; cd ghost/
npm install --production
cp config.example.js config.js  
echo 
echo "installing nginx..."
apt-get install -qq nginx
echo
echo "editing nginx default site and ghost config to allow ghost to proxy through port 80"
echo
`sed -i '36s/root/# &/' /etc/nginx/sites-enabled/default`
`sed -i '39s/index/# &/' /etc/nginx/sites-enabled/default`
`sed -i "41s/server_name\ _/server_name\ $ghosthost/g" /etc/nginx/sites-enabled/default`
`sed -i '46s/try/# &/' /etc/nginx/sites-enabled/default`
proxyvar=$(echo "proxy_set_header X-Real-IP \$remote_addr;\nproxy_set_header Host \$http_host;\nproxy_pass http://127.0.0.1:2368;")
`sed -i "47s@}@${proxyvar}\n}@g" /etc/nginx/sites-enabled/default`
echo "installing systemd service to keep ghost up and running..."
adduser --shell /bin/bash --gecos 'Ghost application server' --no-create-home --disabled-password ghost
chown -R ghost:ghost /var/www/ghost/
cat >/etc/systemd/system/ghost.service << EOL
# Place in /etc/systemd/system/ghost.service
[Unit]
Description=Ghost Blog  
After=network.target

[Service]
Type=simple  
PIDFile=/run/ghostblog.pid  
# This is the directory you installed Ghost to
WorkingDirectory=/var/www/ghost/  
User=ghost  
Group=ghost  
ExecStart=/usr/bin/npm start --production  
ExecStop=/usr/bin/npm stop /var/www/ghost/  
StandardOutput=syslog  
StandardError=syslog

[Install]
WantedBy=multi-user.target
EOL
echo 
echo "restarting nginx, starting ghost, enabling on boot..."
echo
service nginx restart; service ghost start; systemctl enable ghost.service
sleep 2
rm -f /var/www/ghost-latest.zip
`sed -i "13s/my-ghost-blog.com/$ghosthost/g" /var/www/ghost/config.js`
echo
echo "installation complete!"
echo
echo "--------------------------------------------------------------------------------------" 
echo "navigate to http://$ghosthost/ghost/setup to create an account and get started BUT..."
echo "--------------------------------------------------------------------------------------" 
echo
echo "you should reboot to test the setup."
echo
echo "do you wish to do so now? (y or n)"
read yesorno
if [ "$yesorno" = "y" ]; then
    echo "rebooting!"
    reboot
else
    echo
    echo "congrats! navigate to http://$ghosthost/ghost/setup to get started."
fi
