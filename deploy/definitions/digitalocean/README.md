### Supabase Terraform - DigitalOcean Provider

This module is for deploying the Supabase terraform to DigitalOcean.

#### First steps

- Create a DigitalOcean API token
- Create an SSH Token

Please login to your DigitalOcean dashboard or refer to their docs for the most up-to-date information.

#### Configuring secrets

The first thing to do is rename the `./deploy/definitions/digitalocean/dotenv.tf.example` to `./deploy/definitions/digitalocean/dotenv.tf`.

Then, you should add your DigitalOcean API token to the `DIGITAL_OCEAN_DOTOKEN` variable in this file.

While it is possible to let DigitalOcean generate a password for your VPC/Droplet, it is highly recommended that you use SSH.

You should then add your SSH key ID to the `DIGITAL_OCEAN_DROPLET_SSH_TOKEN_ID_LIST` variable in this file. For details on how to retrieve your key: https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/droplet#ssh_keys

For reference, as of writing, this can be achieved with the following CURL request:

```curl
curl -X GET \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
  "https://api.digitalocean.com/v2/account/keys"
```

As long as you have at least 1 SSH key on your account, you will see an `ssh_keys` array, and each item will include an `id` property.

#### Configuring the provider

All non-sensitive variables for this provider are in `./deploy/definitions/digitalocean/digitalocean.tf`.

- `VPC_SIZE` - one of the droplet slugs at https://slugs.do-api.dev/
- `SSH_PRIVATE_KEY_FILE_LOCATION` - The absolute file path to your SSH private key. This is used so that we can connect to your droplet and deploy the stack.
- `DEPLOYMENT_REGION` - one of the region slugs at https://slugs.do-api.dev/
- `VPC_ENABLE_BACKUPS` - set to true if you want backups enabled (see DO documentation for details)
- `VPC_RESIZE_DISK` - Set to true if you want the disk to be resized in the event you change the size of your droplet via Terraform. If this is set to true, it will not be possible to shrink the droplet. If set to false, CPU and RAM will be resized, but the disk will not - it is possible to shrink droplets if this value is set to false.
