#iam policy
resource "aws_iam_policy" "vault_kms_policy" {
  name        = "vault-kms-access-policy-1"
  description = "Policy for vault instances to access KMS"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ],
        Effect   = "Allow",
        Resource = ["${aws_kms_key.vault-key.arn}"]
      }
    ]
  })

  tags = {
    Name = "ec2-kms-access-policy"
  }
}

#iam role
resource "aws_iam_role" "vault_role" {
  name = "vault-kms-access-role-1"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "ec2-kms-access-role-1"
  }
}

#attach policy and role to kms-key
resource "aws_iam_role_policy_attachment" "role-policy-attachment" {
  role       = aws_iam_role.vault_role.id
  policy_arn = aws_iam_policy.vault_kms_policy.arn
}

#attach policy and role to ec2
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile-1"
  role = aws_iam_role.vault_role.name
}