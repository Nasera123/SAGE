Oke, bro! Mantap nih idenya. Aplikasi note-taking SAGE dengan folder, tag, desain modern ala Notion, dan backend Supabase. Ini PRD (Product Requirements Document) yang lengkap buat kamu:

---

**Product Requirements Document: SAGE**

**1. Pendahuluan**
SAGE adalah aplikasi pencatat (note-taking) modern yang dirancang untuk membantu pengguna mengatur ide, tugas, dan informasi penting secara efisien. Dengan antarmuka yang bersih dan intuitif (terinspirasi Notion), SAGE menawarkan fitur folder dan tag untuk organisasi yang fleksibel, didukung oleh backend Supabase yang andal untuk sinkronisasi data real-time dan penyimpanan yang aman.

**2. Visi Produk**
Menjadi aplikasi pencatat pilihan bagi individu yang mencari keseimbangan antara kesederhanaan, fungsionalitas, dan desain estetis untuk meningkatkan produktivitas dan organisasi personal.

**3. Tujuan Proyek**
*   Mengembangkan aplikasi note-taking fungsional dengan fitur inti: pembuatan catatan, folder, dan tag.
*   Menghadirkan pengalaman pengguna yang modern, bersih, dan intuitif.
*   Mengimplementasikan Supabase sebagai backend untuk otentikasi, database, dan sinkronisasi.
*   Memastikan aplikasi responsif dan stabil di platform Flutter (Android & iOS).
*   Menyelesaikan proyek sebagai tugas kuliah dengan kualitas yang baik.

**4. Target Pengguna**
*   **Pelajar & Mahasiswa:** Untuk mencatat materi kuliah, tugas, dan mengatur jadwal belajar.
*   **Profesional Muda:** Untuk mencatat ide, notulen rapat, daftar tugas, dan proyek personal.
*   **Penulis & Kreator Konten:** Untuk draf tulisan, brainstorming ide, dan mengumpulkan referensi.
*   **Siapa saja yang membutuhkan alat untuk mengatur informasi dan ide secara digital dengan antarmuka yang menarik.**

**5. User Persona (Contoh)**
*   **Nama:** Rina
*   **Usia:** 22 tahun
*   **Pekerjaan:** Mahasiswa Desain Grafis
*   **Kebutuhan:** Mencatat ide desain, referensi visual, daftar tugas kuliah, dan inspirasi. Butuh aplikasi yang visualnya menarik dan mudah diorganisir. Sering berpindah perangkat (laptop & HP).
*   **Frustrasi:** Aplikasi catatan yang ada terlalu kaku, fiturnya terbatas, atau desainnya kuno. Sulit menemukan catatan lama.

**6. User Stories**
*   **Pencatatan Dasar:**
    *   Sebagai pengguna, saya ingin bisa membuat catatan baru dengan cepat agar ide tidak hilang.
    *   Sebagai pengguna, saya ingin bisa mengedit isi catatan yang sudah ada agar informasinya tetap relevan.
    *   Sebagai pengguna, saya ingin bisa melihat daftar semua catatan saya.
    *   Sebagai pengguna, saya ingin bisa menghapus catatan yang tidak lagi diperlukan.
    *   Sebagai pengguna, saya ingin catatan saya tersimpan otomatis saat saya mengetik.
*   **Organisasi dengan Folder:**
    *   Sebagai pengguna, saya ingin bisa membuat folder baru untuk mengelompokkan catatan berdasarkan topik atau proyek.
    *   Sebagai pengguna, saya ingin bisa memberi nama/mengubah nama folder.
    *   Sebagai pengguna, saya ingin bisa memindahkan catatan ke dalam folder tertentu.
    *   Sebagai pengguna, saya ingin bisa melihat semua catatan di dalam folder tertentu.
    *   Sebagai pengguna, saya ingin bisa menghapus folder (dan memutuskan apa yang terjadi pada catatan di dalamnya: pindah ke "unfiled" atau terhapus juga).
*   **Organisasi dengan Tag:**
    *   Sebagai pengguna, saya ingin bisa menambahkan satu atau lebih tag pada catatan untuk klasifikasi yang lebih fleksibel.
    *   Sebagai pengguna, saya ingin bisa membuat tag baru saat menambahkan ke catatan atau dari menu khusus tag.
    *   Sebagai pengguna, saya ingin bisa melihat semua catatan yang memiliki tag tertentu.
    *   Sebagai pengguna, saya ingin bisa menghapus tag dari catatan.
    *   Sebagai pengguna, saya ingin bisa mengelola (rename/delete) daftar tag saya.
*   **Pencarian & Filter:**
    *   Sebagai pengguna, saya ingin bisa mencari catatan berdasarkan judul atau isi konten.
    *   Sebagai pengguna, saya ingin bisa memfilter catatan berdasarkan folder.
    *   Sebagai pengguna, saya ingin bisa memfilter catatan berdasarkan satu atau lebih tag.
*   **Akun & Sinkronisasi (Supabase):**
    *   Sebagai pengguna, saya ingin bisa mendaftar akun baru menggunakan email dan password.
    *   Sebagai pengguna, saya ingin bisa login ke akun saya.
    *   Sebagai pengguna, saya ingin catatan, folder, dan tag saya tersinkronisasi secara otomatis antar perangkat jika saya login dengan akun yang sama.
    *   Sebagai pengguna, saya ingin bisa logout dari akun saya.
*   **Antarmuka & Pengalaman Pengguna:**
    *   Sebagai pengguna, saya ingin antarmuka aplikasi terlihat modern, bersih, dan tidak berantakan.
    *   Sebagai pengguna, saya ingin navigasi di dalam aplikasi mudah dipahami dan intuitif.

**7. Fitur Produk (Detail)**

*   **7.1. Manajemen Catatan (Notes)**
    *   **Pembuatan Catatan:**
        *   Tombol "Tambah Catatan Baru" yang mudah diakses.
        *   Input judul catatan.
        *   Area editor teks rich-text sederhana (minimal: bold, italic, underline, bullet list, numbered list).
        *   Simpan otomatis (auto-save) saat pengguna mengetik atau meninggalkan layar editor.
        *   Timestamp (created_at, updated_at) otomatis.
    *   **Tampilan Daftar Catatan:**
        *   Daftar semua catatan dengan judul dan cuplikan konten/tanggal terakhir diubah.
        *   Urutkan berdasarkan tanggal diubah (terbaru di atas) atau judul.
    *   **Edit Catatan:** Buka catatan yang ada dan modifikasi konten/judul.
    *   **Hapus Catatan:** Opsi untuk menghapus catatan (mungkin dengan konfirmasi atau "soft delete" dengan fitur "Trash" di masa depan).

*   **7.2. Manajemen Folder**
    *   **Pembuatan Folder:** Opsi untuk membuat folder baru dari sidebar atau menu khusus.
    *   **Tampilan Daftar Folder:** Biasanya di sidebar, menampilkan semua folder.
    *   **Navigasi Folder:** Klik folder untuk menampilkan catatan di dalamnya.
    *   **Pemindahan Catatan ke Folder:** Drag-and-drop catatan ke folder, atau opsi "Pindahkan ke Folder" dari menu catatan.
    *   **Rename Folder:** Ubah nama folder.
    *   **Hapus Folder:** Opsi menghapus folder. Perlu ditentukan apa yang terjadi pada catatan di dalamnya (misal: dipindahkan ke "Semua Catatan" atau ikut terhapus – untuk MVP, pindahkan ke "Semua Catatan" lebih aman).

*   **7.3. Manajemen Tag**
    *   **Penambahan Tag ke Catatan:** Saat mengedit catatan, ada field untuk menambahkan tag (bisa ketik tag baru atau pilih dari yang sudah ada).
    *   **Pembuatan Tag:** Tag baru bisa dibuat langsung saat ditambahkan ke catatan.
    *   **Tampilan Daftar Tag:** Di sidebar atau area khusus, menampilkan semua tag yang ada.
    *   **Filter berdasarkan Tag:** Klik tag untuk menampilkan semua catatan yang memiliki tag tersebut. Kemampuan filter multi-tag (AND/OR logic – untuk MVP, AND logic atau single tag filter sudah cukup).
    *   **Hapus Tag dari Catatan:** Mudah menghapus tag dari catatan.
    *   **Manajemen Tag (Opsional MVP):** Halaman khusus untuk rename/delete tag secara global.

*   **7.4. Pencarian & Penyaringan**
    *   **Pencarian Global:** Kotak pencarian untuk mencari di semua judul dan konten catatan.
    *   **Penyaringan Aktif:** Saat berada di dalam folder, daftar catatan otomatis terfilter untuk folder tersebut. Saat memilih tag, daftar catatan terfilter.

*   **7.5. Otentikasi & Sinkronisasi Pengguna (Supabase)**
    *   **Registrasi:** Email & Password.
    *   **Login:** Email & Password.
    *   **Logout.**
    *   **Sinkronisasi Real-time:** Perubahan (catatan, folder, tag) otomatis tersinkronisasi ke Supabase dan ke perangkat lain yang login dengan akun sama.
    *   **Mode Offline Sederhana (Opsional MVP):** Kemampuan membaca catatan yang sudah disinkronkan saat offline. Pembuatan/edit saat offline bisa di-queue dan disinkronkan saat online lagi (fitur lebih advanced).

*   **7.6. Antarmuka Pengguna (UI) & Pengalaman Pengguna (UX)**
    *   **Desain Modern & Clean:** Terinspirasi Notion. Banyak whitespace, tipografi yang baik, palet warna minimalis dan menenangkan.
    *   **Navigasi Intuitif:**
        *   Sidebar (kiri): Untuk daftar Folder, Tag, dan mungkin link ke "Semua Catatan", "Pengaturan".
        *   Area Konten Utama (kanan): Menampilkan daftar catatan (terfilter) atau editor catatan.
    *   **Responsif:** Tampilan menyesuaikan dengan baik di berbagai ukuran layar smartphone.
    *   **Tema (Opsional MVP):** Mode Terang (default) dan Mode Gelap.

**8. Arsitektur Teknis**
*   **Frontend:** Flutter (Dart)
*   **Backend:** Supabase
    *   **Otentikasi:** Supabase Auth (Email/Password)
    *   **Database:** Supabase PostgreSQL
        *   Tabel `users` (disediakan Supabase Auth)
        *   Tabel `folders` (id, user_id, name, created_at, updated_at)
        *   Tabel `notes` (id, user_id, folder_id (nullable), title, content, created_at, updated_at)
        *   Tabel `tags` (id, user_id, name, created_at)
        *   Tabel `note_tags` (note_id, tag_id) - Tabel pivot untuk relasi Many-to-Many antara notes dan tags.
    *   **Realtime:** Supabase Realtime Subscriptions untuk sinkronisasi.
    *   **Storage (Opsional Masa Depan):** Supabase Storage jika ingin menambahkan fitur lampiran file.
*   **State Management (Flutter):** Pilih salah satu (Provider, Riverpod, BLoC/Cubit, GetX). Riverpod atau BLoC/Cubit sering direkomendasikan untuk skala menengah.
*   **Navigasi (Flutter):** GoRouter atau Navigator 2.0 bawaan.

**9. Desain & UX Wireframes/Mockups (Perlu dibuat terpisah)**
*   Sangat direkomendasikan untuk membuat wireframes atau mockups sederhana (bisa pakai Figma, Balsamiq, atau bahkan kertas) untuk:
    *   Layar utama (daftar catatan/folder)
    *   Layar editor catatan
    *   Tampilan folder dan tag di sidebar
    *   Alur otentikasi (login/register)
    *   Dialog/popup (misal konfirmasi hapus)

**10. Kebutuhan Non-Fungsional**
*   **Performa:** Aplikasi harus responsif, loading cepat, dan tidak ada lag saat mengetik atau navigasi.
*   **Keamanan:** Data pengguna harus aman. Manfaatkan Row Level Security (RLS) di Supabase.
*   **Stabilitas:** Minimalkan crash dan bug.
*   **Skalabilitas:** Supabase membantu dalam hal ini dari sisi backend.
*   **Kemudahan Penggunaan:** Intuitif dan mudah dipelajari oleh target pengguna.
*   **Keterbacaan Kode:** Kode yang bersih dan terstruktur untuk kemudahan maintenance.

**11. Metrik Kesuksesan (Untuk Tugas Kuliah)**
*   Fungsionalitas inti (catatan, folder, tag) berjalan sesuai spesifikasi.
*   Integrasi dengan Supabase (Auth, DB, Realtime) berhasil.
*   Desain UI/UX sesuai dengan konsep modern & clean.
*   Aplikasi stabil dan bebas dari bug kritikal.
*   Mendapatkan nilai yang baik dari dosen pembimbing. :)

**12. Rencana Rilis (MVP - Minimum Viable Product)**
Fokus pada fitur inti untuk rilis pertama (tugas kuliah):
*   Otentikasi pengguna (email/password).
*   CRUD Catatan (Create, Read, Update, Delete) dengan editor teks sederhana.
*   CRUD Folder (Create, Read, Update, Delete).
*   Kemampuan memindahkan catatan ke folder.
*   Penambahan dan penghapusan tag pada catatan.
*   Filter catatan berdasarkan folder dan satu tag.
*   Pencarian sederhana berdasarkan judul catatan.
*   Sinkronisasi dasar dengan Supabase.
*   Desain UI yang bersih dan fungsional.

**13. Pertimbangan Masa Depan (Setelah MVP/Tugas Selesai)**
*   Editor teks lebih kaya (Markdown support, heading, blockquote, code block, images).
*   Nested folders (folder di dalam folder).
*   Fitur "Trash" untuk catatan yang dihapus.
*   Kemampuan mengurutkan catatan (berdasarkan tanggal, judul, dll.).
*   Filter multi-tag yang lebih canggih.
*   Pengingat (Reminders) pada catatan.
*   Kolaborasi (berbagi catatan/folder dengan pengguna lain).
*   Lampiran file (images, PDF).
*   Mode offline yang lebih robus.
*   Impor/Ekspor catatan.
*   Tema kustomisasi.
*   Shortcut keyboard.

**14. Fitur yang Tidak Termasuk (Out of Scope untuk MVP/Tugas)**
*   Kolaborasi real-time antar banyak pengguna pada satu catatan.
*   Fitur chat/komentar.
*   Integrasi kalender.
*   Analitik penggunaan aplikasi yang kompleks.
*   Fitur AI.