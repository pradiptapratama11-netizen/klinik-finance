# Klinik Finance Online — panduan publikasi

## Isi paket
- `index.html`: aplikasi web (dashboard, transaksi, utang, laporan, login Supabase)
- `schema.sql`: struktur database
- `manifest.webmanifest`, `sw.js`, ikon: dukungan PWA

## Publikasikan via GitHub Pages
1. Login ke https://github.com/
2. Buat repository `klinik-finance`. Untuk GitHub Pages gratis, pilih Public. Jangan unggah password atau secret key.
3. Klik Add file > Upload files, lalu unggah file-file di dalam paket ini ke root repository (bukan file ZIP).
4. Commit changes.
5. Buka Settings > Pages; pilih Deploy from a branch, branch `main`, folder `/(root)`, lalu Save.
6. Setelah GitHub memberi URL HTTPS, buka URL itu.
7. Pada pemakaian pertama, masukkan Supabase Project URL dan publishable key. Konfigurasi tersimpan di browser masing-masing perangkat.
8. Login dengan akun yang dibuat di Supabase Authentication.
9. Android: Chrome > menu ⋮ > Install app/Add to Home screen. iPhone: Safari > Share > Add to Home Screen.

## Database dan keamanan
Jika SQL database belum dijalankan, jalankan `schema.sql` di Supabase SQL Editor. Jangan menjalankan ulang saat ada error yang belum diperiksa.
Gunakan hanya Project URL dan publishable/anon key di browser. Jangan pernah memasukkan `service_role` atau secret key.
Pastikan RLS aktif. Jangan masukkan data pasien atau informasi medis. Uji transaksi nominal kecil dan lakukan backup sebelum penggunaan operasional.
