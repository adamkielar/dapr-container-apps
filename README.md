Table of Contents
=================

- [Infrastructure](#infrastructure)
  - [Infrastructure diagram](#infrastructure-diagram)
- [Application](#application)
  - [Application diagram](#application-diagram)
  - [Application endpoints](#application-endpoints)
    - [Python receiver](#python-receiver)

# Infrastructure

## Infrastructure diagram

![diagram](docs/diagram.png)

# Application
## Application diagram

![app-diagram](docs/dapr-app.png)

## Application endpoints

### Python receiver

FastApi app to receive messages from users about planets.

* `/planets` (POST)

Endpoint saves state to Azure Redis using http protocol:

```python
async with AsyncClient() as client:
    response = await client.post(
        url=f'http://localhost:3500/v1.0/state/{DAPR_STORE_NAME}',
        json=data
    )
```

And makes service-to-service invocation to trigger Python publisher app:
```python
async with AsyncClient() as client:
    publisher_response = await client.post(
        url='http://localhost:3500/sdk/publisher',
        headers={'dapr-app-id': 'python-publisher', 'content-type': 'application/json'},
        json=data
    )
```

* `/planets/{planet_id}` (GET)

Endpoint gets state from Azure Redis using http protocol:

```python
async with AsyncClient() as client:
    response = await client.get(
        url=f'http://localhost:3500/v1.0/state/{DAPR_STORE_NAME}/{planet_id}'
    )
```

*  `/sdk/planets` (POST)