from typing import Optional
from datetime import datetime
from sqlmodel import Field, Session, SQLModel, create_engine, select # <--- Ajout de select

# --- CONFIGURATION BASE DE DONNÉES ---
DB_FILE = "grabberman.db"
sqlite_url = f"sqlite:///{DB_FILE}"
engine = create_engine(sqlite_url, echo=False)

# --- MODÈLE DE DONNÉES (TABLE SQL) ---
class SystemLog(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    date_scan: datetime = Field(default_factory=datetime.now)
    
    mac_address: str = Field(index=True) # On s'en sert pour la recherche
    hostname: str 

    # Champs Hardware
    motherboard: Optional[str] = None
    cpu_model: Optional[str] = None
    cpu_id: Optional[str] = None
    cpu_cores: Optional[str] = None
    cpu_threads: Optional[str] = None
    cpu_frequency_min: Optional[str] = None
    cpu_frequency_cur: Optional[str] = None
    cpu_frequency_max: Optional[str] = None
    gpu_model: Optional[str] = None
    ram_slots: Optional[str] = None
    
    # Champs Software
    os: Optional[str] = None
    arch: Optional[str] = None
    desktop_env: Optional[str] = None
    window_manager: Optional[str] = None
    kernel: Optional[str] = None

def create_db_and_tables():
    SQLModel.metadata.create_all(engine)

# --- GESTION DE LA FLOTTE EN MÉMOIRE ---
flotte = {}

class Grabber:
    def __init__(self, mac_address, hostname="Inconnu"):
        self.mac_address = mac_address
        self.hostname = hostname
        self.data_cache = {} 

    def update(self, json_data):
        """Met à jour les données et prépare l'objet SQLModel."""
        hw = json_data.get("HARDWARE", {})
        sw = json_data.get("SOFTWARE", {})
        
        if "hostname" in sw:
            self.hostname = sw["hostname"]

        self.data_cache = {
            "mac_address": self.mac_address,
            "hostname": self.hostname,
            "motherboard": hw.get("motherboard", "N/A"),
            "cpu_model": hw.get("cpu_model", "N/A"),
            "cpu_id": hw.get("cpu_id", "N/A"),
            "cpu_cores": hw.get("cpu_cores", "N/A"),
            "cpu_threads": hw.get("cpu_threads", "N/A"),
            "cpu_frequency_min": hw.get("cpu_frequency_min", "N/A"),
            "cpu_frequency_cur": hw.get("cpu_frequency_cur", "N/A"),
            "cpu_frequency_max": hw.get("cpu_frequency_max", "N/A"),
            "gpu_model": hw.get("gpu_model", "N/A"),
            "ram_slots": hw.get("ram_slots", "N/A"),
            "os": sw.get("os", "N/A"),
            "arch": sw.get("arch", "N/A"),
            "desktop_env": sw.get("desktop_env", "N/A"),
            "window_manager": sw.get("window_manager", "N/A"),
            "kernel": sw.get("kernel", "N/A")
        }

    def save(self):
        """Enregistre ou met à jour les données dans la BDD."""
        try:
            with Session(engine) as session:
                # 1. On cherche si une machine avec cette MAC existe déjà
                statement = select(SystemLog).where(SystemLog.mac_address == self.mac_address)
                existing_pc = session.exec(statement).first()

                if existing_pc:
                    # --- MISE À JOUR (UPDATE) ---
                    print(f"Mise à jour de la BDD pour : {self.hostname} ({self.mac_address})")
                    
                    # On met à jour chaque champ existant
                    for key, value in self.data_cache.items():
                        if hasattr(existing_pc, key):
                            setattr(existing_pc, key, value)
                    
                    # On force la mise à jour de la date de scan
                    existing_pc.date_scan = datetime.now()
                    
                    session.add(existing_pc)
                
                else:
                    # --- CRÉATION (INSERT) ---
                    print(f"Création d'une nouvelle entrée BDD : {self.hostname}")
                    log_entry = SystemLog(**self.data_cache)
                    session.add(log_entry)

                session.commit()
                
        except Exception as e:
            print(f"Erreur critique BDD : {e}")

    def __getattr__(self, name):
        return self.data_cache.get(name, "N/A")