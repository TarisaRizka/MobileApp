import 'package:finalproject_mobapp/Auth.dart';
import 'package:finalproject_mobapp/Register.dart';
import 'package:finalproject_mobapp/Navigation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final AuthService authService = AuthService();
  bool _isLoading = false;
  bool _biometricAvailable = false;
  bool _hasSavedCredentials = false;
  String _biometricType = 'Biometrik';

  @override
  void initState() {
    super.initState();
    _initializeBiometric();
  }

  Future<void> _initializeBiometric() async {
    await _loadSavedCredentials();
    await _checkBiometricAvailability();
    await _getBiometricType();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedEmail = prefs.getString('saved_email');
      String? savedPassword = prefs.getString('saved_password');
      
      setState(() {
        usernameController.text = savedEmail ?? '';
        _hasSavedCredentials = savedEmail != null && savedPassword != null;
      });
    } catch (e) {
      print('Error loading saved credentials: $e');
    }
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      bool isAvailable = await authService.isBiometricAvailable();
      setState(() {
        _biometricAvailable = isAvailable;
      });
    } catch (e) {
      print('Error checking biometric availability: $e');
      setState(() {
        _biometricAvailable = false;
      });
    }
  }

  Future<void> _getBiometricType() async {
    try {
      String type = await authService.getBiometricTypeString();
      setState(() {
        _biometricType = type;
      });
    } catch (e) {
      print('Error getting biometric type: $e');
    }
  }

  Future<void> _handleBiometricLogin() async {
    if (!_biometricAvailable) {
      _showSnackBar("Autentikasi biometrik tidak tersedia", Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simplified biometric authentication - just check fingerprint and redirect
      bool success = await authService.authenticateWithBiometric(context);
      
      if (success) {
        // Show success message
        _showSnackBar("Login biometrik berhasil!", Colors.green);
        
        // Set logged in state
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        
        // Small delay to show success message
        await Future.delayed(Duration(milliseconds: 500));
        
        // Navigate to home page
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Navigation()),
          (route) => false,
        );
      } else {
        _showSnackBar("Login biometrik gagal atau dibatalkan", Colors.red);
      }
    } catch (e) {
      print('Biometric login error: $e');
      _showSnackBar("Terjadi kesalahan saat login biometrik", Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Center(
          child: Text(
            "LOGIN PAGE",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        automaticallyImplyLeading: false, // Remove back button
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo or Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.blue.shade300],
                    ),
                  ),
                  child: Icon(
                    Icons.school,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 30),

                Text(
                  'Selamat Datang',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Silakan login untuk melanjutkan',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 40),

                // Email TextField
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: usernameController,
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
                SizedBox(height: 16),

                // Password TextField
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: passwordController,
                      obscureText: true,
                      obscuringCharacter: "*",
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        labelText: "Password",
                        hintText: "Masukkan Password",
                        prefixIcon: Icon(Icons.lock, color: Colors.blue),
                        labelStyle: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : Text(
                            "Login",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                
                // Biometric Authentication Section
                if (_biometricAvailable) ...[
                  SizedBox(height: 20),
                  
                  // Divider with "atau" text
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.grey.shade400,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "atau",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.grey.shade400,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Biometric Login Button (Centered)
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade300, Colors.blue.shade600],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: _isLoading 
                          ? SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Icon(
                              Icons.fingerprint,
                              size: 40,
                              color: Colors.white,
                            ),
                      onPressed: _isLoading ? null : _handleBiometricLogin,
                      padding: EdgeInsets.all(20),
                      tooltip: 'Login dengan $_biometricType',
                    ),
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Biometric status text
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.blue.shade200,
                      ),
                    ),
                    child: Text(
                      "Gunakan $_biometricType untuk login cepat",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],

                SizedBox(height: 30),

                // Bottom Links
                Column(
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/reset-request');
                      },
                      child: Text(
                        "Lupa Password?",
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Belum punya akun? ",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Register()),
                            );
                          },
                          child: Text(
                            "Daftar Sekarang",
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      _showSnackBar("Email dan password harus diisi!", Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool success = await authService.login(
        context,
        usernameController.text.trim(),
        passwordController.text,
      );
      
      if (success) {
        // Update saved credentials state after successful login
        setState(() {
          _hasSavedCredentials = true;
        });
        // Refresh biometric availability
        await _checkBiometricAvailability();
      }
    } catch (e) {
      print('Login error: $e');
      _showSnackBar("Login gagal: ${e.toString()}", Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}