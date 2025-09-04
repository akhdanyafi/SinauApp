import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sinauapp/services/notif_service.dart';

class TambahTugasScreen extends StatefulWidget {
  final DocumentSnapshot? tugasToEdit;

  const TambahTugasScreen({super.key, this.tugasToEdit});

  @override
  State<TambahTugasScreen> createState() => _TambahTugasScreenState();
}

class _TambahTugasScreenState extends State<TambahTugasScreen> {
  final _deskripsiController = TextEditingController();
  final NotificationService _notificationService = NotificationService();
  final _formKey = GlobalKey<FormState>();

  String? _selectedMatkul;
  DateTime? _selectedDeadline;
  bool _isLoading = false;
  bool get _isEditMode => widget.tugasToEdit != null;

  final List<String> _matkulList = [
    'Teknopreneur',
    'Pemrograman Web Dinamis',
    'AI dan pembelajaran mesin',
    'Komputer Grafik & Pengolahan Citra',
    'Keamanan Komputer',
    'Finansial',
    'Teori Bahasa Formal dan Automata',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final data = widget.tugasToEdit!.data() as Map<String, dynamic>;
      _selectedMatkul = data['nama_matakuliah'];
      _selectedDeadline = (data['deadline_tugas'] as Timestamp).toDate();
      _deskripsiController.text = data['deskripsi_tugas'];
    }
  }

  Future<void> _pilihDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDeadline) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  Future<void> _simpanTugas() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deadline tugas harus diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditMode) {
        await FirebaseFirestore.instance
            .collection('tugas')
            .doc(widget.tugasToEdit!.id)
            .update({
              'nama_matakuliah': _selectedMatkul,
              'deadline_tugas': Timestamp.fromDate(_selectedDeadline!),
              'deskripsi_tugas': _deskripsiController.text,
              'updated_at': Timestamp.now(),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tugas berhasil diperbarui!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        final int notificationId = DateTime.now().millisecondsSinceEpoch
            .remainder(100000);
        await FirebaseFirestore.instance.collection('tugas').add({
          'nama_matakuliah': _selectedMatkul,
          'deadline_tugas': Timestamp.fromDate(_selectedDeadline!),
          'deskripsi_tugas': _deskripsiController.text,
          'created_at': Timestamp.now(),
          'updated_at': Timestamp.now(),
          'notificationId': notificationId,
          'userId': FirebaseAuth.instance.currentUser?.uid,
        });

        await _notificationService.showNotification(
          'Tugas Baru Ditambahkan!',
          'Tugas mata kuliah $_selectedMatkul berhasil disimpan.',
        );
        await _notificationService.scheduleDailyNotification(
          notificationId,
          'Jangan Lupa Tugas SinauApp!',
          'Kerjakan tugas $_selectedMatkul sebelum deadline.',
          _selectedDeadline!,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tugas berhasil ditambahkan!'),
              backgroundColor: Colors.green,
            ),
          );
          _formKey.currentState!.reset();
          setState(() {
            _selectedMatkul = null;
            _selectedDeadline = null;
            _deskripsiController.clear();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan tugas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _deskripsiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Tugas' : 'Tambah Tugas'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Nama MK'),
              DropdownButtonFormField<String>(
                value: _selectedMatkul,
                hint: const Text('Pilih mata kuliah'),
                items: _matkulList.map((String matkul) {
                  return DropdownMenuItem<String>(
                    value: matkul,
                    child: Text(matkul),
                  );
                }).toList(),
                onChanged: (newValue) =>
                    setState(() => _selectedMatkul = newValue),
                validator: (value) =>
                    value == null ? 'Mata kuliah harus dipilih' : null,
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Deadline Tugas'),
              GestureDetector(
                onTap: () => _pilihDeadline(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDeadline == null
                            ? 'Pilih tanggal'
                            : DateFormat(
                                'EEEE, d MMMM yyyy',
                              ).format(_selectedDeadline!),
                        style: TextStyle(
                          color: _selectedDeadline == null
                              ? Colors.grey[700]
                              : Colors.black,
                          fontSize: 16,
                        ),
                      ),
                      Icon(Icons.calendar_today, color: Colors.grey[700]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Deskripsi Tugas'),
              TextFormField(
                controller: _deskripsiController,
                maxLines: 6,
                validator: (value) => value == null || value.isEmpty
                    ? 'Deskripsi tidak boleh kosong'
                    : null,
                decoration: _inputDecoration(
                  hint: 'Jelaskan detail tugas di sini...',
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _simpanTugas,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF50C878),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          _isEditMode ? 'Update' : 'Simpan',
                          style: const TextStyle(
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
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue),
      ),
    );
  }
}
