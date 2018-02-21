# A Nagios Docker Container with PagerDuty

## Environment Variables

`PAGERDUTY_INTEGRATION_KEY` To enable PagerDuty integration, set this to your
Integration Key value.

`NAGIOS_BASE_URL` The base URL to access Nagios at. Default: `/nagios/`

`NAGIOSADMIN_PASSWORD` Set the password for the `nagiosadmin` user. This
writes an `htpasswd` file and turns on HTTP basic auth.

`PROXY_ALLOW_REMOTE_USER` Respect the `REMOTE_USER` header coming from an
upstream proxy. DO NOT ENABLE THIS UNLESS BEHIND A REVERSE PROXY THAT PROPERLY
SETS THIS HEADER.

`NGINX_HTTP_PORT` Change the default port Nginx listens on.  Useful if you are
using host networking and the default port 80 is already bound to another
process.

`LETSENCRYPT_DOMAINS` Space-separated list of domain names managed by
Letsencrypt. When set, this changes the nginx config to serve Nagios on HTTPS
rather than HTTP at the domains listed in the variable. The letsencrypt
webroot directory must be mounted as a volume to `/var/www/letsencrypt`, and
the letsencrypt certificate directory must be mounted to `/etc/nginx/certs`
(ie. `/etc/nginx/certs/<domain>/live/fullchain.pem` would be the path to the
certificate chain for each domain listed in this variable.) Also, ensure that
there is a `dhparam.pem` file in the certificate directory.

## Volumes and Configuration

You can configure Nagios by mounting a directory containing `nagios.cfg` to
`/opt/nagios/etc`. Note that if you set the `PAGERDUTY_INTEGRATION_KEY`
environment variable, the entrypoint script will attempt to substitute that
value into a file at `/opt/nagios/etc/objects/pagerduty.cfg` (And also modify
a couple other files. See `files/entrypoint.sh` for details.)

You can also configure nginx by mounting to things under `/etc/nagios`. Note
that setting the `NAGIOS_BASE_URL` environment variable will cause the
entrypoint script to write to `/etc/nagios/conf.d/nagios.conf` if it exists.
