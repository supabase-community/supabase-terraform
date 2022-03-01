# # Uncomment these if you want to add Portainer to your installation
# # This is recommended as it makes managing the containers significantly easier, but is entirely optional
# resource "docker_container" "portainer" {
#   image = "cr.portainer.io/portainer/portainer-ce:latest"
#   name  = "portainer"
#   ports {
#     internal = 8000
#     external = 44997
#   }
#   ports {
#     internal = 9000
#     external = 9000
#   }
# }

# # Uncomment these if you want to add Watchtower to your installation
# # This is useful if you're also deploying other containers to the same host and want to automatically update them as new images are released
# resource "docker_container" "watchtower" {
#   image = "containrrr/watchtower:latest"
#   name  = "watchtower"
#   ports {
#     internal = 8080
#     external = 8091
#   }
# }

resource "docker_volume" "pg_data" {
  name = "pg_data"
}

resource "docker_volume" "pg_init" {
  name = "pg_init"
}

resource "docker_volume" "pg_config" {
  name = "pg_config"
}

resource "docker_volume" "kong_data" {
  name = "kong_data"
}

resource "docker_network" "supabase-network" {
  name = "supabase-network"
}

resource "docker_container" "supabase-postgres" {
  image = "supabase/postgres:14.1.0"
  name  = var.POSTGRES_HOST
  ports {
    internal = var.POSTGRES_PORT
    external = var.POSTGRES_PORT
  }
  networks_advanced {
    name    = "supabase-network"
    aliases = ["supabase-db"]
  }
  env = [
    "POSTGRES_PASSWORD=${var.POSTGRES_PASSWORD}",
    "PGDATA=/var/lib/postgresql/data"
  ]
  command = ["postgres", "-c", "config-file=/etc/postgresql/postgresql.conf"]
  restart = "unless-stopped"

  mounts {
    source = docker_volume.pg_data.name
    target = "/var/lib/postgresql/data"
    type   = "volume"
  }

  # remove_volumes = false

  mounts {
    source = docker_volume.pg_config.name
    target = "/etc/postgresql"
    type   = "volume"
  }

  # The file located at volumes/db/config/postgresql.conf will be uploaded into the 'pg_config' volume
  # You can customise this file and then run 'terraform apply' to apply the updated config
  upload {
    source = "${path.root}/volumes/db/config/postgresql.conf"
    file   = "/etc/postgresql/postgresql.conf"
  }

  # Create a place to upload our initialisation scripts
  # These will be run after the container is started
  mounts {
    source = docker_volume.pg_init.name
    target = "/home/init"
    type   = "volume"
  }

  # Upload our init scripts
  upload {
    content = file("${path.root}/volumes/db/init/sql/00-initial-schema.sql")
    file    = "/home/init/00-initial-schema.sql"
  }

  upload {
    content = file("${path.root}/volumes/db/init/sql/01-auth-schema.sql")
    file    = "/home/init/01-auth-schema.sql"
  }

  upload {
    content = file("${path.root}/volumes/db/init/sql/02-storage-schema.sql")
    file    = "/home/init/02-storage-schema.sql"
  }

  upload {
    content = file("${path.root}/volumes/db/init/sql/03-post-setup.sql")
    file    = "/home/init/03-post-setup.sql"
  }
}

resource "docker_container" "supabase-studio" {
  image = "supabase/studio:latest"
  name  = "supabase-studio"
  depends_on = [
    docker_container.supabase-postgres
  ]
  ports {
    internal = 3000
    external = 2500
  }
  networks_advanced {
    name    = "supabase-network"
    aliases = ["supabase-studio"]
  }
  env = [
    "SUPABASE_URL=http://${var.KONG_URL}:${var.KONG_HTTP_PORT}",
    "STUDIO_PG_META_URL=http://${var.META_URL}:${var.META_PORT}",
  ]
}

resource "docker_container" "supabase-kong" {
  image = "kong:2.1"
  name  = "supabase-kong"

  networks_advanced {
    name    = "supabase-network"
    aliases = ["supabase-kong"]
  }
  ports {
    internal = 8000
    external = 8000
  }
  ports {
    internal = 8443
    external = 8443
  }
  restart = "unless-stopped"
  env = [
    "KONG_DATABASE=off",
    "KONG_DECLARATIVE_CONFIG=/var/lib/kong/kong.yml",
    "KONG_DNS_ORDER=LAST,A,CNAME",
    "KONG_PLUGINS=request-transformer,cors,key-auth,acl"
  ]

  upload {
    content = templatefile(abspath("${path.root}/volumes/api/kong.tpl"), {
      ANON_KEY   = var.ANON_KEY,
      SECRET_KEY = var.SERVICE_ROLE_KEY,
      META_URL   = var.META_URL,
      META_PORT  = var.META_PORT,
    })
    file = "/var/lib/kong/kong.yml"
  }

  mounts {
    source = docker_volume.kong_data.name
    target = "/var/lib/kong"
    type   = "volume"
  }
}

resource "docker_container" "pg-meta" {
  image = "supabase/postgres-meta:v0.29.0"
  name  = "pg-meta"
  depends_on = [
    docker_container.supabase-postgres
  ]
  ports {
    internal = 8080
    external = 8080
  }
  networks_advanced {
    name    = "supabase-network"
    aliases = ["supabase-meta"]
  }
  env = [
    "PG_META_PORT=${var.META_PORT}",
    "PG_META_DB_HOST=${var.POSTGRES_HOST}",
    "PG_META_DB_PASSWORD=${var.POSTGRES_PASSWORD}",
  ]
  # entrypoint = ["postgres-meta"]
}

resource "docker_container" "supabase-realtime" {
  image = "supabase/realtime:v0.19.3"
  name  = "supabase-realtime"
  depends_on = [
    docker_container.supabase-postgres
  ]
  ports {
    internal = 4000
    external = 4000
  }
  networks_advanced {
    name    = "supabase-network"
    aliases = ["supabase-realtime"]
  }
  env = [
    "DB_HOST=${var.POSTGRES_HOST}",
    "DB_PORT=${var.POSTGRES_PORT}",
    "DB_USER=${var.POSTGRES_USER}",
    "DB_PASS=${var.POSTGRES_PASSWORD}",
    "DB_SSL=false",
    "PORT=4000",
    "JWT_SECRET=${var.JWT_SECRET}",
    "REPLICATION_MODE=RLS",
    "REPLICATION_POLL_INTERVAL=100",
    "SECURE_CHANNELS=true",
    "SLOT_NAME=supabase_realtime_rls",
    "TEMPORARY_SLOT=true"
  ]
  # command = [
  #   "> bash -c './prod/rel/realtime/bin/realtime eval Realtime.Release.migrate && ./prod/rel/realtime/bin/realtime start'"
  # ]
}

resource "docker_container" "supabase-auth" {
  image = "supabase/gotrue:v2.2.12"
  name  = "supabase-auth"
  depends_on = [
    docker_container.supabase-postgres,
    null_resource.db_setup_03
  ]
  restart = "unless-stopped"
  ports {
    internal = 9999
    external = 9999
  }
  networks_advanced {
    name    = "supabase-network"
    aliases = ["supabase-auth"]
  }
  env = [
    "GOTRUE_API_HOST=0.0.0.0",
    "GOTRUE_API_PORT=9999",
    "GOTRUE_DB_DRIVER=postgres",
    "GOTRUE_DB_DATABASE_URL=postgres://${var.POSTGRES_USER}:${var.POSTGRES_PASSWORD}@${var.POSTGRES_HOST}:${var.POSTGRES_PORT}/${var.POSTGRES_DB}?search_path=auth",
    "GOTRUE_SITE_URL=${var.SITE_URL}",
    "GOTRUE_URI_ALLOW_LIST=${var.ADDITIONAL_REDIRECT_URLS}",
    "GOTRUE_DISABLE_SIGNUP=${var.DISABLE_SIGNUP}",
    "GOTRUE_JWT_SECRET=${var.JWT_SECRET}",
    "GOTRUE_JWT_EXPIRY=${var.JWT_EXPIRY}",
    "GOTRUE_JWT_DEFAULT_GROUP_NAME=authenticated",
    "GOTRUE_EXTERNAL_EMAIL_ENABLED=${var.ENABLE_EMAIL_SIGNUP}",
    "GOTRUE_MAILER_AUTOCONFIRM=${var.ENABLE_EMAIL_AUTOCONFIRM}",
    "API_EXTERNAL_URL=${var.API_EXTERNAL_URL}",
    "GOTRUE_MAILER_TEMPLATES_INVITE=${var.EMAIL_INVITE_TEMPLATE_URL}",
    "GOTRUE_MAILER_TEMPLATES_CONFIRMATION=${var.EMAIL_CONFIRMATION_TEMPLATE_URL}",
    "GOTRUE_MAILER_TEMPLATES_RECOVERY=${var.EMAIL_RECOVERY_TEMPLATE_URL}",
    "GOTRUE_MAILER_TEMPLATES_MAGIC_LINK=${var.EMAIL_MAGICLINK_TEMPLATE_URL}",
    "GOTRUE_SMTP_HOST=${var.SMTP_HOST}",
    "GOTRUE_SMTP_PORT=${var.SMTP_PORT}",
    "GOTRUE_SMTP_USER=${var.SMTP_USER}",
    "GOTRUE_SMTP_PASSWORD=${var.SMTP_PASS}",
    "GOTRUE_SMTP_ADMIN_EMAIL=${var.SMTP_ADMIN_EMAIL}",
    "GOTRUE_MAILER_URLPATHS_INVITE=/auth/v1/verify",
    "GOTRUE_MAILER_URLPATHS_CONFIRMATION=/auth/v1/verify",
    "GOTRUE_MAILER_URLPATHS_RECOVERY=/auth/v1/verify",
    "GOTRUE_MAILER_URLPATHS_EMAIL_CHANGE=/auth/v1/verify",
    "GOTRUE_EXTERNAL_PHONE_ENABLED=${var.ENABLE_PHONE_SIGNUP}",
    "GOTRUE_SMS_AUTOCONFIRM=${var.ENABLE_PHONE_AUTOCONFIRM}",
  ]

  command = ["gotrue"]
}

resource "docker_container" "supabase-rest" {
  image = "postgrest/postgrest:v9.0.0"
  name  = "supabase-rest"
  depends_on = [
    docker_container.supabase-postgres
  ]
  ports {
    internal = 3000
    external = 3000
  }
  networks_advanced {
    name    = "supabase-network"
    aliases = ["supabase-rest"]
  }
  env = [
    "PGRST_DB_URI=postgres://${var.POSTGRES_USER}:${var.POSTGRES_PASSWORD}@${var.POSTGRES_HOST}:${var.POSTGRES_PORT}/${var.POSTGRES_DB}",
    "PGRST_DB_SCHEMAS=public,storage",
    "PGRST_DB_ANON_ROLE=anon",
    "PGRST_JWT_SECRET=${var.JWT_SECRET}",
    "PGRST_DB_USE_LEGACY_GUCS=false"
  ]
  command = ["/bin/postgrest"]
  restart = "unless-stopped"
}
