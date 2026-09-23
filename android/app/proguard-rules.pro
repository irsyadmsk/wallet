# google_mlkit_text_recognition ships script-specific recognizer variants
# (Chinese/Japanese/Korean/Devanagari) as optional, reflection-loaded
# classes. We only use the default Latin-script recognizer, so those extra
# dependencies were never pulled in — R8 can't resolve them and fails the
# release build unless told they're intentionally absent.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
