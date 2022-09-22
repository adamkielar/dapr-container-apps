import json
import logging
import requests
from typing import Dict

from aiohttp import ClientSession
from fastapi import Body
from fastapi import FastAPI
from pydantic import BaseModel

logging.basicConfig(level=logging.INFO)

app = FastAPI()


class PlanetDetails(BaseModel):
    kind: str
    status: str


class Planet(BaseModel):
    key: str
    value: PlanetDetails


@app.get("/health")
def health_check():
    return {"status": "Healthy"}


@app.post("/planets")
async def save_planet(planet: Planet) -> int:
    async with ClientSession() as session:
        response = await session.post(
            url='http://localhost:3500/v1.0/state/statestore?metadata.contentType=application/json',
            data=planet.dict()
        )
        logging.info(f'Saving planets: {planet.dict()}')
    return response.status


@app.get("/planets/{planet_name}")
async def get_planet(planet_name: str) -> Dict:
    async with ClientSession() as session:
        response = await session.get(
            url=f'http://localhost:3500/v1.0/state/statestore/{planet_name.capitalize()}'
        )
        logging.info(f'Retrieve planet: {planet_name}')
    return await response.text()
# @app.post("/orders")
# async def save_order(order):
#     orderId = '1'
#     order = {'orderId': orderId}
#     state = [{
#       'key': orderId,
#       'value': order
#     }]
#     result = requests.post(
#             url='http://localhost:3500/v1.0/state/statestore',
#             json=state
#         )
#     logging.info(f'Saving order {order}')
#     return result.status_code


# @app.get("/orders")
# async def get_order():
#     if result := requests.get(
#             url='http://localhost:3500/v1.0/state/statestore/1'
#     ):
#         logging.info(f'Retrieved order {result.json()}')
#         return result.json()
#     return result.status_code