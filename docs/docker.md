# Docker Setup

When using Docker, I recommend you using a modified docker-compose file. These instructions will include that. Also, these instructions are for running Docker on a Linux host - if you are wanting to use Windows / MacOS, this should still be a helpful starting off point.

### Quick Note

Everytime you restart this container, it will rebind to the domain. If you are deleting and re-creating this container frequently without setting a default hostname, you will notice a new computer account being created everytime. Use the `--hostname` flag to set a default hostname.

## Docker Installation

While the installation of Docker on your server is outside the scope of this documentation, I would highly recommend you follow the information here: https://docs.docker.com/get-docker/

As for the installation of docker-compose, you can look here: https://docs.docker.com/compose/install/

## Using this Container

For the basic configuration (joining to AD), you will need the first 5 of these env variables. The rest of the parameters are optional - if you choose to provide your own configuration files, these will be unnecessary. However, if you choose to use the existing configs, these values will help setup a basic config.

| Env Var                | Required (Y/N) | Default / Example             | Description |
| ---------------------- | -------------- | ----------------------------- | ----------- |
| AD_DOMAIN              | Y              | Example: `ad.example.com`     | Your active directory domain |
| AD_WORKGROUP           | Y              | Example: `example`            | Your active directory netbios name |
| AD_SERVER              | Y              | Example: `ad1.ad.example.com` | The default AD server to talk to |
| AD_USERNAME            | Y              | Example: `test`               | Username for a user with permission to create new computer objects in AD - **DO NOT USE A DOMAIN ADMIN ACCOUNT** |
| AD_PASSWORD            | Y              | Example: `password`           | Password for a user with permission to create new computer objects in AD - **DO NOT USE A DOMAIN ADMIN ACCOUNT** |
| FR_CLIENT_NAME         | N              | Example: `wireless`           | Optionally change the shortname of a client. No spaces allowed. |
| FR_ACCESS_ALLOWED_CIDR | N              | Example: `192.168.0.1/24`     | The allowed subnet for your default client |
| FR_SHARED_SECRET       | N              | Example: `randomsecret`       | Default client's secret |
| FR_DOMAIN              | N              | Example: `example.com`        | Your local realm - this is used in `proxy.conf` file |
| ENABLE_EDUROAM         | N              | Default: `FALSE` Ex: `TRUE`   | When set to `TRUE`, it enabled the DEFAULT realm pointing to the EDUROAM FLRs defined below |
| EDUROAM_FLR1_IPADDR    | N              | Example: `tlrs1.example.net`  | IP / hostname for the eduroam default realm. Required if `ENABLE_EDUROAM` is set to true |
| EDUROAM_FLR2_IPADDR    | N              | Example: `tlrs2.example.net`  | Second IP / hostname for the eduroam default realm |
| EDUROAM_FLR1_SECRET    | N              | Example: `randomsecret`       | Secret for the eduroam realm. Required if `ENABLE_EDUROAM` is set to true |
| EDUROAM_FLR2_SECRET    | N              | Example: `randomsecret`       | Secret for the eduroam realm. Required if `EDUROAM_FLR2_IPADDR` is set |
| EDUROAM_CLIENT1_SERVER | N              | Example: `tlrs1.example.net`  | Domain / IP for the eduroam client | 
| EDUROAM_CLIENT1_SECRET | N              | Example: `randomsecret`       | Secret for eduroam client |
| EDUROAM_CLIENT2_SERVER | N              | Example: `tlrs2.example.net`  | Domain / IP for the eduroam client | 
| EDUROAM_CLIENT2_SECRET | N              | Example: `randomsecret`       | Secret for eduroam client |
| DEBUG                  | N              | Example: `1`                  | When set to anything, debug output for the script will be enabled. _NOTE_: This will send your AD_PASSWORD to STDOUT |

### Mounting Config Files / Extending Container Functionality

This project was designed to solve a singlular use case of allowing NTLM over MSCHAPv2 for local auth, and then forwarding all additional auth onto another server. However, there are many, many more advanced use cases for a FreeRADIUS install. This container was designed in a way to ensure you can still make those changes without affecting the default functionality.

#### Example: VLANs for Local vs eduroam Realm

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

### Certificates

Certificates are easy - do a bind volume mount at `/certs`. Inside this directory, you will need two files: `ca.pem` and `server.pem`. `ca.pem` should ONLY include your Certificate Authority, while `server.pem` should include BOTH your private and public certs. 

## Testing

To test the container functionality when using docker:

```bash
docker exec -it <container_id> radtest -t mschap username@example.com password 127.0.0.1 0 testing123
```
