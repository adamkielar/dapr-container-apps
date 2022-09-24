import json
import logging
from typing import Dict


from dapr.clients import DaprClient
from httpx import AsyncClient
from fastapi import BackgroundTasks
from fastapi import FastAPI


logging.basicConfig(level=logging.INFO)


app = FastAPI()


DAPR_STORE_NAME = "statestore"
DAPR_PUBSUB_NAME = "planetpubsub"
DAPR_TOPIC = "planets"


@app.get("/health")
async def health_check() -> Dict:
    return {"status": "Healthy"}


async def publish_message(planet_data: Dict) -> None:
    async with AsyncClient() as client:
        await client.post(
            url=f'http://localhost:3500/v1.0/publish/{DAPR_PUBSUB_NAME}/{DAPR_TOPIC}',
            json=planet_data
        )
    logging.info(f'Published message: {planet_data}')


async def publish_message_grpc(planet_data: Dict) -> None:
    with DaprClient() as client:
        client.publish_event(
            pubsub_name=DAPR_PUBSUB_NAME,
            topic_name=DAPR_TOPIC,
            data=json.dumps(planet_data).encode('utf-8'),
            data_content_type='application/json'
        )

@app.post("/http/publisher")
async def proces_planet(planet_data: Dict, background_tasks: BackgroundTasks) -> Dict:
    background_tasks.add_task(publish_message, planet_data)
    return {"response": "Message processed"}


@app.post("/sdk/publisher")
async def proces_planet(planet_data: Dict, background_tasks: BackgroundTasks) -> Dict:
    background_tasks.add_task(publish_message_grpc, planet_data)
    return {"response": "Message processed"}