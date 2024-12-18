provider "aws" {
  region = "eu-west-1"
  # profile = "personal"
}

terraform {
  backend "s3" {
    # bucket         = "s3-bucket-nicc"
    bucket         = "nicc-s3bucket"
    key            = "infra-discovery/tfstate"
    # dynamodb_table = "dynamodb-table-nicc"
    dynamodb_table = "nicc-dynamoDB"
    region         = "eu-west-1"
    # encrypt = true
    # profile = "team-20"
  }
}

provider "vault" {
  address = "https://vault.dobeta.shop"
  #login to vault server and pick the token
  token   = file("./vault/token.txt")
  # token = "s.pUBHkYHFzW4FijYhJdG4F44K"
}

data "vault_generic_secret" "vault-secret" {
  path = "secret/database"
}

data "vault_generic_secret" "vault-secret-nr" {
  path = "secret/newrelic"
}