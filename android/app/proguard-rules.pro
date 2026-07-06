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

# AudioPlayers
-keep class xyz.luan.audioplayers.** { *; }

# Background service
-keep class id.flutter.flutter_background_service.** { *; }
