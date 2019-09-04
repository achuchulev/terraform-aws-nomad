#!/usr/bin/env bash

# create dir for nomad configuration
mkdir -p /etc/nomad.d
chmod 700 /etc/nomad.d

# download and run nomad configuration script
curl -o /tmp/nomad-${instance_role}-config.sh https://raw.githubusercontent.com/achuchulev/terraform-aws-nomad/master/scripts/nomad-${instance_role}-config.sh
chmod +x /tmp/nomad-${instance_role}-config.sh
/tmp/nomad-${instance_role}-config.sh ${nomad_region} ${dc} ${authoritative_region} '${retry_join}' ${secure_gossip}
rm -rf /tmp/*

# create dir for certificates and download CA certificates and cfssl.json configuration file to increase the default certificate expiration time for nomad
mkdir -p /root/nomad/ssl
curl -o /root/nomad/ssl/cfssl.json https://raw.githubusercontent.com/achuchulev/terraform-aws-nomad/master/config/cfssl.json
curl -o /root/nomad/ssl/nomad-ca-key.pem https://raw.githubusercontent.com/achuchulev/terraform-aws-nomad/master/ca_certs/nomad-ca-key.pem
curl -o /root/nomad/ssl/nomad-ca.pem https://raw.githubusercontent.com/achuchulev/terraform-aws-nomad/master/ca_certs/nomad-ca.pem
 
# generate nomad node certificates
echo '{}' | cfssl gencert -ca=/root/nomad/ssl/nomad-ca.pem -ca-key=/root/nomad/ssl/nomad-ca-key.pem -config=/root/nomad/ssl/cfssl.json -hostname='${instance_role}.${nomad_region}.nomad,localhost,127.0.0.1' - | cfssljson -bare /root/nomad/ssl/${instance_role}
echo '{}' | cfssl gencert -ca=/root/nomad/ssl/nomad-ca.pem -ca-key=/root/nomad/ssl/nomad-ca-key.pem -profile=client - | cfssljson -bare /root/nomad/ssl/cli

# copy nomad.service
curl -o /etc/systemd/system/nomad.service https://raw.githubusercontent.com/achuchulev/terraform-aws-nomad/master/config/nomad.service

# enable and start nomad service
systemctl enable nomad.service
systemctl start nomad.service

# Enable Nomad's CLI command autocomplete support. Skip if installed
grep "complete -C /usr/bin/nomad nomad" ~/.bashrc &>/dev/null || nomad -autocomplete-install

# export the URL of the Nomad agent
echo 'export NOMAD_ADDR=https://${domain_name}.${zone_name}' >> ~/.profile