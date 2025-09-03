// lib/services/notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // --- Singleton Pattern Setup ---
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Menginisialisasi service notifikasi dan meminta izin.
  /// Harus dipanggil saat aplikasi pertama kali dijalankan (di main.dart).
  Future<void> init() async {
    // Inisialisasi pengaturan untuk Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Menggunakan ikon default aplikasi

    // Pengaturan inisialisasi umum
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // Inisialisasi plugin
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
    
    // --- TAMBAHKAN BAGIAN INI UNTUK MEMINTA IZIN ---
    // Meminta izin notifikasi secara eksplisit (wajib untuk Android 13+)
    // Ini akan menampilkan dialog pop-up kepada pengguna.
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
    // --- AKHIR DARI BAGIAN YANG DITAMBAHKAN ---

    // Inisialisasi database timezone
    tz.initializeTimeZones();
  }

  /// Menampilkan notifikasi instan dan menyimpan riwayatnya ke Firestore.
  Future<void> showNotification(String title, String body) async {
    // Detail spesifik untuk notifikasi Android (channel, prioritas, dll.)
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'sinauapp_channel_id_instant', // ID Channel unik
      'Notifikasi Instan SinauApp',
      channelDescription: 'Channel untuk notifikasi instan seperti tambah/selesai tugas',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Menampilkan notifikasi
    await _flutterLocalNotificationsPlugin.show(
      0, // ID 0 untuk notifikasi instan (bisa ditimpa)
      title,
      body,
      platformChannelSpecifics,
    );

    // Menyimpan salinan notifikasi ini ke Firestore
    await _saveNotificationToFirestore(title, body);
  }

  /// Menjadwalkan notifikasi harian yang berulang pada jam 8 pagi.
  Future<void> scheduleDailyNotification(int id, String title, String body, DateTime deadline) async {
    final now = tz.TZDateTime.now(tz.local);
    // Mengatur waktu notifikasi ke jam 8 pagi
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8);

    // Jika jam 8 pagi hari ini sudah lewat, jadwalkan untuk besok
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Hanya jadwalkan jika tanggalnya masih sebelum atau sama dengan deadline
    if (!scheduledDate.isAfter(deadline.add(const Duration(days: 1)))) { // Beri toleransi 1 hari
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id, // ID unik dari tugas
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'sinauapp_channel_id_daily', // ID Channel unik untuk pengingat
            'Pengingat Harian SinauApp',
            channelDescription: 'Channel untuk notifikasi pengingat tugas harian',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Ini yang membuat notifikasi berulang setiap hari pada jam yang sama
      );
    }
  }

  /// Membatalkan notifikasi terjadwal berdasarkan ID uniknya.
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Helper private untuk menyimpan riwayat notifikasi ke Firestore.
  Future<void> _saveNotificationToFirestore(String title, String body) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; 

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('Gagal menyimpan notifikasi ke Firestore: $e');
    }
  }
}