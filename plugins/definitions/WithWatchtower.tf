resource "docker_image" "watchtower" {
  name         = "containrrr/watchtower:latest"
  keep_locally = true
  count        = var.USE_WATCHTOWER ? 1 : 0
}

resource "docker_container" "watchtower" {
  count = var.USE_WATCHTOWER ? 1 : 0
  image = "containrrr/watchtower:latest"
  name  = "watchtower"
  ports {
    internal = 8080
    external = 8091
  }
}
