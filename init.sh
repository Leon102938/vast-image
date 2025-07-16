#!/bin/bash

### === CONFIG ===
# Tools-Konfiguration laden
source ./tools.config

# Zielpfade definieren
TXT2IMG_PATH="/workspace/ai-core/models/txt2img/${TXT2IMG_MODEL}"
IMG2VID_PATH="/workspace/ai-core/models/img2vid/WAN2.1"

### === FUNKTIONEN ===

# Download mit Check ob Ordner leer ist
download_if_missing() {
  local folder="$1"
  local remote_url="$2"

  if [ -d "$folder" ] && [ "$(ls -A "$folder")" ]; then
    echo "✅ $folder bereits vorhanden – Download übersprungen."
  else
    echo "⬇️  Lade $remote_url nach $folder ..."

    mkdir -p "$folder"

    if command -v aria2c &> /dev/null; then
      echo "🚀 aria2c erkannt – paralleler Download aktiv."
      aria2c -c -x 16 -s 16 --dir="$folder" --allow-overwrite=true \
             --auto-file-renaming=false --max-connection-per-server=16 \
             --min-split-size=1M "${remote_url}"
    else
      echo "⚠️  aria2c nicht gefunden – fallback auf wget."
      wget -r -np -nH --cut-dirs=5 -R "index.html*" -P "$folder" "$remote_url"
    fi
  fi
}

### === LOGIK ===

if [ "$USE_TXT2IMG" == "on" ]; then
  download_if_missing "$TXT2IMG_PATH" "$BASE_URL/models/txt2img/${TXT2IMG_MODEL}/"
fi

if [ "$USE_IMG2VID" == "on" ]; then
  download_if_missing "$IMG2VID_PATH" "$BASE_URL/models/img2vid/WAN2.1/"
fi

echo "✅ Init abgeschlossen – alle aktiven Modelle wurden geprüft."
