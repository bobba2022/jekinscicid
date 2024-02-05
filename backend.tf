terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    region  = "us-east-1"
    bucket  = "jenkins-terraformtest"
    key     = "terraform.tfstate"
    profile = ""
  
  }
}
