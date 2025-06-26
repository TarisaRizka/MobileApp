import 'package:finalproject_mobapp/Auth.dart';
import 'package:finalproject_mobapp/Login.dart';
import 'package:flutter/material.dart';

class Register extends StatefulWidget {
  Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final TextEditingController FullNameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController EmailController = TextEditingController();
  final TextEditingController PasswordController = TextEditingController();
  final TextEditingController ConfirmPasswordController = TextEditingController();
  String selectedUserType = AuthService.userTypeTeacher; // Default to teacher

  // Email validation function
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  // Clean and format email
  String cleanEmail(String email) {
    return email.trim().toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Daftar Akun",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.indigo,
        elevation: 0,
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
              Colors.indigo.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.indigo, Colors.indigo.shade300],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person_add,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Buat Akun Baru",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Lengkapi informasi untuk membuat akun",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 32),

              // Form Fields
              _buildInputCard(
                controller: FullNameController,
                label: "Nama Lengkap",
                hint: "Masukkan nama lengkap Anda",
                icon: Icons.person,
              ),
              
              SizedBox(height: 16),
              
              _buildInputCard(
                controller: idController,
                label: "NIM/NIP",
                hint: "Masukkan NIM/NIP Anda",
                icon: Icons.numbers,
              ),
              
              SizedBox(height: 16),
              
              _buildEmailInputCard(),
              
              // Email validation indicator
              if (EmailController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        isValidEmail(EmailController.text) 
                            ? Icons.check_circle 
                            : Icons.error,
                        color: isValidEmail(EmailController.text) 
                            ? Colors.green 
                            : Colors.red,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        isValidEmail(EmailController.text) 
                            ? "Format email valid" 
                            : "Format email tidak valid",
                        style: TextStyle(
                          color: isValidEmail(EmailController.text) 
                              ? Colors.green 
                              : Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              
              SizedBox(height: 16),
              
              _buildPasswordInputCard(),
              
              // Password strength indicator
              if (PasswordController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        PasswordController.text.length >= 6 
                            ? Icons.check_circle 
                            : Icons.error,
                        color: PasswordController.text.length >= 6 
                            ? Colors.green 
                            : Colors.red,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        PasswordController.text.length >= 6 
                            ? "Password cukup kuat" 
                            : "Password minimal 6 karakter",
                        style: TextStyle(
                          color: PasswordController.text.length >= 6 
                              ? Colors.green 
                              : Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              
              SizedBox(height: 16),
              
              _buildInputCard(
                controller: ConfirmPasswordController,
                label: "Konfirmasi Password",
                hint: "Masukkan password yang sama",
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              
              SizedBox(height: 16),
              
              _buildUserTypeCard(),
              
              SizedBox(height: 32),
              
              // Register Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleRegister,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: Colors.indigo.withOpacity(0.4),
                  ),
                  child: Text(
                    "Daftar Sekarang",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 24),
              
              // Login redirect
              Center(
                child: Column(
                  children: [
                    Text(
                      "Sudah punya akun?",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Colors.indigo.shade50,
                        overlayColor: Colors.indigo.shade100,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.login,
                            color: Colors.indigo,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Masuk di sini",
                            style: TextStyle(
                              color: Colors.indigo,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(4.0),
        child: TextField(
          controller: controller,
          obscureText: isPassword,
          obscuringCharacter: "*",
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: InputBorder.none,
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.indigo),
            labelStyle: TextStyle(color: Colors.indigo),
            hintStyle: TextStyle(color: Colors.grey.shade500),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailInputCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(4.0),
        child: TextField(
          controller: EmailController,
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) {
            setState(() {});
          },
          decoration: InputDecoration(
            border: InputBorder.none,
            labelText: "Email",
            hintText: "Masukkan email (contoh: nama@gmail.com)",
            prefixIcon: Icon(Icons.email, color: Colors.indigo),
            labelStyle: TextStyle(color: Colors.indigo),
            hintStyle: TextStyle(color: Colors.grey.shade500),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordInputCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(4.0),
        child: TextField(
          controller: PasswordController,
          obscureText: true,
          obscuringCharacter: "*",
          onChanged: (value) {
            setState(() {});
          },
          decoration: InputDecoration(
            border: InputBorder.none,
            labelText: "Password",
            hintText: "Minimal 6 karakter",
            prefixIcon: Icon(Icons.lock, color: Colors.indigo),
            labelStyle: TextStyle(color: Colors.indigo),
            hintStyle: TextStyle(color: Colors.grey.shade500),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(4.0),
        child: DropdownButtonFormField<String>(
          value: selectedUserType,
          decoration: InputDecoration(
            border: InputBorder.none,
            labelText: "Pilih Tipe User",
            prefixIcon: Icon(Icons.person_outline, color: Colors.indigo),
            labelStyle: TextStyle(color: Colors.indigo),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          dropdownColor: Colors.white,
          items: [
            DropdownMenuItem(
              value: AuthService.userTypeTeacher,
              child: Row(
                children: [
                  Icon(Icons.school, color: Colors.orange.shade600, size: 20),
                  SizedBox(width: 8),
                  Text("Teacher"),
                ],
              ),
            ),
            DropdownMenuItem(
              value: AuthService.userTypeStudent,
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.blue.shade600, size: 20),
                  SizedBox(width: 8),
                  Text("Student"),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedUserType = value;
              });
            }
          },
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    // Validate input fields
    if (FullNameController.text.isEmpty ||
        EmailController.text.isEmpty ||
        PasswordController.text.isEmpty ||
        ConfirmPasswordController.text.isEmpty) {
      _showSnackBar("Semua field harus diisi!", Colors.red);
      return;
    }

    // Clean and validate email
    String cleanedEmail = cleanEmail(EmailController.text);
    if (!isValidEmail(cleanedEmail)) {
      _showSnackBar("Format email tidak valid! Contoh: nama@gmail.com", Colors.red);
      return;
    }

    // Validate password length
    if (PasswordController.text.length < 6) {
      _showSnackBar("Password harus minimal 6 karakter!", Colors.red);
      return;
    }

    // Check password confirmation
    if (PasswordController.text != ConfirmPasswordController.text) {
      _showSnackBar("Password tidak sama!", Colors.red);
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Container(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    "Mendaftarkan akun...",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.indigo.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      bool success = await AuthService().signUp(
          context,
          cleanedEmail, // Use cleaned email
          PasswordController.text,
          FullNameController.text,
          selectedUserType,
          "");

      // Close loading dialog
      Navigator.of(context).pop();

      if (success) {
        // Show success message
        _showSnackBar("Akun berhasil dibuat! Silakan login.", Colors.green);
        
        // Navigate to login page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      _showSnackBar("Error tidak terduga: ${e.toString()}", Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}