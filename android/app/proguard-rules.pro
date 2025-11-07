# Keep ML Kit Text Recognition optional language classes referenced via reflection
-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google.mlkit.vision.text.**

# Keep TensorFlow Lite GPU delegate classes
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.**

# General: keep Flutter plugin registrant classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

