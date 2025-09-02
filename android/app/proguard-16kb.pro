# Proguard rules for 16KB page size optimization

# Keep native methods for 16KB page size support
-keepclasseswithmembernames class * {
    native <methods>;
}

# Optimize for memory alignment on 16KB pages
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification

# Keep Flutter engine classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Optimize native library loading for 16KB pages
-keep class **.R
-keep class **.R$* {
    <fields>;
}

# Memory optimization for large page sizes
-dontpreverify
-repackageclasses ''
-allowaccessmodification
-optimizations !code/simplification/arithmetic

# Keep Firebase classes if used
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }