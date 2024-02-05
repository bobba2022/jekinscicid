#custom security group with custom ingress rules

resource "aws_security_group" "sg_my_security_group" {
  name        = "sg_my_security_group"
  description = "Implements some security"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    from_port   = 8080
    to_port     = 8080
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
    Name = "my sg"
  }
}

# key pair generation

resource "aws_key_pair" "tf-key-pair" {
key_name = "tf-key-pair5"
public_key = tls_private_key.rsa.public_key_openssh
}
resource "tls_private_key" "rsa" {
algorithm = "RSA"
rsa_bits  = 4096
}
resource "local_file" "tf-key" {
content  = tls_private_key.rsa.private_key_pem
filename = "tf-key-pair5"
}
 
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.3.1"
  
  name = "jenkins-instance"
  ami="ami-0a3c3a20c09d6f377"
  instance_type          = "t2.medium"
  key_name               = "tf-key-pair5"
  monitoring             = false
  vpc_security_group_ids = [aws_security_group.sg_my_security_group.id]
  
  user_data = <<EOF
  #!/bin/bash
    sudo yum update
    echo "Copying the SSH Key Of Jenkins to the server"
    mkdir /home/ec2-user/project
    sudo yum update
    sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo

    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    sudo yum upgrade
    # Add required dependencies for the jenkins package
    sudo yum install java-11-amazon-corretto -y
    #sudo yum remove java-11-amazon-corretto
    sudo alternatives --config java

    sudo yum install jenkins -y
    sudo systemctl daemon-reload

    sudo systemctl enable jenkins
    sudo systemctl start jenkins
    sudo systemctl status jenkins

    #sudo cat /var/lib/jenkins/secrets/initialAdminPassword

  EOF

  subnet_id              = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}



#custom security group with custom ingress rules

/*resource "null_resource" "copy_files" {
  provisioner "file" {
    source      = "~/Desktop/sample-project/python-iac"
    destination = "/home/ec2-user/python-iac"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/scripts/ansible-install.sh",
      "sudo  sh /home/ubuntu/scripts/ansible-install.sh",
    ]
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("tf-key-pair4")
    host        = "44.201.85.249"
    timeout = "45m"
  } 

}  */
