import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sinauapp/loginscreen.dart';
import 'package:sinauapp/main_layout.dart';
import 'package:sinauapp/services/notif_service.dart';

// Import file konfigurasi yang dibuat oleh FlutterFire CLI
import 'firebase_options.dart';

void main() async {
  // Pastikan semua plugin terinisialisasi sebelum menjalankan aplikasi
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase menggunakan file firebase_options.dart
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inisialisasi service notifikasi lokal
  await NotificationService().init();

  // Jalankan aplikasi
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SinauApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'poppins', // Opsional, jika Anda menambahkan font Poppins
        scaffoldBackgroundColor: const Color(0xFFF0F2F5), // Warna latar belakang netral
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder secara otomatis memantau status login pengguna
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Tampilkan loading indicator saat koneksi sedang berjalan
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Jika snapshot memiliki data, artinya pengguna sudah login
        if (snapshot.hasData) {
          return const MainLayout(); // Arahkan ke halaman utama (beranda, tugas, dll.)
        }

        // Jika tidak ada data, artinya pengguna belum login
        return const LoginScreen(); // Arahkan ke halaman login
      },
    );
  }
}