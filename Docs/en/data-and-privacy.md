# Data, files, and privacy

*[Русский](../ru/data-and-privacy.md)*

Sorta processes files in folders you select on your Mac. It does not import your collection into a managed photo library or send photographs to the developer. No account is required.

## Keep a separate copy of your photographs

Start with copies of a small, representative sample. Leave **deletion after processing disabled** and, for the first sorting run, leave **folder structure enabled** and select a separate destination. Open the results and check their names, dates, appearance, and destination before processing a larger collection.

Sorta has no built-in backup or undo for file operations. Cancellation stops further work where the operation supports it; it does not roll back files already written, moved, or changed. A successful operation log is not a substitute for checking the output or keeping an independent backup.

## What an operation can change

| Operation | Effect on files |
|---|---|
| Sorting | Copies files by default, with optional renaming and date-based folders. Enabling removal of originals changes the disposition to moving files. |
| Sorting without folder structure | Uses each file's original directory. This setting does **not** create a flat collection in the selected destination. |
| DNG → HEIC | Reads DNG files recursively and writes HEIC results into the selected root folder. It does not reproduce the source subfolder tree. Optional deletion removes the source after successful conversion. |
| Date correction | Changes filesystem dates and the file's content-creation-date attribute. It does not rewrite EXIF `DateTimeOriginal`. A manually chosen date is applied to the selected operation. |

Conversion is not a promise to preserve every RAW property or every metadata field. Compare results using files from your own camera or workflow. See [operation details and limitations](features.md).

## What stays on the Mac

| Data | Purpose and lifetime |
|---|---|
| First-launch acknowledgement | Stored in local application preferences after you acknowledge the information screen |
| Language and appearance | Stored locally and restored on the next launch |
| Selected folders, operation options, and progress | Current application-session state; the app does not maintain a persistent photo catalog |
| Operation log | In-memory messages that can include file names, paths, dates, and errors; not automatically uploaded or saved as a report |
| Processed files | Written to the locations determined by the operation; managed separately from application preferences |

The first information screen has a 30-second countdown on its acknowledgement button. Acknowledgement is recorded only after you press the enabled button. You can reopen the same information from **Help → Important Information**.

Changing the interface language also changes existing log messages. It does not rename your files, change an operation's selected date, or restart processing.

## Folder access and external providers

Select folders through the macOS folder picker or the application's drop area. A dropped folder may require confirmation in the system picker. Sorta uses the access granted for your selection; a missing, disconnected, or unwritable folder can prevent an operation.

Available local files can be processed without an internet connection. Files in iCloud Drive, on network storage, or with another provider may need a connection and downloading before they are available. Provider synchronization can also propagate file changes or deletions. Sorta does not provide its own cloud synchronization, and the provider's rules apply separately.

## Sharing information

Sorta includes no advertising, analytics SDK, or automatic transmission of photographs or operation logs to the developer. Boosty and GitHub links open an external browser; a support link opens your email application. Those services have their own data practices.

Before sending a screenshot, log excerpt, or sample, remove personal names, complete paths, location metadata, and private image content where possible. Sending a file to support is your choice. The [privacy policy](../../PRIVACY.md) describes local processing and voluntary correspondence; [support](../../SUPPORT.md) explains what helps diagnose a problem.

---

[Documentation](index.md) · [README](../../README.md) · [Support](../../SUPPORT.md)
