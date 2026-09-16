# Сборка под Windows

Целевая версия игры — 2.1.2500. Разрядность — win32 (i386): только в 32-битной сборке
работают скриптовые DLL модов и грузятся родные 32-битные `okgf.dll`, `MatrixGame.dll`,
`xvidcore.dll` из установки игры.

> Проверено на Windows 11 со стоковым FPC 3.2.2 (i386-win32): сборка проходит, собранный exe
> запускается из папки игры и доходит до главного меню (звук, все экраны). Форк `vendor/fpc`
> для этого не нужен.

## Шаг 1. Игра

- Купить и установить обычным способом (Steam или GOG). Запускать не обязательно.
- Записать путь установки — он нужен в шагах 4 и 6. Примеры:
  Steam — `C:\Games\Steam\steamapps\common\Space Rangers HD A War Apart`,
  GOG — `C:\Games\Space Rangers HD A War Apart`.

## Шаг 2. Git

- Скачать и установить
  <https://github.com/git-for-windows/git/releases/download/v2.55.0.windows.5/Git-2.55.0.5-64-bit.exe> —
  настройки по умолчанию.
- Проверка: в консоли `git --version` печатает версию.

## Шаг 3. Репозиторий

```bat
git clone --recurse-submodules https://github.com/pakompom/SpaceRangersHD_FPC.git
cd SpaceRangersHD_FPC
```

Проверка: `git submodule status` печатает две строки — `vendor/fpc` и `vendor/okgf`, каждая
начинается с пробела (не с `-`).

## Шаг 4. FPC и SDL2

1. Скачать и установить FPC 3.2.2 (93.9 МБ):
   <https://sourceforge.net/projects/freepascal/files/Win32/3.2.2/fpc-3.2.2.win32.and.win64.exe/download>
   Проверка: `fpc -iV` печатает версию. Проверять в **новой** консоли — `PATH` подхватывается
   только новыми процессами. Если команда всё равно не найдена, добавить в `PATH` папку
   `bin\i386-win32` из установки FPC.
2. Скачать SDL2 2.32.10 (32-битный):
   <https://github.com/libsdl-org/SDL/releases/download/release-2.32.10/SDL2-2.32.10-win32-x86.zip>
   Из архива нужен один файл — `SDL2.dll` (~1,3 МБ, лежит в корне архива). Положить его
   **в папку игры из шага 1**.
   - SDL3 брать нельзя: код грузит библиотеку с именем `SDL2.dll`, а API у SDL3 другой.

## Шаг 5. Сборка

Из корня репозитория:

```bat
tools\build-win32.cmd
```

- Результат — `.local\win32\Rangers.exe`; папку скрипт создаёт сам, создавать её вручную не
  нужно.

## Шаг 6. Скопировать в папку игры

После шага 5 собранный `Rangers.exe` лежит в `.local\win32`. Сохраните оригинальный Rangers.exe под другим именем и скопируйте новый собранный Rangers.exeсборку в папку игры из шага 1


## Для информации: чем Windows-сборка отличается от macOS/Android

Стоковый FPC 3.2.2 старше закреплённого в `vendor/fpc` (3.3.1), поэтому для x86 понадобились
правки:

| Правка                                      | Где                                                                                                            | Причина                                                                                                                                                                                                                                       |
|---------------------------------------------|----------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `{$POINTERMATH ON}` под `{$IFDEF CPUX86}`   | `source/GameOptions.inc`                                                                                       | в режиме DELPHI FPC включает pointer-арифметику только для fpc/objfpc, а кодогенератору x86 она нужна для выражений вроде `Integer + PChar`; на остальных целях те же выражения компилируются и без директивы, поэтому правка привязана к x86 |
| хелпер `Widen` вместо каста `Extended(...)` | `source/arcade/ab_Global.pas`, `source/core/aMyFunction.pas`                                                   | на x86 FPC запрещает жёсткие касты `Double`/`Single` ↔ `Extended`; на aarch64 `Extended` = `Double`, поэтому там касты были пустышками                                                                                                        |
| `set of 0..39` вместо `set of 8..39`        | `source/screens/fRuinsTalk.pas`                                                                                | внутренняя ошибка кодогенератора x86 (200306031) на `in`/`Include` для множества с ненулевой базой                                                                                                                                            |
| `GameEvents` в `uses`                       | `source/screens/fLoad.pas`, `source/script/aScript.pas`, `source/game/aSaveLoad.pas`, `source/scene/fFilm.pas` | `INFINITE` объявлен только в `platform/GameEvents.pas`, а эти юниты его не подключали                                                                                                                                                         |
| новый юнит `TlHelp32`                       | `platform/TlHelp32.pas`                                                                                        | в FPC нет Delphi-совместимого `TlHelp32`: есть только `jwatlhelp32` из поставки JEDI, а он тянет `jwawinbase`, где `TCriticalSection` объявлен как `CRITICAL_SECTION`                                                                         |
| `Math` после `Windows` — только на Windows  | `source/GR_Main.pas`, implementation `uses`                                                                    | `Windows` объявляет `min`/`max` для LongInt и скрывает перегрузки `Math` для вещественных аргументов; вне Windows порядок `uses` оставлен прежним                                                                                             |
| `SyncObjs.TCriticalSection.Create`          | `source/GR_Main.pas`                                                                                           | `Windows` объявляет `TCRITICALSECTION` (FPC не различает регистр) и перекрывает класс из `SyncObjs`                                                                                                                                           |
| скрипт сборки                               | `tools/build-win32.cmd`                                                                                        | аналог `tools/build.py` для Windows                                                                                                                                                                                                           |
| свои импорты Vorbis                         | `source/audio/VorbisFile.pas`                                                                                  | игра поставляет `libvorbisfile.dll`, а пакет FPC жёстко привязывает `vorbisfile.dll`; теперь exe импортирует то же имя, что грузит и сам движок                                                                                               |
