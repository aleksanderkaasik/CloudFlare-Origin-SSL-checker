# Reverse Proxy, SSL management with cloudflare origin SSL

## Prerequisites
The script was made for Ubuntu server. And still in a working progress

Before running the script, you will need to

* Get CloudFlare API token with these permissions.
    * `Zone.SSL and Certificates.Edit`
    * `Zone.SSL and Certificates.Read`

* Have a domain
    * After adding it to cloudflare, and copy `zone id`


* Install needed packages to run
    ``` bash
    sudo apt install -y jq
    ```

* Creating necessary directories
    ``` bash
    sudo mkdir -p /etc/ssl/private /etc/ssl/csr /etc/ssl/certs
    ```
* Use a user with sudo privileges

## To run

After getting all prerequisites, you should open the `script.sh` add them the script.

```
sudo bash script.sh
```