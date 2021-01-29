# Docker Setup

When using Docker, I recommend you using a modified docker-compose file. These instructions will include that. Also, these instructions are for running Docker on a Linux host - if you are wanting to use Windows / MacOS, this should still be a helpful starting off point.

### Quick Note

Everytime you restart this container, it will rebind to the domain. If you are deleting and re-creating this container frequently without setting a default hostname, you will notice a new computer account being created everytime. Use the `--hostname` flag to set a default hostname.

## Docker Installation

While the installation of Docker on your server is outside the scope of this documentation, I would highly recommend you follow the information here: https://docs.docker.com/get-docker/

As for the installation of docker-compose, you can look here: https://docs.docker.com/compose/install/

## Using this Container

To configure this container, you will need to use environment variables. The following are options are available for the container:

| Env Var                | Required (Y/N) | Default / Example             | Description |
| ---------------------- | -------------- | ----------------------------- | ----------- |
| FR_ACCESS_ALLOWED_CIDR | Y              | Example: `192.168.0.1/24`     | The allowed subnet for your default client |
| FR_SHARED_SECRET       | Y              | Example: `randomsecret`       | Default client's secret |
| FR_DOMAIN              | Y              | Example: `example.com`        | Your local realm - this is used in `proxy.conf` file |
| AD_DOMAIN              | Y              | Example: `ad.example.com`     | Your active directory domain |
| AD_WORKGROUP           | Y              | Example: `example`            | Your active directory netbios name |
| AD_SERVER              | Y              | Example: `ad1.ad.example.com` | The default AD server to talk to |
| AD_USERNAME            | Y              | Example: `test`               | Username for a user with permission to create new computer objects in AD - **DO NOT USE A DOMAIN ADMIN ACCOUNT** |
| AD_PASSWORD            | Y              | Example: `password`           | Password for a user with permission to create new computer objects in AD - **DO NOT USE A DOMAIN ADMIN ACCOUNT** |
| EDUROAM_AUTHHOST       | Y              | Example: `tlrs1.example.net`  | Authorization domain / IP for the eduroam / default realm |
| EDUROAM_ACCTHOST       | Y              | Example: `tlrs1.example.net`  | Accounting domain / IP for the eduroam / default realm |
| EDUROAM_SECRET         | Y              | Example: `randomsecret`       | Secret for the eduroam realm |
| EDUROAM_CLIENT_SERVER  | Y              | Example: `tlrs1.example.net`  | Domain / IP for the eduroam client | 
| EDUROAM_CLIENT_SECRET  | Y              | Example: `randomsecret`       | Secret for eduroam client |

#### Optional ENV Vars

| Env Var | Description |
| ------- | ----------- |
| DEBUG | When set, debug output for the script will be enabled. _NOTE_: This will send your AD_PASSWORD to STDOUT |

### Certificates

Certificates are easy - do a bind volume mount at `/certs`. Inside this directory, you will need two files: `ca.pem` and `server.pem`. `ca.pem` should ONLY include your Certificate Authority, while `server.pem` should include BOTH your private and public certs. 

## Testing

To test the container functionality when using docker:

```bash
docker exec -it <container_id> radtest -t mschap username@example.com password 127.0.0.1 0 testing123
```

## Extending the Container

This project was designed to solve a singlular use case of allowing NTLM over MSCHAPv2 for local auth, and then forwarding all additional auth onto another server. However, there are many, many more advanced use cases for a FreeRADIUS install. This container was designed in a way to ensure you can still make those changes without affecting the default functionality.

### Example: VLANs for Local vs eduroam Realm

Probably the most common scenario it to use a different VLAN if you are authenticated to the local realm vs the eduroam realm. This is provided with the following block of code in the post-auth under `sites-enabled/default`:

```
post-auth {
    # eduroam VLAN config
    update reply {
        Tunnel-Type := VLAN
        Tunnel-Medium-Type := IEEE-802
    }
    if (&control:Proxy-To-Realm) {
        update reply {
            # eduroam realm default vlan
            Tunnel-Private-Group-ID = 4
        }
    }
    else {
        update reply {
            # local users vlan
            Tunnel-Private-Group-ID = 7
        }
    }
...
```

A full file is shown at `extension-examples/eduroam-vlans/default`. To use this config, the following will work:

```bash
docker run -v ${pwd}/extension-examples/eduroam-vlans/default:/etc/freeradius/sites-enabled/default --env-file=example.env -p 1812:1812/udp -p 1813:1813/udp esutwo/freeradius-ntlm:3.0.19-0
```

## You don't have an option for setting X - how do I enable it?

Easy! Just swap out the config file with the additional settings you want. I am not overwriting the existing configs - I provided some new default configs with the lines I need uncommented, and adding some defaults I am going to replace with `sed`. Just make a copy of the file you want with your changes and rebuild the container, or pass it through as a volume mount or ConfigMount. See the above about LDAP authorization for an example.