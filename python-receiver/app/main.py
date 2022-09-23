import logging
from typing import Dict

from dapr.clients import DaprClient
from dapr.clients.grpc.client import DaprResponse
from fastapi import FastAPI
from httpx import AsyncClient
from pydantic import BaseModel

logging.basicConfig(level=logging.INFO)

app = FastAPI()


DAPR_STORE_NAME = "statestore"


class PlanetDetails(BaseModel):
    name: str
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
    data = [planet.dict()]
    async with AsyncClient() as client:
        response = await client.post(
            url=f'http://localhost:3500/v1.0/state/{DAPR_STORE_NAME}',
            json=data
        )
    logging.info(f'Saving planet: {data}')
    return response.status_code


@app.get("/planets/{planet_id}")
async def get_planet(planet_id: str) -> Dict:
    async with AsyncClient() as client:
        response = await client.get(
            url=f'http://localhost:3500/v1.0/state/{DAPR_STORE_NAME}/{planet_id}'
        )
        logging.info(f'Retrieve planet: {planet_id}')
    return response.json()


@app.post("/sdk/planets")
async def save_planet(planet: Planet) -> DaprResponse:
    data = planet.dict()
    with DaprClient() as client:
        response = client.save_state(
            store_name=DAPR_STORE_NAME,
            key=data.get('key'),
            value=str(data.get('value'))
        )
    logging.info(f'Saving planet: {data}')
    return response


@app.get("/sdk/planets/{planet_id}")
async def get_planet(planet_id: str) -> str:
    with DaprClient() as client:
        response = client.get_state(
            store_name=DAPR_STORE_NAME,
            key=planet_id
        )
        logging.info(f'Retrieve planet: {planet_id}')
    return str(response.data)
