scriptroot=$(readlink -f $(dirname $0))
domainname=$1
while [ -z "$domainname" ] ; do
  read -p "Need a domain name for the site: " domainname
done

set -e

cd /opt/codex/bundle/programs/server

# Figure out how many service we're starting.
# On a single core machine, we start a single task at port 28000 that does
# all processing.
# On a multi-core machine, we start a task at port 28000 that only does
# background processing, like the bot. It could handle user requests, but we
# won't direct any at it. We will also start one task per core starting at
# port 28001, and have nginx balance over them.
PORTS=""
if [ $(nproc) -eq 1 ]; then
  PORTS="--port 28000"
else
  for index in $(seq 1 $(nproc)); do
    port=$[$index + 28000]
    PORTS="$PORTS --port $port"
    sudo systemctl enable codex@${port}.service
  done
fi
# ensure transparent hugepages get disabled. Mongodb wants this.
sudo systemctl enable nothp.service
sudo systemctl start mongod.service
  
# Turn on replication on mongodb.
# This lets the meteor instances act like secondary replicas, which lets them
# get updates in real-time instead of after 10 seconds when they poll.
sudo mongo --eval 'rs.initiate({_id: "meteor", members: [{_id: 0, host: "127.0.0.1:27017"}]});'

sudo systemctl enable codex-batch.service
  
sudo apt-get update
sudo apt-get install -y certbot

sudo certbot certonly --standalone -d $domainname

sudo apt-get install -y nginx
  
cd /etc/ssl/certs
sudo openssl dhparam -out dhparam.pem 4096
handlebars < $scriptroot/installtemplates/etc/nginx/sites-available/codex.handlebars $PORTS --domainname "$domainname" | sudo bash -c "cat > /etc/nginx/sites-available/codex"
sudo ln -s /etc/nginx/sites-{available,enabled}/codex
sudo rm /etc/nginx/sites-enabled/default
  
sudo systemctl enable codex.target
sudo systemctl start codex.target
sudo systemctl reload nginx.service

