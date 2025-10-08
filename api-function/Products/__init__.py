import json
import logging
import azure.functions as func

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Products function processed a request.")

    products = [
        {"id": 1, "name": "Widget", "price": 12.99},
        {"id": 2, "name": "Gadget", "price": 23.50},
        {"id": 3, "name": "Doohickey", "price": 7.25}
    ]

    return func.HttpResponse(
        body=json.dumps(products),
        status_code=200,
        mimetype="application/json"
    )
