# Upgrade Dukungan 16 KB Page Size untuk Android

## Ringkasan Perubahan

Project Flutter ini telah diupgrade untuk mendukung perangkat Android dengan 16 KB page size. Berikut adalah perubahan yang telah dilakukan:

## 1. Update Android Gradle Plugin

### File: `android/build.gradle`
- **Android Gradle Plugin**: 7.3.0 → 8.7.0
- **Google Services**: 4.3.5 → 4.4.2

### File: `android/gradle/wrapper/gradle-wrapper.properties`
- **Gradle Version**: 7.5 → 8.10.2

## 2. Update Konfigurasi Build

### File: `android/app/build.gradle`
- **compileSdkVersion**: Tetap 34 (sesuai permintaan)
- **targetSdkVersion**: 35
- **minSdkVersion**: 21

### Penambahan Konfigurasi NDK:
```gradle
ndk {
    abiFilters 'arm64-v8a', 'armeabi-v7a', 'x86_64'
}
```

### Optimasi Build Types:
- **Release**: Menambahkan minifyEnabled dan proguard rules
- **Debug & Release**: Menambahkan packagingOptions untuk JNI libs

## 3. Update Dependencies

### Dependencies yang diupdate untuk mendukung 16KB:
- `desugar_jdk_libs`: 1.1.5 → 2.1.2
- `firebase-messaging`: 23.0.0 → 24.1.0
- `firebase-analytics`: 21.0.0 → 22.1.2
- `window`: 1.1.0 → 1.3.0
- `review-ktx`: 2.0.1 → 2.0.2

### Dependencies baru untuk optimasi:
- `androidx.startup:startup-runtime:1.2.0`
- `androidx.profileinstaller:profileinstaller:1.4.1`

## 4. Konfigurasi Gradle Properties

### File: `android/gradle.properties`
Penambahan konfigurasi khusus 16KB:
```properties
# Support for 16KB page size devices
android.bundle.enableUncompressedNativeLibs=false
android.experimental.enableArtProfiles=true
android.experimental.r8.dex-startup-optimization=true
android.nonFinalResIds=false
```

## 5. Proguard Rules

### File: `android/app/proguard-16kb.pro`
File proguard khusus untuk optimasi 16KB page size yang mencakup:
- Optimasi native methods
- Memory alignment untuk 16KB pages
- Keep Flutter engine classes
- Optimasi loading native libraries

## 6. Android Manifest

### File: `android/app/src/main/AndroidManifest.xml`
Penambahan konfigurasi:
- `android:enableOnBackInvokedCallback="true"`
- `android:extractNativeLibs="false"`
- `io.flutter.embedding.android.EnableImpeller="true"`
- `io.flutter.embedding.android.SurfaceProducerRenderingApi="opengles"`

## Cara Testing

1. **Clean dan Rebuild Project**:
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   flutter pub get
   ```

2. **Build APK untuk Testing**:
   ```bash
   flutter build apk --release
   ```

3. **Test di Perangkat 16KB**:
   - Test di perangkat yang mendukung 16KB page size
   - Monitor performa aplikasi
   - Pastikan tidak ada crash saat startup

## Catatan Penting

- **compileSdkVersion**: Menggunakan 34 sesuai permintaan (bukan 35)
- **targetSdkVersion**: 35 untuk kompatibilitas dengan Play Store
- **Proguard**: Diaktifkan untuk release build untuk optimasi
- **Native Libraries**: Dikonfigurasi untuk tidak diekstrak (sesuai 16KB requirements)

## Troubleshooting

Jika terjadi masalah setelah upgrade:

1. **Build Error**: Pastikan Android SDK 34 terinstall
2. **Gradle Sync Error**: Jalankan `./gradlew --stop` kemudian sync ulang
3. **Runtime Error**: Check logcat untuk error native library loading

## Kompatibilitas

- ✅ Perangkat 4KB page size (backward compatible)
- ✅ Perangkat 16KB page size (newly supported)
- ✅ Android API 21+ (minSdkVersion)
- ✅ Target API 35 (latest requirements)