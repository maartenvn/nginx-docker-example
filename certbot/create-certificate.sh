
#!/bin/bash

# Configuration
rsa_key_size=4096
data_path="./volumes/certbot/"

# Make sure that docker-compose is installed
if ! [ -x "$(command -v docker-compose)" ]; then
	echo "Error: docker-compose is not installed." >&2
	exit 1
fi

# Ask for the domains to register
echo "Enter domain to register: "
read domain_string
IFS="," read -r -a domain <<< $domain_string

# Ask for email address to register for
echo "Enter email address: "
read email

# If the data directory already exists, ask to continue (this will overwrite existing certs)
if [ -d "$data_path" ]; then
	read -p "Existing data found for Let's Encrypt. Continue and replace existing certificate, if present? (y/N) " decision
	if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
		exit
	fi
fi

echo "### Requesting Let's Encrypt certificate for $domain ..."
# Join $domain to -d args
domain_args="-d $domain"

# Select appropriate email arg
case "$email" in
	"") email_arg="--register-unsafely-without-email" ;;
	*) email_arg="--email $email" ;;
esac

# Enable staging mode if needed
if [ $staging != "0" ]; then staging_arg="--staging"; fi

sudo docker-compose run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
    $staging_arg \
    $email_arg \
    $domain_args \
    --rsa-key-size $rsa_key_size \
    --agree-tos \
    --force-renewal" certbot
echo

echo "### Reloading nginx ..."
sudo docker-compose exec nginx nginx -s reload