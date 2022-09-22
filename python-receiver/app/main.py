import json
import logging

from aiohttp import ClientSession
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
async def save_order(order: Order = Body()):
    async with ClientSession() as session:
        async with session.post(
            url='http://localhost:3500/v1.0/state/statestore',
            data=order
        ) as resp:
            logging.info(f'Saving order {order}')
    return await resp.text()


@app.get("/orders/{order_id}")
async def get_order(order_id):
    async with ClientSession() as session:
        async with session.get(
            url=f'http://localhost:3500/v1.0/state/statestore/{order_id}'
        ) as resp:
            logging.info(f'Retrieved order {order_id}')
    return await resp.text()
