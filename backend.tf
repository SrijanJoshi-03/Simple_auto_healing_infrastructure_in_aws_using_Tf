terraform {
  backend "s3" {
    bucket       = "remote-backend-for-terraform-statefile-practice-2026"
    key          = "tf/assesment"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}