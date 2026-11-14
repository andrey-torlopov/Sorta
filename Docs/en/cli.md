# The command-line companion

[Русский](../ru/cli.md) · [Documentation](index.md) · [Quick start](quick-start.md) · [GUI features](features.md)

[PhotoSorterCLI](https://github.com/andrey-torlopov/PhotoSorterCLI) provides interactive photo tools in macOS Terminal. It shares [PhotoSorterCore](https://github.com/andrey-torlopov/PhotoSorterCore) with Sorta and is installed separately. Sorta works without the CLI.

The GUI has three action cards. The CLI exposes six menu operations, including PNG conversion and a filename/date check that have no separate GUI action. The commands, language options and input defaults below describe the **prepared CLI 0.2.0 candidate**.

## Requirements and availability

The CLI requires **macOS 15.0 or later**; the first packaged candidate targets **Apple Silicon (arm64)**. Sorta's GUI requirement is macOS 15.1+.

As of **14 November 2026**, public CLI `main` is still **0.1.0**. A signed **0.2.0** package has been prepared, while its source/tag publication, notarization and public package release remain pending. Follow the [CLI repository](https://github.com/andrey-torlopov/PhotoSorterCLI) and [release status](releases.md) for publication. The current public source does not establish support for the 0.2.0 options or safe input defaults described here.

## Start CLI 0.2.0 when available

First confirm that **0.2.0 or a newer version has actually been published**, then follow that version’s installation or source-build instructions. For an older copy, use its matching documentation. After obtaining 0.2.0, the following commands check its version/help and open the English interface:

```sh
photos-sorter-cli --version
photos-sorter-cli --help
photos-sorter-cli --language en
```

The last command opens the interactive menu. Choose a number, then enter the paths and options requested. This is an interactive interface: operation names and file paths are not command-line subcommands.

The packaged executable is intended for `/usr/local/bin/photos-sorter-cli`. A packaged installation does not require Xcode; source builds have their own prerequisites in the CLI repository.

## Six operations

| Number | Menu operation | Result |
|---|---|---|
| 1 | Convert DNG to HEIC | Converts DNG files; deletion of sources is optional and off by default. |
| 2 | Sort files into Photos(Videos)/Year/Month | Copies or moves supported media, with optional date-based renaming and date correction. |
| 3 | Fix dates in files | Updates supported media file date attributes from available date information. |
| 4 | Set a specific date in files | Applies the date you enter to supported media file date attributes. |
| 5 | Check filename dates against internal dates | Reports name/date mismatches without changing the checked files. |
| 6 | Convert PNG to HEIC | Converts PNG files, with the same optional source deletion as DNG conversion. |

Choose **0** to exit the menu. Folder scans include subfolders. DNG/PNG conversion collects output in the selected root folder. Sorting uses the destination tree when folder structure is enabled; without it, each file's existing folder is used. [GUI file-behavior details](features.md) describe the shared date and format boundaries.

## Language and input in 0.2.0

Use `--language ru` or `--language en`; `--lang` is an alias. The choice applies to that invocation and is not saved. CLI language selection is independent of Sorta's Settings.

Without the flag, the first non-empty value in `LC_ALL`, `LC_MESSAGES`, then `LANG` selects the language. Supported choices are Russian and English; unsupported explicit locales use English. If those variables are absent, the CLI checks supported macOS preferred languages, then uses English.

Both interfaces accept `yes`/`no`, `y`/`n`, `да`/`нет` and `д`/`н`. Enter selects the displayed default; the deletion default is **No**. At an input prompt, **Ctrl-D** cancels incomplete input and exits. `--help` and `--version` only print information and do not process photographs.

## Use working copies

Start with a small sample and keep deletion off. Review the sorting configuration before confirming it. Date operations modify the selected files in place; conversion uses lossy HEIC. Cancellation or leaving the program does not restore changes already completed.

Inspect output, dates and diagnostics before expanding to a full archive. For questions, use [support](../../SUPPORT.md) or the CLI project's own documentation.

---

[Documentation](index.md) · [GUI features](features.md) · [Data and privacy](data-and-privacy.md) · [Release status](releases.md) · [README](../../README.md) · [Русский](../ru/cli.md)
