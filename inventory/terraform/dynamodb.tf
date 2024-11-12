
/*
 * Specification
 *   DynamoDB table with name 'inventory' and primary key ISBN13
 *   Load all records from ../books
 */

/*****************
 DATABASE SECTION
*****************/

resource "aws_dynamodb_table" "books" {
  name         = "inventory"
  hash_key     = "ISBN13"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "ISBN13"
    type = "S"
  }

  tags = {
    Name = "Books"
  }
}

/***************************
 LOAD DATA SECTION
***************************/

resource "aws_dynamodb_table_item" "book" {
  for_each = fileset("../books/", "*.json")

  table_name = aws_dynamodb_table.books.name
  hash_key   = aws_dynamodb_table.books.hash_key
  item       = file("../books/${each.value}")
}

