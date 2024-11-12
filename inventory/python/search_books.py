""" search books for author whose name begins with PARAM """

import argparse
import sys
import boto3

TABLE_NAME = "inventory"


def search_books(ddb_resource, author_begins_with):
    """ Search for a book whose author begins with and return Item """

    response = ddb_resource.scan(TableName=TABLE_NAME,
                                 Select="ALL_ATTRIBUTES",
                                 FilterExpression='begins_with \
                                 (author,:author)',
                                 ExpressionAttributeValues={
                                    ':author': {'S': author_begins_with}
                                 })

    return response


def print_book(book):
    """ pretty print book item """
    print("----- Book")
    print(f"ISBN: {book['ISBN13']['S']}")
    print(f"Title: {book['title']['S']}")
    print(f"Author: {book['author']['S']}")
    print(f"Price: {int(book['price']['N']) // 100}.\
{(int(book['price']['N']) % 100):02}")


def print_books(books):
    """ print all books """
    for book in books:
        print_book(book)


def parse_args():
    """ parse arguments return the arg object """
    parser = argparse.ArgumentParser(
        usage='python3 %(prog) --region REGION AUTHOR_BEGINS_WITH',
        description='Print all books whose author name begins with ARG')

    parser.add_argument('-r', '--region',
                        help=f"AWS Region containing table {TABLE_NAME}",
                        required=True)
    parser.add_argument('name', nargs='?',
                        help='Must provide author begins with argument')

    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()

    if args.name is None:
        print('ERROR: must provide author begins with as string')
        sys.exit(5)

    # do not need to provide access_key and secret, will come from env
    ddb_client = boto3.client('dynamodb', region_name=args.region)

    items = search_books(ddb_client, args.name)
    print_books(items['Items'])
