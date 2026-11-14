# Release status and verification

*[Русский](../ru/releases.md)*

**Recorded on November 14, 2026.** Sorta's source is public. A public Mac App Store release has not been completed. The local GUI candidate, the earlier Apple upload, and the separate CLI release are different deliverables.

## Sorta 1.0.0 (2): public source, local archive

The [Sorta repository](https://github.com/andrey-torlopov/Sorta) was published at commit [`a0193f1`](https://github.com/andrey-torlopov/Sorta/commit/a0193f18d4dd37fd1aa67ac6e6df44a787a88758). This source includes mandatory first-run information, Settings with Russian/English and System/Light/Dark choices, live localization of existing logs and auxiliary windows, and separate GUI/CLI links in the developer section.

| Item | Recorded result |
|---|---|
| Version / build | 1.0.0 (2) |
| System / architecture | macOS 15.1+, Apple Silicon arm64 |
| Processing dependency | Remote PhotoSorterCore exact 0.0.2 |
| Source publication | Public GitHub repository; fresh anonymous clone matched the reviewed source |
| Full unit baseline | 29 tests passed for Settings/localization before the final GUI-link change |
| Final GUI-link change | Fresh Debug build and 3 focused About tests passed |
| Manual checks | Live language/theme changes, retained selections, existing-log translation, a copied PNG, Settings with the main window closed, and GUI-link navigation verified |
| Release archive | Created from the published commit; **local ad-hoc signature** |
| Archive checks | arm64/deployment target, runtime dependencies, sandbox, resources, signature, and matching app/dSYM identifiers verified |
| App Store distribution export / upload of build 2 | Not performed |
| App Review / public App Store release | Not performed |

The 29-test baseline and the 3 focused tests describe different verification points; they are not a claim of a new 32-test full run. Logs, archives, source snapshots and checksums are retained by the maintainer outside the public source tree.

## Earlier App Store Connect upload: 1.0.0 (1)

Build **1**, uploaded on November 14, completed Apple upload/processing and was shown as **Validated**. That build predates the new Settings screen. The recorded TestFlight state was **Missing Compliance**, with no tester groups assigned; TestFlight installation was not verified. It was not submitted to App Review or publicly released.

The local build 2 does not replace that upload automatically. A new distribution export/upload, Apple processing, required metadata and review steps remain separate work. Source publication is not evidence that an App Store binary is available.

## PhotoSorterCLI and PhotoSorterCore

**PhotoSorterCLI 0.2.0** is a separate Terminal application using the same Core version. Its arm64 executable and PKG were signed locally with Developer ID; release process and real-file checks passed in Russian and English. **Notarization and GitHub Release publication remain pending** because the local notary profile is not ready. A signed local package is not yet a verified public download. See the [CLI guide](cli.md) and [CLI repository](https://github.com/andrey-torlopov/PhotoSorterCLI).

**PhotoSorterCore 0.0.2** is publicly tagged at [`6b97352`](https://github.com/andrey-torlopov/PhotoSorterCore/tree/0.0.2). Both applications pin that release. Shared algorithms do not mean that every CLI command has a matching GUI screen.

## Remaining verification boundaries

The first distribution target is arm64. Intel/universal runtime support, a clean installation and upgrade, and runtime on a separate Mac with the minimum supported macOS are not established by the current local results. Exercise external volumes, permissions, and file-provider behavior with representative copies before extending support claims.

For file-processing changes, verify results and source preservation on small samples, including failure and cancellation paths. Check names, dates, content and destination; a UI success message alone does not prove that every original was preserved. Sorta has no automatic rollback of completed file changes.

The [release runbook](../release.md) separates preflight, testing, archive, export, verification, Apple upload and publication. When a public release is actually available, update this page with the verified version, date and download/store link. Keep the [support](../../SUPPORT.md) and [privacy](../../PRIVACY.md) pages consistent with that binary.

---

[Documentation](index.md) · [README](../../README.md) · [Development](development.md)
