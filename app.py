from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from sqlmodel import select, Session
import json
from contextlib import asynccontextmanager

from grabber import Grabber, engine, flotte, SystemLog, create_db_and_tables

@asynccontextmanager
async def lifespan(app: FastAPI):
    create_db_and_tables()
    yield

app = FastAPI(lifespan=lifespan)
app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")

@app.post("/endpoint")
async def receive_info(request: Request):
    body = await request.body()
    try:
        data = json.loads(body)
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid JSON")
    
    sw = data.get("SOFTWARE", {})
    # On récupère l'adresse MAC, c'est notre nouvel identifiant unique
    mac = sw.get("mac_address")
    hostname = sw.get("hostname", "Inconnu")

    if not mac:
        raise HTTPException(status_code=400, detail="Adresse MAC manquante dans le JSON")

    # Si la machine n'est pas encore connue par son adresse MAC
    if mac not in flotte:
        print(f"Nouvelle machine détectée : {hostname} ({mac})")
        flotte[mac] = Grabber(mac, hostname)
    
    ordi_actuel = flotte[mac]
    ordi_actuel.update(data)
    ordi_actuel.save()

    return {"status": "ok", "mac": mac}

@app.get("/")
async def list_ordis(request: Request):
    # On lit la vraie BDD pour avoir l'historique même après redémarrage
    with Session(engine) as session:
        statement = select(SystemLog)
        results = session.exec(statement).all()
    
    list_items = []
    for pc in results:
        nom_affiche = f"{pc.hostname} <small>({pc.mac_address})</small>"
        # On peut ajouter une petite icône ou couleur si la date_scan est récente
        list_items.append(f'<li><a href="/ordi/{pc.mac_address}">{nom_affiche}</a></li>')
    
    liens_html = "".join(list_items)

    return HTMLResponse(f"""
    <html>
        <head>
            <title>Dashboard Grabber</title>
            <style>body{{font-family:sans-serif; padding:20px;}} li{{margin:5px 0;}}</style>
        </head>
        <body>
            <h1>Tableau de bord Grabber</h1>
            <h2>Machines connectées</h2>
            <ul>{liens_html or "En attente de données..."}</ul>
        </body>
    </html>
    """)

# L'URL attend maintenant une adresse MAC (ex: /ordi/00:11:22:33:44:55)
@app.get("/ordi/{mac_address}")
async def show_info(request: Request, mac_address: str):
    if mac_address in flotte:
        return templates.TemplateResponse("item.html", {"request": request, "ordi": flotte[mac_address]})
    else:
        return HTMLResponse("<h1>Machine introuvable</h1>", status_code=404)