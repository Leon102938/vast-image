#!/bin/bash

### === CONFIG EINBINDEN ===
source ./tools.config

### === FUNKTION: Datei herunterladen, wenn sie fehlt ===
download_if_missing() {
  local file_path="$1"
  local remote_url="$2"

  if [ -f "$file_path" ]; then
    echo "✅ $file_path bereits vorhanden – Download übersprungen."
  else
    echo "⬇️  Lade $remote_url nach $file_path ..."
    mkdir -p "$(dirname "$file_path")"

    if command -v aria2c >/dev/null 2>&1; then
      echo "🚀 aria2c erkannt – paralleler Download aktiv."
      aria2c -x 16 -s 16 -c -d "$(dirname "$file_path")" -o "$(basename "$file_path")" "$remote_url"
    else
      echo "⚠️  aria2c nicht gefunden – fallback auf wget."
      wget -nc -O "$file_path" "$remote_url"
    fi
  fi
}

### === TXT2IMG ===
if [ "$USE_TXT2IMG" == "on" ]; then
  for file in $TXT2IMG_MODEL_FILES; do
    download_if_missing "$TXT2IMG_PATH/$file" "$BASE_URL/models/txt2img/$TXT2IMG_MODEL/$file"
  done
fi

### === IMG2VID (voll parallel mit aria2c .txt Liste) ===
if [ "$USE_IMG2VID" == "on" ]; then
  TMP_ARIA_LIST="/tmp/aria2_img2vid.txt"
  echo "📝 Erstelle aria2c-Downloadliste für IMG2VID-Modell ..."
  rm -f "$TMP_ARIA_LIST"
  mkdir -p "$IMG2VID_PATH"

  for file in $IMG2VID_MODEL_FILES; do
    echo "$IMG2VID_BASE_URL/models/img2vid/$IMG2VID_MODEL/$file" >> "$TMP_ARIA_LIST"
  done

  if command -v aria2c >/dev/null 2>&1; then
    echo "🚀 Starte parallelen aria2c-Download für IMG2VID-Modell ..."
    aria2c -j 18 -x 18 -s 18 -c --allow-overwrite=true -d "$IMG2VID_PATH" -i "$TMP_ARIA_LIST"
  else
    echo "⚠️  aria2c nicht gefunden – fallback auf wget (nacheinander)."
    while read -r url; do
      file_name=$(basename "$url")
      wget -nc -O "$IMG2VID_PATH/$file_name" "$url"
    done < "$TMP_ARIA_LIST"
  fi
fi

echo "✅ Init abgeschlossen – alle aktiven Modelle wurden geprüft."

