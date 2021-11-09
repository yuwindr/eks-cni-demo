resource "aws_iam_role" "ec2_iam_role" {
  name = "ec2-instance-iam-role"
  assume_role_policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]
  permissions_boundary = var.iam_permissions_boundary_policy_arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-iam-role"
  role = aws_iam_role.ec2_iam_role.name
}

resource "aws_instance" "target_ec2" {
  ami                    = var.ec2_ami_id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnet.ec2_public_subnet.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true
  key_name = var.key_pair_name
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = <<EOF
        #!/bin/bash
        yum update -y
        amazon-linux-extras install docker
        service docker start
        usermod -a -G docker ec2-user
        chkconfig docker on
        docker pull ${var.serviceA_container_image}
        docker run -p 20:22 -d --rm ${var.serviceA_container_image}
        docker pull ${var.serviceB_container_image}
        docker run -p 80:80 -d --rm ${var.serviceB_container_image}
    EOF

  tags = {
    Name = "Target Instance"
  }
}


output "target_ec2_private_ip" {
    value = aws_instance.target_ec2.private_ip
}

output "target_ec2_public_ip" {
    value = aws_instance.target_ec2.public_ip
}