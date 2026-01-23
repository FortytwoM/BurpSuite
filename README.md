# Burp Suite Professional - Docker

Burp Suite Professional в Docker

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
