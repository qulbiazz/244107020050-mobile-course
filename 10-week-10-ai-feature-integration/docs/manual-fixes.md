# Manual Fixes

## 1. Android SDK

Project menggunakan:

- compileSdk = 36
- targetSdk = 36
- minSdk = 23

Perubahan dilakukan karena firebase_messaging membutuhkan minimum
Android SDK 23 dan beberapa plugin membutuhkan compile SDK 36.

## 2. Android NDK

Project menggunakan:

ndkVersion = "27.0.12077973"

Digunakan untuk menyesuaikan kebutuhan Firebase dan plugin
Flutter yang digunakan.

## 3. Core Library Desugaring

flutter_local_notifications membutuhkan core library desugaring.

Konfigurasi ditambahkan pada android/app/build.gradle.kts:

isCoreLibraryDesugaringEnabled = true

dan dependency:

com.android.tools:desugar_jdk_libs:2.1.5

## 4. Firebase

Firebase diinisialisasi sebelum runApp():

await Firebase.initializeApp();

File google-services.json ditempatkan pada:

android/app/google-services.json

## 5. Background Handler

Background handler dibuat sebagai fungsi top-level:

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message
) async {
  ...
}

Background handler tidak menggunakan BuildContext atau Riverpod.

## 6. Foreground Notification

Karena notification tidak otomatis menampilkan banner ketika aplikasi
berada di foreground, local notification digunakan secara manual
melalui flutter_local_notifications.

## 7. Deep Link

Data route digunakan untuk menentukan halaman tujuan:

message.data['route']

Contoh:

/pengumuman/3

## 8. Topic

Aplikasi melakukan subscribe ke:

pengumuman-kampus