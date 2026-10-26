# patches/<branch>/<project>/ — engine patches

Applied by `tools/apply-overlay.sh` step 0, before every option and device patch, to **every device
and every preset** on that branch. Put a patch here only when the branch itself broke something that
any device with the same shape hits; device-specific fixes go in the device repo's
`overlay/patches/`, option-specific ones in `options/<name>/patches/<branch>/`.

Rules: generate from a pristine clone (`git clone --no-local`, GOTCHAS §14), `--zero-commit
--no-signature`, strip `Change-Id:`, verify with `git apply --check` against the synced project.
Don't stack a patch on top of another one's output; one problem, one patch.

| Branch | Project | Patch | Why |
|---|---|---|---|
| lineage-24.0 | `build/soong` | 0001 forward GOMEMLIMIT/GOGC | `soong_ui` starts `soong_build` with `env -i`, so `SOONG_MEM_LIMIT` never reached it; a 24.0 tree with a 32-bit second arch needs it or analysis OOMs on 30 GB + 38 GB swap. |
| lineage-24.0 | `build/soong` | 0002 fsgen: keep vendor-only modules out of the generated system image | A device with no vendor partition puts vendor in `system/vendor`, so `PartitionTag()` answers "system" for a vendor-only module and fsgen resolves it with the core variation: `missing variant: os:android,arch:arm64_armv8-a`. The mutator already skips ramdisk/recovery for the same reason; vendor and product join them. No-op where those partitions exist. |
| lineage-24.0 | `frameworks/base` | 0001 let an unowned preinstalled package adopt its sysconfig update owner | A sysconfig `<update-ownership>` entry only latched on a clean install. `InstallPackageHelper` takes it when `!pkgAlreadyExists || isSameUpdateOwner`, and `isSameUpdateOwner` requires a non-null recorded owner, so on an upgrade the else branch clears the owner every boot. An entry added to the image after a device first installed the app could never take effect, and because the bundled F-Droid APKs carry upstream's own certificate, Play recognises the signature and takes the app over. Eleven bundled apps on a dirty-flashed Pixel 3a XL, no owner on any of them. Adopts sysconfig when the recorded owner is null too; a real owner that disagrees, Play included, is still cleared. |
| lineage-24.0 | `vendor/lineage` | 0001 Revert "kernel: Rip out GCC support" | 24.0 builds every kernel with `LLVM=1` only. Kernels < 5.7 ignore it: `HOSTCC=gcc` (absent in the container, header genrule yields nothing, every UAPI-including HAL fails) and no binutils behind `CROSS_COMPILE`. Restores the pre-5.10 path behind `KERNEL_NO_GCC`; ≥ 5.10 unchanged. **Devices using it must add** `prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9` and `.../arm/arm-linux-androideabi-4.9` (LineageOS, `lineage-19.1`) to their local manifest — 24.0 dropped them. |
