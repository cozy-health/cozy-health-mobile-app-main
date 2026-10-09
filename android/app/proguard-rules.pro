# Flutter/plugin registrants and JNI entrypoints must remain available to R8.
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-keepclasseswithmembernames class * { native <methods>; }
-keepattributes Signature,InnerClasses,EnclosingMethod
