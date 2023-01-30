provider "aws" {
  region     = "us-east-1"
  access_key = "AKIAZA4FJZCSLN3YVA2I"
  secret_key = "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"
}


# VPC

resource "aws_vpc" "MyVPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "MyVPC"
  }
}

#Public subnet

resource "aws_subnet" "Public_Subnet" {
  vpc_id     = aws_vpc.MyVPC.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Public_Subnet"
  }
}

# Internet Gateway

resource "aws_internet_gateway" "MyIG" {
  vpc_id = aws_vpc.MyVPC.id

  tags = {
    Name = "MyIG"
  }
}

# Public Routing Table

resource "aws_route_table" "Public_RT" {
  vpc_id = aws_vpc.MyVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.MyIG.id
  }
  tags = {
    Name = "Public_RT"
  }
}

# Public Routing Table Association

resource "aws_route_table_association" "Public_RT_Assoc" {
  subnet_id      = aws_subnet.Public_Subnet.id
  route_table_id = aws_route_table.Public_RT.id
}


#ELastic IP

resource "aws_eip" "My_ELB" {
  vpc      = true
}

# Private Subnet

resource "aws_subnet" "Private_Subnet" {
  vpc_id     = aws_vpc.MyVPC.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "Private_Subnet"
  }
}

# NAT Gateway

resource "aws_nat_gateway" "MyNAT" {
  allocation_id = aws_eip.My_ELB.id
  subnet_id     = aws_subnet.Public_Subnet.id

  tags = {
    Name = "MyNAT"
  }
  depends_on = [aws_internet_gateway.MyIG]
}

# Private Routing Table

resource "aws_route_table" "Private_RT" {
  vpc_id = aws_vpc.MyVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.MyNAT.id
  }
  tags = {
    Name = "Private_RT"
  }
}

# Private Routing Table Association

resource "aws_route_table_association" "Private_RT_Assoc" {
  subnet_id      = aws_subnet.Private_Subnet.id
  route_table_id = aws_route_table.Private_RT.id
}

# Security Group

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.MyVPC.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  
  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_instance" "publicmachine" {
  ami                         =  "ami-00874d747dde814fa"
  instance_type               =  "t2.micro"  
  subnet_id                   =  aws_subnet.Public_Subnet.id
  key_name                    =  "hanuman"
  vpc_security_group_ids      =  ["${aws_security_group.allow_tls.id}"]
  associate_public_ip_address =  true
  tags = {
    Name = "Public Instance"
  }
}
resource "aws_instance" "private" {
  ami                         =  "ami-00874d747dde814fa"
  instance_type               =  "t2.micro"  
  subnet_id                   =  aws_subnet.Private_Subnet.id
  key_name                    =  "hanuman"
  vpc_security_group_ids      =  ["${aws_security_group.allow_tls.id}"]
  tags = {
    Name = "Private Instance"
  }
}


#Create VPC
#Create Subnets - public & private
#Create Internet Gateway and attach to VPC
#Create Routing Table and associate to appropriate subnets
#Edit the public routing table and map the internet gateway
#Create Public & Private Security Group and add the rules. For Windows give RDP and HTTP and for Linux give SSH & HTTP
#Create Public & Private Instances by proving appropriate VPC, Subnets and security groups. Enable auto allocate IP address.
#Login into Public Instance and check the internet connectivity
#Create NAT GW adn map to Private Subnet
#Login into Private instance from public instance using private IP address adn check internet connectivity
