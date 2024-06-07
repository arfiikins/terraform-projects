# For the Access Key, you will need to do the AWS configure since it is not best practice to hardcode the Access Keys
provider "aws" {
  region     = "us-east-1"
  alias      = "nvirg"                                    # North Virginia
}

provider "aws" {
  region     = "us-west-1"
  alias      = "ncali"                                    # North California
}
