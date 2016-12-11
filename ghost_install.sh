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
curl -sL https://deb.nodesource.com/setup_4.x | sudo bash -
apt-get install -qq nodejs
npm install -g ghost --production
#cd /usr/lib/node_modules/ghost/ # move this and next step to post-install
#npm start --production
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
`sed -i "47s/}/$proxyvar\n} &/" /etc/nginx/sites-enabled/default`
echo "installing supervisor to keep ghost up and running..."
apt-get install -qq supervisor
cat >/etc/supervisor/conf.d/ghost.conf << EOL
[program:ghost]  
command = node /usr/lib/node_modules/ghost/index.js  
directory = /usr/lib/node_modules/ghost  
user = ghost  
autostart = true  
autorestart = true  
stdout_logfile = /var/log/supervisor/ghost.log  
stderr_logfile = /var/log/supervisor/ghost_err.log  
environment = NODE_ENV="production"
EOL
echo "starting supervisor..."
service supervisor start
useradd ghost
chown -R ghost /usr/lib/node_modules/ghost/
echo 
echo "restarting nginx and supervisor..."
echo
service supervisor restart
service nginx restart
sleep 3
`sed -i "13s/my-ghost-blog.com/$ghosthost/g" /usr/lib/node_modules/ghost/config.js`
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
