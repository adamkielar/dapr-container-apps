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

planets = [f'planet{i}' for i in range(1, 10)]


def proces_planets():
    with DaprClient() as client:
        response = client.get_bulk_state(
            store_name=DAPR_STORE_NAME,
            keys=planets
        )
        logging.info(f'Retrieve planet: {response.items}')


schedule.every(30).seconds.do(proces_planets)


def scheduler():
    while True:
        schedule.run_pending()
        time.sleep(1)


thread = threading.Thread(target=scheduler)
thread.start()