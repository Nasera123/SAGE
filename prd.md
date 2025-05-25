# Dokumen Kebutuhan Produk (PRD)

**Nama Proyek:** SAGE  
**Kategori:** Aplikasi Mobile Pencatat Digital (Note-Taking Application)

## 1. Ringkasan Produk (Apa dan Mengapa)

### 1.1 Ikhtisar
Dokumen ini mendefinisikan kebutuhan untuk aplikasi pencatat digital bernama SAGE. Aplikasi ini memungkinkan pengguna untuk membuat, mengedit, mengorganisasi, dan menyinkronkan catatan di berbagai perangkat melalui platform cloud. SAGE dikembangkan sebagai solusi komprehensif untuk manajemen catatan dengan fitur-fitur seperti editor teks kaya, pengelolaan tag, folder untuk organisasi, pengaturan buku untuk catatan terstruktur, serta kemampuan untuk mempublikasikan buku agar dapat dibaca oleh pengguna lain.

### 1.2 Latar Belakang dan Konteks
Di era digital yang serba cepat, kebutuhan akan aplikasi pencatat yang efisien dan fleksibel semakin meningkat. Banyak pengguna membutuhkan platform untuk menyimpan ide, catatan, dan informasi penting dengan kemampuan untuk mengaksesnya kapan saja dan di mana saja. Aplikasi pencatat yang ada saat ini sering kali memiliki keterbatasan dalam hal kemampuan organisasi, format konten, atau tidak menyediakan sinkronisasi real-time yang andal.

SAGE hadir untuk memenuhi kebutuhan ini dengan menawarkan pengalaman pencatatan komprehensif yang memadukan kekuatan editor teks kaya (rich text), organisasi yang fleksibel melalui tag dan folder, serta kemampuan sinkronisasi cloud yang seamless melalui platform Supabase. Selain itu, SAGE juga menyediakan fitur untuk mempublikasikan buku yang telah dibuat, sehingga pengguna dapat berbagi pengetahuan dengan komunitas yang lebih luas.

## 2. Kriteria Keberhasilan / Dampak

### 2.1 Metrik untuk Mengukur Keberhasilan
- **Akuisisi Pengguna**: Jumlah pengguna yang mendaftar dan membuat akun
- **Retensi Pengguna**: Persentase pengguna yang kembali menggunakan aplikasi setelah 7 dan 30 hari
- **Engagement**: Rata-rata jumlah catatan yang dibuat per pengguna per bulan
- **Ketahanan Produk**: Jumlah crash per 1000 sesi pengguna
- **Penggunaan Fitur Utama**: Persentase pengguna yang menggunakan fitur tag, folder, dan buku
- **Publikasi Buku**: Jumlah buku yang dipublikasikan
- **Pembacaan Buku**: Jumlah views pada buku yang dipublikasikan

### 2.2 Metrik yang Perlu Dipantau
- **Performa Aplikasi**: Waktu muat untuk editor catatan dan daftar catatan
- **Kinerja Sinkronisasi**: Frekuensi konflik sinkronisasi dan waktu resolusi
- **Penggunaan Penyimpanan**: Ukuran rata-rata catatan dan total penggunaan penyimpanan per pengguna
- **Penggunaan Fitur Kolaborasi**: Jumlah sesi kolaborasi dan perubahan sinkronisasi antar pengguna
- **Waktu Baca**: Waktu rata-rata yang dihabiskan pengguna untuk membaca buku yang dipublikasikan

## 3. Tim

- **Product Manager**: [Nama]
- **UI/UX Designer**: [Nama]
- **Frontend Developer**: [Nama]
- **Backend Developer**: [Nama]
- **QA Engineer**: [Nama]

## 4. Desain Solusi

### 4.1 Kebutuhan Fungsional

#### Manajemen Pengguna
- Pengguna dapat mendaftar dan masuk menggunakan email/password
- Pengguna dapat melihat dan mengubah informasi profil, termasuk foto profil
- Pengguna dapat keluar dari aplikasi (logout)
- Pengguna dapat mereset kata sandi jika lupa

#### Manajemen Catatan
- Pengguna dapat membuat catatan baru dengan judul dan konten
- Pengguna dapat mengedit catatan dengan editor teks kaya (rich text editor)
- Pengguna dapat menyisipkan gambar, daftar, dan format teks dalam catatan
- Pengguna dapat menghapus catatan (memindahkan ke tempat sampah)
- Pengguna dapat memulihkan catatan dari tempat sampah
- Pengguna dapat menghapus catatan secara permanen

#### Organisasi Catatan
- Pengguna dapat membuat dan mengelola folder untuk mengategorikan catatan
- Pengguna dapat membuat dan menetapkan tag ke catatan untuk pengorganisasian lintas kategori
- Pengguna dapat mencari catatan berdasarkan judul, konten, tag, atau folder
- Pengguna dapat melihat daftar semua catatan, difilter berdasarkan folder atau tag

#### Fitur Buku
- Pengguna dapat membuat buku untuk mengorganisir catatan terkait
- Pengguna dapat menambahkan dan menghapus halaman (catatan) dalam buku
- Pengguna dapat mengatur urutan halaman dalam buku
- Pengguna dapat menetapkan gambar sampul untuk buku
- Pengguna dapat mempublikasikan buku untuk dapat dilihat oleh pengguna lain
- Pengguna dapat menarik kembali publikasi buku (unpublish)

#### Fitur Media
- Pengguna dapat menyisipkan dan mengelola gambar dalam catatan
- Pengguna dapat menyematkan dan mendengarkan file musik saat menulis catatan

#### Kolaborasi dan Sinkronisasi
- Catatan disinkronkan secara real-time ke cloud
- Pengguna mendapatkan notifikasi saat ada perubahan yang dilakukan pada perangkat lain
- Pengguna dapat melihat siapa yang sedang mengedit catatan yang sama

#### Publikasi dan Pembacaan
- Pengguna dapat mempublikasikan buku mereka agar dapat dilihat oleh publik
- Pengguna dapat menarik kembali publikasi buku jika tidak ingin lagi menampilkannya secara publik
- Pengguna dapat melihat status publikasi buku mereka (publik atau privat)
- Pengguna dapat menjelajahi daftar buku yang telah dipublikasikan oleh pengguna lain
- Pengguna dapat membaca isi buku publik secara read-only
- Pengguna dapat mencari buku publik berdasarkan judul atau kata kunci

#### Pengaturan Aplikasi
- Pengguna dapat mengubah tema aplikasi (terang/gelap)
- Pengguna dapat mengatur preferensi bahasa

### 4.2 Kebutuhan Non-Fungsional
- **Keamanan**: Data pengguna harus dienkripsi dan dilindungi
- **Performa**: Aplikasi harus merespon input pengguna dalam waktu kurang dari 200ms
- **Skalabilitas**: Aplikasi harus mampu menangani hingga 10.000 catatan per pengguna
- **Ketersediaan**: Aplikasi harus memiliki uptime 99.9%
- **Kompatibilitas**: Aplikasi harus berjalan pada perangkat Android dan iOS terbaru

## 5. Implementasi

### 5.1 Dokumen Desain Teknis
Aplikasi SAGE menggunakan arsitektur berbasis flutter dengan struktur berikut:
- **Frontend**: Flutter dengan GetX untuk state management
- **Backend**: Supabase untuk autentikasi, penyimpanan data, dan realtime subscriptions
- **Database**: PostgreSQL (melalui Supabase)
- **Penyimpanan**: Supabase Storage untuk menyimpan gambar dan media
- **Sinkronisasi**: Supabase Realtime untuk sinkronisasi data real-time

#### Komponen Utama:
1. **Modul Otentikasi**:
   - Login, Register, Reset Password
   - Manajemen profil pengguna

2. **Modul Note Editor**:
   - Editor teks kaya menggunakan Flutter Quill
   - Dukungan untuk format teks, daftar, dan gambar
   - Sinkronisasi real-time saat pengeditan

3. **Modul Organisasi**:
   - Pengelolaan folder
   - Pengelolaan tag
   - Fungsi pencarian dan filter

4. **Modul Buku**:
   - Pembuatan dan pengelolaan buku
   - Organisasi halaman
   - Publikasi buku

5. **Modul Media**:
   - Integrasi musik
   - Manajemen gambar

6. **Modul Publikasi dan Perpustakaan**:
   - Interface untuk mempublikasikan buku
   - Perpustakaan untuk menjelajahi buku yang dipublikasikan
   - Antarmuka pembaca untuk buku publik

#### Modifikasi Struktur Data (Supabase)

**Tabel books**:
- `id`: string (primary key)
- `title`: string
- `description`: text
- `user_id`: string (referensi ke auth.users.id)
- `user_display_name`: string
- `is_public`: boolean (default: false)
- `created_at`: timestamp
- `updated_at`: timestamp
- `cover_url`: string (URL ke gambar sampul)

**Tabel book_pages**:
- `id`: string (primary key)
- `book_id`: string (referensi ke books.id)
- `note_id`: string (referensi ke notes.id)
- `order`: integer (untuk menentukan urutan page dalam book)
- `created_at`: timestamp
- `updated_at`: timestamp

**Row Level Security**:
- Kebijakan untuk memastikan hanya pemilik yang dapat mengubah status publikasi buku
- Kebijakan untuk mengizinkan pembacaan buku publik oleh semua pengguna

### 5.2 Rencana Pengujian dan QA

#### Unit Testing
- Pengujian komponen individu dan fungsi inti aplikasi
- Pengujian validasi input dan logika bisnis

#### Integration Testing
- Pengujian integrasi antara frontend dan backend
- Pengujian sinkronisasi data antara perangkat

#### End-to-End Testing
- Alur pengguna dari registrasi hingga pembuatan dan pengeditan catatan
- Skenario kolaborasi antar pengguna dan perangkat
- Alur publikasi buku dan pembacaan oleh pengguna lain

#### Performance Testing
- Kinerja aplikasi dengan jumlah catatan yang besar
- Waktu respons dan efisiensi memori pada berbagai perangkat

## 6. Dampak
Implementasi SAGE akan memberikan solusi pencatatan yang modern dan efisien bagi pengguna. Aplikasi ini akan membantu pengguna mengorganisir informasi mereka secara lebih baik, dengan akses kapan saja dan di mana saja. Penggunaan teknologi cloud memastikan data pengguna tersimpan aman dan dapat diakses di berbagai perangkat.

Dengan fitur publikasi buku, SAGE juga akan menjadi platform berbagi pengetahuan di mana pengguna dapat mempublikasikan dan membaca karya-karya tulis, meningkatkan nilai sosial dari aplikasi pencatat konvensional.

Risiko potensial termasuk tantangan dalam menskalakan infrastruktur backend untuk mendukung jumlah pengguna yang besar, terutama dengan fitur sinkronisasi real-time yang membutuhkan bandwidth tinggi. Mitigasi termasuk implementasi strategi caching yang efisien dan pengoptimalan kueri database.

## 7. Catatan
- Implementasi awal akan fokus pada fitur inti pencatatan dan organisasi
- Fitur kolaborasi real-time antar pengguna yang berbeda direncanakan untuk tahap selanjutnya
- Dukungan untuk mode offline dengan sinkronisasi otomatis saat kembali online akan ditambahkan pada iterasi berikutnya
- Fitur audio dan video embedding dipertimbangkan untuk pengembangan masa depan
- Fitur interaksi sosial seperti like dan komentar pada buku publik akan dikembangkan setelah MVP

## 8. Link Dokumentasi Program
https://github.com/[username]/sage
