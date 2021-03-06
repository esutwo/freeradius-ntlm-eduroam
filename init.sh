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

# Check for eduroam Params
[ -z "$EDUROAM_CLIENT_SERVER" ] && echo "EDUROAM_CLIENT_SERVER env variable not defined! Exiting..." && exit 1
[ -z "$EDUROAM_CLIENT_SECRET" ] && echo "EDUROAM_CLIENT_SECRET env variable not defined! Exiting..." && exit 1
[ -z "$EDUROAM_AUTHHOST" ] && echo "EDUROAM_AUTHHOST env variable not defined! Exiting..." && exit 1
[ -z "$EDUROAM_ACCTHOST" ] && echo "EDUROAM_ACCTHOST env variable not defined! Exiting..." && exit 1
[ -z "$EDUROAM_SECRET" ] && echo "EDUROAM_SECRET env variable not defined! Exiting..." && exit 1

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

sed -i "s|EDUROAM_CLIENT_SERVER|$EDUROAM_CLIENT_SERVER|g" /etc/freeradius/clients.conf
sed -i "s|EDUROAM_CLIENT_SECRET|$EDUROAM_CLIENT_SECRET|g" /etc/freeradius/clients.conf
sed -i "s|ACCESS_ALLOWED_CIDR|$FR_ACCESS_ALLOWED_CIDR|g" /etc/freeradius/clients.conf
sed -i "s|SHARED_SECRET|$FR_SHARED_SECRET|g" /etc/freeradius/clients.conf

echo --------------------------------------------------
echo 'Configuring FreeRADIUS: proxy.conf'
echo --------------------------------------------------

sed -i "s|REALM_DOMAIN_NAME|$FR_DOMAIN|g" /etc/freeradius/proxy.conf
sed -i "s|AD_WORKGROUP|${AD_WORKGROUP^^}|g" /etc/freeradius/proxy.conf
## eduroam
sed -i "s|EDUROAM_AUTHHOST|$EDUROAM_AUTHHOST|g" /etc/freeradius/proxy.conf
sed -i "s|EDUROAM_ACCTHOST|$EDUROAM_ACCTHOST|g" /etc/freeradius/proxy.conf
sed -i "s|EDUROAM_SECRET|$EDUROAM_SECRET|g" /etc/freeradius/proxy.conf

#echo --------------------------------------------------
#echo 'Configuring FreeRADIUS: mods-available/ldap'
#echo --------------------------------------------------

## ldap
#sed -i "s|LDAP_SERVER|$LDAP_SERVER|g" /etc/freeradius/mods-available/ldap
#sed -i "s|LDAP_PASSWORD|$LDAP_PASSWORD|g" /etc/freeradius/mods-available/ldap
#sed -i "s|LDAP_USERNAME|$LDAP_USERNAME|g" /etc/freeradius/mods-available/ldap
#sed -i "s|LDAP_BASE_DN|$LDAP_BASE_DN|g" /etc/freeradius/mods-available/ldap
#sed -i "s|LDAP_GROUP_CLASS|$LDAP_GROUP_CLASS|g" /etc/freeradius/mods-available/ldap
#sed -i "s|LDAP_IDENTIFIER|$LDAP_IDENTIFIER|g" /etc/freeradius/mods-available/ldap

# Handle the certs
#if test -v LDAP_CERTS; then
#	cp /certs/ldap-client.key /etc/freeradius/certs/ldap-client.key
#	cp /certs/ldap-client.crt /etc/freeradius/certs/ldap-client.crt
#	chown freerad:freerad /etc/freeradius/certs/ldap-client*
#	chmod 640 /etc/freeradius/certs/ldap-client*
#	sed -i '/#.*certificate_file/s/^#//g' /etc/freeradius/mods-available/ldap
#	sed -i '/#.*private_key_file/s/^#//g' /etc/freeradius/mods-available/ldap
#fi

echo --------------------------------------------------
echo 'Configuring FreeRADIUS: mods-available/mschap'
echo --------------------------------------------------

sed -i "s|/path/to/ntlm_auth|/usr/bin/ntlm_auth|g" /etc/freeradius/mods-available/mschap
sed -i '/ntlm_auth\ \=\ /s/^#//g' /etc/freeradius/mods-available/mschap
# enable password change requests
sed -i '/ntlm_auth_/s/^#//g' /etc/freeradius/mods-available/mschap

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
unset EDUROAM_SECRET

/docker-entrypoint.sh "$@"
