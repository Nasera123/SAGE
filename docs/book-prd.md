Oke, bro! Ide SAGE ini emang punya potensi besar. Mari kita buat PRD (Product Requirements Document) yang lebih proper dan detail untuk fitur publikasi book ini, dengan fokus pada implementasi menggunakan Flutter untuk frontend dan Firebase (Firestore, Firebase Authentication, mungkin Cloud Functions) untuk backend.

Product Requirements Document: SAGE - Fitur Publikasi Book

Versi: 1.0
Tanggal: 26 Oktober 2023
Penulis: [Nama Kamu/Tim SAGE] & AI Assistant
Aplikasi: SAGE (Note-taking & Community Publishing)

1. Pendahuluan

SAGE adalah aplikasi note-taking yang bertujuan untuk memberdayakan pengguna tidak hanya dalam mencatat ide dan pengetahuan pribadi, tetapi juga untuk membagikannya kepada komunitas yang lebih luas. Fitur "Publikasi Book" akan mentransformasi SAGE menjadi platform di mana pengguna dapat dengan mudah mempublikasikan kumpulan catatan mereka sebagai book digital, yang dapat diakses dan dibaca oleh pengguna lain.

2. Tujuan & Sasaran (Goals)

Bagi Pembuat Konten (Creator):

Menyediakan platform untuk mempublikasikan karya tulis/kumpulan catatan dengan mudah.

Meningkatkan visibilitas karya dan membangun audiens.

Mendapatkan pengakuan atas pengetahuan dan kreativitas.

Bagi Pembaca (Reader):

Menyediakan akses ke beragam book informatif dan kreatif dari komunitas SAGE.

Memudahkan penemuan konten berkualitas berdasarkan minat.

Bagi Platform SAGE:

Meningkatkan user engagement dan retensi.

Membangun komunitas yang aktif dan saling berbagi pengetahuan.

Membedakan SAGE dari aplikasi note-taking konvensional.

3. Pengguna Target (Target Users)

Pelajar & Mahasiswa: Mempublikasikan catatan kuliah, ringkasan materi, atau panduan belajar.

Profesional & Ahli: Membagikan pengetahuan industri, best practices, atau studi kasus.

Penulis & Kreator: Mempublikasikan cerita pendek, puisi, esai, atau portofolio.

Pengguna Umum: Siapa saja yang ingin berbagi pengetahuan, hobi, atau panduan.

4. User Stories

Sebagai Pengguna (Pembuat Konten):

Saya ingin bisa menandai book saya sebagai "publik" agar bisa dilihat orang lain.

Saya ingin bisa menarik kembali (unpublish) book saya jika saya tidak ingin lagi menampilkannya secara publik.

Saya ingin melihat status publikasi book saya (apakah sudah publik atau masih privat).

Saya ingin book publik saya memiliki halaman detail yang menampilkan judul, deskripsi, dan semua catatannya.

Sebagai Pengguna (Pembaca):

Saya ingin bisa menjelajahi daftar book yang telah dipublikasikan oleh pengguna lain.

Saya ingin bisa membaca isi book publik secara read-only.

Saya ingin bisa mencari book publik berdasarkan judul atau kata kunci (opsional untuk v1).

Saya ingin bisa melihat siapa penulis book publik (opsional: tautan ke profil penulis).

5. Ruang Lingkup Fitur (MVP - Minimum Viable Product)

5.1. Modifikasi Struktur Data (Firestore)

Koleksi users:

userId (doc ID)

displayName

photoUrl (opsional)

... (data pengguna lainnya)

Koleksi books:

{
  bookId: string (doc ID),
  title: string,
  description: string,
  ownerId: string (referensi ke users/userId),
  ownerDisplayName: string, // Denormalisasi untuk kemudahan query
  isPublic: boolean (default: false),
  createdAt: Timestamp,
  updatedAt: Timestamp,
  coverImageUrl: string (opsional, URL ke gambar sampul),
  // (Opsional untuk v1)
  // tags: List<string>,
  // likeCount: number (default: 0),
}


Sub-Koleksi notes di dalam setiap dokumen books: books/{bookId}/notes

{
  noteId: string (doc ID),
  title: string (opsional, jika note punya judul sendiri),
  content: string (isi note, bisa Markdown/Rich Text),
  order: number (untuk menentukan urutan note dalam book),
  createdAt: Timestamp,
  updatedAt: Timestamp
}
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
IGNORE_WHEN_COPYING_END

5.2. Perubahan pada Antarmuka Pengguna (Flutter)

Halaman "My Books" (Daftar Book Milik Pengguna):

Menampilkan daftar book yang dibuat pengguna.

Untuk setiap book:

Indikator status: "Privat" atau "Publik".

Tombol/Opsi "Publikasikan" (jika isPublic == false).

Tombol/Opsi "Tarik Publikasi" (jika isPublic == true).

Saat "Publikasikan" diklik:

Konfirmasi dialog.

Update field isPublic menjadi true dan updatedAt di Firestore.

Saat "Tarik Publikasi" diklik:

Konfirmasi dialog.

Update field isPublic menjadi false dan updatedAt di Firestore.

Halaman "Explore / Public Library" (Tampilan Baru):

Tab/Menu baru di navigasi utama aplikasi.

Menampilkan daftar card atau list item dari book yang isPublic == true.

Setiap item menampilkan:

coverImageUrl (jika ada, jika tidak, placeholder).

title.

ownerDisplayName.

Potongan description (misal 1-2 baris).

(Opsional V1) likeCount.

Kemampuan infinite scroll atau paginasi untuk memuat lebih banyak book.

Urutan default: berdasarkan updatedAt atau createdAt (terbaru dulu).

Saat item book diklik, navigasi ke "Halaman Detail Book Publik".

Halaman "Book Detail (Public View)" (Tampilan Baru):

Menampilkan informasi book yang dipilih dari halaman "Explore".

Menampilkan:

coverImageUrl (jika ada).

title.

description lengkap.

ownerDisplayName (opsional: bisa diklik untuk ke halaman profil penulis jika fitur itu ada).

Daftar notes dari book tersebut secara read-only, diurutkan berdasarkan field order.

Konten setiap note ditampilkan (misal, jika Markdown, dirender sebagai HTML).

Tidak ada tombol edit/hapus untuk pembaca.

5.3. Logika Backend (Firebase)

Firestore Security Rules:

Membaca books publik:

Izinkan baca untuk koleksi books jika resource.data.isPublic == true.

Izinkan baca untuk sub-koleksi notes dari book publik (books/{bookId}/notes) jika get(/databases/$(database)/documents/books/$(bookId)).data.isPublic == true.

Menulis/Mengubah books:

Izinkan create, update, delete pada books/{bookId} hanya jika request.auth.uid == resource.data.ownerId.

Untuk update status isPublic: hanya ownerId yang boleh.

Menulis/Mengubah notes:

Izinkan create, update, delete pada books/{bookId}/notes/{noteId} hanya jika request.auth.uid == get(/databases/$(database)/documents/books/$(bookId)).data.ownerId.

Operasi Firestore dari Klien (Flutter):

Publikasikan Book:
FirebaseFirestore.instance.collection('books').doc(bookId).update({'isPublic': true, 'updatedAt': FieldValue.serverTimestamp()});

Tarik Publikasi Book:
FirebaseFirestore.instance.collection('books').doc(bookId).update({'isPublic': false, 'updatedAt': FieldValue.serverTimestamp()});

Ambil Daftar Book Publik (Explore Page):
FirebaseFirestore.instance.collection('books').where('isPublic', isEqualTo: true).orderBy('updatedAt', descending: true).limit(20).get(); (dengan paginasi)

Ambil Detail Book Publik:

FirebaseFirestore.instance.collection('books').doc(bookId).get(); (pastikan isPublic == true dari data yang didapat atau filter di query jika memungkinkan).

FirebaseFirestore.instance.collection('books').doc(bookId).collection('notes').orderBy('order').get();

(Opsional) Cloud Functions:

Jika ada logika kompleks saat publikasi (misal: notifikasi, update data agregat), bisa dipertimbangkan. Untuk MVP, operasi klien dengan security rules yang kuat sudah cukup.

Untuk likeCount, Cloud Function bisa digunakan untuk atomic increment/decrement yang lebih aman.

6. Pertimbangan Teknis

Struktur Data Note: Konten note bisa berupa plain text, Markdown, atau format Rich Text Editor. Pilih salah satu dan pastikan renderer di Flutter bisa menampilkannya dengan baik secara read-only.

Paginasi: Untuk halaman "Explore", implementasikan paginasi (misalnya, memuat 20 book per halaman) untuk performa.

Indexing Firestore: Pastikan field yang digunakan untuk query (isPublic, updatedAt, createdAt) diindeks di Firestore untuk performa query yang optimal. Firestore biasanya membuat indeks otomatis untuk field tunggal, tapi untuk query komposit (misal isPublic dan updatedAt), perlu dibuat indeks komposit.

Denormalisasi: Menyimpan ownerDisplayName di dokumen book adalah bentuk denormalisasi untuk menghindari query tambahan saat menampilkan daftar book publik. Perlu di-update jika displayName pengguna berubah (bisa via Cloud Function yang di-trigger saat update profil pengguna, atau saat pengguna mengedit book-nya).

Gambar Sampul (coverImageUrl): Pengguna bisa mengunggah gambar sampul. Simpan di Firebase Storage, lalu URL-nya disimpan di field coverImageUrl.

7. Pertimbangan Keamanan & Privasi

Firestore Security Rules adalah kunci utama. Pastikan hanya book dengan isPublic == true yang bisa diakses publik.

Hanya pemilik book yang dapat mengubah status isPublic dan konten book.

Data pengguna yang ditampilkan di publik (seperti ownerDisplayName) harus merupakan data yang memang dimaksudkan untuk publik. Jangan tampilkan email atau informasi sensitif lainnya.

Pertimbangkan batasan ukuran untuk deskripsi, judul, dan konten note untuk mencegah penyalahgunaan.

8. Langkah Implementasi (High-Level)

Backend Setup (Firebase):

Buat proyek Firebase.

Aktifkan Firestore dan Firebase Authentication.

(Opsional) Aktifkan Firebase Storage jika menggunakan coverImageUrl.

Modifikasi Model & Firestore Structure:

Implementasikan model Book dan Note di Flutter.

Tambahkan field isPublic, ownerDisplayName, coverImageUrl (opsional) pada struktur books di Firestore.

Sesuaikan struktur notes sebagai sub-koleksi.

Update Halaman "My Books":

Tambahkan UI untuk menampilkan status publikasi.

Implementasikan fungsi "Publish" dan "Unpublish" yang mengupdate Firestore.

Buat Halaman "Explore / Public Library":

Desain UI untuk menampilkan daftar book publik.

Implementasikan query ke Firestore untuk mengambil book dengan isPublic == true, dengan paginasi.

Buat Halaman "Book Detail (Public View)":

Desain UI untuk menampilkan detail book dan konten notes-nya secara read-only.

Implementasikan query untuk mengambil data book spesifik dan notes-nya.

Implementasikan Firestore Security Rules:

Tulis dan uji aturan keamanan yang ketat.

Testing:

Uji semua alur dari perspektif pembuat konten dan pembaca.

Uji kasus edge dan keamanan.

9. Metrik Keberhasilan (Success Metrics) - untuk V1

Jumlah book yang dipublikasikan.

Jumlah views pada halaman "Explore".

Jumlah views pada halaman "Book Detail (Public View)".

Waktu rata-rata yang dihabiskan pengguna di halaman "Explore" dan "Book Detail".

10. Fitur Masa Depan (Post-MVP)

Interaksi Sosial: Suka (likes), komentar pada book.

Profil Penulis Publik: Halaman yang menampilkan semua book publik dari seorang penulis.

Mengikuti Penulis (Follow Author).

Pencarian & Filter Lanjutan: Berdasarkan kategori/tag, popularitas, rating.

Sistem Kategori/Tagging untuk book.

Notifikasi untuk penulis ketika book-nya disukai/dikomentari, atau untuk pengikut ketika penulis favoritnya mempublikasikan book baru.

Analytics untuk Penulis: Jumlah pembaca, likes, dll.

Draft Mode: Sebelum benar-benar publik, book bisa di-preview oleh penulis dalam mode publik.

Dokumen ini memberikan kerangka kerja yang cukup solid untuk memulai. Jika ada bagian yang ingin didetailkan lagi, misalnya terkait flow spesifik di UI Flutter atau struktur query Firestore yang lebih kompleks, kasih tahu aja ya, bro! Mantap SAGE!