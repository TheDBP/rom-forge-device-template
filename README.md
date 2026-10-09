# Build a LineageOS ROM for your phone

A ready-to-use template for building a custom Android (LineageOS) ROM for a device you own.
Clone it, run one script, and it works out the rest.

The *build* happens inside Docker. No JDK, no repo tool, no build dependencies scattered across
your machine — just Docker, git, and disk. (`start-here.sh` and the scaffolder it calls also use
`curl`, `python3` and `rsync` on the host; they check for them and say so.)

```sh
git clone https://github.com/TheDBP/rom-forge-device-template.git my-phone
cd my-phone
./start-here.sh
```

`start-here.sh` checks your machine, works out which phone you have (plug it in via USB, or type
its codename), looks up whether LineageOS has the pieces, fills in the config, and tells you
honestly how hard your particular port is likely to be.

---

## What you can build

One command produces one image. A **preset** is a saved set of **options**:

| Preset | Adds | Good for |
|---|---|---|
| `clean` | nothing (plus whatever you put in `COMMON_OPTIONS`) | The baseline, and what `release.sh` publishes: it takes the first preset whose options contain neither `gapps` nor `oem`. |
| `libre` | F-Droid, K-9 Mail, KDE Connect, ConnectBot | A no-Google daily driver. |
| `full` | `libre` + Google apps | A daily driver with everything. |
| `stock` | nothing — not even `COMMON_OPTIONS` | Every device has this without declaring it. Device patches and nothing else, so "is this bug mine or upstream's?" has an answer. (`STOCK_OPTIONS` in `device.conf` is the exception: options the phone needs to work at all.) |

```sh
PRESET=clean ./forge/bootstrap.sh        # start here -- it needs no inputs you have to find
PRESET=full  ./forge/bootstrap.sh
OPTIONS="root" ./forge/bootstrap.sh      # or pick options directly, no preset needed
```

Queueing builds, or launching one unattended? Use `./forge/tools/run-one.sh . <preset> <extras>`
instead. It refuses to start while another build is running — two AOSP builds on one machine is an
OOM kill — and writes a timestamped log with a start and finish line a watcher can read.

Presets live in `device.conf`; options live in the forge and work on any device. Adding an option to
a preset is one word — there is no per-device wiring to write.

Only an option's **patches** are branch-scoped — its `product.mk`, fetched APKs and hooks apply
everywhere. So the column below is coverage, not permission: `fdroid` has no `lineage-20.0` patch
and still ships in that build, because there it only has to fetch the APK. An option is refused on a
branch just when it has patches for other branches and nothing else to contribute here — then the
build stops at the option check rather than quietly shipping an image missing what you asked for.

<!-- options:start -->

| option | what it does | branches with patches |
|---|---|---|
| `advanced-restart` | Advanced restart in the power menu. | 18.1, 19.1, 20.0, 22.2, 23.2, 24.0 |
| `bringup` | adbd from boot with no authorisation prompt, plus persistent logcat, so a build that never reaches the lock screen can still be traced. **Never hand out an image built with this** — it accepts adb from any host. | any |
| `connectbot` | ConnectBot: an SSH client with saved hosts, keys and port forwarding. Pulls in `fdroid`. | 20.0, 22.2, 23.2, 24.0 |
| `dark-default` | Default to dark theme. | 20.0, 21.0, 22.2, 23.2, 24.0 |
| `drm-trace` | Diagnostic: kernel trace of whoever disables a DRM plane or CRTC, for a panel that dies while the framework still thinks it is on. | any |
| `fdroid` | F-Droid app store + Privileged Extension (silent installs/updates). | 22.2, 23.2, 24.0 |
| `firefox` | Firefox (Fennec F-Droid) as the browser, replacing Jelly. Pulls in `fdroid`. Mutually exclusive with `fulguris`. **In no preset**: it overrides Jelly, and stages 320 MB against Fulguris's 9. | 22.2, 23.2, 24.0 |
| `fulguris` | Fulguris as the browser, replacing Jelly. Pulls in `fdroid`. A WebView browser, 9 MB where Fennec stages 320 MB. Mutually exclusive with `firefox`. **In no preset**: it overrides Jelly, so a preset carrying it ships the only browser in the image, and its first run asks you to accept terms with nothing else able to open them. | 20.0, 22.2, 23.2, 24.0 |
| `gapps` | Google apps: Play Store and GMS from MindTheGapps, plus Google's versions of the stock apps. | 18.1, 19.1, 20.0, 21.0, 22.2, 23.2, 24.0 |
| `google-feed-off` | Google feed (-1 screen) off by default. | 18.1, 19.1, 20.0, 22.2, 23.2, 24.0 |
| `home-defaults` | Home screen defaults: no icon labels, no auto-add. | 18.1, 19.1, 20.0, 22.2, 23.2, 24.0 |
| `k9` | K-9 Mail (the Thunderbird for Android codebase) as the mail client. Pulls in `fdroid`. | 20.0, 22.2, 23.2, 24.0 |
| `kdeconnect` | KDE Connect (phone <-> desktop: notifications, clipboard, files, remote input). Pulls in `fdroid`. | 20.0, 22.2, 23.2, 24.0 |
| `linphone` | Linphone: a SIP client, for voice over data where the device has no VoLTE. Pulls in `fdroid`. | 20.0, 22.2, 23.2, 24.0 |
| `linux` | On-device Linux environment (chroot + Docker): container kernel config and cgroup fixes. | any |
| `livedisplay-off` | LiveDisplay off by default. | 18.1, 19.1, 20.0, 22.2, 23.2, 24.0 |
| `minimal-home` | Minimal home screen: hotseat only, no second page. | 18.1, 19.1, 20.0, 22.2, 23.2, 24.0 |
| `nav-icons` | Nextbit Robin style nav-bar icons, drawn as scalable tintable vectors. | 20.0, 21.0, 22.2, 23.2, 24.0 |
| `nextcloud` | Nextcloud bundle: Files, Talk, NextPush, Deck, NC Passwords, Notes, DAVx5, Tasks — the current F-Droid build of each. Pulls in `fdroid`. ~600 MB against `nextcloud-core`'s ~270. Check the partition before adding either. | 20.0, 22.2, 23.2, 24.0 |
| `nextcloud-core` | Nextcloud, the four that make the phone a client: Files, Talk, NextPush, DAVx5 — the current F-Droid build of each. Pulls in `fdroid`. Mutually exclusive with `nextcloud`, which already carries these four. | 20.0, 22.2, 23.2, 24.0 |
| `nfc-off` | NFC off by default. | 18.1, 19.1, 20.0, 22.2, 23.2, 24.0 |
| `oem` | The manufacturer's own boot animation, wallpapers and sounds, reclaimed from its stock ROM. Needs that phone's own stock ROM and a pack that understands its layout — see `forge/docs/OEM-ASSETS.md`. | any |
| `openvpn` | OpenVPN for Android (de.blinkt.openvpn) as a bundled VPN client. Pulls in `fdroid`. | 20.0, 22.2, 24.0 |
| `pong-notification` | Pong as the default notification sound (LineageOS default is Argon). | 20.0, 22.2, 24.0 |
| `root` | Magisk baked into the boot image, so the zip flashes pre-rooted. Pulls in `termoneplus`. The image flashes pre-rooted, so treat it like one. | any |
| `setup-mobile-data` | Mobile data usable during setup, instead of a sign-in page with no way online but Wi-Fi. | 20.0, 24.0 |
| `setupwizard-lineage` | Use Lineage SetupWizard over Google's (WITH_GAPPS). | 18.1, 19.1, 20.0, 24.0 |
| `setupwizard-nag-skip` | Skip recovery/metrics/backup setup pages. | 18.1, 19.1, 20.0, 22.2, 23.2, 24.0 |
| `syncthing-fork` | Syncthing-Fork: continuous file sync between your own devices, no server or account. Pulls in `fdroid`. | 20.0, 22.2, 23.2, 24.0 |
| `teal-skin` | Teal accent — fixed #009D94 Monet preset seed. | 19.1, 20.0, 22.2, 23.2, 24.0 |
| `teal-wallpaper` | Teal-shag default wallpaper (baked into framework-res). | any |
| `terminal-visible` | Show the Terminal app in the launcher. | 18.1, 19.1 |
| `termoneplus` | TermOne Plus terminal emulator (F-Droid build). Pulls in `fdroid`. | 20.0, 22.2, 23.2, 24.0 |
| `themed-icons` | Themed (monochrome) app icons on by default. | 19.1, 20.0, 22.2, 23.2, 24.0 |
| `volte` | The manufacturer's own IMS stack, rebuilt from its stock firmware, so the phone can place calls over LTE. Turns itself on when the phone's stock firmware is present and off when it is not, marking the build tag `-novolte` — see `forge/options/volte/README.md`. | any |

<!-- options:end -->
The app options (`connectbot`, `fdroid`, `firefox`, `fulguris`, `k9`, `kdeconnect`, `linphone`,
`nextcloud`, `nextcloud-core`, `openvpn`, `syncthing-fork`, `termoneplus`) ship no APK of their own: each downloads the build F-Droid currently suggests at
sync time and verifies it against a pinned signing certificate, so an image carries the app as it
was on the day it was built. `FDROID_PINS` in `device.conf` holds one to a versionCode when you
need to reproduce a release or hold back a bad update.

`firefox` and `fulguris` are both the browser, replacing Jelly, and are mutually exclusive.
Fennec stages 320 MB against Fulguris's 9 MB, which is the difference between fitting and not on a
smaller device.

**Neither is in the example presets, on purpose.** Both *override* Jelly rather than installing
beside it, so a preset carrying one ships it as the only browser in the image — and both ask you to
accept a privacy policy and terms on first run, which nothing else can open. Leaving them out keeps
Jelly, Lineage's own browser, which is in the base image anyway. Add one deliberately:

```sh
EXTRA_OPTIONS=fulguris PRESET=full ./forge/bootstrap.sh
```
The same goes for `nextcloud` (~600 MB) against `nextcloud-core` (~270 MB). Check the partition
before adding any of them: an image that does not fit fails hours in, when it is assembled.

## What it does for you

- **Reproducible builds in Docker** — the same image every time, on any Linux host
- **Behaviour changes as composable options** — themed icons on, Google feed off, NFC off, minimal
  home screen, no setup-wizard nags. Enable per device in `device.conf`; they are patch sets, not
  forks
- **Bakes in what you want** — Google apps, Magisk root, F-Droid, Firefox, your own wallpaper and
  boot animation
- **Tools for hard ports** — for pushing a device onto an Android version it was never supported on

## Who this is for

**Your phone is officially supported by LineageOS.** This is mostly a convenience wrapper: it
builds a signed ROM with your choices baked in, without you learning the AOSP build system. Sync
the source, and it works.

**Your phone was supported once, but has been dropped.** This is where the tooling earns its keep.
You are carrying a device tree forward yourself, which is a substantially bigger job. Read
[`forge/docs/porting-a-branch-bump.md`](forge/docs/porting-a-branch-bump.md) before you start.

**Your phone was never supported at all.** No LineageOS repo for your codename means no device
tree, and that is a porting job rather than configuration. Options, roughly in order of pain:

- **A tree exists but not in LineageOS.** Common for popular phones — check the maintainer's GitHub,
  XDA, or another ROM project, then point `overlay/local_manifests/` at it. This is usually fine.
- **A close sibling has a tree.** Same SoC and similar hardware can often be adapted. "Similar" is
  doing a lot of work in that sentence, but it beats starting blank.
- **Nothing at all.** Writing a device tree from scratch means partition layout, kernel, HAL wiring
  and SELinux policy. Months, not evenings. This template will not do that for you, though
  everything around it still helps once you have a tree.

Whichever it is, the tree plugs in the same way: point the local manifest at it. And run
`./forge/tools/check-platform-support.sh` once the source is synced — it reports what the port will
cost before you write any code.

## Being realistic

Some of this is genuinely hard, and it is better to know up front:

- **A first sync downloads the entire Android source tree.** Later builds reuse it and ccache.
- **Old hardware fights back.** A 2016 phone on Android 13 may need patches to the platform itself
  because its kernel predates features Android now assumes exist. That is normal for this kind of
  port and the docs cover the common ones.
- **Flashing can brick a phone.** Use a device you can afford to lose. Wiping is routine here.
- **It might not work.** Some ports die on something unfixable. The checks here are built to tell
  you that before you have invested in a build.

## When a build fails

Do **not** fix one error per build cycle. Collect them all first:

```sh
KEEP_GOING=true PRESET=clean ./forge/bootstrap.sh               # keep going past errors
./forge/tools/triage-build-log.sh build_output/logs/build.log   # collapse into distinct causes
```

Then check [`forge/GOTCHAS.md`](forge/GOTCHAS.md) — it is a list of things that have gone wrong
before, indexed by the error you are staring at.

## When it boots but something is broken

A build that boots and then misbehaves is a different job from one that will not compile. Each of
these is a worked method, not a description:

| Doc | For |
|---|---|
| [`forge/docs/debugging-a-boot-loop.md`](forge/docs/debugging-a-boot-loop.md) | It builds but will not boot. |
| [`forge/docs/debugging-a-vendor-blob.md`](forge/docs/debugging-a-vendor-blob.md) | A prebuilt HAL that worked on the old branch and crashes on the new one. |
| [`forge/docs/debugging-a-dead-panel.md`](forge/docs/debugging-a-dead-panel.md) | The screen goes black and stays black while the framework still reports the display on. |
| [`forge/docs/porting-a-branch-bump.md`](forge/docs/porting-a-branch-bump.md) | Moving the device to a newer Android — checks to run before the first build. |
| [`forge/docs/lineage-branches.md`](forge/docs/lineage-branches.md) | Choosing a branch, and avoiding a higher number that is actually older code. |
| [`forge/docs/debugging-mobile-data.md`](forge/docs/debugging-mobile-data.md) | It registers on the network and no data flows. |
| [`forge/docs/debugging-volte.md`](forge/docs/debugging-volte.md) | Calls fall back to 2G/3G, or connect with no audio — and porting an OEM IMS stack in the first place. Needs the phone's stock firmware; the doc opens with what to extract. |
| [`forge/docs/OEM-ASSETS.md`](forge/docs/OEM-ASSETS.md) | Putting the manufacturer's own boot animation, wallpapers and sounds back on the build. |
| [`forge/docs/TOOLS.md`](forge/docs/TOOLS.md) | Every tool the forge ships, what it answers, and which doc uses it. |

## Signing and publishing

A build signed with AOSP's public test keys is fine to flash and not fine to hand out. Make your own
once, outside every repo, and point at them from the gitignored `device.conf.local`:

```sh
./forge/tools/make-keys.sh --src build_output/src /home/me/keys/rom '/C=US/O=Me/CN=Me/emailAddress=me@example.org'
echo 'KEYS_DIR=/home/me/keys/rom' >> device.conf.local
```

Additive: a newer branch wants keys the last one did not, so re-run it after a branch bump and only
the missing ones are made.

Publish with `./forge/tools/release.sh`, not by uploading a zip: it takes the first preset with
neither Google apps nor reclaimed manufacturer assets, audits the image (not the label), refuses
test-key builds, and makes the GitHub release with sha256s. Details in
[`forge/docs/RELEASING.md`](forge/docs/RELEASING.md).

## Tools worth knowing about

Run these **before** committing to a hard port. They need a synced source tree but no build, and can
save days.

| Tool | Answers |
|---|---|
| `check-platform-support.sh` | Which upstream makefile gates silently exclude my chip? |
| `check-hal-readiness.sh` | Which HALs are missing, and which will block boot if they fail? |
| `find-orphaned-sepolicy-types.sh` | Which SELinux types did the new branch delete? |
| `find-removed-platform-symbols.sh` | Which C symbols did it delete that my device still uses? |
| `triage-build-log.sh` | 200 build errors → the 3 actual causes |

## Layout

```
device.conf          the only file you must edit — every key documented
start-here.sh        interactive setup; run this first
bootstrap.sh         build (sync, patch, compile, package)
overlay/
  local_manifests/   extra git projects to sync
  patches/           your patches, applied after sync
forge/               the build engine (vendored; ./forge/tools/sync-forge.sh to update)
  options/           build options -- one capability each, usable on any device
```

## Updating the engine

```sh
./forge/tools/sync-forge.sh
```

Pulls the latest [rom-forge](https://github.com/TheDBP/rom-forge) into `forge/` and records the
commit in `forge/FORGE_REF`, so "which version is this?" is one `grep`.

`.github/workflows/sync-forge.yml` also runs this **every Monday 06:00 UTC** and commits the result
to your default branch. Two things follow from that, both worth knowing before you leave it on: the
sync is `rsync --delete`, so local edits inside `forge/` are discarded rather than merged — change
the engine upstream, or keep your changes in `overlay/patches/` where they belong — and the commits
come from a bot, unattended. Disable the workflow if you would rather update by hand.

## Support

The engine this template carries, [rom-forge](https://github.com/TheDBP/rom-forge), is unpaid work
on phones their makers abandoned. If it saved one from the drawer,
[a donation](https://www.paypal.com/donate/?hosted_button_id=7U8PDZLK7742Q) keeps the next one
coming. (Replace this section with your own once this repo is yours.)

## License

Apache-2.0 — see `LICENSE`. The ROM you build is LineageOS, under its own licences. Proprietary
blobs and Google apps are **not** included and are not ours to redistribute — the tooling helps you
extract them from hardware or images you already have.
