# Features and file behavior

[Русский](../ru/features.md) · [Documentation](index.md) · [Quick start](quick-start.md) · [CLI](cli.md)

Sorta provides three folder-based actions on **macOS 15.1+ with Apple Silicon**. This page describes the current source; see [release status](releases.md) for distribution information. Start with a small set of copies and keep deletion disabled, as shown in the [quick start](quick-start.md).

## Sort photos

Choose a source and target folder. The sorter reads supported media in the source tree and offers these settings:

| Setting | Effect |
|---|---|
| **Rename files to date format** | Uses the date-based name format, for example `2026-06-15--14-30.jpg`. |
| **Fix metadata (creation/modification dates)** | Updates file date attributes on the resulting file using an available date. |
| **Create folder structure in destination** | Organizes output inside the target as `Photos/Year/Month` or `Videos/Year/Month`. |
| **Delete after processing** | Off: keep source files and copy the output. On: move files from the source. |
| **Set custom date** | Available when automatic metadata correction is turned off; applies the selected date to the resulting file's attributes. |

Renaming, date correction and folder structure start enabled. Deletion starts disabled.

**The folder-structure setting determines where sorting output goes.** When it is disabled, the operation uses each file's existing source folder. Keep it enabled to place output in the selected target. If a resulting path is identical to its source, that file may stay in place without creating a new copy.

Date-based names and folders use the date found during analysis. A custom date changes the resulting file's date attributes; it does not choose the name or year/month folders for that run. Existing filenames receive a numeric suffix when a separate output name is needed. Check the messages if a file has no usable date or cannot be processed.

## Convert DNG → HEIC

Select a folder containing DNG files. The converter also finds DNG files in subfolders and writes the HEIC results into the **selected root folder**. It does not reproduce the source subfolder hierarchy. Name collisions receive a numeric suffix.

**Delete after processing** is off by default. If enabled, a DNG source is removed after its conversion succeeds. Keep it off while checking image quality, orientation and dates.

HEIC conversion uses lossy compression. The implementation carries supported image metadata and file dates into the result, but the available metadata and rendered image can differ. Keep DNG originals for RAW editing and archival purposes. The GUI has no PNG-to-HEIC action; that operation is available in the [CLI companion](cli.md).

## Fix dates

This action updates supported media in the selected folder and its subfolders. With **Set custom date** off, it uses the earliest usable date found in the file's available date information. With the option on, it applies your chosen date.

The operation changes filesystem date attributes, including creation/modification dates and the content-creation attribute where applicable. It does not rewrite the image's embedded EXIF `DateTimeOriginal` field. The earliest available date is not proof of the real capture time, so inspect representative files first.

There is no separate target folder for this action. Work on copies even though it has no deletion switch.

## Files and operation scope

Sorting and date tools recognize these extensions:

| Group | Extensions |
|---|---|
| Images | `jpg`, `jpeg`, `png`, `tiff`, `bmp`, `gif`, `webp`, `heic` |
| Video | `mpg`, `m4v`, `mp4`, `mov`, `avi`, `mkv`, `flv`, `wmv` |

DNG is handled by the dedicated conversion action; it is not in the sorting/date-tool extension list. Recognizing an extension does not guarantee that every file of that type has usable date information. Processing depends on file contents and access permissions.

Folder scans include subfolders and skip symbolic links. The interface works with files in folders selected through the system picker or drag and drop. Review the selected paths before starting, especially on external or network storage.

## Progress and cancellation

The operation screen shows progress and error messages. **Cancel** requests a stop; finishing the current file can take time. The app keeps processing protected until work has actually stopped, and prevents closing or quitting while it is still active. Cancellation keeps changes already completed; it is not an undo operation.

After the operation ends, **Back to start** clears the current workflow so you can choose another source. File-operation logs are not a backup of the photographs.

## Language, appearance and developer links

Open **Settings** from the main screen or with **Command-,**. Choose System, Light or Dark appearance, and Русский or English. These choices are saved locally and update app-owned windows, Help, Important Information, dates and existing log messages without restarting a task.

macOS-provided menu commands, Services and file-dialog controls use the system language. The initial app language follows a supported macOS preference; a saved explicit choice takes precedence.

Settings and **About Sorta** include the developer's [Boosty](https://boosty.to/andreytorlopov), [Sorta source](https://github.com/andrey-torlopov/Sorta), the [CLI repository](https://github.com/andrey-torlopov/PhotoSorterCLI) and contact information. The CLI is separate and is not required to run Sorta.

---

[Documentation](index.md) · [Quick start](quick-start.md) · [Data and privacy](data-and-privacy.md) · [CLI](cli.md) · [README](../../README.md) · [Русский](../ru/features.md)
