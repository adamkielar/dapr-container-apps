from fastapi import FastAPI

app = FastAPI()


@app.get("/health")
def health_check():
    return {"status": "Healthy"}


@app.post("/orders")
async def save_order(order):
    return order
