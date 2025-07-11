# 🚀 FASTAPI SERVER – FÜR txt2img + img2vid

# 📦 INSTALLATIONEN & IMPORTS
from fastapi import FastAPI, Request
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional
import uvicorn
import os


# 🧠 TOOL IMPORTS
from text2img import generate_image_from_json         # txt2img Logik
from img2vid import generate_video_from_json          # img2vid Logik (NEU)

# 🚀 FASTAPI APP INITIALISIEREN
app = FastAPI()


#output_url
os.makedirs("workspace", exist_ok=True)
app.mount("/workspace", StaticFiles(directory="workspace"), name="workspace")


# 📄 DATENSTRUKTUR | TXT2IMG INPUT MODELL
class Txt2ImgRequest(BaseModel):
    # 1. Standard
    prompt: str
    negative_prompt: Optional[str] = ""

    # 2. Pflichtfelder – keine Defaults mehr!
    model: str
    width: int
    height: int
    steps: int
    cfg: float
    sampler: str
    seed: Optional[int] = None

    # 3. Upscale
    upscale: Optional[bool] = False

    # 4. Output path (optional)
    output_path: Optional[str] = None

    # 5. LoRAs (Platzhalter)
    loras: Optional[list] = []

    # 6. ControlNet (Platzhalter)
    controlnet: Optional[dict] = {}

# 🔁 TOOL ENDPOINT | TXT2IMG
@app.post("/txt2img")
async def txt2img_route(request: Request):
    # 💡 Empfängt JSON mit Bildparametern und startet Bildgenerierung
    data = await request.json()
    image_path = generate_image_from_json(data)

    # Baue absolute URL (für späteren Direktzugriff z. B. via img2vid)
    base_url = str(request.base_url).rstrip("/")
    if isinstance(image_path, dict):
       image_path = image_path.get("image", "")
    rel_path = os.path.relpath(image_path, start=".")
    full_url = f"{base_url}/{rel_path}"

    return JSONResponse(content={
        "output_path": image_path,
        "output_url": full_url
    })


# 📄 DATENSTRUKTUR | IMG2VID INPUT MODELL (NEU)
class Img2VidRequest(BaseModel):
    # 1. Prompt-Basis für Bewegung
    prompt: str
    negative_prompt: Optional[str] = ""

    # 2. Quelldaten
    image_path: str  # Eingabebild

    # 3. Videoeinstellungen
    fps: int
    duration: int
    motion_strength: float
    seed: Optional[int] = None

    # 4. Modell & Effekte
    model: str
    loop: Optional[bool] = False
    interpolate: Optional[bool] = False
    camera_motion: Optional[str] = "none"  # z. B. "none", "pan", "zoom", "forward"

    # 5. Optionaler Output-Pfad
    output_path: Optional[str] = None

# 🔁 TOOL ENDPOINT | IMG2VID (NEU)
@app.post("/img2vid")
async def img2vid_route(request: Request):
    # 💡 Empfängt JSON mit Video-Parametern und startet die Videogenerierung
    data = await request.json()
    video_path = generate_video_from_json(data)
    return {"output": video_path}


