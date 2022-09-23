import logging
from typing import Dict, List

from arq import cron
from dapr.clients import DaprClient
from dapr.clients.grpc.client import DaprResponse

logging.basicConfig(level=logging.INFO)

DAPR_STORE_NAME = "statestore"
DAPR_PUBSUB_NAME = "planetpubsub"
DAPR_TOPIC = "planets"


async def proces_planets():
    with DaprClient() as client:
        response = client.query_state(
            store_name=DAPR_STORE_NAME,
            query = '''
            {
                "filter": {
                    "EQ": { "status": "active" }
                },
                "sort": [
                    {
                        "key": "name",
                        "order": "DESC"
                    }
                ]
            }
            '''
        )
        for item in response.results:
            logging.info(f'Retrieve planet: {item}')

class WorkerSettings:
    cron_jobs = [
        cron(proces_planets, second=10)
    ]
