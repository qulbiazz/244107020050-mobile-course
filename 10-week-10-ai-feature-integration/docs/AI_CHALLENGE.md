## Usulan Struktur Folder

```text
lib/
├── app/
│   ├── app.dart
│   └── router.dart
├── core/
│   ├── error/
│   └── network/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── pages/
│   │       ├── providers/
│   │       └── widgets/
│   └── announcements/
│       ├── data/
│       │   ├── datasources/
│       │   ├── models/
│       │   └── repositories/
│       ├── domain/
│       │   ├── entities/
│       │   └── repositories/
│       └── presentation/
│           ├── pages/
│           ├── providers/
│           └── widgets/
├── messaging/
└── main.dart
```

## Pembagian Tanggung Jawab

- **Presentation:** halaman, widget, state management, dan interaksi pengguna.
- **Domain:** entity dan kontrak repository.
- **Data:** model, datasource, serta implementasi repository.
- **Core:** infrastruktur lintas fitur seperti HTTP client dan penanganan error.
- **Messaging:** integrasi Firebase Cloud Messaging dan notifikasi.
- **App:** bootstrap aplikasi dan konfigurasi router apabila diperlukan.


## Dependency Injection dengan Riverpod

Contoh alur dependency untuk fitur pengumuman:

```dart
final announcementRemoteDataSourceProvider =
    Provider<AnnouncementRemoteDataSource>((ref) {
  return AnnouncementRemoteDataSourceImpl(
    client: ref.watch(apiClientProvider),
  );
});

final announcementRepositoryProvider =
    Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepositoryImpl(
    remoteDataSource: ref.watch(
      announcementRemoteDataSourceProvider,
    ),
  );
});

final announcementsProvider =
    FutureProvider<List<Announcement>>((ref) {
  return ref
      .watch(announcementRepositoryProvider)
      .getAnnouncements();
});
```

Alur dependency:

1. `apiClientProvider` menyediakan HTTP client.
2. Datasource menggunakan HTTP client untuk mengakses API.
3. Repository implementation menggunakan datasource dan memenuhi kontrak repository domain.
4. Provider menyediakan repository kepada state management.
5. UI membaca provider dan menampilkan data.

Widget tidak membuat `RepositoryImpl()` secara langsung dan tidak memanggil Dio untuk mengambil daftar pengumuman.

