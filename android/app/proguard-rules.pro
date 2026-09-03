# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Fix Play Core missing classes
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.**

# Hive
-keep class hive.** { *; }
-keep class hive_flutter.** { *; }
-keepnames class * extends hive.TypeAdapter

# Awesome Notifications
-keep class me.carda.awesome_notifications.** { *; }
-keep interface me.carda.awesome_notifications.** { *; }
-keep enum me.carda.awesome_notifications.** { *; }
-keep class me.carda.awesome_notifications.core.** { *; }

# Just Audio
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.ryanheise.audio_session.** { *; }

# Background service
-keep class id.flutter.flutter_background_service.** { *; }

# Keep necessary SQLite and SQLCipher classes
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }
-keep,includedescriptorclasses class net.sqlcipher.** { *; }
-keep,includedescriptorclasses interface net.sqlcipher.** { *; }

# Awesome Notifications & Models
-keep public class me.carda.** { *; }

# Gson specific classes (used by Awesome Notifications serialization)
-dontwarn sun.misc.**
-keep class com.google.gson.stream.** { *; }

# Prevent stripping TypeAdapter, TypeAdapterFactory, JsonSerializer, JsonDeserializer
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Prevent R8 from nullifying Data object members annotated with SerializedName
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
