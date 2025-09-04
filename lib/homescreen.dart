import 'package:sinauapp/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:sinauapp/detail_tugas_screen.dart';
import 'package:sinauapp/services/notif_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final NotificationService _notificationService = NotificationService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  void _toggleTaskStatus(DocumentSnapshot tugasDoc) {
    if (currentUser == null) return;
    final tugasId = tugasDoc.id;
    final statusRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('statusTugas')
        .doc(tugasId);

    statusRef.get().then((doc) {
      if (doc.exists) {
        statusRef.delete(); 
      } else {
        statusRef.set({'dikerjakan': true}); 
        final data = tugasDoc.data() as Map<String, dynamic>;
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
    String displayName =
        currentUser?.displayName ?? currentUser?.email?.split('@')[0] ?? 'User';

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser?.uid)
            .collection('statusTugas')
            .snapshots(),
        builder: (context, statusSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tugas')
                .orderBy('deadline_tugas')
                .snapshots(),
            builder: (context, tugasSnapshot) {
              if (tugasSnapshot.connectionState == ConnectionState.waiting || statusSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: LoadingAnimationWidget.flickr(
                    leftDotColor: Colors.redAccent,
                    rightDotColor: Colors.blueAccent,
                    size: 50,
                  ),
                );
              }

              final List<DocumentSnapshot> semuaTugas = tugasSnapshot.data?.docs ?? [];
              final Set<String> idTugasSelesai = statusSnapshot.data?.docs.map((doc) => doc.id).toSet() ?? {};
              
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final threeDaysFromNow = today.add(const Duration(days: 3));

              final tugasBelumSelesai = semuaTugas.where((tugas) => !idTugasSelesai.contains(tugas.id)).toList();
              final tugasSelesai = semuaTugas.where((tugas) => idTugasSelesai.contains(tugas.id)).toList();
              
              final tugasLewatDL = tugasBelumSelesai.where((t) {
                final deadline = (t['deadline_tugas'] as Timestamp).toDate();
                return deadline.isBefore(today);
              }).toList();

              final tugasMepetDL = tugasBelumSelesai.where((t) {
                final deadline = (t['deadline_tugas'] as Timestamp).toDate();
                return !deadline.isBefore(today) && deadline.isBefore(threeDaysFromNow);
              }).toList();
              
              final tugasAkanDatang = tugasBelumSelesai.where((t) {
                final deadline = (t['deadline_tugas'] as Timestamp).toDate();
                return !deadline.isBefore(threeDaysFromNow);
              }).toList();
              
              final tugasSaatIni = tugasBelumSelesai;
              
              final Map<DateTime, List<DocumentSnapshot>> deadlineEvents = {};
              for (var tugas in tugasSaatIni) {
                final deadline = (tugas['deadline_tugas'] as Timestamp).toDate();
                final deadlineDate = DateTime.utc(deadline.year, deadline.month, deadline.day);
                if (deadlineEvents[deadlineDate] == null) {
                  deadlineEvents[deadlineDate] = [];
                }
                deadlineEvents[deadlineDate]!.add(tugas);
              }

              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Text('Selamat Datang, $displayName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryCard('Lewat DL', tugasLewatDL.length, const Color(0xFFF87171)),
                      _buildSummaryCard('Mepet DL', tugasMepetDL.length, const Color(0xFFFBBF24)),
                      _buildSummaryCard('Saat Ini', tugasSaatIni.length, const Color(0xFF60A5FA)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Kalender Deadline Tugas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Card(
                    color: const Color.fromARGB(255, 209, 228, 238),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onFormatChanged: (format) {
                        if (_calendarFormat != format) setState(() => _calendarFormat = format);
                      },
                      onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                      eventLoader: (day) => deadlineEvents[DateTime.utc(day.year, day.month, day.day)] ?? [],
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(color: Colors.blue.shade200, shape: BoxShape.circle),
                        selectedDecoration: BoxDecoration(color: Colors.blue.shade400, shape: BoxShape.circle),
                        markerDecoration: const BoxDecoration(color: Color.fromARGB(255, 255, 0, 0), shape: BoxShape.circle),
                      ),
                      headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Tugas yang sudah dikerjakan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (tugasSelesai.isNotEmpty)
                    ...tugasSelesai.map((tugas) => _buildTugasCard(tugas, const Color(0xFF34D399), true))
                  else
                    _buildEmptyStateCard("Belum ada tugas yang selesai dikerjakan."),
                  const SizedBox(height: 24),
                  const Text('Tugas mepet deadline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (tugasMepetDL.isNotEmpty)
                    ...tugasMepetDL.map((tugas) => _buildTugasCard(tugas, const Color(0xFFFBBF24), false))
                  else
                    _buildEmptyStateCard("Tidak ada tugas yang mendekati deadline."),
                  const SizedBox(height: 24),
                  const Text('Tugas Akan Datang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (tugasAkanDatang.isNotEmpty)
                    ...tugasAkanDatang.map((tugas) => _buildTugasCard(tugas, const Color(0xFF60A5FA), false))
                  else
                    _buildEmptyStateCard("Tidak ada tugas lain yang akan datang."),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        (context.findAncestorStateOfType<State<MainLayout>>() as dynamic)?.onItemTapped(1);
                      },
                      icon: const Icon(Icons.list_alt),
                      label: const Text('Lihat Semua Tugas'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4A90E2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  
  Widget _buildTugasCard(DocumentSnapshot doc, Color color, bool isDone) {
    final data = doc.data() as Map<String, dynamic>;
    final deadline = (data['deadline_tugas'] as Timestamp).toDate();

    return Card(
      color: color,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => _navigateToDetail(doc.id),
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: const Icon(Icons.school, color: Colors.white, size: 30),
          title: Text(data['nama_matakuliah'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          subtitle: Text('Deadline: ${DateFormat('d MMMM yyyy').format(deadline)}', style: const TextStyle(color: Colors.white70)),
          trailing: isDone
              ? IconButton(
                  icon: const Icon(Icons.undo, color: Colors.white),
                  tooltip: 'Tandai Belum Selesai',
                  onPressed: () => _toggleTaskStatus(doc),
                )
              : Transform.scale(
                  scale: 1.2,
                  child: Checkbox(
                    value: false,
                    onChanged: (bool? value) => _toggleTaskStatus(doc),
                    checkColor: color,
                    activeColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    side: const BorderSide(color: Colors.white, width: 2),
                  ),
                ),
        ),
      ),
    );
  }
  
  Widget _buildSummaryCard(String title, int count, Color color) {
    return Expanded(
      child: Card(
        color: color,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              Text(count.toString(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard(String message) {
    return Card(
      color: Colors.grey[200],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Text(
            message,
            style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
          ),
        ),
      ),
    );
  }
}