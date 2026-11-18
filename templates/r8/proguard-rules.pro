# proguard-rules.pro — app-level R8 rules, commented.
# R8 is the default shrinker/obfuscator in AGP. Most libraries ship
# their own consumer rules and need NOTHING here. Add a rule only
# when a release build actually breaks, and write down why.
# Prefer -dontwarn over -keep when a warning is known-harmless.

# ------------------------------------------------------------------
# General
# ------------------------------------------------------------------
# Keep line numbers + source file so release stack traces (Play
# vitals, Crashlytics) can be deobfuscated with the mapping file.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
# Keep annotations and generics signatures: reflection-heavy
# libraries (serialization, Room, Retrofit) read these at runtime.
-keepattributes Signature,*Annotation*,InnerClasses,EnclosingMethod

# ------------------------------------------------------------------
# kotlinx.serialization
# ------------------------------------------------------------------
# Generated serializers are found reflectively by the runtime.
# (kotlinx.serialization also ships consumer rules — these cover the
# common gaps: serializable companions and serializer lookups.)
-keepattributes RuntimeVisibleAnnotations,AnnotationDefault
-keepclassmembers @kotlinx.serialization.Serializable class ** {
    *** Companion;
}
-keepclasseswithmembers class **$$serializer { *; }
-if @kotlinx.serialization.Serializable class **
-keepclassmembers class <1> {
    kotlinx.serialization.KSerializer serializer(...);
}

# ------------------------------------------------------------------
# Retrofit / OkHttp
# ------------------------------------------------------------------
# Retrofit creates service interfaces by dynamic proxy; keep the
# interfaces and their method annotations. OkHttp/Okio ship complete
# consumer rules — do not duplicate them; these two dontwarn lines
# silence the well-known optional-platform warnings.
-keep,allowobfuscation interface * {
    @retrofit2.http.* <methods>;
}
-keepattributes RuntimeVisibleAnnotations,RuntimeVisibleParameterAnnotations
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**

# ------------------------------------------------------------------
# Room
# ------------------------------------------------------------------
# Room's generated implementations (*_Impl) are instantiated by name
# from the database class. Room ships consumer rules for this; the
# rule below is the belt-and-braces version for projects whose
# release build reports a missing *_Impl at runtime.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class **_Impl { <init>(); }
# Room 3 (androidx.room3): same generated-class idea, new package —
# uncomment instead if the project is on Room 3, never mix majors:
# -keep class * extends androidx.room3.RoomDatabase { <init>(); }
# -keep class **_Impl { <init>(); }

# ------------------------------------------------------------------
# Your own code — last resort only
# ------------------------------------------------------------------
# Anything looked up by name (JNI, reflection, WorkManager workers,
# App Startup providers) may need a keep. Prefer AndroidX's
# @Keep annotation on the class itself so the rule travels with the
# code, e.g.:
#   -keep class com.example.app.work.UploadWorker { <init>(...); }
# Never "fix" a crash with a broad -keep class com.example.** { *; }
# — it defeats shrinking for the whole app.
