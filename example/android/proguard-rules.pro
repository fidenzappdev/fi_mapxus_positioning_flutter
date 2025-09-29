-keep class com.mapxus.positioning.** {*;}
-dontwarn com.mapxus.positioning.**
-keep class com.mapxus.map.auth.** {*;}
-dontwarn com.mapxus.map.auth.**

# Keep all networking related classes for Mapxus SDK
-keep class retrofit2.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn retrofit2.**
-dontwarn okhttp3.**
-dontwarn okio.**

# Keep Gson classes if used by Mapxus SDK
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Keep Jackson classes if used
-keep class com.fasterxml.jackson.** { *; }
-dontwarn com.fasterxml.jackson.**

# Keep all interfaces that might be used for networking
-keep interface * {
    @retrofit2.http.* <methods>;
}

# Keep model classes that might be serialized/deserialized
-keep class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep RxJava classes if used by networking layer
-keep class io.reactivex.** { *; }
-dontwarn io.reactivex.**

# Keep generic signature of retrofit interfaces
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep classes with native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# More aggressive networking preservation
-keep class * extends retrofit2.CallAdapter$Factory { *; }
-keep class * extends retrofit2.Converter$Factory { *; }
-keep class * implements retrofit2.Call { *; }
-keep class * implements retrofit2.Response { *; }

# Keep all service interfaces
-keep interface * {
    public <methods>;
}

# Preserve call adapters and converters
-keepclassmembers,allowobfuscation class * {
    @retrofit2.http.* <methods>;
}

# Keep everything that might be used by reflection in networking
-keepclassmembers class ** {
    @retrofit2.** *;
}

# Additional safety for call adapters
-keep class retrofit2.adapter.** { *; }
-keep class retrofit2.converter.** { *; }

# Keep everything related to HTTP annotations
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes RuntimeInvisibleParameterAnnotations

# Prevent obfuscation of types referenced in method signatures
-keepattributes LocalVariableTable,LocalVariableTypeTable