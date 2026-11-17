# Flutter/plugin registrants and JNI entrypoints must remain available to R8.
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-keepclasseswithmembernames class * { native <methods>; }
-keepattributes Signature,InnerClasses,EnclosingMethod
# Notification schedules are serialized by Gson; retain their model fields.
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
