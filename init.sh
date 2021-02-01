#!/bin/bash

set -e

[ "$DEBUG" ] && set -x

echo "$@"

echo --------------------------------------------------
echo "Checking / Setting ENV vars"
echo --------------------------------------------------

# Check if all env parameters exist
[ -z "$FR_ACCESS_ALLOWED_CIDR" ] && echo "ACCESS_ALLOWED_CIDR env variable not defined! Exiting..." && exit 1
[ -z "$FR_SHARED_SECRET" ] && echo "FR_SHARED_SECRET env variable not defined! Exiting..." && exit 1
[ -z "$FR_DOMAIN" ] && echo "DOMAIN env variable not defined! Exiting..." && exit 1

# Check for optional eduroam Params
if [ "${ENABLE_EDUROAM^^}" == "TRUE" ]; then
    [ -z "$EDUROAM_FLR1_IPADDR" ] && echo "EDUROAM_FLR1_IPADDR env variable not defined! Exiting..." && exit 1
    [ -z "$EDUROAM_FLR1_SECRET" ] && echo "EDUROAM_FLR1_SECRET env variable not defined! Exiting..." && exit 1
    
    # optionally check for FLR2
    if [ "$EDUROAM_FLR2_IPADDR" ]; then
        [ -z "$EDUROAM_FLR2_SECRET" ] && echo "EDUROAM_FLR2_SECRET env variable not defined! Exiting..." && exit 1
    fi

    [ -z "$EDUROAM_CLIENT_SERVER" ] && echo "EDUROAM_CLIENT_SERVER env variable not defined! Exiting..." && exit 1
    [ -z "$EDUROAM_CLIENT_SECRET" ] && echo "EDUROAM_CLIENT_SECRET env variable not defined! Exiting..." && exit 1
fi

# Check for LDAP Params
#[ -z "$LDAP_PASSWORD" ] && echo "LDAP_PASSWORD env variable not defined! Exiting..." && exit 1
#[ -z "$LDAP_USERNAME" ] && echo "LDAP_USERNAME env variable not defined! Exiting..." && exit 1

# Check for required AD Params
[ -z "$AD_DOMAIN" ] && echo "AD_DOMAIN env variable not defined! Exiting..." && exit 1
[ -z "$AD_SERVER" ] && echo "AD_SERVER env variable not defined! Exiting..." && exit 1
[ -z "$AD_WORKGROUP" ] && echo "AD_WORKGROUP env variable not defined! Exiting..." && exit 1
[ -z "$AD_USERNAME" ] && echo "AD_USERNAME env variable not defined! Exiting..." && exit 1
[ -z "$AD_PASSWORD" ] && echo "AD_PASSWORD env variable not defined! Exiting..." && exit 1
export AD_HOSTNAME=$(hostname)

echo --------------------------------------------------
echo "Setting up Kerberos realm: \"${AD_DOMAIN^^}\""
echo --------------------------------------------------

cat > /etc/krb5.conf << EOL
[logging]
    default = FILE:/var/log/krb5.log 
    kdc = FILE:/var/log/kdc.log 
    admin_server = FILE:/var/log/kadmind.log
[libdefaults]
    default_realm = ${AD_DOMAIN^^}
    dns_lookup_realm = false
    dns_lookup_kdc = false
[realms]
    ${AD_DOMAIN^^} = {
        kdc = $(echo ${AD_SERVER,,} | awk '{print $1}')
        admin_server = $(echo ${AD_SERVER,,} | awk '{print $1}')
        default_domain = ${AD_DOMAIN^^}       
    }
    ${AD_DOMAIN,,} = {
        kdc = $(echo ${AD_SERVER,,} | awk '{print $1}')
        admin_server = $(echo ${AD_SERVER,,} | awk '{print $1}')
        default_domain = ${AD_DOMAIN,,}
    }
    ${AD_WORKGROUP^^} = {
        kdc = $(echo ${AD_SERVER,,} | awk '{print $1}')
        admin_server = $(echo ${AD_SERVER,,} | awk '{print $1}')
        default_domain = ${AD_DOMAIN^^}       
    }
    
[domain_realm]
    .${AD_DOMAIN,,} = ${AD_DOMAIN^^}
    ${AD_DOMAIN,,} = ${AD_DOMAIN^^}
EOL

echo --------------------------------------------------
echo "Setting up SMBD and NMBD"
echo --------------------------------------------------

sed -i "s|AD_DOMAIN|${AD_DOMAIN^^}|g" /etc/samba/smb.conf
sed -i "s|AD_WORKGROUP|${AD_WORKGROUP^^}|g" /etc/samba/smb.conf
sed -i "s|AD_HOSTNAME|$AD_HOSTNAME|g" /etc/samba/smb.conf
/etc/init.d/nmbd restart
/etc/init.d/smbd restart

echo --------------------------------------------------
echo 'Generating Kerberos ticket'
echo --------------------------------------------------

echo $AD_PASSWORD | kinit -V $AD_USERNAME

echo --------------------------------------------------
echo 'Joining Active Directory'
echo --------------------------------------------------

net ads join -U "$AD_USERNAME"%"$AD_PASSWORD"
/etc/init.d/winbind restart

echo --------------------------------------------------
echo 'Configuring FreeRADIUS: clients.conf'
echo --------------------------------------------------

["$FR_CLIENT_NAME"] && sed -i "s|user_defined_client|$FR_CLIENT_NAME|g" /etc/freeradius/clients.conf
sed -i "s|EDUROAM_CLIENT_SERVER|$EDUROAM_CLIENT_SERVER|g" /etc/freeradius/clients.conf
sed -i "s|EDUROAM_CLIENT_SECRET|$EDUROAM_CLIENT_SECRET|g" /etc/freeradius/clients.conf
sed -i "s|ACCESS_ALLOWED_CIDR|$FR_ACCESS_ALLOWED_CIDR|g" /etc/freeradius/clients.conf
sed -i "s|SHARED_SECRET|$FR_SHARED_SECRET|g" /etc/freeradius/clients.conf

echo --------------------------------------------------
echo 'Configuring FreeRADIUS: proxy.conf'
echo --------------------------------------------------

sed -i "s|REALM_DOMAIN_NAME|$FR_DOMAIN|g" /etc/freeradius/proxy.conf

## eduroam
if [ "${ENABLE_EDUROAM^^}" == "TRUE" ]; then
    echo "Enabling eduroam Config..."
    LINESTART=$(grep -nr "realm DEFAULT {" /etc/freeradius/proxy.conf | cut -d : -f1 )
    if [ "$LINESTART" ]; then
        LINEEND=$((LINESTART+3))
        sed -i "${LINESTART},${LINEEND} s/# *//" /etc/freeradius/proxy.conf
        unset LINESTART
        unset LINEEND
    fi

    sed -i "s|EDUROAM_FLR1_IPADDR|$EDUROAM_FLR1_IPADDR|g" /etc/freeradius/proxy.conf
    sed -i "s|EDUROAM_FLR1_SECRET|$EDUROAM_FLR1_SECRET|g" /etc/freeradius/proxy.conf
    if [ "$EDUROAM_FLR2_IPADDR" ]; then
        LINESTART=$(grep -nr "home_server eduroam_flr_server_2" /etc/freeradius/proxy.conf | cut -d : -f1 )
        if [ "$LINESTART" ]; then
            LINEEND=$((LINESTART+8))
            sed -i "${LINESTART},${LINEEND} s/# *//" /etc/freeradius/proxy.conf
            unset LINESTART
            unset LINEEND
        fi
        sed -i '/eduroam_flr_server_2/s/^#//g' /etc/freeradius/proxy.conf
        sed -i "s|EDUROAM_FLR2_IPADDR|$EDUROAM_FLR2_IPADDR|g" /etc/freeradius/proxy.conf
        sed -i "s|EDUROAM_FLR2_SECRET|$EDUROAM_FLR2_SECRET|g" /etc/freeradius/proxy.conf
    fi
fi

echo --------------------------------------------------
echo 'Configuring FreeRADIUS: mods-available/mschap'
echo --------------------------------------------------

sed -i "s|/path/to/ntlm_auth|/usr/bin/ntlm_auth|g" /etc/freeradius/mods-available/mschap
sed -i '/ntlm_auth\ \=\ /s/^#//g' /etc/freeradius/mods-available/mschap
# enable password change requests
sed -i '/ntlm_auth_/s/^#//g' /etc/freeradius/mods-available/mschap

echo --------------------------------------------------
echo 'Configuring FreeRADIUS: radiusd.conf'
echo --------------------------------------------------
# enable auth logging ;)
sed -i 's/^\s*auth\ =\ no/auth\ =\ yes/g' etc/freeradius/radiusd.conf

echo --------------------------------------------------
echo 'Configuring FreeRADIUS: logfiles'
echo --------------------------------------------------
# make sure loglines exist with appropriate permissions
touch /var/log/freeradius/linelog-access
touch /var/log/freeradius/linelog-accounting
chmod 644 /var/log/freeradius/linelog-access
chmod 644 /var/log/freeradius/linelog-accounting

echo --------------------------------------------------
echo 'Configuring FreeRADIUS: certificates'
echo --------------------------------------------------

# Handle the rest of the certificates
# First the array of files which need 640 permissions
FILES_640=( "ca.key" "server.key" "server.p12" "server.pem" "ldap-client.crt" "ldap-client.key" )
for i in "${FILES_640[@]}"
do
	if [ -f "/certs/$i" ]; then
	    cp /certs/$i /etc/raddb/certs/$i
	    chmod 640 /etc/raddb/certs/$i
	fi
done

# Now all files that need a 644 permission set
FILES_644=( "ca.pem" "server.crt" "server.csr" "dh" )
for i in "${FILES_644[@]}"
do
	if [ -f "/certs/$i" ]; then
	    cp /certs/$i /etc/raddb/certs/$i
	    chmod 644 /etc/raddb/certs/$i
	fi
done

echo --------------------------------------------------
echo 'Unset ENV Vars'
echo --------------------------------------------------

unset AD_PASSWORD
unset FR_SHARED_SECRET
unset EDUROAM_CLIENT_SECRET
unset EDUROAM_FLR1_SECRET
unset EDUROAM_FLR2_SECRET

/docker-entrypoint.sh "$@"
