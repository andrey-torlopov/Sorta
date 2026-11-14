# Sorta — подготовленные тексты App Store

Статус: тексты обновлены 14 ноября для кандидата с настройками темы и языка;
эти тексты не загружены в App Store Connect. Уже загруженный build 1 не содержит
новые настройки; перед отправкой нужен проверенный build с ними.
Подтверждено владельцем 13 ноября 2026 года: бесплатное приложение, первый выпуск
только для Apple Silicon (arm64), прежних публичных установок не было.
Назначение номера версии, стран, возраста, support/privacy HTTPS URLs и
проверка утверждений на финальном build остаются условиями отправки.

## Русский

Название: **Sorta**

Подзаголовок: **Порядок в фотоархиве**

Ключевые слова: `фото,сортировка,архив,метаданные,дата,DNG,HEIC,фотографии,папки`

Описание:

Sorta помогает навести порядок в фотографиях на Mac. Выберите папку и нужное
действие: сортировку фото по датам, преобразование DNG в HEIC или исправление дат.

При сортировке можно создавать структуру папок, переименовывать файлы по дате
и выбирать сохранение исходников. Преобразование DNG в HEIC и исправление дат
выполняются в выбранной папке. Перед запуском проверьте настройки операции.

Обработка выполняется локально. Sorta не загружает ваш фотоархив на сервер.
Доступ к папкам предоставляется через системный диалог macOS. Интерфейс и справка
доступны на русском и английском языках.
Язык можно переключить в настройках на главном экране. Там же доступны системная,
светлая и тёмная темы; выбор сохраняется между запусками.

Фотографии незаменимы. Сначала обработайте небольшой набор копий, не включайте
«Удалить после обработки» и проверьте результат. Переходите ко всему архиву только
после проверки и сохраняйте резервную копию оригиналов. Важная информация всегда
доступна в меню «Помощь».

Текст изменений:

Обязательное знакомство с правилами безопасной обработки при первом запуске,
повторный просмотр важной информации через меню помощи, окно с информацией об авторе,
настройки системной, светлой и тёмной темы, переключение русского и английского
языков без перезапуска и корректное ожидание завершения отмены.

## English

Name: **Sorta**

Subtitle: **Organize your photo archive**

Keywords: `photo,sort,archive,metadata,date,DNG,HEIC,pictures,folders`

Description:

Sorta helps organize photographs on your Mac. Select a folder and choose an action:
sort photos by date, convert DNG files to HEIC, or correct file dates.

Sorting can create a folder structure, rename files using dates, and preserve the
originals. DNG conversion and date correction work in the selected folder. Review
the operation settings before starting.

Processing happens locally. Sorta does not upload your photo archive to a server.
You grant folder access through the macOS system dialog. The interface and help
are available in English and Russian.
Switch languages in Settings on the main screen. Choose System, Light, or Dark
appearance; your preferences are saved between launches.

Your photographs are irreplaceable. Start with a small set of copies, leave
“Delete after processing” turned off, and check the results. Only process your
entire archive after checking the results, and keep a backup of the originals.
You can always reopen Important Information from the Help menu.

What's New:

Required first-launch guidance for safer photo processing, Important Information
in the Help menu, developer information, System/Light/Dark appearance settings,
English/Russian language switching without restarting, and cancellation that keeps
the operation locked until work has actually stopped.

## App Review notes

Sorta is a free local photo utility for Apple Silicon Macs running macOS 15.1 or later. It does not require an
account or an installed CLI. On first launch, Important Information appears over
the main window. The Close button counts down for 30 seconds, then becomes enabled.
Press Close to complete onboarding. Help → Important Information opens the same
text immediately after completion. Sorta → About Sorta opens developer information.
The Settings button on the main screen and Sorta → Settings open appearance and
language controls. Changes apply immediately without resetting the selected folder
or operation state. System-owned menu commands and file dialog controls may use the macOS language.

Use a temporary folder containing copied test images. Choose a folder through the
system picker and select an operation. For sorting, choose a different destination
folder and keep originals. DNG conversion needs a DNG fixture. Avoid deleting
originals during evaluation. Cancellation keeps navigation locked while the active
operation finishes stopping.

Separate GitHub links open the Sorta GUI and related PhotoSorterCLI repositories.
The CLI uses the same processing engine through macOS Terminal. Boosty opens the
developer's external profile; no Sorta capability is unlocked through it. The
support action opens the user's mail application. External destinations apply their
own privacy policies. The actual Boosty content and applicable storefront rules
must be checked before submission.

## Материалы, которые зависят от проверки build

- Скриншоты RU/EN: главный экран, настройки языка/темы, настройка сортировки, процесс,
  важная информация, окно «О программе». Снимать фактический интерфейс кандидата.
- TestFlight: первый и повторный запуск, все три GUI-операции, сохранение исходников,
  отказ доступа, отмена, длинные пути, RU/EN, сохранение темы/языка, Apple Silicon.
- App Privacy: локальные фото не передаются разработчику; подтвердить финальным аудитом
  приложения и зависимостей. Веб-сайты и почтовое приложение открываются отдельно.
- Availability, возрастная анкета, соглашения, export compliance и публичные
  URLs требуют фактических ответов владельца и состояния App Store Connect.
