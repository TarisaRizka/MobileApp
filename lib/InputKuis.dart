import 'package:finalproject_mobapp/Review.dart';
import 'package:finalproject_mobapp/soal.dart';
import 'package:finalproject_mobapp/SoalEssay.dart'; // Import your QuizApp
import 'package:finalproject_mobapp/Auth.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math';
import 'dart:io';
import 'dart:typed_data';

// Enum untuk mode aplikasi
enum AppMode { teacher, student }

class InputKuisTab extends StatefulWidget {
  final AuthService authService;

  const InputKuisTab({
    Key? key,
    required this.authService,
  }) : super(key: key);

  @override
  InputKuisTabState createState() => InputKuisTabState();
}

class InputKuisTabState extends State<InputKuisTab> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> kelasList = [];
  bool isLoading = false;
  ScreenshotController screenshotController = ScreenshotController();
  
  // Mode aplikasi berdasarkan user type
  AppMode currentMode = AppMode.student;
  bool isLoadingUserType = true;

  @override
  void initState() {
    super.initState();
    _loadUserType();
    _loadKelas();
    _requestPermissions();
  }

  // Load user type from AuthService
  Future<void> _loadUserType() async {
    try {
      final userInfo = await widget.authService.getCurrentUserInfo();
      String userType = userInfo?['userType'] ?? AuthService.userTypeStudent;
      
      // Normalize user type
      if (userType.toLowerCase().contains('teacher')) {
        userType = AuthService.userTypeTeacher;
      } else {
        userType = AuthService.userTypeStudent;
      }

      setState(() {
        currentMode = userType == AuthService.userTypeTeacher 
            ? AppMode.teacher 
            : AppMode.student;
        isLoadingUserType = false;
      });

      print('InputKuis: User type loaded: $userType, Mode: $currentMode');
    } catch (e) {
      print('InputKuis: Error loading user type: $e');
      setState(() {
        currentMode = AppMode.student; // Default to student
        isLoadingUserType = false;
      });
    }
  }

  // Request permissions untuk menyimpan file
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
      // Untuk Android 13+ (API 33+)
      await Permission.photos.request();
      await Permission.mediaLibrary.request();
    } else if (Platform.isIOS) {
      await Permission.photos.request();
    }
  }

  // Generate random kode kuis
  String _generateKodeKuis() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  // Generate ID MK
  String _generateIdMK() {
    return 'MK${DateTime.now().millisecondsSinceEpoch}';
  }

  // Load semua data kelas
  Future<void> _loadKelas() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await supabase
          .from('kelas')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        kelasList = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $error')),
      );
    }
  }

  // Create kelas baru
  Future<void> _createKelas(String mk) async {
    try {
      final kodeKuis = _generateKodeKuis();
      final idMK = _generateIdMK();

      await supabase.from('kelas').insert({
        'mk': mk,
        'kode_kuis': kodeKuis,
        'id_mk': idMK,
        'created_at': DateTime.now().toIso8601String(),
      });

      _loadKelas();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kelas berhasil ditambahkan!')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating kelas: $error')),
      );
    }
  }

  // Update kelas
  Future<void> _updateKelas(int id, String mk) async {
    try {
      await supabase.from('kelas').update({
        'mk': mk,
      }).eq('id', id);

      _loadKelas();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kelas berhasil diupdate!')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating kelas: $error')),
      );
    }
  }

  // Delete kelas
  Future<void> _deleteKelas(int id) async {
    try {
      await supabase.from('kelas').delete().eq('id', id);
      _loadKelas();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kelas berhasil dihapus!')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting kelas: $error')),
      );
    }
  }

  // Save QR Code sebagai PNG
  Future<void> _saveQRCode(String kodeKuis, String mk) async {
    try {
      // Capture screenshot dari QR code widget
      final Uint8List? image = await screenshotController.capture();

      if (image != null) {
        // Dapatkan direktori untuk menyimpan file
        Directory? directory;

        if (Platform.isAndroid) {
          // Untuk Android, simpan di Downloads
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } else if (Platform.isIOS) {
          // Untuk iOS, simpan di Documents
          directory = await getApplicationDocumentsDirectory();
        }

        if (directory != null) {
          final String fileName =
              'QR_${mk.replaceAll(' ', '_')}_${kodeKuis}_${DateTime.now().millisecondsSinceEpoch}.png';
          final String filePath = '${directory.path}/$fileName';

          // Simpan file
          final File file = File(filePath);
          await file.writeAsBytes(image);

          // Tampilkan notifikasi sukses
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('QR Code berhasil disimpan ke: $filePath'),
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Bagikan',
                onPressed: () => _shareQRCode(filePath),
              ),
            ),
          );
        }
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error menyimpan QR Code: $error')),
      );
    }
  }

  // Share QR Code
  Future<void> _shareQRCode(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)], text: 'QR Code Kuis');
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing QR Code: $error')),
      );
    }
  }

  // Show create/edit dialog
  void _showKelasDialog({Map<String, dynamic>? kelas}) {
    final TextEditingController mkController = TextEditingController();

    if (kelas != null) {
      mkController.text = kelas['mk'] ?? '';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(kelas == null ? 'Tambah Kelas' : 'Edit Kelas'),
          content: TextField(
            controller: mkController,
            decoration: InputDecoration(
              labelText: 'Mata Kuliah',
              hintText: 'Masukkan nama mata kuliah',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text(kelas == null ? 'Tambah' : 'Update'),
              onPressed: () {
                if (mkController.text.isNotEmpty) {
                  if (kelas == null) {
                    _createKelas(mkController.text);
                  } else {
                    _updateKelas(kelas['id'], mkController.text);
                  }
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Show detail kelas dengan QR code
  void _showKelasDetail(Map<String, dynamic> kelas) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Detail Kelas',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  _buildDetailRow('ID MK', kelas['id_mk'] ?? ''),
                  _buildDetailRow('Mata Kuliah', kelas['mk'] ?? ''),
                  _buildDetailRow('Kode Kuis', kelas['kode_kuis'] ?? ''),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () =>
                        _showQRCode(kelas['kode_kuis'] ?? '', kelas['mk'] ?? ''),
                    child: Text('Generate QR Code'),
                  ),
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Tutup'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  // FIXED: Show QR Code dengan fitur save - No overflow
  void _showQRCode(String kodeKuis, String mk) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'QR Code Kuis',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      mk,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 16),
                    // Widget QR Code yang akan di-capture
                    Screenshot(
                      controller: screenshotController,
                      child: Container(
                        color: Colors.white,
                        padding: EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            QrImageView(
                              data: kodeKuis,
                              version: QrVersions.auto,
                              size: 160.0, // Reduced size
                              backgroundColor: Colors.white,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Kode: $kodeKuis',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              mk,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Buttons in a more compact layout
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _saveQRCode(kodeKuis, mk),
                          icon: Icon(Icons.download, size: 16),
                          label: Text('Simpan', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size(80, 36),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final image = await screenshotController.capture();
                            if (image != null) {
                              final tempDir = await getTemporaryDirectory();
                              final tempFile = File('${tempDir.path}/qr_temp.png');
                              await tempFile.writeAsBytes(image);
                              await Share.shareXFiles([XFile(tempFile.path)],
                                  text: 'QR Code $mk - $kodeKuis');
                            }
                          },
                          icon: Icon(Icons.share, size: 16),
                          label: Text('Bagikan', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size(80, 36),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    // Action buttons in vertical layout
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => EssayQuestionApp()),
                              );
                            },
                            child: Text(
                              "Buat Soal",
                              style: TextStyle(
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => EssayAnswerTab()),
                              );
                            },
                            child: Text(
                              "Lihat Jawaban",
                              style: TextStyle(
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Tutup', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Show delete confirmation
  void _showDeleteConfirmation(Map<String, dynamic> kelas) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus'),
          content:
              Text('Apakah Anda yakin ingin menghapus kelas "${kelas['mk']}"?'),
          actions: <Widget>[
            TextButton(
              child: Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Hapus'),
              onPressed: () {
                _deleteKelas(kelas['id']);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Widget untuk Teacher Mode (Manajemen Kelas)
  Widget _buildTeacherMode() {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadKelas,
            child: kelasList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada kelas',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap tombol + untuk menambah kelas baru',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: kelasList.length,
                    itemBuilder: (context, index) {
                      final kelas = kelasList[index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.school, color: Colors.white),
                          ),
                          title: Text(
                            kelas['mk'] ?? '',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ID MK: ${kelas['id_mk'] ?? ''}'),
                              Text('Kode Kuis: ${kelas['kode_kuis'] ?? ''}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () =>
                                    _showKelasDialog(kelas: kelas),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _showDeleteConfirmation(kelas),
                              ),
                            ],
                          ),
                          onTap: () => _showKelasDetail(kelas),
                        ),
                      );
                    },
                  ),
          );
  }

  // Widget untuk Student Mode (Quiz App)
  Widget _buildStudentMode() {
    return QuizHomePage(); // Menggunakan QuizHomePage dari SoalEssay.dart
  }

  // Method to refresh when user changes profile
  void refreshUserType() {
    _loadUserType();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while determining user type
    if (isLoadingUserType) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Loading...'),
          backgroundColor: Colors.grey,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat profil pengguna...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentMode == AppMode.teacher ? 'Manajemen Kelas' : 'Quiz App'
        ),
        backgroundColor: currentMode == AppMode.teacher ? Colors.blue : Colors.green,
        foregroundColor: Colors.white,
        actions: [
          // Show current mode indicator
          Container(
            margin: EdgeInsets.only(right: 16),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  currentMode == AppMode.teacher ? Icons.school : Icons.person,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  currentMode == AppMode.teacher ? 'Teacher' : 'Student',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: currentMode == AppMode.teacher 
          ? _buildTeacherMode()
          : _buildStudentMode(),
      floatingActionButton: currentMode == AppMode.teacher
          ? FloatingActionButton(
              onPressed: () => _showKelasDialog(),
              child: Icon(Icons.add),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            )
          : null, // No FAB for student mode
    );
  }
}