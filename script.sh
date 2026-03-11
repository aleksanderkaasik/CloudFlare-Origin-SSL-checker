cloudflareApiToken=""

zoneId=""
domain=""
subDomains=("" "" "") # Array of strings

echo "--- [ Deleting unused certs ] ---"
PrivateKeysList=$(ls /etc/ssl/private | grep -E '^[^.]+\.[^.]+\.[^.]+.*\.key$' | sed "s/.key//" )
CsrKeysList=$(ls /etc/ssl/csr | grep -E '^[^.]+\.[^.]+\.[^.]+.*\.csr$' | sed "s/.csr//" )
PublicKeysList=$(ls /etc/ssl/certs | grep -E '^[^.]+\.[^.]+\.[^.]+.*\.pem$' | sed "s/.pem//" )

ListDomain=$(printf "%s\n" ${PublicKeysList[@]} ${CsrKeysList[@]} ${PrivateKeysList[@]} | sort -u)
validDomains=$(printf "%s.$domain\n" ${subDomains[@]})

for host in ${ListDomain[@]}; do
    echo "( $host )"
    if [[ ${validDomains[@]} =~ ${host} ]]; then
        echo "skipping host"
        continue
    fi
    echo "Delete keys from local machine"
    
    rm -f "/etc/ssl/private/$host.key"
    rm -f "/etc/ssl/csr/$host.csr"
    rm -f "/etc/ssl/certs/$host.pem"

    echo "Done"
    Data=$(curl -s https://api.cloudflare.com/client/v4/certificates?zone_id=$zoneId \
        -H "Authorization: Bearer $cloudflareApiToken")

    ListId=$(echo $Data | jq -r ".result[] | select(.hostnames[] == \"$host\") | .id")
    echo "Delete keys from cloudflare"
    for id in ${ListId[@]}; do
        DATA=$(curl -s "https://api.cloudflare.com/client/v4/certificates/$id" \
        -X DELETE \
        -H "Authorization: Bearer $cloudflareApiToken")
    done
done
echo

echo "--- [ Creating certs ] ---"
for sub in ${subDomains[@]}; do
    echo "( $sub.$domain )"
    if [[ ! -f "/etc/ssl/private/$sub.$domain.key" ]]; then
        echo "Create private key"
        openssl genrsa -out "/etc/ssl/private/$sub.$domain.key" 4096
        chmod 640 "/etc/ssl/private/$sub.$domain.key"
        sudo chgrp ssl-cert "/etc/ssl/private/$sub.$domain.key"
        echo "Done"
    fi

    if [[ ! -f "/etc/ssl/csr/$sub.$domain.csr" ]]; then
        echo "Create csr key"
        openssl req -new -sha256 \
            -subj "/CN=$sub.$domain" \
            -key "/etc/ssl/private/$sub.$domain.key" \
            -out "/etc/ssl/csr/$sub.$domain.csr"
        chmod 644 "/etc/ssl/csr/$sub.$domain.csr"
        chgrp ssl-cert "/etc/ssl/csr/$sub.$domain.csr"
        echo "Done"
    fi

    if [[ ! -f "/etc/ssl/certs/$sub.$domain.pem" ]]; then
        echo "Create public key"
        csr=$(awk '{printf "%s\\n", $0}' "/etc/ssl/csr//$sub.$domain.csr")
        curl -s "https://api.cloudflare.com/client/v4/certificates?zone_id=$zoneId" \
            -X POST \
            -H 'Content-Type: application/json' \
            -H "Authorization: Bearer $cloudflareApiToken" \
            -d "{
                \"csr\": \"$csr\",
                \"hostnames\": [\"$sub.$domain\"],
                \"request_type\": \"origin-rsa\",
                \"requested_validity\": 90
            }" | jq -r '.result.certificate' > /etc/ssl/certs/$sub.$domain.pem
        echo "Done"
    fi
done
