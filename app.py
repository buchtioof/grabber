from fastapi import FastAPI, Request, HTTPException
import json
from grabber import Grabber

app = FastAPI()

ordi1 = Grabber()

@app.post("/endpoint")
async def receive_info(request: Request):
    # Lire le body brut
    body = await request.body()
    print(body)

    # Parser le JSON
    try:
        data = json.loads(body)
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid JSON")
    
    # Debug
    print("Data grabbed :", data)
    
    ordi1.hostname = data['HARDWARE']['hostname']
    ordi1.mb_serial = data['HARDWARE']['mb_serial']

    print(f"Hostname is {ordi1.hostname}")
    print(f"Motherboard serial is {ordi1.mb_serial}")

    return {"status": "ok"}

@app.get("/ordi1")
async def get_ordi1_info():
    return ordi1