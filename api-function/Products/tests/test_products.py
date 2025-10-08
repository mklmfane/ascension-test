import json
import azure.functions as func
from Products import main

def test_products_returns_list_of_products():
    req = func.HttpRequest(
        method="GET",
        url="http://localhost:7071/api/products",
        params={},
        body=b""
    )

    resp = main(req)
    assert resp.status_code == 200

    data = json.loads(resp.get_body().decode("utf-8"))
    assert isinstance(data, list)
    assert len(data) >= 1
    assert {"id", "name", "price"}.issubset(set(data[0].keys()))
