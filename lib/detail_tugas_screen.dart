import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sinauapp/services/notif_service.dart';
import 'package:sinauapp/tambah_tugas.dart';

class DetailTugasScreen extends StatelessWidget {
  final String documentId;

  const DetailTugasScreen({super.key, required this.documentId});

  
  void _toggleTaskStatus(BuildContext context, DocumentSnapshot tugasDoc) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final tugasId = tugasDoc.id;
    final statusRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('statusTugas')
        .doc(tugasId);

    // Dialog konfirmasi
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selesaikan Tugas?'),
        content: const Text(
          'Tugas ini akan ditandai sebagai "sudah dikerjakan".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              // Tandai sebagai selesai
              statusRef.set({'dikerjakan': true});

              final data = tugasDoc.data() as Map<String, dynamic>;
              NotificationService().showNotification(
                'Tugas Selesai! 🎉',
                'Kerja bagus! Tugas ${data['nama_matakuliah']} telah diselesaikan.',
              );


              Navigator.of(context).pop(); 
              Navigator.of(context).pop(); 
            },
            child: const Text('Ya, Selesaikan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tugas'),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('tugas')
            .doc(documentId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Tugas tidak ditemukan.'));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Gagal memuat data tugas.'));
          }

          final doc = snapshot.data!;
          final data = doc.data() as Map<String, dynamic>;
          final deadline = (data['deadline_tugas'] as Timestamp).toDate();
          final lastUpdated = (data['updated_at'] as Timestamp).toDate();

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem('Nama MK:', data['nama_matakuliah']),
                const SizedBox(height: 24),
                _buildDetailItem(
                  'Terakhir Diubah:',
                  DateFormat('d MMMM yyyy, HH:mm').format(lastUpdated),
                ),
                const SizedBox(height: 24),
                _buildDetailItem(
                  'Deadline Tugas:',
                  DateFormat('EEEE, d MMMM yyyy').format(deadline),
                ),
                const SizedBox(height: 24),
                _buildDetailItem(
                  'Deskripsi Tugas:',
                  data['deskripsi_tugas'],
                  maxLines: 5,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TambahTugasScreen(tugasToEdit: doc),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFBBF24),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Edit tugas',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _toggleTaskStatus(
                      context,
                      doc,
                    ), // Memanggil fungsi yang diperbarui
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34D399),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Sudah dikerjakan',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailItem(String title, String value, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18, color: Colors.black87),
        ),
      ],
    );
  }
}
