
resource "aws_backup_vault" "books" {
  name = "inventory-${terraform.workspace}"
}

resource "aws_backup_plan" "books_dynamodb" {
  name = "book-dynamodb"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.books.name
    schedule          = "cron(0 17 * * ? *)" # 5PM UTC / 12PM CST daily

    lifecycle {
      delete_after = 7 # 7 days of retention
    }
  }
}

resource "aws_backup_selection" "books_dynamodb" {
  plan_id      = aws_backup_plan.books_dynamodb.id
  name         = "books-dynamodb-selection"
  iam_role_arn = aws_iam_role.ddb_backup_role.arn

  resources = [
    aws_dynamodb_table.books.arn
  ]
}

resource "aws_iam_role" "ddb_backup_role" {
  name = "ddb-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "backup.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

}

resource "aws_iam_role_policy" "ddb_backup_role_policy" {
  name = "ddb-backup-role-policy"
  role = aws_iam_role.ddb_backup_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:CreateBackup",
          "dynamodb:DeleteBackup",
          "dynamodb:DescribeBackup",
          "dynamodb:ListBackups",
          "dynamodb:ListTables",
          "dynamodb:RestoreTableFromBackup",
          "dynamodb:ListTagsOfResource",
          "dynamodb:StartAwsBackupJob",
          "dynamodb:RestoreTableFromAwsBackup",
        ],
        Resource = [aws_dynamodb_table.books.arn]
      },
      {
        Effect = "Allow",
        Action = [
          "backup:StartBackupJob",
          "backup:StopBackupJob",
          "backup:TagResource",
          "backup:UntagResource",
        ],
        Resource = "*"
      }
    ]
  })

}
