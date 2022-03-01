
resource "docker_image" "watchtower" {
  name         = "containrrr/watchtower:latest"
  keep_locally = true
}

resource "docker_image" "portainer" {
  name         = "cr.portainer.io/portainer/portainer-ce:latest"
  keep_locally = true
}

resource "docker_image" "supabase-postgres" {
  name         = "supabase/postgres:14.1.0"
  keep_locally = true
}

resource "docker_image" "supabase-studio" {
  name         = "supabase/studio:latest"
  keep_locally = true
}

resource "docker_image" "supabase-kong" {
  name         = "kong:2.1"
  keep_locally = true
}

resource "docker_image" "pg-meta" {
  name         = "supabase/postgres-meta:v0.29.0"
  keep_locally = true
}

resource "docker_image" "supabase-realtime" {
  name         = "supabase/realtime:v0.19.3"
  keep_locally = true
}

resource "docker_image" "supabase-rest" {
  name         = "postgrest/postgrest:v9.0.0"
  keep_locally = true
}

resource "docker_image" "supabase-auth" {
  name         = "supabase/gotrue:v2.2.12"
  keep_locally = true
}

# TODO: Add storage image
# resource "docker_image" "" {}
