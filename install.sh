#!/bin/bash

apt install -y docker.io runit

if [ ! -d /etc/service/nagios ]; then
    echo Installing nagios service runscript
    mkdir -p /etc/service/nagios
    cat > /etc/service/nagios/run <<EOF
#!/bin/bash

exec docker run \\
    --name nagios \\
    -e LETSENCRYPT_DOMAINS=example.com \\
    -e NAGIOSADMIN_PASSWORD=superstrongpassword \\
    -v /etc/nagios:/opt/nagios/etc:ro \\
    -v /var/lib/nagios:/opt/nagios/var \\
    -v /var/www/letsencrypt:/var/www/letsencrypt:ro \\
    -v /etc/letsencrypt:/etc/nginx/certs:ro \\
    -p 80:80 -p 443:443 \\
    --rm nagios-pagerduty:latest
EOF
    chmod 750 /etc/service/nagios/run
fi

if crontab -l | grep -q 'certbot renew'; then
    echo Installing certbot renew cronjob
    crontab - <<EOF
5 0 * * * /usr/bin/docker run --rm -v /var/www/letsencrypt:/var/www/letsencrypt -v /var/lib/letsencrypt:/var/lib/letsencrypt -v /etc/letsencrypt:/etc/letsencrypt -it certbot/certbot renew
EOF
fi
