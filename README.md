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
| `libre` | F-Droid, Firefox, K-9 Mail, TermOne Plus, KDE Connect | Sharing: the one `release.sh` will publish. |
| `full` | `libre` + Google apps + Magisk root | A daily driver with everything. |

```sh
PRESET=clean ./forge/bootstrap.sh        # start here -- it needs no inputs you have to find
PRESET=full  ./forge/bootstrap.sh
OPTIONS="root" ./forge/bootstrap.sh      # or pick options directly, no preset needed
```

Presets live in `device.conf`; options live in the forge and work on any device. Adding an option to
a preset is one word — there is no per-device wiring to write. The app options in `libre` carry
patches for lineage-22.2 and 23.2 (`k9`, `kdeconnect` and `termoneplus` also 20.0); on another
branch, drop the ones without a patch set from the preset or the build stops at its option check.

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
