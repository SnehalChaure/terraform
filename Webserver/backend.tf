terraform{
backend "s3" {
   bucket         = "tf-backend-example"
   key            = "terraform.tfstate"
   region         = "ap-south-1"
   encrypt        = true
   kms_key_id     = "alias/terraform-bucket-key"
   dynamodb_table = "terraform-state"
 }
 }
