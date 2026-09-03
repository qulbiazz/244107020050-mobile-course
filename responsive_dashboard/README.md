## Eksperimen layout

1. Ubah breakpoint dari 700 menjadi nilai lain dan amati perubahan jumlah kolom.

![screenshoots](screenshots/1_Eksperimen_layout.png)
Jika lebar layar kurang dari 500, dashboard memiliki 1 kolom.
Jika lebar layar 500 atau lebih, dashboard memiliki 2 kolom.

2. Ubah themeMode menjadi ThemeMode.dark, lalu kembalikan ke ThemeMode.system.

![screenshoots](screenshots/2_Eksperimen_layout.png) -> mode gelap
Aplikasi akan selalu menggunakan Dark Mode, meskipun switch diubah.

![screenshoots](screenshots/2.1_Eksperimen_layout.png) -> mode default sistem
aplikasi akan mengikuti tema perangkat, apakah perangkat sedang menggunakan Light Mode atau Dark Mode.

3. Uji aplikasi dengan ukuran layar emulator yang berbeda.

![screenshoots](screenshots/3_Eksperimen_layout.png) -> iphone 15 promax
![screenshoots](screenshots/3.1_Eksperimen_layout.png) -> iphone 16 promax

4. Tambahkan Semantics atau label yang bermakna pada elemen yang penting bagi screen reader.

Widget Semantics ditambahkan pada switch tema dan kartu dashboard. Hal ini membantu screen reader memberikan informasi yang lebih jelas mengenai fungsi dan isi elemen kepada pengguna.