#!/usr/bin/env bash
# start-here.sh — the friendly front door. Run this first.
#
# Works out what phone you're targeting, checks whether LineageOS has the pieces, writes
# device.conf for you, and tells you honestly how hard this port is likely to be.
#
#   ./start-here.sh              # plug the phone in, or answer one question
#   ./start-here.sh --codename bonito --branch lineage-22.2
set -o pipefail
cd "$(dirname "$0")"

b()  { printf '\033[1m%s\033[0m\n' "$*"; }
ok() { printf '  \033[32m✓\033[0m %s\n' "$*"; }
no() { printf '  \033[31m✗\033[0m %s\n' "$*"; }
hm() { printf '  \033[33m!\033[0m %s\n' "$*"; }
say(){ printf '  %s\n' "$*"; }

CODENAME=""; BRANCH=""
while [ $# -gt 0 ]; do
  case "$1" in
    --codename) CODENAME="$2"; shift 2;;
    --branch)   BRANCH="$2";   shift 2;;
    -h|--help)  sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) shift;;
  esac
done

echo
b "Building a LineageOS ROM for your phone"
echo
say "This gets you a custom Android build for a device you own. Everything happens"
say "inside Docker, so it will not install a toolchain all over your machine."
echo
b "Before we start, the honest version:"
say "• You need roughly 350 GB of free disk and a few hours for the first source sync."
say "• If LineageOS already supports your phone, this is mostly waiting."
say "• If it does not, you are porting -- that is a real project, measured in days,"
say "  and it may not work at all. This tool will tell you which one you are in."
say "• Flashing a custom ROM can brick a phone. Use one you can afford to lose."
echo

# ---- 1. host prerequisites ----
b "1. Checking your machine"
FAIL=0
if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then ok "Docker is installed and running"
  else no "Docker is installed but not running (or needs sudo). Start it, then re-run."; FAIL=1; fi
else no "Docker is not installed -- https://docs.docker.com/engine/install/"; FAIL=1; fi
command -v git >/dev/null 2>&1 && ok "git" || { no "git is not installed"; FAIL=1; }
AVAIL=$(df -BG --output=avail . 2>/dev/null | tail -1 | tr -dc '0-9')
if [ -n "$AVAIL" ]; then
  if [ "$AVAIL" -ge 350 ]; then ok "disk: ${AVAIL} GB free"
  elif [ "$AVAIL" -ge 200 ]; then hm "disk: ${AVAIL} GB free -- tight. 350 GB is comfortable."
  else no "disk: only ${AVAIL} GB free. You want ~350 GB."; FAIL=1; fi
fi
RAM=$(free -g 2>/dev/null | awk '/Mem:/{print $2}')
[ -n "$RAM" ] && { [ "$RAM" -ge 16 ] && ok "RAM: ${RAM} GB" || hm "RAM: ${RAM} GB -- builds may be slow or need a lower JOBS"; }
[ "$FAIL" = 1 ] && { echo; say "Fix the ✗ items above and run this again."; exit 1; }
echo

# ---- 1.5 make sure the engine is current ----
# A downloaded template can be months old. Pull the current engine before doing anything, so
# nobody debugs a problem that was fixed upstream long ago. Offline or a failed fetch is fine --
# the vendored copy still works.
b "1b. Updating the build engine"
if [ -x ./forge/tools/sync-forge.sh ]; then
  BEFORE=$(grep -m1 '^commit=' forge/FORGE_REF 2>/dev/null | cut -d= -f2 | cut -c1-12)
  if ./forge/tools/sync-forge.sh >/dev/null 2>&1; then
    AFTER=$(grep -m1 '^commit=' forge/FORGE_REF 2>/dev/null | cut -d= -f2 | cut -c1-12)
    if [ "$BEFORE" != "$AFTER" ]; then ok "engine updated: ${BEFORE:-none} -> ${AFTER:-?}"
    else ok "engine already current (${AFTER:-?})"; fi
  else
    hm "could not reach the engine repo -- using the bundled copy (${BEFORE:-?})"
  fi
fi
echo

# ---- 2. which phone ----
b "2. Which phone?"
if [ -z "$CODENAME" ] && command -v adb >/dev/null 2>&1; then
  DEV=$(adb devices 2>/dev/null | awk 'NR>1 && $2=="device"{print $1; exit}')
  if [ -n "$DEV" ]; then
    CODENAME=$(adb -s "$DEV" shell getprop ro.product.device 2>/dev/null | tr -d '\r')
    MODEL=$(adb -s "$DEV" shell getprop ro.product.model 2>/dev/null | tr -d '\r')
    [ -n "$CODENAME" ] && ok "found a connected phone: $MODEL (codename: $CODENAME)"
  fi
fi
if [ -z "$CODENAME" ]; then
  say "Every Android device has a short codename -- a Pixel 3a XL is 'bonito',"
  say "an LG V20 is 'vs995'. Look yours up on the LineageOS wiki if unsure."
  echo
  printf "  Codename: "; read -r CODENAME
fi
[ -z "$CODENAME" ] && { no "Need a codename to continue."; exit 1; }
echo

# ---- 3. does LineageOS have the pieces? ----
b "3. Looking up $CODENAME upstream"
REPO=""
for guess in $(curl -s "https://api.github.com/search/repositories?q=android_device+$CODENAME+org:LineageOS" 2>/dev/null \
               | grep -oE '"full_name": *"LineageOS/android_device_[^"]*"' | sed 's/.*"LineageOS/LineageOS/;s/"//g'); do
  case "$guess" in *_"$CODENAME") REPO="$guess"; break;; esac
done
if [ -z "$REPO" ]; then
  hm "No LineageOS device tree found for '$CODENAME'."
  say "Either the codename is wrong, or nobody has ported this device."
  say "You can still continue, but you will be writing the device tree yourself --"
  say "that is the hardest kind of port."
else
  ok "device tree: https://github.com/$REPO"
  BRANCHES=$(git ls-remote --heads "https://github.com/$REPO" 2>/dev/null \
             | grep -oE 'lineage-[0-9]+(\.[0-9]+)?$' | sort -Vu)
  NEWEST=$(echo "$BRANCHES" | tail -1)
  PREV=$(echo "$BRANCHES" | tail -2 | head -1)
  say "branches: $(echo $BRANCHES | tr '\n' ' ')"

  # A HIGHER branch number is not always NEWER code: devices get branched and then abandoned,
  # leaving the "newest" branch an ANCESTOR of the older one. Basing a port on it silently
  # discards everything the older branch gained since. Ask GitHub rather than guessing -- the
  # compare API gives ahead_by without needing a clone.
  if [ -z "$BRANCH" ] && [ -n "$PREV" ] && [ "$PREV" != "$NEWEST" ]; then
    AHEAD=$(curl -s "https://api.github.com/repos/$REPO/compare/$PREV...$NEWEST" 2>/dev/null \
            | grep -m1 -oE '"ahead_by": *[0-9]+' | grep -oE '[0-9]+')
    if [ "${AHEAD:-1}" = "0" ]; then
      hm "$NEWEST exists but is NOT ahead of $PREV -- it was branched and abandoned."
      say "Using $PREV instead, which has the newer code."
      say "(This is real: the Pixel 3a XL's lineage-23.0 is an ancestor of its lineage-22.2.)"
      BRANCH="$PREV"
    else
      BRANCH="$NEWEST"
    fi
  fi
  [ -z "$BRANCH" ] && BRANCH="$NEWEST"
  ok "targeting: $BRANCH"
fi
echo

# ---- 4. write device.conf ----
b "4. Writing device.conf"
if [ -n "$REPO" ]; then
  # new-device-repo.sh refuses to write into an existing directory (rightly -- it is a scaffolder).
  # Generate into a temp dir and copy the two files we actually want out of it.
  TMPD=$(mktemp -d)
  if ./forge/tools/new-device-repo.sh --codename "$CODENAME" ${BRANCH:+--branch "$BRANCH"} \
        "$TMPD/gen" >/dev/null 2>&1 && [ -f "$TMPD/gen/device.conf" ]; then
    cp -f "$TMPD/gen/device.conf" ./device.conf
    if [ -d "$TMPD/gen/overlay/local_manifests" ]; then
      mkdir -p overlay/local_manifests
      cp -f "$TMPD/gen/overlay/local_manifests/"*.xml overlay/local_manifests/ 2>/dev/null || true
    fi
    ok "device.conf and overlay/local_manifests/ filled in"
    UNSET=$(grep -cE '^[A-Z_]+=[[:space:]]*(#|$)' device.conf 2>/dev/null); UNSET=${UNSET:-0}
    [ "$UNSET" -gt 0 ] 2>/dev/null && hm "$UNSET key(s) still blank in device.conf -- open it and fill them in"
  else
    hm "could not auto-fill; edit device.conf by hand"
  fi
  rm -rf "$TMPD"
else
  hm "skipped -- no upstream tree to read from. Edit device.conf by hand."
fi
echo

# ---- 5. what next ----
b "You're set up. What happens next:"
echo
say "  ./bootstrap.sh                 build it (hours the first time)"
say "  PRESET=clean ./bootstrap.sh    build without Google apps or root"
say "  PRESET=libre ./bootstrap.sh    the same plus F-Droid, K-9, ConnectBot -- the one you can publish"
echo
say "The ROM lands in build_output/artifacts/ (a copy that survives the next build)"
echo
b "If you are porting to a branch your device does not officially support:"
say "  ./forge/tools/check-platform-support.sh build_output/src device/<vendor>/$CODENAME"
say "runs before any build and tells you what upstream has quietly dropped for your"
say "chip. It is the cheapest hour you will spend. See forge/docs/porting-a-branch-bump.md."
echo
say "When a build fails, do not fix one error per cycle:"
say "  KEEP_GOING=true ./bootstrap.sh"
say "  ./forge/tools/triage-build-log.sh build_output/logs/build.log"
echo
say "Good luck. forge/GOTCHAS.md is where the scars are written down."
echo
