from fastapi import FastAPI, Request, HTTPException
import json

app = FastAPI()

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
    print("Infos recues :", data)
    return {"status": "ok"}