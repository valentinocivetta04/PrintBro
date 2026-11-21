#!/bin/bash
# Compila en release y arma PrintBro.app firmada ad-hoc (sin Xcode).
# Uso: ./build.sh              arma PrintBro.app en esta carpeta
#      ./build.sh --instalar   además la copia a /Applications
set -euo pipefail
cd "$(dirname "$0")"

INSTALAR=0
for arg in "$@"; do
    case "$arg" in
        --instalar) INSTALAR=1 ;;
        *) echo "Uso: ./build.sh [--instalar]" >&2; exit 1 ;;
    esac
done

swift build -c release
BIN="$(swift build -c release --show-bin-path)/PrintBro"

APP="PrintBro.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/PrintBro"
# Textos de la interfaz (sin Xcode no se puede compilar un .xcstrings).
cp -R Resources/es.lproj "$APP/Contents/Resources/"

# Ícono: de Resources/AppIcon-1024.png a AppIcon.icns. El .iconset va a una carpeta
# temporal que se borra sola al terminar el script (también si falla).
TEMPORAL="$(mktemp -d)"
trap 'rm -rf "$TEMPORAL"' EXIT
ICONSET="$TEMPORAL/AppIcon.iconset"
mkdir "$ICONSET"
for tam in 16 32 128 256 512; do
    doble=$((tam * 2))
    sips -z "$tam" "$tam" Resources/AppIcon-1024.png --out "$ICONSET/icon_${tam}x${tam}.png" >/dev/null
    sips -z "$doble" "$doble" Resources/AppIcon-1024.png --out "$ICONSET/icon_${tam}x${tam}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>local.valentino.printbro</string>
    <key>CFBundleName</key>
    <string>PrintBro</string>
    <key>CFBundleExecutable</key>
    <string>PrintBro</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleDevelopmentRegion</key>
    <string>es</string>
    <key>CFBundleLocalizations</key>
    <array>
        <string>es</string>
    </array>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Documento para imprimir</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSHandlerRank</key>
            <string>Alternate</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>com.adobe.pdf</string>
                <string>public.png</string>
                <string>public.jpeg</string>
                <string>public.heic</string>
                <string>public.plain-text</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"
echo "Listo: $APP"

if [ "$INSTALAR" -eq 1 ]; then
    # Se reemplaza la copia anterior entera para que no queden archivos viejos adentro.
    rm -rf "/Applications/$APP"
    cp -R "$APP" /Applications/
    echo "Instalada en /Applications/$APP"
fi
