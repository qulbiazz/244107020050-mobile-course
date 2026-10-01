# FCM Testing

## FCM Configuration

Application:
Campus Notify

Topic:
pengumuman-kampus

Test route:
/pengumuman/3

Payload:

{
  "notification": {
    "title": "Jadwal kuliah berubah",
    "body": "Kelas Mobile pindah ke Ruang A2 jam 13.00"
  },
  "data": {
    "route": "/pengumuman/3",
    "id": "3"
  }
}

---

## Test 1 - Foreground

### Kondisi

Aplikasi Campus Notify sedang terbuka dan aktif.

### Pengujian

Kirim notification dari Firebase Console.

### Expected Result

Local notification muncul karena aplikasi berada pada foreground.

Ketika notification diklik, aplikasi diarahkan ke:

/pengumuman/3

### Screenshot

02-foreground-notification.png

### Result

[ ] Berhasil
[ ] Tidak berhasil

---

## Test 2 - Background

### Kondisi

Campus Notify sedang berjalan tetapi berada di background.

### Pengujian

Tekan tombol Home emulator kemudian kirim notification.

### Expected Result

System notification muncul.

Ketika notification diklik:

Campus Notify terbuka

dan diarahkan ke:

/pengumuman/3

### Screenshot

03-background-notification.png

### Result

[ ] Berhasil
[ ] Tidak berhasil

---

## Test 3 - Terminated

### Kondisi

Campus Notify ditutup/swipe dari recent apps.

### Pengujian

Kirim notification kemudian klik notification.

### Expected Result

Aplikasi dibuka.

getInitialMessage() mendapatkan notification.

Aplikasi diarahkan ke:

/pengumuman/3

### Screenshot

04-terminated-notification.png

### Result

[ ] Berhasil
[ ] Tidak berhasil

---

## Test 4 - Topic

### Kondisi

Device telah subscribe ke:

pengumuman-kampus

### Pengujian

Firebase Console mengirim notification menggunakan topic:

pengumuman-kampus

### Expected Result

Device menerima notification.

### Screenshot

05-topic-notification.png

### Result

[ ] Berhasil
[ ] Tidak berhasil