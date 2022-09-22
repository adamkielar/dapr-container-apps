import logging
from typing import Dict

from fastapi import FastAPI
from httpx import AsyncClient
from pydantic import BaseModel

logging.basicConfig(level=logging.INFO)

app = FastAPI()


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
            url='http://localhost:3500/v1.0/state/statestore',
            json=data
        )
    logging.info(f'Saving planet: {data}')
    return response.status_code


@app.get("/planets/{planet_id}")
async def get_planet(planet_id: str) -> Dict:
    async with AsyncClient() as client:
        response = await client.get(
            url=f'http://localhost:3500/v1.0/state/statestore/{planet_id}'
        )
        logging.info(f'Retrieve planet: {planet_id}')
    return response.json()
