# local_manifests

XML fragments telling `repo` about projects the upstream manifest does not carry: your device tree,
its kernel, the vendor blobs, and anything else the device needs.

Minimal example — replace the names with your device's:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <project name="LineageOS/android_device_<vendor>_<codename>"
           path="device/<vendor>/<codename>" remote="github" revision="lineage-22.2" />
  <project name="LineageOS/android_kernel_<vendor>_<soc>"
           path="kernel/<vendor>/<soc>" remote="github" revision="lineage-22.2" />
  <project name="TheMuppets/proprietary_vendor_<vendor>"
           path="vendor/<vendor>" remote="github" revision="lineage-22.2" />
</manifest>
```

Two things that will bite you:
- branch names differ per repo — check each with `git ls-remote` rather than assuming
- `--` is illegal inside an XML comment, and `repo sync` dies on it with "not well-formed"
