# Build & tes di komputer lokal (Windows)

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter build apk --debug
```

Build pertama mengunduh Gradle 9.3.1 dan komponen Android (bisa ±45 menit);
selanjutnya jauh lebih cepat.

## Jika muncul "Unable to establish loopback connection"

Java 17 di Windows membuat saluran internal (*Unix domain socket*) di folder
Temp. Di sebagian komputer itu gagal (`Invalid argument: connect`), sehingga
Gradle tidak bisa berjalan. Perbaikannya: arahkan ke folder lain lewat
variabel lingkungan **pengguna** (tanpa admin):

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.gradle\uds"
[Environment]::SetEnvironmentVariable('JAVA_TOOL_OPTIONS', "-Djdk.net.unixdomain.tmpdir=$env:USERPROFILE\.gradle\uds", 'User')
```

Buka terminal baru setelahnya. Java akan menulis
`Picked up JAVA_TOOL_OPTIONS: ...` — itu normal. Untuk membatalkan, hapus
variabel `JAVA_TOOL_OPTIONS` di *Edit environment variables for your account*.

## Jika unduhan Gradle terputus

`An established connection was aborted by the software in your host machine`
berarti unduhan besar diputus di tengah jalan. Hapus folder
`%USERPROFILE%\.gradle\wrapper\dists\gradle-<versi>-bin` lalu ulangi, atau
unduh zip-nya lewat browser dan letakkan di folder itu.
