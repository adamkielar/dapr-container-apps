import logging
import schedule
import time
import threading
from typing import Dict, List


from dapr.clients import DaprClient
from dapr.clients.grpc.client import DaprResponse

logging.basicConfig(level=logging.INFO)

DAPR_STORE_NAME = "statestore"
DAPR_PUBSUB_NAME = "planetpubsub"
DAPR_TOPIC = "planets"


def proces_planets():
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


schedule.every(10).seconds.do(proces_planets)


def scheduler():
    while True:
        schedule.run_pending()
        time.sleep(1)


thread = threading.Thread(target=scheduler)
thread.start()