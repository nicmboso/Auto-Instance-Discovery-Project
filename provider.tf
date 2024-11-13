provider "aws" {
  region = "eu-west-1"
  # profile = "team-20"
}

terraform {
  backend "s3" {
    bucket         = "nicc-s3bucket"
    key            = "infra-discovery/tfstate"
    dynamodb_table = "nicc-dynamoDB"
    region         = "eu-central-1"
    # region         = "eu-west-1"
    # encrypt = true
    # profile = "team2"
  }
}

provider "vault" {
  address = "https://vault.dobetabeta.shop"
  #login to vault server and pick the token
  token = "s.2r8yIx8G5cReQ1OvuFNrWLar"
}

data "vault_generic_secret" "vault-secret" {
  path = "secret/database"
}