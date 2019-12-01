aws_region  = "us-east-1"
aws_profile = "superhero"
vpc_cidr    = "10.0.0.0/16"
cidrs = {
  public1  = "10.0.1.0/24"
  public2  = "10.0.2.0/24"
  private1 = "10.0.3.0/24"
  private2 = "10.0.4.0/24"
}
hbr_key_name    = "ironman"
public_key_path = "/root/.ssh/ironman.pub"
hbr_instance    = "t2.medium"
hbr_ami         = "ami-04b9e92b5572fa0d1"