resource "docker_image" "portainer" {
  name         = "cr.portainer.io/portainer/portainer-ce:latest"
  keep_locally = true
  count        = var.USE_PORTAINER ? 1 : 0
}

resource "docker_container" "portainer" {
  image = "cr.portainer.io/portainer/portainer-ce:latest"
  name  = "portainer"
  count = var.USE_PORTAINER ? 1 : 0
  ports {
    internal = 8000
    external = 44997
  }
  ports {
    internal = 9000
    external = 9000
  }
}
