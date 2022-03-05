module "WithDeployment" {
  source = "./deploy"
}


module "WithSupabase" {
  source = "./supabase"
  depends_on = [
    module.WithDeployment
  ]
}

module "WithPlugins" {
  source = "./plugins"
  depends_on = [
    module.WithSupabase
  ]
}

