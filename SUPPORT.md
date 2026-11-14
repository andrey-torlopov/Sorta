# Поддержка Sorta / Sorta Support

[Русский](#русский) · [English](#english)

## Русский

Sorta помогает сортировать фотографии, конвертировать DNG в HEIC и исправлять даты файлов на Mac. Требуется **macOS 15.1 или новее и Apple Silicon**. Разработчик — **Andrey Torlopov**; помощь: [mail@torlopov.dev](mailto:mail@torlopov.dev).

Исходники опубликованы, но публичный выпуск в Mac App Store ещё не выполнен. Настройки языка и темы описаны для текущего кандидата **1.0.0 (2)**; ранее загруженная в Apple сборка 1 их не содержит. [Состояние выпуска](Docs/ru/releases.md) отделяет эти версии.

### Первый запуск и пробная обработка

1. Прочитайте обязательное информационное окно. Кнопка подтверждения станет доступна после 30-секундного отсчёта.
2. Подготовьте копии небольшого набора фотографий и отдельную папку назначения.
3. Для первой сортировки оставьте структуру папок включённой, а удаление оригиналов — выключенным.
4. Проверьте файлы результата, имена, даты и место сохранения. Только затем переходите к большой коллекции, сохраняя независимую резервную копию.

Повторно открыть предупреждение можно через **Помощь → Важная информация**. Подробная инструкция — [быстрый старт](Docs/ru/quick-start.md).

### Результат оказался не там или дата не изменилась

При отключённой структуре папок сортировка использует исходный каталог каждого файла; выбранное назначение не становится плоской папкой результата. При конвертации DNG вложенные файлы читаются рекурсивно, а HEIC сохраняются в выбранной корневой папке.

Исправление дат меняет даты файловой системы и атрибут создания содержимого, а не EXIF `DateTimeOriginal`. Разные программы могут показывать разные поля даты. Укажите в обращении, где именно вы смотрели дату. См. [функции и ограничения](Docs/ru/features.md).

### Папка недоступна или обработка не начинается

Проверьте, что папка существует и открывается в Finder, внешний диск подключён, а исходные файлы доступны локально. Выберите папку ещё раз через системное окно. Перетаскивание иногда требует дополнительного подтверждения доступа. Для назначения нужна запись; для перемещения или удаления — также запись в исходную папку.

iCloud Drive и другие поставщики файлов могут требовать загрузки и подключения к сети. Для диагностики попробуйте копии нескольких файлов в обычной локальной папке и отдельное доступное назначение. Не обходите системные ограничения доступа вслепую и не удаляйте оригиналы для исправления ошибки.

### Настройки, язык и остановка

Кнопка **«Настройки»** на главном экране или **⌘,** открывает темы **Системная / Светлая / Тёмная** и языки **Русский / English**. Выбор применяется сразу и сохраняется. Дополнительные окна и существующие записи журнала переводятся; системные команды меню и части диалогов macOS могут сохранять язык системы.

Смена языка и темы не перезапускает обработку. Запрос остановки не откатывает уже выполненные файловые изменения; дождитесь окончания работы и проверьте журнал и результат. Встроенного восстановления удалённых оригиналов нет.

### Сообщить о проблеме

В письме укажите:

- версию и номер сборки Sorta из окна «О программе», версию macOS и модель Mac;
- операцию и включённые параметры, последовательность действий;
- формат файла и место хранения: локальный диск, внешний том или поставщик файлов;
- ожидаемый и фактический результат, текст ошибки или обезличенный фрагмент журнала.

Не требуется отправлять коллекцию фотографий. Сначала воспроизводите проблему на копиях; перед отправкой примера или скриншота уберите личные имена, полные пути, геометки и частное содержимое. Переписка добровольна; см. [конфиденциальность](PRIVACY.md).

### Автор и связанные проекты

[Boosty](https://boosty.to/andreytorlopov) — страница автора и добровольной поддержки. [Исходники Sorta](https://github.com/andrey-torlopov/Sorta) и [PhotoSorterCLI](https://github.com/andrey-torlopov/PhotoSorterCLI) опубликованы в отдельных репозиториях. CLI работает через Терминал с тем же ядром, но набор доступных команд отличается; для Sorta устанавливать CLI не нужно. Его локально подписанный кандидат 0.2.0 ещё ожидает notarization и публикации.

[Полная документация](Docs/ru/index.md) · [Данные и файлы](Docs/ru/data-and-privacy.md) · [Состояние выпуска](Docs/ru/releases.md)

## English

Sorta helps sort photographs, convert DNG to HEIC and correct file dates on a Mac. It requires **macOS 15.1 or later and Apple Silicon**. Developer: **Andrey Torlopov**. For help, email [mail@torlopov.dev](mailto:mail@torlopov.dev).

The source is public, but a public Mac App Store release has not been completed. Language and appearance settings are described for the current **1.0.0 (2)** candidate; the earlier build 1 uploaded to Apple does not include them. [Release status](Docs/en/releases.md) distinguishes these versions.

### First launch and a small trial

1. Read the mandatory information window. Its acknowledgement button becomes available after the 30-second countdown.
2. Prepare copies of a small photo sample and a separate destination folder.
3. For the first sorting run, keep folder structure enabled and deletion of originals disabled.
4. Check the resulting files, names, dates and destination. Only then move on to a larger collection, keeping an independent backup.

Reopen the information through **Help → Important Information**. See the [quick start](Docs/en/quick-start.md) for the complete walkthrough.

### Unexpected destination or unchanged date

With folder structure disabled, sorting uses each file's original directory; the selected destination does not become a flat output folder. DNG conversion reads subfolders recursively but writes HEIC files into the selected root folder.

Date correction changes filesystem dates and the content-creation-date attribute, not EXIF `DateTimeOriginal`. Different applications can display different date fields. Include where you checked the date when reporting an issue. See [features and limitations](Docs/en/features.md).

### A folder is unavailable or processing will not start

Check that the folder exists and opens in Finder, the external drive is connected, and source files are available locally. Select the folder again through the system picker. Drag and drop sometimes needs additional access confirmation. The destination needs write access; moving or deleting also needs write access in the source folder.

iCloud Drive and other providers can require downloading and a network connection. For diagnosis, try copies of a few files in an ordinary local folder and a separate writable destination. Do not bypass system access restrictions blindly or delete originals to work around an error.

### Settings, language and stopping

The **Settings** button on the main screen or **⌘,** opens **System / Light / Dark** appearance and **Русский / English** language choices. Changes apply immediately and persist. Auxiliary windows and existing log entries are translated; system-owned menu commands and macOS dialog controls may retain the system language.

Changing language or appearance does not restart processing. Requesting a stop does not roll back completed file changes; wait for work to finish and inspect the log and results. There is no built-in recovery of deleted originals.

### Report a problem

Include:

- the Sorta version and build from About, your macOS version and Mac model;
- the operation, enabled options and steps to reproduce it;
- the file format and location: local disk, external volume or file provider;
- expected and actual results, and the error text or a non-personal log excerpt.

You do not need to send your photo collection. Reproduce the problem using copies first. Before sending a sample or screenshot, remove personal names, full paths, location metadata and private content. Correspondence is voluntary; see [privacy](PRIVACY.md).

### Developer and related projects

[Boosty](https://boosty.to/andreytorlopov) is the developer's page for voluntary support. [Sorta source](https://github.com/andrey-torlopov/Sorta) and [PhotoSorterCLI](https://github.com/andrey-torlopov/PhotoSorterCLI) have separate repositories. The CLI runs through Terminal with the same engine, but its command set differs; Sorta does not require it to be installed. Its locally signed 0.2.0 candidate is still awaiting notarization and publication.

[Full documentation](Docs/en/index.md) · [Data and files](Docs/en/data-and-privacy.md) · [Release status](Docs/en/releases.md)

---

[README · English](README.md) · [README · Русский](README-ru.md)
