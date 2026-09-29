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

module "app_configuration" {
  source  = "codectl/appcfg/azure"
  version = "~> 1.0"

  resource_group_name = module.rg.groups.demo.name
  location            = module.rg.groups.demo.location

  app_configurations = {
    dev = {
      name = module.naming.app_configuration.name_unique
      sku  = "standard"

      role_assignments = {
        data_owner = {
          role_definition_name = "App Configuration Data Owner"
        }
      }

      features = {
        dark_mode = {
          name        = "DarkMode"
          description = "enables dark mode for all users"
          enabled     = true
        }

        beta_rollout = {
          name    = "BetaRollout"
          enabled = false
          label   = "beta"
          targeting_filter = {
            default = {
              default_rollout_percentage = 10
              users                      = ["alice@example.com", "bob@example.com"]
              groups = {
                internal = {
                  name               = "internal-testers"
                  rollout_percentage = 100
                }
              }
            }
          }
          timewindow_filter = {
            q4 = {
              start = "2026-10-01T00:00:00Z"
              end   = "2026-12-31T23:59:59Z"
            }
          }
        }
      }
    }
  }

  tags = { environment = "demo" }
}
