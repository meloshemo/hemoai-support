# Keep ML Kit Text Recognition optional language classes referenced via reflection
-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google.mlkit.vision.text.**

# Keep TensorFlow Lite GPU delegate classes
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.**

# General: keep Flutter plugin registrant classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Keep contacts_service classes (required for namespace fix)
-keep class com.baseflow.contacts.** { *; }
-dontwarn com.baseflow.contacts.**

# Keep all native methods
-keepclasseswithmembers class * {
    native <methods>;
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator CREATOR;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
