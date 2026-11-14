# Sorta

Native macOS application for organizing photographs, converting DNG images to HEIC,
and correcting file dates. Photo operations use
[PhotoSorterCore](https://github.com/andrey-torlopov/PhotoSorterCore).

## Requirements and availability

- macOS 15.1 or later.
- Apple Silicon (arm64) for the first release.
- The intended application distribution channel is the Mac App Store. A public
  store release is not established by the presence of this source tree.

## Safe first use

On first launch, read the mandatory information screen. Its Close button becomes
available after 30 seconds. Start with a small set of **copies**, keep **Delete after
processing** disabled, inspect the output and preserve a backup of the originals
before processing a full archive. The same information is available from
**Help → Important Information**.

## Settings

Open **Settings** on the main screen or press **Command-,**. Select **System**,
**Light** or **Dark** appearance and **Русский** or **English**. Changes apply
immediately and are saved between launches. Existing operation logs are displayed
in the selected language; changing presentation settings does not restart an
operation. macOS-owned dialog controls and system-provided menu entries follow
the macOS language.

The developer section is available in Settings and About Sorta. It includes
[Boosty](https://boosty.to/andreytorlopov), support contact information,
[Sorta source code](https://github.com/andrey-torlopov/Sorta) and the
[PhotoSorterCLI repository](https://github.com/andrey-torlopov/PhotoSorterCLI).
The CLI uses the same photo-processing engine through macOS Terminal. It is a
separate application; installing it is not required to use Sorta.

## Source project

Open `MacosApp.xcodeproj` in Xcode and select the shared `MacosApp` scheme.
The project pins the remote PhotoSorterCore package to version `0.0.2`; keep its
SwiftPM lockfile with the source. Signing and release preparation are described
in [Docs/release.md](Docs/release.md).

See [support](Docs/support.md) and [privacy](Docs/privacy.md). Store descriptions
under `Docs` are preparation material, not evidence of an approved or published
App Store release.

## По-русски

Sorta — приложение для macOS: сортировка фотографий, конвертация DNG в HEIC и
исправление дат файлов. Первый выпуск предназначен для Apple Silicon и macOS
15.1 или новее. Планируемый канал распространения — Mac App Store.

При первом запуске обязательно прочитайте важную информацию; кнопка закрытия
станет доступна через 30 секунд. Сначала обработайте небольшой набор копий,
оставьте «Удалить после обработки» выключенным, проверьте результат и сохраните
резервную копию оригиналов. Повторно открыть экран можно в меню
«Помощь → Важная информация».

Кнопка «Настройки» на главном экране и сочетание **Command-,** открывают выбор
темы (система, светлая, тёмная) и языка (Русский, English). Выбор применяется сразу
и сохраняется между запусками. Язык уже существующего журнала тоже меняется;
обработка от этого не перезапускается. Системные элементы диалогов и меню могут
оставаться на языке macOS.

В настройках и окне «О программе» есть информация об авторе, Boosty, ссылки на
[исходники Sorta](https://github.com/andrey-torlopov/Sorta) и PhotoSorterCLI.
Консольная версия использует то же ядро обработки через Терминал
macOS и устанавливается отдельно. Для работы Sorta она не нужна.
