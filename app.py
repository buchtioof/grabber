from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
import json
from grabber import Grabber

app = FastAPI()
app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")

ordi1 = Grabber()

@app.get("/ordi1", response_class=HTMLResponse)
async def read_item(request: Request):
    return templates.TemplateResponse(
        request=request, name="ordi.html", context={"ordi": ordi1}
    )

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