# FreeRADIUS w/ NTLM in Docker

_I want to be the first to say, yes, this is weird. This container binds itself to your AD domain with winbind. It's as peculiar for me to say as you to think. But it works, and it works quite swell._

This project provides the source for a FreeRADIUS container to bind to your domain.

### Quick Note

Everytime you restart this container, it will rebind to the domain. If you are deleting and re-creating this container frequently without setting a default hostname, you will notice a new computer account being created everytime. Use the `--hostname` flag to set a default hostname.

## Configuration

### Required ENV Vars

The following are required in order for the container to properly function.

| Env Var | Description |
| ------- | ----------- |
| FR_ACCESS_ALLOWED_CIDR | The allowed subnet for your default client |
| FR_SHARED_SECRET | Default client's secret |
| FR_DOMAIN | Your local realm |
| AD_DOMAIN | Your active directory domain |
| AD_WORKGROUP | Your active directory netbios name |
| AD_SERVER | The default AD server to talk to |
| AD_USERNAME | Username for a user with permission to create new computer objects in AD |
| AD_PASSWORD | Password for a user with permission to create new computer objects in AD |
| EDUROAM_AUTHHOST | Authorization domain / IP for the eduroam / default realm |
| EDUROAM_ACCTHOST | Accounting domain / IP for the eduroam / default realm |
| EDUROAM_SECRET | Secret for the eduroam realm |
| EDUROAM_CLIENT_SERVER | Domain / IP for the eduroam client | 
| EDUROAM_CLIENT_SECRET | Secret for eduroam client |

#### Optional ENV Vars

| Env Var | Description |
| ------- | ----------- |
| DEBUG | When set, debug output for the script will be enabled. _NOTE_: This will send your AD_PASSWORD to STDOUT |

### Certificates



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

## Based off the following projects:

* [Docker-Samba-Join-AD](https://github.com/fjudith/docker-samba-join-ad/)
* [FreeRADIUS AD Setup](https://xenomorph.net/linux/ubuntu/misc/radius-unifi/)
