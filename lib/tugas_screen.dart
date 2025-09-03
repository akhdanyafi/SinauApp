// lib/screens/tugas_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sinauapp/detail_tugas_screen.dart';
import 'package:sinauapp/services/notif_service.dart';

class TugasScreen extends StatefulWidget {
  const TugasScreen({super.key});

  @override
  State<TugasScreen> createState() => _TugasScreenState();
}

class _TugasScreenState extends State<TugasScreen> {
  String _selectedFilter = 'Semua';
  final NotificationService _notificationService = NotificationService();
  late Stream<QuerySnapshot> _tugasStream;

  // --- PENAMBAHAN 1: State untuk fitur search ---
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tugasStream = FirebaseFirestore.instance
        .collection('tugas')
        .orderBy('deadline_tugas')
        .snapshots();

    // --- PENAMBAHAN 2: Listener untuk memantau input search ---
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  // --- PENAMBAHAN 3: Dispose controller untuk mencegah memory leak ---
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ... (fungsi _toggleTaskStatus dan _navigateToDetail tetap sama)
  void _toggleTaskStatus(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final bool isNowDone = !data['dikerjakan'];
    final int notificationId = data['notificationId'] ?? 0;

    FirebaseFirestore.instance
        .collection('tugas')
        .doc(doc.id)
        .update({'dikerjakan': isNowDone})
        .then((_) {
          if (isNowDone && notificationId != 0) {
            _notificationService.cancelNotification(notificationId);
            _notificationService.showNotification(
              'Tugas Selesai! 🎉',
              'Kerja bagus! Tugas ${data['nama_matakuliah']} telah diselesaikan.',
            );
          }
        });
  }

  void _navigateToDetail(String docId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailTugasScreen(documentId: docId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tugas Kuliah'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  // --- MODIFIKASI 1: Hubungkan controller ke TextField ---
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari berdasarkan MK atau deskripsi...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('tugas')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final matkulSet = <String>{};
                      for (var doc in snapshot.data!.docs) {
                        matkulSet.add(doc['nama_matakuliah'] as String);
                      }
                      final matkulList = ['Semua', ...matkulSet.toList()];
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: matkulList.length,
                        itemBuilder: (context, index) {
                          final matkul = matkulList[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(matkul),
                              selected: _selectedFilter == matkul,
                              onSelected: (selected) {
                                if (selected)
                                  setState(() => _selectedFilter = matkul);
                              },
                              selectedColor: const Color.fromARGB(
                                255,
                                47,
                                49,
                                52,
                              ),
                              labelStyle: TextStyle(
                                color: _selectedFilter == matkul
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                              backgroundColor: Colors.grey[200],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _tugasStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Hore! Tidak ada tugas saat ini.",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                var allTugas = snapshot.data!.docs;

                // --- MODIFIKASI 2: Terapkan semua filter di sini ---
                final tugasBelumDikerjakan = allTugas.where(
                  (doc) => !(doc['dikerjakan'] as bool),
                );

                final List<DocumentSnapshot> filteredByCourse;
                if (_selectedFilter != 'Semua') {
                  filteredByCourse = tugasBelumDikerjakan
                      .where((doc) => doc['nama_matakuliah'] == _selectedFilter)
                      .toList();
                } else {
                  filteredByCourse = tugasBelumDikerjakan.toList();
                }

                final List<DocumentSnapshot> searchResult;
                if (_searchQuery.isNotEmpty) {
                  searchResult = filteredByCourse.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final matkul = data['nama_matakuliah']
                        .toString()
                        .toLowerCase();
                    final deskripsi = data['deskripsi_tugas']
                        .toString()
                        .toLowerCase();
                    final query = _searchQuery.toLowerCase();
                    return matkul.contains(query) || deskripsi.contains(query);
                  }).toList();
                } else {
                  searchResult = filteredByCourse;
                }
                // --- AKHIR DARI BLOK FILTER ---

                if (searchResult.isEmpty) {
                  return const Center(
                    child: Text(
                      "Tidak ada tugas yang cocok.",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final tugasLewatDL = searchResult
                    .where(
                      (t) => (t['deadline_tugas'] as Timestamp)
                          .toDate()
                          .isBefore(today),
                    )
                    .toList();
                final tugasLainnya = searchResult
                    .where(
                      (t) => !(t['deadline_tugas'] as Timestamp)
                          .toDate()
                          .isBefore(today),
                    )
                    .toList();

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    if (tugasLewatDL.isNotEmpty) ...[
                      _buildCategoryHeader("Tugas lewat deadline"),
                      ...tugasLewatDL.map(
                        (doc) => _buildTugasCard(doc, Colors.red.shade300),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (tugasLainnya.isNotEmpty) ...[
                      _buildCategoryHeader("Tugas - tugas kuliah kamu"),
                      ...tugasLainnya.map(
                        (doc) => _buildTugasCard(doc, Colors.blue.shade300),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ... (widget _buildCategoryHeader dan _buildTugasCard tetap sama)
  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTugasCard(DocumentSnapshot doc, Color color) {
    final data = doc.data() as Map<String, dynamic>;
    final deadline = (data['deadline_tugas'] as Timestamp).toDate();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: InkWell(
        onTap: () => _navigateToDetail(doc.id),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border(left: BorderSide(color: color, width: 8)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              data['nama_matakuliah'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Deadline: ${DateFormat('EEEE, d MMMM yyyy').format(deadline)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: Transform.scale(
              scale: 1.2,
              child: Checkbox(
                value: data['dikerjakan'],
                onChanged: (bool? value) => _toggleTaskStatus(doc),
                activeColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: BorderSide(color: Colors.grey[400]!, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
