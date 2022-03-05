variable "DEPLOYMENT_PROVIDER" {
  description = "The deployment provider to use. Set to 'none' to not deploy remotely"
  type        = string
  default     = "digitalocean"
  validation {
    condition = contains(
      [
        "digitalocean",
        "aws",
        "azure",
        "googlecloud",
        "none"
      ],
      var.DEPLOYMENT_PROVIDER
    )
    error_message = "The value provided to DEPLOYMENT_PROVIDER was not valid."
  }
}

variable "ENABLE_REMOTE_DEPLOYMENT" {
  type        = bool
  default     = false
  description = "Enable remote deployment. If set to true, you MUST ensure you have configured the deployment provider correctly (see readme's in the /deploy folder and subfolders)"
}

module "DigitalOceanDeploy" {
  source                   = "./definitions/digitalocean"
  DEPLOYMENT_PROVIDER      = var.DEPLOYMENT_PROVIDER
  ENABLE_REMOTE_DEPLOYMENT = var.ENABLE_REMOTE_DEPLOYMENT
}
