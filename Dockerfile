FROM freeradius/freeradius-server:3.0.19

# Install winbind Dependencies
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
    apt-get install -y winbind krb5-user libpam-krb5 libnss-winbind libpam-winbind samba samba-dsdb-modules samba-vfs-modules

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Allow freerad to access winbind socket & Enable Status
RUN usermod -aG winbindd_priv freerad && \
    ln -s /etc/freeradius/sites-available/status /etc/freeradius/sites-enabled/status && \
    echo "rest {}" > /etc/freeradius/mods-enabled/rest

COPY configs/clients.conf /etc/freeradius/clients.conf
COPY configs/proxy.conf /etc/freeradius/proxy.conf
COPY configs/default /etc/freeradius/site-enabled/default
COPY configs/inner-tunnel /etc/freeradius/site-enabled/inner-tunnel
COPY configs/linelog /etc/freeradius/mods-enabled/linelog
COPY dictionary-files/dictionary.fortinet /usr/share/freeradius/dictionary.fortinet
COPY dictionary-files/dictionary.eduroam /etc/freeradius/dictionary
COPY configs/smb.conf /etc/samba/smb.conf
COPY init.sh /usr/local/bin

RUN chmod +x /usr/local/bin/init.sh

ENTRYPOINT ["/usr/local/bin/init.sh"]

CMD ["freeradius"]

