# Create a VPC named ‘wordpress-vpc’ (add name tag).
resource "aws_vpc" "wordpress-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "wordpress-vpc"
  }
}

# Create an Internet Gateway named ‘wordpress_igw’ (add name tag).
resource "aws_internet_gateway" "wordpress_igw" {
  vpc_id = aws_vpc.wordpress-vpc.id

  tags = {
    Name = "wordpress_igw"
  }
}

# Create a route table named ‘wordpress_rt’ and add Internet Gateway route to it (add name tag).
resource "aws_route_table" "wordpress_rt" {
  vpc_id = aws_vpc.wordpress-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wordpress_igw.id
  }

  tags = {
    Name = "wordpress-rt"
  }
}

# Create 3 public and 3 private subnets in the us-east region (add name tag).
# PUBLIC
resource "aws_subnet" "pub_sub_1" {
  vpc_id            = aws_vpc.wordpress-vpc.id
  cidr_block        = "10.0.0.0/18"
  availability_zone = "us-east-1a"

  tags = {
    Name = "pub-sub-1"
  }
}

resource "aws_subnet" "pub_sub_2" {
  vpc_id            = aws_vpc.wordpress-vpc.id
  cidr_block        = "10.0.64.0/18"
  availability_zone = "us-east-1b"

  tags = {
    Name = "pub-sub-2"
  }
}

resource "aws_subnet" "pub_sub_3" {
  vpc_id            = aws_vpc.wordpress-vpc.id
  cidr_block        = "10.0.128.0/18"
  availability_zone = "us-east-1c"

  tags = {
    Name = "pub-sub-3"
  }
}

# PRIVATE
resource "aws_subnet" "priv_sub_1" {
  vpc_id            = aws_vpc.wordpress-vpc.id
  cidr_block        = "10.0.192.0/21"
  availability_zone = "us-east-1a"

  tags = {
    Name = "priv-sub-1"
  }
}

resource "aws_subnet" "priv_sub_2" {
  vpc_id            = aws_vpc.wordpress-vpc.id
  cidr_block        = "10.0.200.0/21"
  availability_zone = "us-east-1b"

  tags = {
    Name = "priv-sub-2"
  }
}

resource "aws_subnet" "priv_sub_3" {
  vpc_id            = aws_vpc.wordpress-vpc.id
  cidr_block        = "10.0.208.0/21"
  availability_zone = "us-east-1c"

  tags = {
    Name = "priv-sub-3"
  }
}

# Associate subnets with the route table.
resource "aws_route_table_association" "pub_rt_assoc_1" {
  subnet_id      = aws_subnet.pub_sub_1.id
  route_table_id = aws_route_table.wordpress_rt.id
}

resource "aws_route_table_association" "pub_rt_assoc_2" {
  subnet_id      = aws_subnet.pub_sub_2.id
  route_table_id = aws_route_table.wordpress_rt.id
}

resource "aws_route_table_association" "pub_rt_assoc_3" {
  subnet_id      = aws_subnet.pub_sub_3.id
  route_table_id = aws_route_table.wordpress_rt.id
}

resource "aws_route_table_association" "priv_rt_assoc_1" {
  subnet_id      = aws_subnet.priv_sub_1.id
  route_table_id = aws_route_table.wordpress_rt.id
}

resource "aws_route_table_association" "priv_rt_assoc_2" {
  subnet_id      = aws_subnet.priv_sub_2.id
  route_table_id = aws_route_table.wordpress_rt.id
}

resource "aws_route_table_association" "priv_rt_assoc_3" {
  subnet_id      = aws_subnet.priv_sub_3.id
  route_table_id = aws_route_table.wordpress_rt.id
}

# Create a security group named ‘wordpress-sg’ and open HTTP, HTTPS, SSH ports to the Internet (add name tag).
resource "aws_security_group" "wordpress_sg" {
  name        = "wordpress-sg"
  description = "Security group for WordPress with HTTP, HTTPS, and SSH access"
  vpc_id      = aws_vpc.wordpress-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wordpress-sg"
  }
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
  subnet_id     = aws_subnet.pub_sub_1.id  # You can change this to any of the public subnets
  associate_public_ip_address = true
  # WordPress and HTTPD installation:
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
  description = "Security group for MySQL WordPress that allows traffic only from wordpress-sg security group"
  vpc_id      = aws_vpc.wordpress-vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.wordpress_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg-MySQL"
  }
}

# Use ‘aws_db_subnet_group’ resource to define private subnets where the DB instance will be created.
resource "aws_db_subnet_group" "mysql_subnet_group" {
  name       = "mysql-subnet-group"
  subnet_ids = [
    aws_subnet.priv_sub_1.id,
    aws_subnet.priv_sub_2.id,
    aws_subnet.priv_sub_3.id
  ]

  tags = {
    Name = "mysql-subnet-group"
  }
}

# Create a MySQL DB instance named ‘mysql_test’: 20GB, gp2, t2.micro instance class, username=admin, password=adminadmin.
resource "aws_db_instance" "mysql_test" {
  allocated_storage    = 20
  db_name              = "mysql_test"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "adminadmin"
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.mysql_subnet_group.name
  skip_final_snapshot  = true
  storage_type         = "gp2"

  tags = {
    Name = "mysql_test"
  }
}

# Outputs
output "vpc_id" {
  value = aws_vpc.wordpress-vpc.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.wordpress_igw.id
}

output "route_table_id" {
  value = aws_route_table.wordpress_rt.id
}

output "public_subnet_1_id" {
  value = aws_subnet.pub_sub_1.id
}

output "private_subnet_1_id" {
  value = aws_subnet.priv_sub_1.id
}
