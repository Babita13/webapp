provider "aws" {
    region = "${var.AWS_REGION}"
}

module "webapp" {
    source = "./module"

    AWS_REGION = var.AWS_REGION
    vpc_cidr = var.vpc_cidr
    public_subnets_cidr =  var.public_subnets_cidr
    private_subnets_cidr = var.private_subnets_cidr
    AMI = var.AMI

}