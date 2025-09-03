// lib/screens/main_layout.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sinauapp/homescreen.dart';
import 'package:sinauapp/notifikasi_screen.dart';
import 'package:sinauapp/profile_screen.dart';
import 'package:sinauapp/tambah_tugas.dart';
import 'package:sinauapp/tugas_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    TugasScreen(),
    TambahTugasScreen(),
    NotifikasiScreen(),
    ProfileScreen(),
  ];

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- WIDGET UNTUK MEMBUAT IKON LONCENG DENGAN BADGE ---
  Widget _buildNotificationIcon() {
    return StreamBuilder<QuerySnapshot>(
      // Mendengarkan perubahan pada koleksi notifikasi pengguna saat ini
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .collection('notifications')
          .snapshots(),
      builder: (context, snapshot) {
        // Jika tidak ada data, tampilkan ikon biasa
        if (!snapshot.hasData) {
          return IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () => onItemTapped(3),
          );
        }

        // Ambil jumlah notifikasi
        final notificationCount = snapshot.data!.docs.length;

        // Gunakan Stack untuk menumpuk badge di atas ikon
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.white),
              onPressed: () => onItemTapped(3),
            ),
            // Tampilkan badge hanya jika ada notifikasi
            if (notificationCount > 0)
              Positioned(
                top: 10,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF4A90E2),
                      width: 2,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    '$notificationCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String displayName =
        currentUser?.displayName ?? currentUser?.email?.split('@')[0] ?? 'User';
    return Scaffold(
      appBar: AppBar(
        // AppBar sekarang akan selalu ditampilkan
        toolbarHeight: 100,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        title: IconButton(
          onPressed: () {
            onItemTapped(0);
          },
          icon: Image.asset('assets/img/SinauApp.png', height: 50),
        ),
        backgroundColor: const Color(0xFF4A90E2),
        elevation: 0,
        actions: [
          _buildNotificationIcon(), // Panggil widget notifikasi di sini
          Padding(
            padding: const EdgeInsets.only(top: 15, right: 30.0),
            child: IconButton(
              onPressed: () {
                onItemTapped(4);
              },
              icon: Column(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(
                      currentUser?.photoURL ??
                          'https://ui-avatars.com/api/?name=$displayName&background=random',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    displayName,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: Container(
        height: 100,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          color: Colors.blueAccent,
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_rounded),
              label: 'Tugas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_box_rounded),
              label: 'Tambah',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Notifikasi',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Akun'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color.fromARGB(255, 172, 213, 245),
          unselectedItemColor: const Color.fromARGB(255, 255, 255, 255),
          showUnselectedLabels: true,
          onTap: onItemTapped,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      ),
    );
  }
}
