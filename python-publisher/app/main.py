import json
import logging
from typing import Dict, List


from dapr.clients import DaprClient
from dapr.clients.grpc.client import DaprResponse
from httpx import AsyncClient
from fastapi import BackgroundTasks
from fastapi import FastAPI

logging.basicConfig(level=logging.INFO)

app = FastAPI()

DAPR_STORE_NAME = "statestore"
DAPR_PUBSUB_NAME = "planetpubsub"
DAPR_TOPIC = "planets"


async def proces_planets(planet_id: str) -> None:
    async with AsyncClient() as client:
        response = await client.get(
            url=f'http://localhost:3500/v1.0/state/{DAPR_STORE_NAME}/{planet_id}'
        )
        logging.info(f'Retrieve planet: {response.json()}')

    if response.json():
        async with AsyncClient() as client:
            queue_response = await client.post(
                url=f'http://localhost:3500/v1.0/publish/{DAPR_PUBSUB_NAME}/{DAPR_TOPIC}',
                json=response.json()
            )
        logging.info(f'Published: {response.json()}')
    # with DaprClient() as client:
    #     response = client.get_state(
    #         store_name=DAPR_STORE_NAME,
    #         key=planet
    #     )
    #     logging.info(f'Retrieve planet: {response.data}')

    #     result = client.publish_event(
    #         pubsub_name=DAPR_PUBSUB_NAME,
    #         topic_name=DAPR_TOPIC,
    #         data=response.data,
    #         data_content_type='application/json'
    #     )

@app.post("/sdk/publisher/{planet_id}")
async def on_startup(planet_id: str, background_tasks: BackgroundTasks) -> Dict:
    background_tasks.add_task(proces_planets, planet_id)
    return {"status": "Work in progress"}
