terraform {
  backend "s3" {
    bucket         = "fraud-prevention-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "fraud-prevention-terraform-locks"
    encrypt        = true
  }
}
