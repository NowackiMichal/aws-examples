# IAM Role for Session Manager
resource "aws_iam_role" "session_manager_role" {
  name = "session_manager_role"

  assume_role_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "ssm.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        },
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Action": "sts:AssumeRole",
          "Sid": ""
        }
      ]
    }
  EOF
}

# IAM Policy for Session Manager
resource "aws_iam_policy" "session_manager_policy" {
  name        = "session_manager_policy"
  description = "Policy for Session Manager"
  
  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "ssm:StartSession",
            "ssm:ResumeSession"
          ],
          "Resource": "*"
        }
      ]
    }
  EOF
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "session_manager_attachment" {
  role       = aws_iam_role.session_manager_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile for the bastion host
resource "aws_iam_instance_profile" "ec2_bastion_host_instance_profile" {
  name = "ec2_bastion_host_instance_profile"
  role = aws_iam_role.session_manager_role.name
}

# Create IAM user
resource "aws_iam_user" "nebo_user" {
  name = "nebo"
}

# Create IAM access key for the user
resource "aws_iam_access_key" "nebo_user_access_key" {
  user = aws_iam_user.nebo_user.name
}

# IAM Policy for EC2 actions
resource "aws_iam_policy" "ec2_policy" {
  name        = "ec2_policy"
  description = "Policy for EC2 actions"

  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "ec2:DescribeInstances",
            "ec2:StartInstances",
            "ec2:StopInstances",
            "ec2:RebootInstances",
            "ec2:DescribeSecurityGroups"
          ],
          "Resource": "*"
        }
      ]
    }
  EOF
}

# Attach EC2 policy to IAM user
resource "aws_iam_user_policy_attachment" "nebo_user_ec2_attachment" {
  user       = aws_iam_user.nebo_user.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

# IAM Policy for connecting to the bastion host
resource "aws_iam_policy" "bastion_access_policy" {
  name        = "bastion_access_policy"
  description = "Policy for connecting to the bastion host"

  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "ssm:StartSession",
            "ssm:ResumeSession",
            "ssm:DescribeInstanceInformation",
            "ssm:GetConnectionStatus"
          ],
          "Resource": "*"
        }
      ]
    }
  EOF
}

# Attach bastion access policy to IAM user
resource "aws_iam_user_policy_attachment" "bastion_user_bastion_access_attachment" {
  user       = aws_iam_user.nebo_user.name
  policy_arn = aws_iam_policy.bastion_access_policy.arn
}