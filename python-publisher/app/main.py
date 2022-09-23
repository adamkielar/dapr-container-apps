import json
import logging
from typing import Dict, List


from dapr.clients import DaprClient
from dapr.clients.grpc.client import DaprResponse
from fastapi import BackgroundTasks
from fastapi import FastAPI

logging.basicConfig(level=logging.INFO)

app = FastAPI()

DAPR_STORE_NAME = "statestore"
DAPR_PUBSUB_NAME = "planetpubsub"
DAPR_TOPIC = "planets"


def proces_planets(planet: str) -> None:
    with DaprClient() as client:
        response = client.get_state(
            store_name=DAPR_STORE_NAME,
            keys=planet
        )
        logging.info(f'Retrieve planet: {response.data}')

        result = client.publish_event(
            pubsub_name=DAPR_PUBSUB_NAME,
            topic_name=DAPR_TOPIC,
            data=response.data,
            data_content_type='application/json'
        )

@app.post("/sdk/publisher/{planet}")
async def on_startup(planet: str, background_tasks: BackgroundTasks) -> Dict:
    background_tasks.add_task(proces_planets, planet)
    return {"status": "Work in progress"}
