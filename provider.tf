provider "aws" {
  region = "eu-west-1"
  profile = "team-20"
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
    profile = "team-20"
  }
}

provider "vault" {
  address = "https://vault.dobetabeta.shop"
  #login to vault server and pick the token
  token = var.vault_token
  # token = "s.EmgH5ULrQh3SDE0bxGsA0y3X"
}

data "vault_generic_secret" "vault-secret" {
  path = "secret/database"
}