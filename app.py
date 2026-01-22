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
    
    hw = data["HARDWARE"]
    sw = data["SOFTWARE"]

    ordi1.host = hw["hostname"]
    ordi1.cpu = hw["cpu_model"]
    ordi1.cpu_id = hw["cpu_id"]
    ordi1.cpu_cores_number = hw["cpu_cores"]
    ordi1.cpu_threads_number = hw["cpu_threads"]
    ordi1.cpu_frequency_min = hw["cpu_frequency_min"]
    ordi1.cpu_frequency_cur = hw["cpu_frequency_cur"]
    ordi1.cpu_frequency_max = hw["cpu_frequency_max"]
    

    ordi1.os = sw["os"]
    ordi1.arch = sw["arch"]
    ordi1.desktop = sw["desktop_env"]
    ordi1.wm = sw["window_manager"]
    ordi1.kernel = sw["kernel"]

    print(f"Hostname is {ordi1.host}")
    print(f"Motherboard serial is {ordi1.mb_serial}")

    return {"status": "ok"}


@app.get("/ordi1") #page affichant les infos de l'ordi
async def show_info(request: Request):
    return templates.TemplateResponse("item.html", {"request": request, "ordi": ordi1})