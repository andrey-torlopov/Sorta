# Quick start

[Русский](../ru/quick-start.md) · [Documentation](index.md) · [Features](features.md) · [CLI](cli.md)

This guide describes the current Sorta source for **Apple Silicon Macs with macOS 15.1 or later**. Check [release status](releases.md) for availability. Developers can follow [source setup](development.md).

## 1. Prepare a small working copy

Copy a few representative photos into a separate test folder. JPG, PNG and HEIC are useful for a first sorting run; test DNG files separately with the converter. Keep your original archive and backup outside that working folder.

Create an empty destination folder outside the test source folder. This makes the first sorting result easy to inspect without including earlier output in a later source scan.

## 2. Read Important Information

On first launch, Sorta displays a mandatory information window. The **Close** button shows a countdown and becomes available after **30 seconds**. Read the text, then click Close; the timer does not accept it for you.

You can reopen the same screen from **Help → Important Information**. After the first acknowledgement, repeated viewing has an immediately available Close button.

## 3. Select the source

Click **Choose source folder** on the main screen and select the test folder. You can also drop a folder into the selection area. If macOS asks you to confirm access, select that folder in the system dialog.

Processing includes supported files in subfolders. Symbolic links are skipped. The source selection leads to three actions:

| Action | What it uses |
|---|---|
| **Sort photos** | A source folder and a separately selected target folder. |
| **Convert DNG → HEIC** | DNG files in the selected folder and its subfolders; HEIC output goes into the selected root folder. |
| **Fix dates** | Supported media in the selected folder and its subfolders; date changes are applied there. |

## 4. Try sorting with originals kept

Choose **Sort photos**, then **Choose target folder** and select the empty destination.

For the first run, keep **Create folder structure in destination** enabled and **Delete after processing** disabled. Review **Rename files to date format** and **Fix metadata (creation/modification dates)** according to the result you want, then click **Run**.

With folder structure enabled, output is organized under `Photos/Year/Month` and `Videos/Year/Month` in the target. Deletion is off by default; sorting copies files instead of moving them. [Features](features.md) explains what happens when the folder-structure option is disabled.

## 5. Inspect the result

Read the operation messages, open several output files, and compare their appearance, names and dates with the test sources. Keep **Delete after processing** off until the results suit your needs and your backup is confirmed. Only then expand to a larger set.

Use **Cancel** if you need to stop. Sorta may finish the current file before it stops; wait for the final state. Completed changes are retained. When processing has ended, **Back to start** returns to source selection.

For DNG conversion, keep deletion off and compare HEIC quality with the RAW source. HEIC uses lossy compression and does not preserve the editing flexibility of DNG. **Fix dates** updates files in the selected working folder, so use copies for that action too.

## 6. Choose language and appearance

Open **Settings** on the main screen or press **Command-,**. Choose **System**, **Light** or **Dark**, and **Русский** or **English**. The choice applies immediately and survives a restart.

Already-open app windows and existing operation messages follow the selected language. Changing settings keeps the selected folders, operation options and running task. System-provided menu entries and file-dialog controls use the macOS language.

For more help, open **Help → Sorta Help**, or see [data and privacy](data-and-privacy.md) and [support](../../SUPPORT.md).

---

[Documentation](index.md) · [Features](features.md) · [CLI companion](cli.md) · [README](../../README.md) · [Русский](../ru/quick-start.md)
