import logging
import requests

from fastapi import Body, FastAPI
from pydantic import BaseModel

logging.basicConfig(level=logging.INFO)

app = FastAPI()


class Order(BaseModel):
    order_id: str


@app.get("/health")
def health_check():
    return {"status": "Healthy"}


@app.post("/orders")
async def save_order():
    orderId = '1'
    order = {'orderId': orderId}
    state = [{
      'key': orderId,
      'value': order
    }]
    result = requests.post(
            url='http://localhost:3500/v1.0/state/statestore',
            json=state
        )
    logging.info(f'Saving order {order}')
    return result.json()


@app.get("/orders")
async def get_order():
    if result := requests.get(
            url='http://localhost:3500/v1.0/state/statestore/1'
    ):
        logging.info(f'Retrieved order {result.json()}')
        return result.json()
    return result.status_code