# Panduan Validasi Dukungan 16 KB Page Size

## 1. Validasi Konfigurasi Build

### A. Cek Gradle Configuration
```bash
cd android
./gradlew properties | grep -E "(compileSdk|targetSdk|gradle)"
```

### B. Validasi Dependencies
```bash
./gradlew app:dependencies --configuration releaseRuntimeClasspath | grep -E "(androidx|firebase)"
```

### C. Cek NDK Configuration
```bash
./gradlew app:tasks --all | grep ndk
```

## 2. Build dan Test

### A. Clean Build
```bash
cd /Users/findigiosdev/Desktop/test\ ios/ios-flavorin
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
```

### B. Build APK untuk Testing
```bash
# Build debug untuk testing awal
flutter build apk --debug

# Build release untuk validasi final
flutter build apk --release
```

### C. Analyze APK
```bash
cd android
./gradlew assembleRelease
# APK akan ada di: android/app/build/outputs/apk/release/
```

## 3. Validasi APK Structure

### A. Cek Native Libraries
```bash
# Install APK analyzer (jika belum ada)
# Kemudian analyze APK structure
unzip -l android/app/build/outputs/apk/release/app-release.apk | grep -E "\.so$|lib/"
```

### B. Cek Page Size Alignment
```bash
# Cek alignment native libraries
readelf -l android/app/build/outputs/apk/release/app-release.apk
```

## 4. Runtime Testing

### A. Test di Emulator
```bash
# Buat emulator dengan 16KB page size (jika ada)
# Atau gunakan emulator biasa untuk backward compatibility
flutter run --release
```

### B. Monitor Memory Usage
```bash
# Saat app berjalan, monitor memory
adb shell dumpsys meminfo com.seepaysbiller.app
```

### C. Check Native Library Loading
```bash
# Monitor log saat app startup
adb logcat | grep -E "(native|jni|16kb|page)"
```

## 5. Automated Tests

### A. Build Test Script
Buat file `test_16kb.sh`:
```bash
#!/bin/bash

echo "=== 16KB Page Size Validation ==="

echo "1. Cleaning project..."
flutter clean && flutter pub get

echo "2. Building APK..."
flutter build apk --release

echo "3. Checking APK size..."
ls -lh build/app/outputs/flutter-apk/

echo "4. Analyzing native libraries..."
unzip -l build/app/outputs/flutter-apk/app-release.apk | grep "\.so$"

echo "5. Checking for 16KB optimizations..."
grep -r "16KB\|page.*size\|useLegacyPackaging.*false" android/

echo "=== Validation Complete ==="
```

### B. Jalankan Test
```bash
chmod +x test_16kb.sh
./test_16kb.sh
```

## 6. Validasi Khusus 16KB Features

### A. Cek Gradle Properties
```bash
cat android/gradle.properties | grep -E "(16KB|page|bundle|native)"
```

Expected output:
```
android.bundle.enableUncompressedNativeLibs=false
android.experimental.enableArtProfiles=true
android.experimental.r8.dex-startup-optimization=true
```

### B. Cek Build.gradle Settings
```bash
grep -A 10 -B 5 "useLegacyPackaging\|ndk\|abiFilters" android/app/build.gradle
```

### C. Cek AndroidManifest
```bash
grep -E "extractNativeLibs|EnableImpeller" android/app/src/main/AndroidManifest.xml
```

## 7. Performance Testing

### A. App Startup Time
```bash
# Test startup time
adb shell am start -W -n com.seepaysbiller.app/.MainActivity
```

### B. Memory Footprint
```bash
# Monitor memory usage
adb shell "while true; do dumpsys meminfo com.seepaysbiller.app | grep TOTAL; sleep 5; done"
```

## 8. Device Compatibility Test

### A. Test Matrix
- ✅ Android 5.0+ (API 21+) - 4KB pages
- ✅ Android 14+ devices dengan 16KB pages
- ✅ Different architectures (arm64, armv7, x86_64)

### B. Install dan Run
```bash
# Install di device/emulator
flutter install

# Run dan monitor
flutter run --release --verbose
```

## 9. Troubleshooting Common Issues

### A. Build Errors
```bash
# Jika ada error Gradle
cd android
./gradlew --stop
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### B. Native Library Issues
```bash
# Cek ABI compatibility
adb shell getprop ro.product.cpu.abi
adb shell getprop ro.product.cpu.abilist
```

### C. Memory Issues
```bash
# Increase Gradle memory
echo "org.gradle.jvmargs=-Xmx8192M" >> android/gradle.properties
```

## 10. Success Indicators

### ✅ Build Success
- APK builds without errors
- All native libraries included
- No compatibility warnings

### ✅ Runtime Success
- App starts normally
- No native library loading errors
- Memory usage optimized
- Smooth performance

### ✅ 16KB Specific
- `extractNativeLibs=false` in manifest
- `useLegacyPackaging=false` in build
- Updated dependencies versions
- Proguard rules applied

## 11. Final Validation Checklist

- [ ] Gradle 8.10.2 installed
- [ ] Android Gradle Plugin 8.7.0
- [ ] compileSdk 34, targetSdk 35
- [ ] Updated dependencies
- [ ] Native library optimization enabled
- [ ] APK builds successfully
- [ ] App runs on target devices
- [ ] No performance regression
- [ ] Memory usage acceptable

## 12. Quick Validation Commands

```bash
# One-liner validation
cd /Users/findigiosdev/Desktop/test\ ios/ios-flavorin && \
flutter clean && flutter pub get && \
flutter build apk --release && \
echo "✅ Build successful!" || echo "❌ Build failed!"
```