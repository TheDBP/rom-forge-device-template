# Build a LineageOS ROM for your phone

A ready-to-use template for building a custom Android (LineageOS) ROM for a device you own.
Clone it, run one script, and it works out the rest.

Everything happens inside Docker. No JDK, no Python, no repo tool, no build dependencies scattered
across your machine — just Docker, git, and disk.

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
| `clean` | nothing | The baseline. Nothing proprietary baked in. |
| `libre` | F-Droid, Fulguris, K-9 Mail, TermOne Plus, KDE Connect, ConnectBot, Linphone | Sharing: the one `release.sh` will publish. |
| `full` | `libre` + Google apps + Magisk root | A daily driver with everything. |

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

An option only works on a branch it carries patches for. Put one in a preset on a branch without
them and the build stops at the option check — deliberately, rather than quietly shipping an image
missing what you asked for. On `lineage-24.0` only the app options and `gapps` are ready so far;
the look-and-behaviour set has no 24.0 patches yet.

| option | what it does | branches with patches |
|---|---|---|
| `advanced-restart` | Advanced restart in the power menu | 18.1, 19.1, 20.0, 22.2, 23.2 |
| `connectbot` | ConnectBot: an SSH client with saved hosts, keys and port forwarding | 20.0, 22.2, 23.2, 24.0 |
| `dark-default` | Default to dark theme | 20.0, 21.0, 22.2, 23.2 |
| `fdroid` | F-Droid app store + Privileged Extension (silent installs/updates) | 22.2, 23.2, 24.0 |
| `firefox` | Firefox (Fennec F-Droid) as the browser, replacing Jelly — still available, no preset carries it now | 22.2, 23.2, 24.0 |
| `fulguris` | Fulguris as the browser, replacing Jelly | 20.0, 22.2, 23.2, 24.0 |
| `gapps` | Google apps: Play Store and GMS from MindTheGapps, plus Google's versions of the stock apps | 18.1, 19.1, 20.0, 21.0, 22.2, 23.2, 24.0 |
| `google-feed-off` | Google feed (-1 screen) off by default | 18.1, 19.1, 20.0, 22.2, 23.2 |
| `home-defaults` | Home screen defaults: no icon labels, no auto-add | 18.1, 19.1, 20.0, 22.2, 23.2 |
| `k9` | K-9 Mail (the Thunderbird for Android codebase) as the mail client | 20.0, 22.2, 23.2, 24.0 |
| `kdeconnect` | KDE Connect (phone <-> desktop: notifications, clipboard, files, remote input) | 20.0, 22.2, 23.2, 24.0 |
| `linphone` | Linphone: a SIP client, for voice over data where the device has no VoLTE | 20.0, 22.2, 23.2, 24.0 |
| `linux` | On-device Linux environment (chroot + Docker): container kernel config and cgroup fixes | any |
| `livedisplay-off` | LiveDisplay off by default | 18.1, 19.1, 20.0, 22.2, 23.2 |
| `minimal-home` | Minimal home screen: hotseat only, no second page | 18.1, 19.1, 20.0, 22.2, 23.2 |
| `nav-icons` | Nextbit Robin style nav-bar icons, drawn as scalable tintable vectors | 20.0, 21.0, 22.2, 23.2 |
| `nextcloud` | Nextcloud bundle: Files, Talk, NextPush, Deck, NC Passwords, Notes, DAVx5, Tasks — the current F-Droid build of each | 20.0, 22.2, 23.2, 24.0 |
| `nextcloud-core` | Nextcloud, the four that make the phone a client: Files, Talk, NextPush, DAVx5 — the current F-Droid build of each | 20.0, 22.2, 23.2, 24.0 |
| `nfc-off` | NFC off by default | 18.1, 19.1, 20.0, 22.2, 23.2 |
| `oem` | The manufacturer's own boot animation, wallpapers and sounds, reclaimed from its stock ROM | any |
| `root` | Magisk baked into the boot image, so the zip flashes pre-rooted | any |
| `setupwizard-lineage` | Use Lineage SetupWizard over Google's (WITH_GAPPS) | 18.1, 19.1, 20.0 |
| `setupwizard-nag-skip` | Skip recovery/metrics/backup setup pages | 18.1, 19.1, 20.0, 22.2, 23.2 |
| `teal-skin` | Teal accent — fixed #009D94 Monet preset seed | 19.1, 20.0, 22.2, 23.2 |
| `teal-wallpaper` | Teal-shag default wallpaper (baked into framework-res) | any |
| `terminal-visible` | Show the Terminal app in the launcher | 18.1, 19.1 |
| `termoneplus` | TermOne Plus terminal emulator (F-Droid build) | 20.0, 22.2, 23.2, 24.0 |
| `themed-icons` | Themed (monochrome) app icons on by default | 19.1, 20.0, 22.2, 23.2 |

The app options (`fdroid`, `firefox`, `fulguris`, `k9`, `termoneplus`, `kdeconnect`, `nextcloud`,
`nextcloud-core`) ship no APK of their own: each downloads the build F-Droid currently suggests at
sync time and verifies it against a pinned signing certificate, so an image carries the app as it
was on the day it was built. `FDROID_PINS` in `device.conf` holds one to a versionCode when you
need to reproduce a release or hold back a bad update.

`firefox` and `fulguris` are both the browser, replacing Jelly, and are mutually exclusive.
`fulguris` is what the example presets carry: Fennec stages 320 MB against Fulguris's 9 MB, which
is the difference between fitting and not on a smaller device. Fennec has not gone anywhere --
swap the names in `device.conf` if you have the room and want it.
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

## Support

This is unpaid work on phones their makers abandoned. If a build saved one from the drawer, [a donation](https://www.paypal.com/donate/?hosted_button_id=7U8PDZLK7742Q) keeps the next one coming.

## License

Apache-2.0 — see `LICENSE`. The ROM you build is LineageOS, under its own licences. Proprietary
blobs and Google apps are **not** included and are not ours to redistribute — the tooling helps you
extract them from hardware or images you already have.
