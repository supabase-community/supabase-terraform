resource "time_sleep" "sleep_10" {
  depends_on = [docker_container.supabase-postgres]

  create_duration = "10s"
}

resource "null_resource" "db_setup_00" {
  provisioner "local-exec" {
    command = "docker exec -e PGPASSWORD=${var.POSTGRES_PASSWORD} -i ${var.POSTGRES_HOST} psql -h ${var.POSTGRES_HOST} -p ${var.POSTGRES_PORT} -U ${var.POSTGRES_USER} -d ${var.POSTGRES_DB} -f \"/home/init/00-initial-schema.sql\""
  }
  depends_on = [
    docker_container.supabase-postgres,
    time_sleep.sleep_10
  ]
  # depends_on = ["postgresql_role.readwrite_role", "postgresql_role.readonly_role"]
}

resource "null_resource" "db_setup_01" {
  provisioner "local-exec" {
    command = "docker exec -e PGPASSWORD=${var.POSTGRES_PASSWORD} -i ${var.POSTGRES_HOST} psql -h ${var.POSTGRES_HOST} -p ${var.POSTGRES_PORT} -U ${var.POSTGRES_USER} -d ${var.POSTGRES_DB} -f \"/home/init/01-auth-schema.sql\""
    # command = "docker exec -i ${var.POSTGRES_HOST} /bin/bash -c EXPORT PGPASSWORD=${var.POSTGRES_PASSWORD} && psql -h ${var.POSTGRES_HOST} -p ${var.POSTGRES_PORT} -U ${var.POSTGRES_USER} -d ${var.POSTGRES_DB} -f \"/home/init/01-auth-schema.sql\""
  }
  depends_on = [
    docker_container.supabase-postgres,
    null_resource.db_setup_00,
    time_sleep.sleep_10
  ]
  # depends_on = ["postgresql_role.readwrite_role", "postgresql_role.readonly_role"]
}

resource "null_resource" "db_setup_02" {
  provisioner "local-exec" {
    command = "docker exec -e PGPASSWORD=${var.POSTGRES_PASSWORD} -i ${var.POSTGRES_HOST} psql -h ${var.POSTGRES_HOST} -p ${var.POSTGRES_PORT} -U ${var.POSTGRES_USER} -d ${var.POSTGRES_DB} -f \"/home/init/02-storage-schema.sql\""
    # command = "docker exec -i ${var.POSTGRES_HOST} /bin/bash -c EXPORT PGPASSWORD=${var.POSTGRES_PASSWORD} && psql -h ${var.POSTGRES_HOST} -p ${var.POSTGRES_PORT} -U ${var.POSTGRES_USER} -d ${var.POSTGRES_DB} -f \"/home/init/02-storage-schema.sql\""
  }
  depends_on = [
    docker_container.supabase-postgres,
    null_resource.db_setup_01,
    time_sleep.sleep_10
  ]
  # depends_on = ["postgresql_role.readwrite_role", "postgresql_role.readonly_role"]
}

resource "null_resource" "db_setup_03" {
  provisioner "local-exec" {
    command = "docker exec -e PGPASSWORD=${var.POSTGRES_PASSWORD} -i ${var.POSTGRES_HOST} psql -h ${var.POSTGRES_HOST} -p ${var.POSTGRES_PORT} -U ${var.POSTGRES_USER} -d ${var.POSTGRES_DB} -f \"/home/init/03-post-setup.sql\""
    # command = "docker exec -i ${var.POSTGRES_HOST} /bin/bash -c EXPORT PGPASSWORD=${var.POSTGRES_PASSWORD} && psql -h ${var.POSTGRES_HOST} -p ${var.POSTGRES_PORT} -U ${var.POSTGRES_USER} -d ${var.POSTGRES_DB} -f \"/home/init/03-post-setup.sql\""
  }
  depends_on = [
    docker_container.supabase-postgres,
    null_resource.db_setup_02,
    time_sleep.sleep_10
  ]
  # depends_on = ["postgresql_role.readwrite_role", "postgresql_role.readonly_role"]
}
