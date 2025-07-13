#!/bin/bash

# Tools-Konfiguration laden
source ./tools.config


# ============ 🔧 PYTHONPATH ============
export PYTHONPATH="$PYTHONPATH:/workspace/app"

# ============ 🔷 JUPYTERLAB THEME ============
mkdir -p /root/.jupyter/lab/user-settings/@jupyterlab/apputils-extension
echo '{ "theme": "JupyterLab Dark" }' > /root/.jupyter/lab/user-settings/@jupyterlab/apputils-extension/themes.jupyterlab-settings

# ============ 🔷 JUPYTERLAB (Port 8888) ============
if [ "$JUPYTER" == "on" ]; then
  echo "🧠 Starte JupyterLab (Port 8888)..."
  nohup jupyter lab \
    --ip=0.0.0.0 \
    --port=8888 \
    --no-browser \
    --allow-root \
    --NotebookApp.token='' \
    --NotebookApp.password='' \
    --NotebookApp.disable_check_xsrf=True \
    --NotebookApp.notebook_dir='/workspace' \
    --ServerApp.allow_origin='*' \
    > /workspace/jupyter.log 2>&1 &
fi

# ============ 🔷 FASTAPI (Port 8000) ============
if [ "$FASTAPI" == "on" ]; then
  echo "🚀 Starte zentrale FastAPI (Port 8000)..."
  nohup uvicorn app.main:app --host 0.0.0.0 --port 8000 > /workspace/fastapi.log 2>&1 &
fi


# ============ Volume Mount ============

mkdir -p /workspace/ai-core

rclone mount server-volume: /workspace/ai-core \
  --allow-other \
  --dir-cache-time 30s \
  --poll-interval 30s \
  --vfs-read-chunk-size 128M \
  --vfs-cache-mode writes \
  --vfs-cache-max-age 1m \
  --daemon || echo "⚠️ Rclone mount fehlgeschlagen – wird später manuell gefixt."


# ============ ✅ ABSCHLUSS ============
echo "✅ Dienste wurden gestartet: Modelle geladen, JupyterLab und/oder FastAPI aktiv (je nach config)"
tail -f /dev/null


