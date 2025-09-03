import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // --- Logout Logic ---
  Future<void> _logout(BuildContext context) async {
    // Tampilkan dialog konfirmasi sebelum logout
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    // Jika pengguna mengonfirmasi, lakukan proses logout
    if (confirmLogout == true) {
      await FirebaseAuth.instance.signOut();
      // Navigasi akan dihandle oleh StreamBuilder di main.dart
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String displayName =
        user?.displayName ?? user?.email?.split('@')[0] ?? 'Pengguna';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          children: [
            // --- Profile Picture ---
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(
                user?.photoURL ??
                    'https://ui-avatars.com/api/?name=$displayName&background=random&size=128',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // --- Info Cards ---
            _buildInfoCard(
              icon: Icons.person_outline,
              title: 'Nama',
              subtitle: displayName,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.email_outlined,
              title: 'Alamat Email',
              subtitle: user?.email ?? 'Tidak ditemukan',
            ),

            const Spacer(), // Mendorong tombol ke bawah
            // --- Logout Button ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _logout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Logout',
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
      ),
    );
  }

  // --- Reusable Widget for Info Card ---
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      color: const Color.fromARGB(255, 77, 76, 73),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: Icon(
          icon,
          size: 30,
          color: const Color.fromARGB(255, 255, 255, 255),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(221, 255, 255, 255),
          ),
        ),
      ),
    );
  }
}
