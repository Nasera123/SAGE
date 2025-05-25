# Dokumen Kebutuhan Produk (PRD)

**Nama:** Diyah Rochmawati  
**Kelas:** RPL D  
**Judul Proyek:** Aplikasi Mobile 'MyApp' untuk Sistem Presensi  
**Sekolah Tujuan Implementasi:** SMPN 56 Malang

## 1. Ringkasan Produk (Apa dan Mengapa)

### 1.1 Ikhtisar
Dokumen ini mendefinisikan kebutuhan dan spesifikasi untuk pengembangan aplikasi mobile bernama 'MyApp'. Aplikasi ini dirancang untuk mempermudah proses presensi di SMPN 56 Malang dengan menyediakan fitur digitalisasi presensi yang terintegrasi dengan laporan kehadiran, lokasi GPS, dan notifikasi kepada wali siswa. Aplikasi ini bertujuan mengurangi proses presensi manual yang memakan waktu dan rawan kesalahan, serta meningkatkan efisiensi pelaporan kehadiran siswa.

### 1.2 Latar Belakang dan Konteks
Presensi siswa selama ini dilakukan secara manual menggunakan kertas yang kemudian direkap oleh wali kelas setiap minggu. Proses ini rentan terhadap kehilangan data, kesalahan pencatatan, dan memerlukan waktu yang cukup lama. Dalam era digitalisasi, sekolah perlu sistem yang efisien, akurat, dan dapat digunakan di mana saja untuk mempercepat proses kehadiran, mengurangi beban administratif guru, serta meningkatkan transparansi terhadap orang tua.

### 1.3 Kriteria Keberhasilan / Dampak
- Seluruh guru dan siswa dapat menggunakan aplikasi tanpa pelatihan teknis yang mendalam.
- Proses presensi dapat dilakukan dalam waktu kurang dari 2 menit per kelas.
- Data presensi dapat langsung diakses oleh wali kelas dan kepala sekolah.
- Orang tua mendapatkan notifikasi jika anaknya tidak hadir.
- Riwayat kehadiran tersimpan rapi dan dapat diekspor dalam format Excel atau PDF.

### 1.4 Metrik untuk Mengukur Keberhasilan
- Tingkat adopsi aplikasi oleh guru (target 100%) dan siswa (target 100%).
- Rata-rata waktu presensi per kelas kurang dari 2 menit.
- Jumlah notifikasi ke orang tua yang dikirim per hari.
- Feedback positif dari pengguna dalam survei bulanan minimal 80%.

### 1.5 Metrik yang Perlu Dipantau
- Jumlah error koneksi saat input presensi.
- Ketersediaan server cloud (uptime > 99%).
- Performa aplikasi saat digunakan secara bersamaan oleh banyak pengguna.
- Rata-rata waktu respon API untuk sinkronisasi data kehadiran.

## 2. Tim
- **Product Manager & Developer:** Diyah Rochmawati
- **UI/UX Designer:** Tim Siswa RPL D
- **QA Tester:** Tim Guru Pembimbing
- **Client:** SMPN 56 Malang (Wakil Kepala Sekolah dan Wali Kelas)

## 3. Desain Solusi

### 3.1 Kebutuhan Fungsional
- Guru dapat memilih kelas dan melakukan presensi siswa (Hadir, Izin, Sakit, Alpha).
- Siswa melakukan presensi melalui scan QR Code yang disediakan guru di kelas.
- Fitur validasi lokasi menggunakan GPS untuk memastikan siswa berada di lingkungan sekolah saat presensi.
- Admin sekolah dapat menambahkan/mengedit data guru, siswa, dan kelas.
- Riwayat presensi harian, mingguan, dan bulanan yang dapat diunduh dalam format PDF dan Excel.
- Fitur notifikasi otomatis ke orang tua jika anak tidak hadir tanpa keterangan.
- Login aman menggunakan akun Google atau sistem autentikasi sekolah.
- Dashboard real-time untuk kepala sekolah memantau kehadiran seluruh kelas.
- Mode offline presensi, data akan disinkronisasi otomatis saat koneksi tersedia.

### 3.2 Implementasi Teknis
Aplikasi akan dikembangkan menggunakan Flutter agar dapat berjalan di Android dan iOS. Backend menggunakan Firebase untuk autentikasi, penyimpanan data, dan notifikasi. QR Code akan dihasilkan secara dinamis dan hanya berlaku dalam durasi tertentu. Data disimpan dalam Cloud Firestore dan dapat disinkronisasi ke Google Sheets melalui Firebase Functions. Penggunaan GPS akan dilakukan dengan plugin Geolocator.

### 3.3 Rencana Pengujian dan QA
- **Pengujian Unit:** Setiap modul seperti login, QR scanner, GPS validation.
- **Pengujian Integrasi:** Proses lengkap mulai dari scan QR hingga data tersimpan di database.
- **Pengujian End-to-End:** Alur pengguna dari login, presensi, hingga laporan harian diakses admin.
- **Tools:** Flutter test untuk unit test, Firebase Test Lab untuk integrasi, dan manual testing di sekolah.
- Simulasi penggunaan secara bersamaan di beberapa perangkat untuk mengukur stabilitas.

## 4. Dampak
Dengan penerapan aplikasi 'MyApp', guru tidak lagi perlu mencatat manual, siswa memiliki cara presensi yang lebih cepat, dan pihak sekolah dapat langsung memantau statistik kehadiran. Orang tua lebih tenang karena adanya notifikasi. Namun, perlu mitigasi untuk perangkat siswa yang tidak mendukung atau koneksi yang tidak stabil.

## 5. Catatan
- Implementasi tahap awal akan dimulai dengan 2 kelas sebagai pilot project.
- Pengembangan selanjutnya dapat mencakup integrasi dengan sistem nilai dan perizinan sekolah digital.
- Backup data otomatis akan dijalankan setiap malam ke Google Drive sekolah.

## 6. Link Dokumentasi Program
http:..........

