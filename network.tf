data "aws_vpc" "eks_vpc" {
  id = var.eks_vpc_id
}

data "aws_subnet_ids" "main_public_subnets" {
  vpc_id = data.aws_vpc.eks_vpc.id
  tags = {
    Tier = "Public"
    CIDR = "Main"
  }
}

# resource "aws_subnet" "main_public_subnet_1a" {
#   vpc_id     = data.aws_vpc.eks_vpc.id
#   cidr_block = cidrsubnet(var.eks_vpc_main_cidr, 1, 0)
#   availability_zone = "ap-southeast-1a"
#   map_public_ip_on_launch = true
#   tags = {
#     Name = "Public Subnet 1"
#   }
# }

# resource "aws_subnet" "main_public_subnet_1b" {
#   vpc_id     = data.aws_vpc.eks_vpc.id
#   cidr_block = cidrsubnet(var.eks_vpc_main_cidr, 1, 1)
#   availability_zone = "ap-southeast-1b"
#   map_public_ip_on_launch = true
#   tags = {
#     Name = "Public Subnet 2"
#   }
# }

resource "aws_subnet" "secondary_public_subnet_1a" {
  vpc_id     = data.aws_vpc.eks_vpc.id
  cidr_block = cidrsubnet(var.eks_vpc_secondary_cidr, 2, 0)
  availability_zone = "ap-southeast-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Secondary Public Subnet 1"
    Tier = "Public"
    CIDR = "Secondary"
  }
}

resource "aws_subnet" "secondary_public_subnet_1b" {
  vpc_id     = data.aws_vpc.eks_vpc.id
  cidr_block = cidrsubnet(var.eks_vpc_secondary_cidr, 2, 1)
  availability_zone = "ap-southeast-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "Secondary Public Subnet 2"
    Tier = "Public"
    CIDR = "Secondary"
  }
}

# data "aws_subnet" "secondary_public_subnet_1a" {
#   vpc_id            = data.aws_vpc.eks_vpc.id
#   availability_zone = "ap-southeast-1a"
#   tags = {
#     Tier = "Public"
#     CIDR = "Secondary"
#   }
# }

# data "aws_subnet" "secondary_public_subnet_1b" {
#   vpc_id            = data.aws_vpc.eks_vpc.id
#   availability_zone = "ap-southeast-1b"
#   tags = {
#     Tier = "Public"
#     CIDR = "Secondary"
#   }
# }

data "aws_vpc" "ec2_vpc" {
  id = var.ec2_vpc_id
}

data "aws_subnet" "ec2_public_subnet" {
  vpc_id            = data.aws_vpc.ec2_vpc.id
  availability_zone = "ap-southeast-1a"
  tags = {
    Tier = "Public"
  }
}

# resource "aws_subnet" "ec2_public_subnet" {
#   vpc_id     = data.aws_vpc.ec2_vpc.id
#   cidr_block = cidrsubnet(var.ec2_vpc_main_cidr, 0, 0)
#   availability_zone = "ap-southeast-1a"
#   map_public_ip_on_launch = true
#   tags = {
#     Name = "Public Subnet"
#     Tier = "Public"
#   }
# }

resource "aws_security_group" "eks_pod_sg" {
  name        = "eks_sg_allow_from_vpc"
  description = "Allow all traffic from VPC"
  vpc_id      = data.aws_vpc.eks_vpc.id

  ingress = [
    {
      description      = "All ports from VPC"
      from_port        = 0
      to_port          = 0
      protocol         = -1
      cidr_blocks      = ["${var.eks_vpc_main_cidr}"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "All ports from VPC"
      from_port        = 0
      to_port          = 0
      protocol         = -1
      cidr_blocks      = ["${var.eks_vpc_secondary_cidr}"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress = [
    {
      description      = ""
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  tags = {
    "Name" = "eks_sg_allow_from_vpc"
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg"
  description = "Allow HTTP traffic"
  vpc_id      = data.aws_vpc.ec2_vpc.id

  ingress = [
    {
      description      = "HTTP from everywhere"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["${var.eks_vpc_main_cidr}"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "All ports from VPC"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["${var.eks_vpc_main_cidr}"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress = [
    {
      description      = ""
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  tags = {
    "Name" = "ec2_sg"
  }
}