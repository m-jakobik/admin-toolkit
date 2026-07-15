#!/usr/bin/env bash
set -e

REPORT="/home/f3t1/Documents/Backups/app-export-mint-$(date '+%Y-%m-%d').txt"
mkdir -p "$(dirname "$REPORT")"

echo "📦 Collecting installed applications..."

# -----------------------------
# 🧩 Desktop apps (.desktop + flatpak + snap)
# -----------------------------

DESKTOP_APPS=$(
  (
    find /usr/share/applications ~/.local/share/applications 2>/dev/null \
      -name "*.desktop" -exec basename {} .desktop \;

    command -v flatpak >/dev/null 2>&1 && \
      flatpak list --app --columns=application 2>/dev/null

    command -v snap >/dev/null 2>&1 && \
      snap list 2>/dev/null | awk 'NR>1 {print $1}'
  ) | sort -u
)

# -----------------------------
# 🧠 Classification buckets
# -----------------------------

USER_APPS=""
DEV_TOOLS=""
DESKTOP_PKGS=""
SYSTEM_PKGS=""

while read -r pkg; do
  [[ -z "$pkg" ]] && continue

  # 🧩 USER APPS
  if echo "$pkg" | grep -Eq \
    "firefox|chrome|chromium|vlc|zathura|yt-dlp|libreoffice|keepassxc|transmission|rclone|virt-manager|wine|lutris|geany|meld"; then
    USER_APPS+="$pkg\n"
    continue
  fi

  # 🧪 DEV TOOLS
  if echo "$pkg" | grep -Eq \
    "git|node|npm|python|gcc|g\\+\\+|make|cmake|cargo|go|rust|pip|docker|clang|gdb"; then
    DEV_TOOLS+="$pkg\n"
    continue
  fi

  # 🖥️ DESKTOP / UI
  if echo "$pkg" | grep -Eq \
    "xfce|cinnamon|gnome|mate|thunar|nemo|xfwm|xfdesktop|lightdm|xapp|mint-|yaru|adwaita|xreader|xed|xviewer"; then
    DESKTOP_PKGS+="$pkg\n"
    continue
  fi

  # 🧱 everything else
  SYSTEM_PKGS+="$pkg\n"

done <<< "$DESKTOP_APPS"

# -----------------------------
# 📄 REPORT
# -----------------------------

{
  echo "🧾 MINT → DEBIAN MIGRATION REPORT"
  echo "Generated: $(date)"
  echo ""

  echo "=============================="
  echo "🧩 USER APPLICATIONS"
  echo "=============================="
  echo -e "$USER_APPS" | sort

  echo ""
  echo "=============================="
  echo "🧪 DEV TOOLS"
  echo "=============================="
  echo -e "$DEV_TOOLS" | sort

  echo ""
  echo "=============================="
  echo "🖥️ DESKTOP / UI STACK"
  echo "=============================="
  echo -e "$DESKTOP_PKGS" | sort

  echo ""
  echo "=============================="
  echo "🧱 SYSTEM / OTHER"
  echo "=============================="
  echo -e "$SYSTEM_PKGS" | sort

  echo ""
  echo "=============================="
  echo "📦 RAW APP LIST"
  echo "=============================="
  echo "$DESKTOP_APPS"

} > "$REPORT"

# -----------------------------
# 📊 SUMMARY
# -----------------------------

USER_COUNT=$(echo -e "$USER_APPS" | grep -c . || true)
DEV_COUNT=$(echo -e "$DEV_TOOLS" | grep -c . || true)
DESKTOP_COUNT=$(echo -e "$DESKTOP_PKGS" | grep -c . || true)
SYS_COUNT=$(echo -e "$SYSTEM_PKGS" | grep -c . || true)

echo "✅ Done!"
echo "📄 Report saved to: $REPORT"
echo ""
echo "📊 Summary:"
echo "   🧩 Apps:   $USER_COUNT"
echo "   🧪 Dev:    $DEV_COUNT"
echo "   🖥️ Desktop: $DESKTOP_COUNT"
echo "   🧱 System:  $SYS_COUNT"
sleep 3
