# Terraform Supabase

This repo includes an example of starting a local copy of the Supabase stack via Terraform

### Very important notice

This repo is still a work in progress - it should **NOT** be used for production deployments at this time. For example, the Terraform configuration currently created will destroy all volumes when `destroy` is called. You **WILL** lose all data.

Known issues such as this will be resolved in due course.

### Instructions

1. Install the Terraform CLI - instructions at https://www.terraform.io/downloads
2. Open up `dotenv.tf.example` file (in this repo) in your code editor
3. Inside, you will find all the variables that are used to setup the Supabase stack
4. You should ensure that you change any which are marked as sensitive
5. Once you have made your changes, save the file, and then rename it to `dotenv.tf`
   a. You can rename it to any filename as long as the file extension it `.tf`, but `dotenv.tf` is already included in `.gitignore` so you won't accidentally commit it
6. Run `terraform init` from the root of this repo
7. Run `terraform apply` and type `yes` when prompted

To stop the stack, type `terraform destroy` and type `yes` when prompted.

If there are any errors, please, please, **please** read what the terminal outputs as it will often tell you how to resolve the issue.

If you're still having trouble, you can remove the Terraform dependencies and packages by removing the following from your copy of this repo:

- `.terraform/` folder
- `terraform.tfstate` file
- `terraform.tfstate.backup` file
- `terraform.lock.hcl` file

### Additional information

This repo allows you to customise the `postgresql.conf` file before deployment. The default config provided within the Supabase docker image (as of 28th February 2022) is included at `./volumes/db/config/postgresql.conf`. The default config should be sufficient, but feel free to adjust this according to your requirements.

Also included is the `kong.yml` config file used by Kong - available at `./volumes/api/kong.tpl`. This is a Terraform template file, meaning that it includes some template variables which are replaced during deployment:

- `${META_URL}` - The URL which docker containers can access the `pg-meta` container at
- `${META_PORT}` - The port which the `pg-meta` container is running on
- `${ANON_KEY}` - The Supabase anon key
- `${SECRET_KEY}` - The supabase service role key

These variables are passed into the template from `docker.containers.tf` and should not be modified. If you want to change any of these value, change them in the `dotenv.tf` file (see instructions section above for details).

The reason for using a template file is that it allows us to keep the environmental variables secret, while also avoiding the need to change them in more than one place. With the normal docker-compose deployment, you have to change some env variables in `kong.yml` as well as in the `.env` file.

With that said, feel free to make adjustments to this file if necessary.
