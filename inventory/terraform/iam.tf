
/*
 * Specicication:
 *  Inveotry Server user
 *      Access to read from the DynamoDB Table
 *      Access Keys & Secret
 */

/***************************
 POLICY FOR USER
***************************/

resource "aws_iam_policy" "inventory_server" {
  name        = "inventory-server"
  path        = "/"
  description = "Policy to Read Books Table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Query",
          "dynamodb:Scan"
        ],
        Resource = [aws_dynamodb_table.books.arn]
      }
    ]
  })
}


/***************************
 INVENTORY USER SECTION
***************************/

resource "aws_iam_user" "inventory_server" {
  name = "InventoryServer"

  tags = {
    name = "InventoryServer"
  }
}

resource "aws_iam_user_policy_attachment" "attach_inventory_server" {
  user       = aws_iam_user.inventory_server.name
  policy_arn = aws_iam_policy.inventory_server.arn
}


/********************************
 INVENTORY ACCESS KEYS SECTION
 ********************************/

resource "aws_iam_access_key" "inventory_server" {
  user = aws_iam_user.inventory_server.name
}

output "inventory_server_user_id" {
  value = aws_iam_access_key.inventory_server.id
}

output "inventory_server_secret_key" {
  value     = aws_iam_access_key.inventory_server.secret
  sensitive = true
}

/********************************
 ROLE FOR INVENTORY SERVER
 ********************************/

resource "aws_iam_role" "inventory_server" {
  name = "inventoryServer"

  assume_role_policy = <<EOI
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
         ]
       },
       "Action": "sts:AssumeRole"
    }
  ]
}
EOI
}

/********************************************
 ATTACH ROLE NECESSARY FOR SSM AND INSPECTOR
 ********************************************/

resource "aws_iam_role_policy_attachment" "inventory_ssm" {
  role       = aws_iam_role.inventory_server.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "inventory_inspector" {
  role       = aws_iam_role.inventory_server.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonInspector2ManagedCisPolicy"
}

/********************************************
 INSTANCE PROFILE FOR THE SERVER
 ********************************************/

resource "aws_iam_instance_profile" "inventory_server" {
  name = "inventoryServer"
  role = aws_iam_role.inventory_server.name
}


