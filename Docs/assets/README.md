# Sorta artwork

Four original vector compositions are used by the English and Russian documentation:

- `banner-en.svg` and `banner-ru.svg` — 1920 × 480; Sorta's name and message, invented landscape photo cards, and folders grouped by date.
- `workflow-en.svg` and `workflow-ru.svg` — 1600 × 420; a small set of copies with deletion off → checking the result → the full archive with a separate backup.

These are conceptual illustrations, **not screenshots**. The backup step is an action for the user; it does not depict an automatic backup feature. Dates and landscapes are illustrative. No personal photographs, third-party artwork, audio assets, embedded font files, scripts, or external images are included. The geometry is original SVG code; fonts use local Arial/Helvetica/sans-serif fallbacks. The palette follows Sorta's indigo accent (`#6E8BFF`) and dark/light surfaces, with violet illustration details.

The four SVG artworks listed above are dedicated to the public domain under [CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/). This dedication applies only to those four SVG files; it does not set a license for the application code or other repository contents.

Regenerate and validate the four SVG files from the `Macos` repository root:

```sh
python3 Docs/tools/generate_artwork.py
python3 Docs/tools/validate_docs.py
```

The generator uses only Python's standard library, runs without network access, and produces deterministic SVG. The SVG files render directly on GitHub. App Store screenshots must remain separate real app captures.

## Русский

Баннеры и схема нарисованы специально для Sorta в виде SVG-кода. Фотокарточки, пейзажи и даты — условные иллюстрации, а не скриншоты и не личные фотографии. Чужие изображения, аудио-оформление, внешние ресурсы, встроенные файлы шрифтов и скрипты не используются.

Четыре перечисленных SVG-иллюстрации переданы в общественное достояние на условиях [CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/). Условия CC0 распространяются только на эти четыре SVG-файла и не устанавливают лицензию для кода приложения или других материалов репозитория.

Схема предлагает начать с небольшого набора копий, оставить удаление оригиналов выключенным, проверить результат и только затем обработать архив с отдельной резервной копией. Резервную копию готовит пользователь; иллюстрация не обещает автоматическое резервное копирование в приложении. Команды выше воспроизводят все четыре SVG без дополнительных библиотек и проверяют документацию. Для App Store нужны реальные снимки приложения.
