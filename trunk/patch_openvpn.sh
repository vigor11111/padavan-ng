#!/usr/bin/env bash
set -e

OPENVPN_DIR="user/openvpn/openvpn-2.5.9"
PATCHES=(
  "02-tunnelblick-openvpn_xorpatch-a.diff"
  "03-tunnelblick-openvpn_xorpatch-b.diff"
  "04-tunnelblick-openvpn_xorpatch-c.diff"
  "05-tunnelblick-openvpn_xorpatch-d.diff"
  "06-tunnelblick-openvpn_xorpatch-e.diff"
)

# Проверка уже пропатчено (например, по .patched)
if [[ -f "$OPENVPN_DIR/.patched" ]]; then
  echo "OpenVPN уже пропатчен"
  exit 0
fi

cd "$OPENVPN_DIR"

# Применяем основной патч если есть
if [[ -f "../../../openvpn-orig.patch" ]]; then
  patch -p1 < "../../../openvpn-orig.patch"
fi

# Скачиваем и применяем патчи Tunnelblick
for patch in "${PATCHES[@]}"; do
  if [[ ! -f "$patch" ]]; then
    wget "https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/sources/openvpn/openvpn-2.5.9/patches/$patch"
  fi
  git apply "$patch"
done

touch .patched
echo "Патчи OpenVPN применены"
