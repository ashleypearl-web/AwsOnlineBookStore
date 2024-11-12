""" inventory display server """

import json
from flask import Flask
import boto3

# constants
BOOKS_TABLE = "inventory"

# globals
CONFIG = None


def read_json_file(filename):
    """ read and parse a JSON format file """
    return json.loads(read_file(filename))


def read_file(filename):
    """ read full contents of a file """
    with open(filename, "r", encoding="utf-8") as file:
        return file.read()


def create_client(service):
    """ create AWS client using passed in configuration """
    return boto3.client(
        service,
        aws_access_key_id=CONFIG['aws_user_id'],
        aws_secret_access_key=CONFIG['aws_secret_key'],
        region_name=CONFIG['region'])


def get_inventory():
    """ get the books inventory """

    boto3_client = create_client("dynamodb")

    return boto3_client.scan(
        TableName=BOOKS_TABLE,
        Select="ALL_ATTRIBUTES"
    )


def construct_html_table(books):
    """ given an input books array, produce HTML table """
    ret = ""
    for i in books['Items']:
        price = int(i['price']['N'])
        price_display = f"{price // 100}.{price % 100}"
        row = f"""
      <tr class="books">
        <td class="booksimage">
            <img src="{CONFIG['covers_url']}/{i['ISBN13']['S']}.jpg"
                alt="Book Cover" width="50" height="75"/>
        </td>
        <td class="bookstext">{i['ISBN13']['S']}</td>
        <td class="bookstext">{i['title']['S']}</td>
        <td class="bookstext">{i['author']['S']}</td>
        <td class="booksprice">{price_display}</td>
      </tr>
    """
        ret += row

    return ret


app = Flask(__name__, static_url_path='', static_folder='static')


@app.route("/", methods=['GET'])
@app.route("/index.html", methods=['GET'])
def index_page():
    """ returns the index with the inventory """
    html = read_file("static/index.html")

    table = construct_html_table(get_inventory())

    return html.replace('{{TABLE}}', table)


if __name__ == '__main__':
    CONFIG = read_json_file("pyconfig.json")
    app.run(host="0.0.0.0", port=CONFIG['service_port'])
    print("end of main")
