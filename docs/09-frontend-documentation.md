# Frontend Documentation

## API baseUrl

`baseUrl` is no longer hard-coded directly in these services:

- `lib/services/auth_service.dart`
- `lib/services/classroom_service.dart`
- `lib/services/fund_service.dart`
- `lib/services/event_service.dart`

The shared API base URL is managed in:

```txt
lib/core/config/app_config.dart
```

Default value:

```txt
http://localhost:8080/api
```

Run on Android emulator:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
```

Run on a real Android device on the same Wi-Fi:

```bash
flutter run --dart-define=API_BASE_URL=http://<IP-LAN>:8080/api
```

Build a demo APK:

```bash
flutter build apk --release --dart-define=API_BASE_URL=http://<IP-LAN>:8080/api
```
