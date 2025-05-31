import json


def lambda_handler(event, context):
    print("Received event: " + json.dumps(event))
    print("All messages processed successfully.")
    return "Success"
