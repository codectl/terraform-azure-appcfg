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

module "kv" {
  source  = "codectl/kv/azure"
  version = "~> 1.0"


  vault = {
    name                = module.naming.key_vault.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name

    secrets = {
      predefined_string = {
        connection-string1 = {
          value = module.storage1.account.primary_connection_string
        }
        connection-string2 = {
          value = module.storage2.account.primary_connection_string
        }
      }
      random_string = {
        example = {
          length  = 24
          special = false
        }
      }
    }
  }
}

module "storage1" {
  source  = "codectl/sa/azure"
  version = "~> 1.0"

  storage = {
    name                = module.naming.storage_account.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
  }
}

module "storage2" {
  source  = "codectl/sa/azure"
  version = "~> 1.0"

  storage = {
    name                = "${module.naming.storage_account.name_unique}2"
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
  }
}

module "keys" {
  source  = "codectl/appcfg/azure//modules/keys"
  version = "~> 1.0"

  configuration_store_id = module.app_configuration.configs.dev.id

  app_configuration_keys = {
    keys = {
      blob_container_id = {
        key   = "Storage:BlobContainer:Id"
        value = "function-deployments"
      },

      primary_storage_connection = {
        key                 = "Storage:PrimaryAccount:ConnectionString"
        vault_key_reference = module.kv.secrets["connection-string1"].id
      },

      backup_storage_connection = {
        key                 = "Storage:BackupAccount:ConnectionString"
        vault_key_reference = module.kv.secrets["connection-string2"].id
      }
    }
  }

  depends_on = [module.app_configuration]
}

module "app_configuration" {
  source  = "codectl/appcfg/azure"
  version = "~> 1.0"

  resource_group_name = module.rg.groups.demo.name
  location            = module.rg.groups.demo.location

  app_configurations = {
    dev = {
      name                  = module.naming.app_configuration.name_unique
      sku                   = "standard"
      public_network_access = "Enabled"

      role_assignments = {
        data_owner = {
          role_definition_name = "App Configuration Data Owner"
        }
      }
    }
  }
}
