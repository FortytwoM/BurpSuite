# Burp Suite Loader

Java-агент `loader.jar` для Burp Suite Professional (Windows, установщик `.exe`): обходит проверку лицензии и генерирует ключи и ответы активации.

[Русский](#русский) · [English](#english)

## Состав проекта

| Файл | Назначение |
| --- | --- |
| `loader.jar` | готовый java-агент (результат сборки) |
| `BurpSuite.vmoptions` | опции JVM для Windows/Linux: `-javaagent:loader.jar` + `--add-opens` |
| `src/Loader.java` | агент (ASM): патчит классы Burp |
| `src/Filter.java` | обработчики лицензии и активации |
| `src/Keygen.java` | генерация ключа и ответа активации |
| `scripts/build_loader.ps1` / `.sh` | сборка `loader.jar` |
| `lib/` | ASM 9.5 (упаковывается внутрь jar) |

---

# Русский

## Шаг 1. Установите Burp Suite Professional

Запустите установщик `burpsuite_windows-x64_v2026_10_1.exe` и установите Burp.

- Каталог по умолчанию: `C:\Program Files\BurpSuiteProfessional`
- В конце установки **снимите галочку запуска Burp** — сначала настроим агент.

Проверить каталог можно так: правой кнопкой по ярлыку Burp → **Расположение файла**. Внутри должны быть:

```
BurpSuiteProfessional.exe
BurpSuite.vmoptions
jre\bin\java.exe
```

## Шаг 2. Получите loader.jar

**Вариант A — готовый jar.** Возьмите `loader.jar` из проекта.

**Вариант B — собрать самому.** Нужен JDK 21+:

```powershell
cd C:\путь\к\проекту
.\scripts\build_loader.ps1
```

Готовый `loader.jar` появится в корне проекта. ASM уже внутри, внешние библиотеки не нужны.

> Burp 2026 работает на Java 21+, поэтому jar, собранный с `--release 21`, подходит. Если ваша версия Burp старше, замените `--release 21` в скрипте на нужную версию.

## Шаг 3. Скопируйте loader.jar в каталог установки

PowerShell **от имени администратора** (запись в `Program Files` требует прав):

```powershell
Copy-Item .\loader.jar "C:\Program Files\BurpSuiteProfessional\loader.jar" -Force
```

Если вы устанавливали Burp в другой каталог, подставьте свой путь.

## Шаг 4. Замените BurpSuite.vmoptions

1. Сделайте резервную копию штатного файла:

   ```powershell
   Copy-Item "C:\Program Files\BurpSuiteProfessional\BurpSuite.vmoptions" `
             "C:\Program Files\BurpSuiteProfessional\BurpSuite.vmoptions.bak" -Force
   ```

2. Скопируйте файл из проекта поверх штатного:

   ```powershell
   Copy-Item .\BurpSuite.vmoptions `
             "C:\Program Files\BurpSuiteProfessional\BurpSuite.vmoptions" -Force
   ```

3. Убедитесь, что в файле есть строка запуска агента:

   ```
   -javaagent:loader.jar
   ```

   Если Burp не подхватывает агент (нет эффекта от лицензии), укажите абсолютный путь:

   ```
   -javaagent:C:\Program Files\BurpSuiteProfessional\loader.jar
   ```

4. Строки `--add-opens=...` из файла не удаляйте.

5. Если нужны свои параметры памяти (`-Xmx2g` и т.п.) — добавьте их отдельными строками: файл заменяется целиком, старые опции не сохраняются.

> **Обновления Burp.** При обновлении `BurpSuite.vmoptions` может быть перезаписан. Чтобы настройка сохранялась, сделайте копию файла с именем `user.vmoptions` в том же каталоге и держите строки агента там (Burp учитывает его вместе с основным файлом). После обновления также проверьте, что `loader.jar` на месте — при необходимости скопируйте заново.

## Шаг 5. Запустите Burp

Запустите ярлык **Burp Suite Professional** (или `BurpSuiteProfessional.exe` из каталога установки).

Агент считается загруженным, если Burp не требует действующую лицензию и проходит активация из Шага 6. Если лицензия не принимается — проверьте путь в `-javaagent` (см. Шаг 4, п. 3).

## Шаг 6. Сгенерируйте ключ и активируйте Burp

Используйте встроенную Java из Burp (своего JDK не требуется). В cmd:

```cmd
cd /d "C:\Program Files\BurpSuiteProfessional"
jre\bin\java.exe -cp loader.jar Keygen "Ваше имя"
```

В PowerShell:

```powershell
cd "C:\Program Files\BurpSuiteProfessional"
.\jre\bin\java.exe -cp loader.jar Keygen "Ваше имя"
```

Если каталога `jre` нет, используйте `java` из PATH (JDK 21+).

Далее:

1. Вставьте полученный ключ в окно активации Burp.
2. Выберите **Manual activation** → **Next**.
3. Скопируйте **Activation Request** из Burp.
4. Получите ответ:

   ```cmd
   cd /d "C:\Program Files\BurpSuiteProfessional"
   jre\bin\java.exe -cp loader.jar Keygen -activate "<REQUEST>"
   ```

5. Вставьте ответ в Burp → **Next**.

### Где задаются характеристики лицензии

- **Имя владельца** — аргумент команды `Keygen` (см. выше).
- **Срок действия и редакция** — константы в `src/Keygen.java`, метод `generateLicense`:
  - срок: `l.add("4102415999000");` — миллисекунды от 1970-01-01 (2099-12-31);
  - редакция: `l.add("full");`;
  - ID лицензии: `l.add(randomStr());`.

После правки пересоберите `loader.jar` (Шаг 2) и повторите Шаг 3.

## Если что-то не работает

- **Лицензия не принимается** — проверьте путь в `-javaagent`: при запуске из ярлыка относительный путь может не найтись, используйте абсолютный.
- **Burp не стартует** — проверьте синтаксис `BurpSuite.vmoptions` (по одной опции в строке), версию Java относительно `--release` и права администратора при замене файлов.
- **Нужно сбросить активацию** (Burp закрыт):

  ```powershell
  reg delete "HKCU\Software\JavaSoft\Prefs\burp" /f
  ```

## Другие ОС (кратко)

- **Linux:** каталог установки, файл `BurpSuite.vmoptions`, сборка `./scripts/build_loader.sh`.
- **macOS:** файл `vmoptions.txt` в `Burp Suite Professional.app/Contents`, сборка `./scripts/build_loader.sh`.

---

# English

## Step 1. Install Burp Suite Professional

Run `burpsuite_windows-x64_v2026_10_1.exe` and install Burp.

- Default installation directory: `C:\Program Files\BurpSuiteProfessional`
- At the end of installation, **clear the "launch Burp" checkbox** — the agent must be configured first.

To confirm the directory: right-click the Burp shortcut → **Open file location**. It should contain:

```
BurpSuiteProfessional.exe
BurpSuite.vmoptions
jre\bin\java.exe
```

## Step 2. Get loader.jar

**Option A — ready-made jar.** Use the `loader.jar` from this project.

**Option B — build it yourself.** Requires JDK 21+:

```powershell
cd C:\path\to\project
.\scripts\build_loader.ps1
```

The resulting `loader.jar` is placed in the project root. ASM is bundled inside, so no external libraries are needed.

> Burp 2026 runs on Java 21+, so a jar built with `--release 21` is compatible. For older Burp versions, change `--release 21` in the build script accordingly.

## Step 3. Copy loader.jar to the installation directory

Run PowerShell **as Administrator** (writing to `Program Files` requires elevation):

```powershell
Copy-Item .\loader.jar "C:\Program Files\BurpSuiteProfessional\loader.jar" -Force
```

If Burp is installed elsewhere, use your path.

## Step 4. Replace BurpSuite.vmoptions

1. Back up the original file:

   ```powershell
   Copy-Item "C:\Program Files\BurpSuiteProfessional\BurpSuite.vmoptions" `
             "C:\Program Files\BurpSuiteProfessional\BurpSuite.vmoptions.bak" -Force
   ```

2. Copy the file from this project over it:

   ```powershell
   Copy-Item .\BurpSuite.vmoptions `
             "C:\Program Files\BurpSuiteProfessional\BurpSuite.vmoptions" -Force
   ```

3. Make sure the agent line is present:

   ```
   -javaagent:loader.jar
   ```

   If the agent is not picked up, use an absolute path:

   ```
   -javaagent:C:\Program Files\BurpSuiteProfessional\loader.jar
   ```

4. Do not remove the `--add-opens=...` lines.

5. If you need custom memory settings (`-Xmx2g`, etc.), add them on separate lines: the file is replaced entirely, previous options are not preserved.

> **Burp updates.** An update may overwrite `BurpSuite.vmoptions`. To make the setting survive, create a copy named `user.vmoptions` in the same directory and keep the agent lines there (Burp reads it alongside the main file). After an update, also verify that `loader.jar` is still present and copy it again if needed.

## Step 5. Start Burp

Launch the **Burp Suite Professional** shortcut (or `BurpSuiteProfessional.exe` from the installation directory).

The agent is loaded if Burp does not insist on a valid license and activation from Step 6 succeeds. If activation fails, check the `-javaagent` path (Step 4, item 3).

## Step 6. Generate a key and activate Burp

Use Burp's bundled Java (no separate JDK required). In cmd:

```cmd
cd /d "C:\Program Files\BurpSuiteProfessional"
jre\bin\java.exe -cp loader.jar Keygen "Your Name"
```

In PowerShell:

```powershell
cd "C:\Program Files\BurpSuiteProfessional"
.\jre\bin\java.exe -cp loader.jar Keygen "Your Name"
```

If there is no `jre` directory, use `java` from PATH (JDK 21+).

Then:

1. Paste the generated key into the Burp activation window.
2. Choose **Manual activation** → **Next**.
3. Copy the **Activation Request** from Burp.
4. Generate the response:

   ```cmd
   cd /d "C:\Program Files\BurpSuiteProfessional"
   jre\bin\java.exe -cp loader.jar Keygen -activate "<REQUEST>"
   ```

5. Paste the response into Burp → **Next**.

### Where license properties are defined

- **License holder name** — the `Keygen` command argument (see above).
- **Expiry date and edition** — constants in `src/Keygen.java`, method `generateLicense`:
  - expiry: `l.add("4102415999000");` — milliseconds since 1970-01-01 (2099-12-31);
  - edition: `l.add("full");`;
  - license ID: `l.add(randomStr());`.

After editing the sources, rebuild `loader.jar` (Step 2) and repeat Step 3.

## Troubleshooting

- **License is rejected** — check the `-javaagent` path: when launching from a shortcut, a relative path may not resolve; use an absolute path.
- **Burp does not start** — check the `BurpSuite.vmoptions` syntax (one option per line), the Java version against `--release`, and that files were replaced with administrator rights.
- **Need to reset activation** (Burp closed):

  ```powershell
  reg delete "HKCU\Software\JavaSoft\Prefs\burp" /f
  ```

## Other OS (brief)

- **Linux:** installation directory, `BurpSuite.vmoptions`, build with `./scripts/build_loader.sh`.
- **macOS:** `vmoptions.txt` inside `Burp Suite Professional.app/Contents`, build with `./scripts/build_loader.sh`.
