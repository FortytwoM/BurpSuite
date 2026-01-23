# Burp Suite Professional - Docker

Burp Suite Professional в Docker с VNC доступом.

## Быстрый старт

```bash
# Собрать loader.jar (JDK 21+)
.\scripts\build_loader.ps1   # Windows
./scripts/build_loader.sh    # Linux

# Опционально: создать .env файл с паролем VNC
echo "VNC_PASSWORD=your_secure_password" > .env

# Запустить
docker compose up -d

# VNC: localhost:5901 (пароль будет показан в логах при первом запуске)
# Просмотр пароля: docker compose logs | grep "VNC PASSWORD"
```

## Активация

1. Получите VNC пароль: `docker compose logs | grep "VNC PASSWORD"`
2. Скопируйте LICENSE KEY из логов: `docker compose logs`
3. Подключитесь по VNC: `localhost:5901` (используйте пароль из шага 1)
4. Вставьте ключ в Burp Suite
5. Выберите **Manual activation** → Next
6. Скопируйте **Activation Request** из Burp
7. Выполните:
   ```bash
   docker compose exec burpsuite java -cp /app/loader.jar Keygen -activate "<REQUEST>"
   ```
8. Вставьте полученный Response в Burp → Next

## Безопасность

- ✅ VNC защищен паролем (автогенерация или через `VNC_PASSWORD` в `.env`)
- ✅ Порты ограничены только localhost (127.0.0.1)
- ✅ Контейнер работает от непривилегированного пользователя (burp:1000)
- ✅ Ограничены capabilities контейнера
- ✅ Чувствительные данные выводятся в stderr, а не в логи

### Переменные окружения

Создайте файл `.env` для настройки:

```env
# VNC Password (оставьте пустым для автогенерации)
VNC_PASSWORD=your_secure_password_here

# License name
LICENSE_NAME=User
```

## Структура

```
├── Dockerfile
├── docker-compose.yml
├── start.sh
├── loader.jar
├── src/
│   ├── Loader.java    # Java Agent
│   ├── Filter.java    # License filter
│   └── Keygen.java    # Key generator
├── scripts/
│   ├── build_loader.ps1
│   └── build_loader.sh
└── burp_data/         # Persistent data
```

## CLI

```bash
# Generate license
java -cp loader.jar Keygen "Name"

# Generate activation response
java -cp loader.jar Keygen -activate "<REQUEST>"
```

## Troubleshooting

```bash
# Logs
docker compose logs -f

# Rebuild
docker compose down
docker compose build --no-cache
docker compose up -d
```
