# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Specific plugins
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.ryanheise.audioservice.** { *; }
-keep class io.flutter.plugins.urllauncher.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.webviewflutter.** { *; }
-keep class com.baseflow.geolocator.** { *; }

# Home Widget Plugin & AppWidgetProvider
-keep class com.dhikr.adhkar.DhikrAppWidgetProvider { *; }
-keep class es.antonborri.home_widget.** { *; }
-keepclassmembers class es.antonborri.home_widget.** { *; }
-keep public class * extends android.appwidget.AppWidgetProvider { *; }
-keepclassmembers class * extends android.appwidget.AppWidgetProvider { *; }
