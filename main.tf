# Create a VPC named ‘wordpress-vpc’ (add name tag). (X)
resource "aws_vpc" "wordpress-vpc" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "wordpress-vpc"
  }
}
# Create an Internet Gateway named ‘wordpress_igw’ (add name tag). (X)
resource "aws_internet_gateway" "wordpress_igw" {
  vpc_id = aws_vpc.wordpress-vpc.id

  tags = {
    Name = "wordpress_igw"
  }
}
# Create a route table named ‘wordpess-rt’ and add Internet Gateway route to it (add name tag). (X)
resource "aws_route_table" "wordpess-rt" {
  vpc_id = aws_vpc.wordpress-vpc.id

  # since this is exactly the route AWS will create, the route will be adopted
  route {
    cidr_block = "0.0.0.0/0"  # Corrected to allow internet traffic
    gateway_id = aws_internet_gateway.wordpress_igw.id
  }

  tags = {
    Name = "wordpess-rt"
  }
}
# Create 3 public and 3 private subnets in the us-east region (add name tag). Associate them with the ‘wordpess-rt’ route table. What subnets should be associated with the ‘wordpess-rt’ route table? What about other subnets? Use AWS documentation. (X)
# PUBLIC
resource "aws_subnet" "pub-sub-1" {
  vpc_id = aws_vpc.wordpress-vpc.id
  cidr_block = "10.0.0.0/18"

  tags = {
    Name = "pub-sub-1"
  }
}

resource "aws_subnet" "pub-sub-2" {
  vpc_id = aws_vpc.wordpress-vpc.id
  cidr_block = "10.0.128.0/18"

  tags = {
    Name = "pub-sub-2"
  }
}

resource "aws_subnet" "pub-sub-3" {
  vpc_id = aws_vpc.wordpress-vpc.id
  cidr_block = "10.0.224.0/20"

  tags = {
    Name = "pub-sub-3"
  }
}

#Private:
resource "aws_subnet" "priv-sub-1" {
  vpc_id = aws_vpc.wordpress-vpc.id
  cidr_block = "10.0.240.0/21"

  tags = {
    Name = "priv-sub-1"
  }
}

resource "aws_subnet" "priv-sub-2" {
  vpc_id = aws_vpc.wordpress-vpc.id
  cidr_block = "10.0.248.0/22"

  tags = {
    Name = "priv-sub-2"
  }
}

resource "aws_subnet" "priv-sub-3" {
  vpc_id = aws_vpc.wordpress-vpc.id
  cidr_block = "10.0.252.0/22"

  tags = {
    Name = "priv-sub-3"
  }
}

# Create a security group named ‘wordpress-sg’ and open HTTP, HTTPS, SSH ports to the Internet (add name tag). Define port numbers in a variable named ‘ingress_ports’. (X)
variable "ingress_ports" {
  description = "List of ingress ports to be opened"
  type        = list(string)
  default     = ["80", "443", "22"]
}

resource "aws_security_group" "wordpress_sg" {
  name        = "wordpress-sg"
  description = "Security group for WordPress with HTTP, HTTPS, and SSH access"
  vpc_id = aws_vpc.wordpress-vpc.id 

  tags = {
    Name = "wordpress-sg"
  }
}

resource "aws_security_group_rule" "allow_ingress" {
  for_each          = toset(var.ingress_ports)
  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.wordpress_sg.id
}
# Create a key pair named ‘ssh-key’ (you can use your public key).
resource "aws_key_pair" "ssh_key" {
  key_name   = "ssh-key"
  public_key = file("/Users/emiliyavuntsova/312.pub")
}

# Create an EC2 instance named ‘wordpress-ec2’ (add name tag). Use Amazon Linux 2 AMI (can store AMI in a variable), t2.micro, ‘wordpress-sg’ security group, ‘ssh-key’ key pair, public subnet 1.
resource "aws_instance" "wordpress-ec2" {
  ami           = "ami-0d191299f2822b1fa"  # Example AMI, replace with your own
  instance_type = "t2.micro"
  key_name      = aws_key_pair.ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.wordpress_sg.id]
  subnet_id = aws_subnet.pub-sub-1.id

  #woedpress and httpd:
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install -y php7.2
              yum install -y httpd mysql php php-mysqlnd wget
              systemctl start httpd
              systemctl enable httpd
              cd /var/www/html
              wget https://wordpress.org/latest.tar.gz
              tar -xzf latest.tar.gz
              cp -r wordpress/* .
              rm -rf wordpress latest.tar.gz
              chown -R apache:apache /var/www/html
              chmod -R 755 /var/www/html
              cp wp-config-sample.php wp-config.php
              sed -i "s/database_name_here/your_database_name/" wp-config.php
              sed -i "s/username_here/your_database_username/" wp-config.php
              sed -i "s/password_here/your_database_password/" wp-config.php
              sed -i "s/localhost/your_database_endpoint/" wp-config.php
              systemctl restart httpd
              EOF
              
  tags = {
    Name = "wordpress-ec2"
  }
}

# Create a security group named ‘rds-sg’ and open MySQL port and allow traffic only from ‘wordpress-sg’ security group (add name tag).
resource "aws_security_group" "rds-sg" {
  name        = "rds-sg"
  description = "Security group for MySQL WordPress that allow traffic only from wordpress-sg security group"
  vpc_id = aws_vpc.wordpress-vpc.id 

  tags = {
    Name = "rds-sg-MySQL"
  }
}

resource "aws_security_group_rule" "allow_ingress_MySQL" {
  type                    = "ingress"
  from_port               = 3306
  to_port                 = 3306
  protocol                = "tcp"
  security_group_id = aws_security_group.rds-sg.id
  source_security_group_id = aws_security_group.wordpress_sg.id
}
#Use ‘aws_db_subnet_group’ resource to define private subnets where the DB instance will be created.
resource "aws_db_subnet_group" "mysql_subnet_group" {
  name       = "mysql-subnet-group"
  subnet_ids = [
    aws_subnet.priv-sub-1.id,
    aws_subnet.priv-sub-2.id,
    aws_subnet.priv-sub-3.id
  ]

  tags = {
    Name = "mysql-subnet-group"
  }
} 

# Create a MySQL DB instance named ‘mysql’: 20GB, gp2, t2.micro instance class, username=admin, password=adminadmin. 
resource "aws_db_instance" "mysql" {
  allocated_storage    = 20
  db_name              = "mysql"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t2.micro"
  username             = "admin"
  password             = "adminadmin"
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.mysql_subnet_group.name
  skip_final_snapshot  = true
  storage_type         = "gp2"

  tags = {
    Name = "mysql"
  }
}
 

# You have to install wordpress on 'wordpress-ec2'. Desired result: on wordpress-ec2-public-ip/blog address, you have to see wordpress installation page. You can install wordpress manually or through user_data. 





output "vpc_id" {
  value = aws_vpc.wordpress-vpc.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.wordpress_igw.id
}

output "route_table_id" {
  value = aws_route_table.wordpess-rt.id
}

output "public_subnet_1_id" {
  value = aws_subnet.pub-sub-1.id
}

output "public_subnet_2_id" {
  value = aws_subnet.pub-sub-2.id
}

output "public_subnet_3_id" {
  value = aws_subnet.pub-sub-3.id
}

output "private_subnet_1_id" {
  value = aws_subnet.priv-sub-1.id
}

output "private_subnet_2_id" {
  value = aws_subnet.priv-sub-2.id
}

output "private_subnet_3_id" {
  value = aws_subnet.priv-sub-3.id
}

output "security_group_id" {
  value = aws_security_group.wordpress_sg.id
}

output "key_pair_name" {
  value = aws_key_pair.ssh_key.key_name
}

output "ec2_instance_id" {
  value = aws_instance.wordpress-ec2.id
}

output "ec2_instance_public_ip" {
  value = aws_instance.wordpress-ec2.public_ip
}
