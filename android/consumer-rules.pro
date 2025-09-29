# Mapxus Positioning Flutter Plugin - Auto-included ProGuard Rules
# These rules are automatically applied to any app that includes this plugin

# Official Mapxus SDK rules
-keep class com.mapxus.positioning.** {*;}
-dontwarn com.mapxus.positioning.**
-keep class com.mapxus.map.auth.** {*;}
-dontwarn com.mapxus.map.auth.**

# Google Play Core missing classes (common in Flutter apps)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-keep class com.google.android.play.core.** { *; }

# AWT classes (not available on Android, commonly referenced by math libraries)
-dontwarn java.awt.**
-dontwarn javax.swing.**

# Apache Commons Math (used by Mapxus SDK)
-dontwarn org.apache.commons.math3.**
-keep class org.apache.commons.math3.** { *; }

# Comprehensive Retrofit protection (Mapxus SDK uses this for networking)
-keep class retrofit2.** { *; }
-keep interface retrofit2.** { *; }
-keepclassmembers,allowshrinking,allowobfuscation interface * {
    @retrofit2.http.* <methods>;
}

# Keep all HTTP-related classes
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn retrofit2.**
-dontwarn okhttp3.**
-dontwarn okio.**

# Keep Gson and JSON serialization (used by Mapxus SDK)
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep service interfaces (prevents UserRemoteService obfuscation issues)
-keep class * {
    *Service* <methods>;
}
-keep class *UserRemoteService* { <methods>; }
-keep class *RemoteService* { <methods>; }

# Keep call adapters and converters
-keep class * extends retrofit2.CallAdapter$Factory { *; }
-keep class * extends retrofit2.Converter$Factory { *; }
-keep class * implements retrofit2.Call { *; }

# Keep everything with Retrofit annotations
-keepclasseswithmembers class * {
    @retrofit2.http.* <methods>;
}

# Essential attributes for reflection
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes RuntimeInvisibleParameterAnnotations
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Generic dontwarn for common missing classes
-dontwarn javax.**
-dontwarn org.slf4j.**
-dontwarn org.apache.**