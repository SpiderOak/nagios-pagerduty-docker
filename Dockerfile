FROM ubuntu:16.04
MAINTAINER David Hain <dhain@spideroak-inc.com>

ENV NAGIOS_BRANCH nagios-4.3.4
ENV NAGIOS_PLUGINS_BRANCH release-2.2.1
ENV NRPE_BRANCH nrpe-3.2.1

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    apt-transport-https && \
    curl -sL https://packages.pagerduty.com/GPG-KEY-pagerduty | apt-key add - && \
    echo 'deb https://packages.pagerduty.com/pdagent deb/' > /etc/apt/sources.list.d/pdagent.list && \
    apt-get update && \
    mv /bin/systemctl /bin/systemctl.bak && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    pdagent \
    pdagent-integrations && \
    mv /bin/systemctl.bak /bin/systemctl && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    php7.0-fpm \
    fcgiwrap \
    nginx \
    runit \
    iputils-ping \
    netcat \
    build-essential \
    automake \
    autoconf \
    m4 \
    gettext \
    git \
    php-gd \
    libgd-dev \
    libssl-dev \
    unzip && \
    useradd nagios && \
    usermod -aG nagios www-data && \
    rm /etc/nginx/sites-*/default && \
    cd /tmp && \
    git clone https://github.com/NagiosEnterprises/nagioscore.git -b $NAGIOS_BRANCH && \
    cd nagioscore && \
    ./configure \
    --prefix=/opt/nagios \
    --exec-prefix=/opt/nagios \
    --with-command-user=nagios \
    --with-command-group=nagios \
    --with-nagios-user=nagios \
    --with-nagios-group=nagios \
    --enable-event-broker && \
    make all && \
    make install && \
    make install-init && \
    make install-config && \
    make install-commandmode && \
    cp -R contrib/eventhandlers/ /opt/nagios/libexec/ && \
    chown -R nagios:nagios /opt/nagios/libexec/eventhandlers && \
    cd $WORKDIR && \
    rm -rf /tmp/nagioscore && \
    cd /tmp && \
    git clone https://github.com/nagios-plugins/nagios-plugins.git -b $NAGIOS_PLUGINS_BRANCH && \
    cd nagios-plugins && \
    ./tools/setup && \
    ./configure --prefix=/opt/nagios && \
    make && \
    make install && \
    mkdir -p /usr/lib/nagios/plugins && \
    ln -sf /opt/nagios/libexec/utils.pm /usr/lib/nagios/plugins && \
    cd $WORKDIR && \
    rm -rf /tmp/nagios-plugins && \
    cd /tmp && \
    git clone https://github.com/NagiosEnterprises/nrpe.git -b $NRPE_BRANCH && \
    cd nrpe && \
    ./configure \
    --with-ssl=/usr/bin/openssl \
    --with-ssl-lib=/usr/lib/x86_64-linux-gnu && \
    make check_nrpe && \
    cp src/check_nrpe /opt/nagios/libexec/ && \
    cd $WORKDIR && \
    rm -rf /tmp/nrpe && \
    apt-get purge --autoremove -y \
    build-essential \
    git && \
    rm -rf /var/lib/apt/lists/*

ADD files /

EXPOSE 80

VOLUME "/opt/nagios/var" "/opt/nagios/etc" "/opt/nagios/libexec"

ENTRYPOINT ["/entrypoint.sh"]
