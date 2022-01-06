terraform {
  backend "s3" {
    bucket = "infra-tf01"
    key    = "infra-terraform/"
    region = "us-east-2"
  }
}
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "vpc1" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  
  tags = {
    Name = "coupa-vpc"
  }
}
resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.vpc1.id
  cidr_block = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  
  tags = {
    Name = "pubsubnet"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id     = aws_vpc.vpc1.id

  tags = {
    Name = "ig"
}
}
resource "aws_route_table" "public" {
  vpc_id     = aws_vpc.vpc1.id

  tags = {
    Name = "pubroute"
}
}
resource "aws_route_table_association" "sn" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "b" {
  gateway_id     = aws_internet_gateway.gw.id
  route_table_id = aws_route_table.public.id
}

data "aws_vpc" "vpc1" {
  cidr_block       = "10.0.0.0/16"
  depends_on       =  [aws_vpc.vpc1, aws_subnet.subnet1]

}

data "aws_subnet" "subnet1" {
  vpc_id     = "${data.aws_vpc.vpc1.id}"
  cidr_block = "10.0.1.0/24"

}


resource "aws_network_interface" "ni" {
  subnet_id   = "${data.aws_subnet.subnet1.id}"
  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_instance" "ec2" {
  ami           = "ami-0fb653ca2d3203ac1"
  instance_type = "${instance_type}"
  key_name      = "ohio"
  depends_on    =  [aws_vpc.vpc1, aws_subnet.subnet1]

  network_interface {
    network_interface_id = aws_network_interface.ni.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"

  }

  tags = {
    Name = "coupa"
  }

}
