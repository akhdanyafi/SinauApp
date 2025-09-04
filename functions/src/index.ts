// File: functions/src/index.ts

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Inisialisasi Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();

/**
 * Cloud Function terjadwal untuk menghapus tugas-tugas lama.
 */
export const hapusTugasLama = functions.pubsub
  .schedule("every day 01:00")
  .timeZone("Asia/Jakarta")
  .onRun(async () => { // Parameter 'context' dihapus karena tidak digunakan
    // Tentukan tanggal batas (hari ini - 21 hari).
    const batasWaktu = new Date();
    batasWaktu.setDate(batasWaktu.getDate() - 21);

    // Cari semua tugas yang deadline-nya sudah lebih dari 3 minggu yang lalu.
    const query = db.collection("tugas")
      .where("deadline_tugas", "<=", batasWaktu);

    const tugasLamaSnapshot = await query.get();

    // Jika tidak ada tugas yang perlu dihapus, hentikan fungsi.
    if (tugasLamaSnapshot.empty) {
      console.log("Tidak ada tugas lama untuk dihapus.");
      return null;
    }

    // Gunakan batch write untuk menghapus semua dokumen yang ditemukan
    const batch = db.batch();
    tugasLamaSnapshot.docs.forEach((doc) => {
      console.log(`Menjadwalkan penghapusan untuk tugas: ${doc.id}`);
      batch.delete(doc.ref);
    });

    // Jalankan proses penghapusan
    await batch.commit();

    // Tulis log untuk konfirmasi
    console.log(`Berhasil menghapus ${tugasLamaSnapshot.size} tugas lama.`);
    return null;
  });