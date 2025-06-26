import 'package:finalproject_mobapp/Auth.dart';
import 'package:finalproject_mobapp/ForgetPassword.dart';
import 'package:finalproject_mobapp/Login.dart';
import 'package:finalproject_mobapp/Navigation.dart';
import 'package:finalproject_mobapp/Register.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://hufllvpkzyriezwedyxp.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh1ZmxsdnBrenlyaWV6d2VkeXhwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ4OTgzNDAsImV4cCI6MjA2MDQ3NDM0MH0.29FCMwv3NHQ0mZgaBH3fEhPlvcAgpxzU4gcFeb03pxo',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthGate(), // Check auth status first
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => Register(),
        '/reset-request': (context) => ResetPasswordRequestPage(),
        '/home': (context) => Navigation(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: Text('Page Not Found')),
            body: Center(
              child: Text('Route ${settings.name} not found'),
            ),
          ),
        );
      },
    );
  }
}

// AuthGate to check if user is already logged in
class AuthGate extends StatefulWidget {
  @override
  _AuthGateState createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      setState(() {
        _isLoggedIn = isLoggedIn;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _isLoggedIn ? Navigation() : LoginPage();
  }
}

// Updated ResetPasswordRequestPage in main.dart
class ResetPasswordRequestPage extends StatefulWidget {
  @override
  _ResetPasswordRequestPageState createState() =>
      _ResetPasswordRequestPageState();
}

class _ResetPasswordRequestPageState extends State<ResetPasswordRequestPage> {
  final TextEditingController emailController = TextEditingController();
  final AuthService authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          "Reset Password",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.blue.shade300],
                  ),
                ),
                child: Icon(
                  Icons.lock_reset,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 30),

              Text(
                "Lupa Password?",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Masukkan email Anda untuk menerima kode reset password",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),

              // Email Input
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      labelText: "Email",
                      hintText: "Masukkan Email",
                      prefixIcon: Icon(Icons.email, color: Colors.blue),
                      labelStyle: TextStyle(color: Colors.blue),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Send Reset Button - Navigate immediately to token page
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sendResetEmailAndNavigate,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    "Lanjut ke Reset Password",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 30),

              // Info section
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 32,
                      color: Colors.blue.shade600,
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Setelah mengklik tombol di atas, Anda akan diarahkan ke halaman untuk memasukkan kode reset password. Kode akan dikirim ke email Anda.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),

              // Back to Login
              TextButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
                child: Text(
                  "Kembali ke Login",
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendResetEmailAndNavigate() async {
    // Validate email first
    if (emailController.text.trim().isEmpty) {
      _showSnackBar("Email harus diisi!", Colors.red);
      return;
    }

    // Basic email validation
    if (!emailController.text.trim().contains('@')) {
      _showSnackBar("Format email tidak valid!", Colors.red);
      return;
    }

    // Navigate to token page immediately without sending email
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManualTokenResetPage(
          email: emailController.text.trim(),
        ),
      ),
    );

    // Send email in background (optional - for when user actually needs the token)
    _sendEmailInBackground();
  }

  void _sendEmailInBackground() async {
    try {
      await authService.resetPassword(context, emailController.text.trim());
    } catch (e) {
      // Silently handle error - user is already on token page
      print('Background email sending failed: $e');
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Identitas Grup',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Grup
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [Colors.indigo, Colors.indigo.shade300],
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.group,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Grup Mobile Development',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kelas: Pemrograman Mobile',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Title Anggota
              Row(
                children: [
                  Icon(
                    Icons.people,
                    color: Colors.indigo,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Anggota Grup',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ...groupMembers
                  .map((member) => _buildMemberCard(member))
                  .toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(GroupMember member) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Foto Anggota
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.indigo.shade200,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: _buildMemberPhoto(member),
              ),
            ),
            const SizedBox(width: 16),

            // Informasi Anggota
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.nama,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.badge,
                        size: 16,
                        color: Colors.indigo,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        member.nim,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: member.role == 'Teacher'
                          ? Colors.orange.shade100
                          : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      member.role,
                      style: TextStyle(
                        fontSize: 12,
                        color: member.role == 'Teacher'
                            ? Colors.orange.shade800
                            : Colors.blue.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberPhoto(GroupMember member) {
    // Cek apakah ada foto lokal
    if (member.photoUrl.isNotEmpty && !member.photoUrl.startsWith('http')) {
      return Image.asset(
        member.photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading local image: $error');
          return _buildDefaultAvatar(member.nama);
        },
      );
    }
    // Jika ada URL online
    else if (member.photoUrl.isNotEmpty && member.photoUrl.startsWith('http')) {
      return Image.network(
        member.photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading network image: $error');
          return _buildDefaultAvatar(member.nama);
        },
      );
    }
    // Jika tidak ada foto
    else {
      return _buildDefaultAvatar(member.nama);
    }
  }

  Widget _buildDefaultAvatar(String nama) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.indigo.shade300, Colors.indigo.shade600],
        ),
      ),
      child: Center(
        child: Text(
          nama.isNotEmpty ? nama[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class GroupMember {
  final String nama;
  final String nim;
  final String photoUrl;
  final String role;

  GroupMember({
    required this.nama,
    required this.nim,
    required this.photoUrl,
    required this.role,
  });
}

final List<GroupMember> groupMembers = [
  GroupMember(
    nama: 'Gelar Budiman',
    nim: '2023001001',
    photoUrl: 'assets/images/gelar.jpg', // Gunakan path assets
    role: 'Teacher',
  ),
  GroupMember(
    nama: 'Tarisa Rizka Ghaisanni Rioeh',
    nim: '1101213052',
    photoUrl: 'lib/image/riri.jpg', // Perbaiki path
    role: 'Student',
  ),
  GroupMember(
    nama: 'Maulana Yudha Ariq',
    nim: '1101213269',
    photoUrl: 'lib/image/yudha.jpg', // Tambahkan foto jika ada
    role: 'Student',
  ),
  GroupMember(
    nama: 'Adhisty Putrina Suwandhi',
    nim: '1101213216',
    photoUrl: 'lib/image/adhisty.jpg', // Tambahkan foto jika ada
    role: 'Student',
  ),
  GroupMember(
    nama: 'Aria Tresna Apandi',
    nim: '1101210069',
    photoUrl: 'lib/image/aria.jpg', // Tambahkan foto jika ada
    role: 'Student',
  ),
];