


terraform {
  required_version = ">= 1.0.7"
}

module "functionapp" {
  source      = "./modules/function-app"
  location = var.location
  environment = var.environment
  project = var.project
  
}
