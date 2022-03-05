# Variable passed in from a parent - do not delete or change
variable "DEPLOYMENT_PROVIDER" {}
variable "ENABLE_REMOTE_DEPLOYMENT" {}

resource "digitalocean_droplet" "SUPABASE_DOCKER_DIGITALOCEAN_DROPLET" {
  image         = "docker-20-04"
  region        = var.DEPLOYMENT_REGION
  size          = var.VPC_SIZE
  backups       = var.VPC_ENABLE_BACKUPS
  name          = "${var.DEPLOYMENT_REGION}-${var.VPC_SIZE}-supabase-docker-${random_password.DEPLOYMENT_VPC_NAME_SUFFIX.result}"
  resize_disk   = var.VPC_RESIZE_DISK
  droplet_agent = true
  monitoring    = true
  count         = var.DEPLOYMENT_PROVIDER == "digitalocean" && var.ENABLE_REMOTE_DEPLOYMENT ? 1 : 0
  ssh_keys      = var.DIGITAL_OCEAN_DROPLET_SSH_TOKEN_ID_LIST
  connection {
    host        = self.ipv4_address
    user        = "root"
    type        = "ssh"
    private_key = file(var.SSH_PRIVATE_KEY_FILE_LOCATION)
    timeout     = "2m"
  }
}

# DO NOT CHANGE ANYTHING ABOVE THIS LINE

variable "DEPLOYMENT_REGION" {
  type        = string
  default     = "lon1"
  description = "The slug of region to deploy to (Details: https://docs.digitalocean.com/products/platform/availability-matrix/)"
}

variable "VPC_SIZE" {
  type        = string
  default     = "s-2vcpu-4gb"
  description = "The slug that represents the desired size of the VPC (Details: https://slugs.do-api.dev/)"
}

variable "VPC_ENABLE_BACKUPS" {
  type        = bool
  default     = true
  description = "Set this to true if you wish to enable backups for the VPC"
}

variable "VPC_RESIZE_DISK" {
  type        = bool
  default     = true
  description = "Set this to true if you wish to resize the VPC disk when resizing the VPC. If true, you will not be able to make the VPC smaller. If set to false, you will be able to keep the same disk size while adjusting CPU and RAM (this is reversible)"
}
