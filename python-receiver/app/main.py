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
async def save_order(order: Order = Body(...)):
    result = requests.post(
            url='http://localhost:3500/v1.0/state/statestore',
            data=order.dict()
        )
    logging.info(f'Saving order {order.json()}')
    return result.json()


@app.get("/orders/{order_id}")
async def get_order(order_id: str):
    result = requests.get(
            url=f'http://localhost:3500/v1.0/state/statestore/{order_id}'
        )
    logging.info(f'Retrieved order {order_id}')
    return result.json()
