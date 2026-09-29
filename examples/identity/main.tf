module "naming" {
  source  = "codectl/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
}

module "regions" {
  source  = "codectl/locations/azure"
  version = "~> 1.0"

  location = {
    primary = "westeurope"
  }
}

module "rg" {
  source  = "codectl/rg/azure"
  version = "~> 1.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = module.regions.location.primary.name
    }
  }
}

module "identity" {
  source  = "codectl/uai/azure"
  version = "~> 1.0"

  identity = {
    name                = module.naming.user_assigned_identity.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
  }
}

module "app_configuration" {
  source  = "codectl/appcfg/azure"
  version = "~> 1.0"

  resource_group_name = module.rg.groups.demo.name
  location            = module.rg.groups.demo.location

  app_configurations = {
    dev = {
      name = module.naming.app_configuration.name_unique
      identity = {
        type         = "UserAssigned"
        identity_ids = [module.identity.identity.id]
      }
    }
  }
}
