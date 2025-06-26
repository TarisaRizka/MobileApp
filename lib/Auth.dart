// ignore_for_file: use_build_context_synchronously

import 'package:finalproject_mobapp/Navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:local_auth/local_auth.dart';

class AuthService {
  static const String userTypeStudent = 'Student';
  static const String userTypeTeacher = 'Teacher';
  static const String userTypeAdmin = 'Admin';

  final SupabaseClient _supabase = Supabase.instance.client;
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Debug method to check biometric setup
  Future<void> debugBiometricSetup() async {
    print('🔍 === BIOMETRIC DEBUG INFO ===');
    
    try {
      // Check device support
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      print('📱 Device supported: $isDeviceSupported');
      
      // Check if biometrics can be checked
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      print('🔍 Can check biometrics: $canCheckBiometrics');
      
      // Get available biometric types
      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      print('👆 Available biometrics: $availableBiometrics');
      
      // Check saved credentials
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedEmail = prefs.getString('saved_email');
      bool hasCredentials = savedEmail != null;
      print('💾 Has saved credentials: $hasCredentials');
      
    } catch (e) {
      print('❌ Debug error: $e');
    }
    
    print('🔍 === END DEBUG INFO ===');
  }

  // Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      // Check if device supports biometrics
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      print('🔍 Device supported: $isDeviceSupported');

      if (!isDeviceSupported) {
        print('❌ Device does not support biometric authentication');
        return false;
      }

      // Check if biometrics are available
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      print('🔍 Can check biometrics: $canCheckBiometrics');

      if (!canCheckBiometrics) {
        print('❌ Biometric authentication not available');
        return false;
      }

      // Get available biometric types
      final List<BiometricType> availableBiometrics =
          await _localAuth.getAvailableBiometrics();
      print('🔍 Available biometrics: $availableBiometrics');

      return availableBiometrics.isNotEmpty;
    } catch (e) {
      print('❌ Error checking biometric availability: $e');
      return false;
    }
  }

  // Get available biometric types as string for UI display
  Future<String> getBiometricTypeString() async {
    try {
      final List<BiometricType> availableBiometrics =
          await _localAuth.getAvailableBiometrics();
      
      if (availableBiometrics.contains(BiometricType.face)) {
        return 'Face ID';
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        return 'Sidik Jari';
      } else if (availableBiometrics.contains(BiometricType.iris)) {
        return 'Iris';
      } else if (availableBiometrics.contains(BiometricType.strong)) {
        return 'Biometrik';
      } else if (availableBiometrics.contains(BiometricType.weak)) {
        return 'Biometrik';
      } else {
        return 'Biometrik';
      }
    } catch (e) {
      print('❌ Error getting biometric type: $e');
      return 'Biometrik';
    }
  }

  // Enhanced biometric login with auto-redirect to main app
  Future<bool> biometricLogin(BuildContext context) async {
    try {
      print('🔐 Starting biometric login...');
      
      // Check if user has saved credentials
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedEmail = prefs.getString('saved_email');
      String? savedPassword = prefs.getString('saved_password');

      if (savedEmail == null || savedPassword == null) {
        print('❌ No saved credentials found');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak ada kredensial tersimpan. Login normal terlebih dahulu.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
        return false;
      }

      print('✅ Saved credentials found, attempting biometric auth...');

      // Get the biometric type for better user message
      String biometricType = await getBiometricTypeString();
      print('👆 Biometric type: $biometricType');

      // Authenticate with biometrics
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Gunakan $biometricType Anda untuk login',
        options: AuthenticationOptions(
          biometricOnly: false,           // Allow fallback to PIN/password
          stickyAuth: true,              // Keep auth dialog until success/cancel
          useErrorDialogs: true,         // Show system error dialogs
        ),
      );

      print('🔐 Biometric authentication result: $didAuthenticate');

      if (didAuthenticate) {
        print('✅ Biometric authentication successful, logging in...');
        
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.blue),
                SizedBox(height: 16),
                Text(
                  'Login berhasil, mengarahkan...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );

        try {
          // Verify credentials with Supabase
          final AuthResponse response = await _supabase.auth.signInWithPassword(
            email: savedEmail,
            password: savedPassword,
          );

          // Close loading dialog
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }

          if (response.user != null) {
            // Update login state
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('userEmail', savedEmail);
            await prefs.setString('userId', response.user!.id);

            // Get user type from metadata or determine from email
            String userType = response.user?.userMetadata?['user_type'] ?? userTypeStudent;
            String originalUserType = response.user?.userMetadata?['original_user_type'] ?? userType;
            
            // Fallback: determine user type based on email if not in metadata
            if (userType == userTypeStudent &&
                (savedEmail.contains('teacher') ||
                    savedEmail.contains('dosen') ||
                    savedEmail.contains('admin'))) {
              userType = userTypeTeacher;
              // If we don't have original type stored, assume they registered as teacher
              if (originalUserType == userTypeStudent) {
                originalUserType = userTypeTeacher;
              }
            }

            await prefs.setString('userType', userType);
            await prefs.setString('originalUserType', originalUserType);
            await prefs.setString('displayName',
                response.user?.userMetadata?['full_name'] ?? savedEmail.split('@')[0]);

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Login biometrik berhasil!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );

            // Auto-redirect to main app
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => Navigation()),
              (route) => false,
            );

            return true;
          } else {
            throw Exception('Login verification failed');
          }
        } catch (e) {
          // Close loading dialog if exists
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          
          print('❌ Login verification error: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memverifikasi kredensial'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }
      } else {
        print('❌ Biometric authentication failed or cancelled');
        return false;
      }
    } on PlatformException catch (e) {
      print('❌ Platform exception during biometric login: $e');
      
      String errorMessage = 'Gagal melakukan login biometrik';
      switch (e.code) {
        case 'NotAvailable':
          errorMessage = 'Biometrik tidak tersedia di perangkat ini';
          break;
        case 'NotEnrolled':
          errorMessage = 'Belum ada biometrik yang terdaftar di perangkat';
          break;
        case 'LockedOut':
          errorMessage = 'Biometrik terkunci sementara, coba lagi nanti';
          break;
        case 'PermanentlyLockedOut':
          errorMessage = 'Biometrik terkunci permanen, gunakan PIN/password';
          break;
        case 'UserCancel':
          errorMessage = 'Autentikasi dibatalkan';
          break;
        case 'UserFallback':
          errorMessage = 'Menggunakan metode autentikasi alternatif';
          break;
        default:
          errorMessage = 'Error biometrik: ${e.message}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    } catch (e) {
      print('❌ General biometric login error: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat login biometrik'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }

  // Simplified biometric authentication - just check fingerprint, no email/password dependency
  Future<bool> authenticateWithBiometric(BuildContext context) async {
    try {
      print('🔐 Starting simplified biometric authentication...');
      
      // Check if biometric is available
      bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometrik tidak tersedia di perangkat ini'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return false;
      }

      // Get the biometric type for better user message
      String biometricType = await getBiometricTypeString();
      print('👆 Biometric type: $biometricType');

      // Authenticate with biometrics
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Gunakan $biometricType Anda untuk login',
        options: AuthenticationOptions(
          biometricOnly: false,           // Allow fallback to PIN/password
          stickyAuth: true,              // Keep auth dialog until success/cancel
          useErrorDialogs: true,         // Show system error dialogs
        ),
      );

      print('🔐 Biometric authentication result: $didAuthenticate');
      return didAuthenticate;

    } on PlatformException catch (e) {
      print('❌ Platform exception during biometric auth: $e');
      
      String errorMessage = 'Gagal melakukan autentikasi biometrik';
      switch (e.code) {
        case 'NotAvailable':
          errorMessage = 'Biometrik tidak tersedia di perangkat ini';
          break;
        case 'NotEnrolled':
          errorMessage = 'Belum ada biometrik yang terdaftar di perangkat';
          break;
        case 'LockedOut':
          errorMessage = 'Biometrik terkunci sementara, coba lagi nanti';
          break;
        case 'PermanentlyLockedOut':
          errorMessage = 'Biometrik terkunci permanen, gunakan PIN/password';
          break;
        case 'UserCancel':
          print('ℹ️ User cancelled biometric authentication');
          return false; // Don't show error for user cancellation
        case 'UserFallback':
          errorMessage = 'Menggunakan metode autentikasi alternatif';
          break;
        default:
          errorMessage = 'Error biometrik: ${e.message}';
      }
      
      // Only show error message for actual errors, not user cancellation
      if (e.code != 'UserCancel') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    } catch (e) {
      print('❌ General biometric authentication error: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat autentikasi biometrik'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }

  // Test biometric authentication (for debugging)
  Future<bool> testBiometricAuth(BuildContext context) async {
    try {
      String biometricType = await getBiometricTypeString();
      
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Test $biometricType authentication',
        options: AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(didAuthenticate ? 'Test biometrik berhasil!' : 'Test biometrik gagal'),
          backgroundColor: didAuthenticate ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );

      return didAuthenticate;
    } catch (e) {
      print('❌ Biometric test error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test biometrik error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }

  // Login method with enhanced biometric credential saving and original user type tracking
  Future<bool> login(BuildContext context, String email, String password,
      {bool isFromBiometric = false}) async {
    try {
      // Show loading indicator only for manual login
      if (!isFromBiometric) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Attempt to sign in with Supabase
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Close loading dialog if not from biometric
      if (!isFromBiometric && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (response.user != null) {
        // Login successful
        SharedPreferences prefs = await SharedPreferences.getInstance();

        // Save login state
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userEmail', email);
        await prefs.setString('userId', response.user!.id);

        // Save credentials for biometric login (only if not from biometric to avoid overwriting)
        if (!isFromBiometric) {
          await prefs.setString('saved_email', email);
          await prefs.setString('saved_password', password);
          print('💾 Credentials saved for biometric login');
        }

        // Get user type from user metadata (set during registration) or determine from email
        String userType =
            response.user?.userMetadata?['user_type'] ?? userTypeStudent;

        // Get original user type from metadata, fallback to current user type
        String originalUserType = 
            response.user?.userMetadata?['original_user_type'] ?? userType;

        // Fallback: determine user type based on email if not in metadata
        if (userType == userTypeStudent &&
            (email.contains('teacher') ||
                email.contains('dosen') ||
                email.contains('admin'))) {
          userType = userTypeTeacher;
          // If we don't have original type stored, assume they registered as teacher
          if (originalUserType == userTypeStudent) {
            originalUserType = userTypeTeacher;
          }
        }

        await prefs.setString('userType', userType);
        await prefs.setString('originalUserType', originalUserType);
        await prefs.setString('displayName',
            response.user?.userMetadata?['full_name'] ?? email.split('@')[0]);

        print('✅ Login successful - userType: $userType, originalUserType: $originalUserType');

        // Show success message
        String loginMethod = isFromBiometric ? 'biometrik' : 'normal';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login $loginMethod berhasil!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate to main app
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Navigation()),
          (route) => false,
        );

        return true;
      } else {
        throw Exception('Login failed');
      }
    } catch (e) {
      // Close loading dialog if exists
      if (!isFromBiometric && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('❌ Login error: $e');

      String errorMessage = 'Login gagal';
      if (e.toString().contains('Invalid login credentials')) {
        errorMessage = 'Email atau password salah';
      } else if (e.toString().contains('Email not confirmed')) {
        errorMessage = 'Email belum dikonfirmasi';
      } else if (e.toString().contains('Too many requests')) {
        errorMessage = 'Terlalu banyak percobaan, coba lagi nanti';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }

  // Clear saved biometric credentials
  Future<void> clearBiometricCredentials() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      print('🧹 Biometric credentials cleared');
    } catch (e) {
      print('❌ Error clearing biometric credentials: $e');
    }
  }

  // Check if biometric credentials are saved
  Future<bool> hasSavedCredentials() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedEmail = prefs.getString('saved_email');
      String? savedPassword = prefs.getString('saved_password');
      return savedEmail != null && savedPassword != null;
    } catch (e) {
      print('❌ Error checking saved credentials: $e');
      return false;
    }
  }

  // Register method
  Future<bool> register(BuildContext context, String email, String password,
      String fullName) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      // Close loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Registrasi berhasil! Silakan cek email untuk konfirmasi.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate back to login
        Navigator.pop(context);
        return true;
      } else {
        throw Exception('Registration failed');
      }
    } catch (e) {
      // Close loading dialog if exists
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('❌ Registration error: $e');

      String errorMessage = 'Registrasi gagal';
      if (e.toString().contains('already registered')) {
        errorMessage = 'Email sudah terdaftar';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }

  // SignUp method with original user type tracking
  Future<bool> signUp(BuildContext context, String email, String password,
      String fullName, String userType, String additionalData) async {
    try {
      print('🔐 Starting signup for userType: $userType');
      
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'user_type': userType,
          'original_user_type': userType, // Track the original registration type
          'additional_data': additionalData,
        },
      );

      if (response.user != null) {
        // Store the original user type in SharedPreferences immediately
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('originalUserType', userType);
        
        print('✅ Signup successful - originalUserType stored: $userType');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Registrasi berhasil! Silakan cek email untuk konfirmasi.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return true;
      } else {
        throw Exception('Registration failed');
      }
    } catch (e) {
      print('❌ SignUp error: $e');

      String errorMessage = 'Registrasi gagal';
      if (e.toString().contains('already registered') ||
          e.toString().contains('already been registered')) {
        errorMessage = 'Email sudah terdaftar';
      } else if (e.toString().contains('Invalid email')) {
        errorMessage = 'Format email tidak valid';
      } else if (e.toString().contains('Password should be at least')) {
        errorMessage = 'Password terlalu pendek';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }

  // Reset password method
  Future<bool> resetPassword(BuildContext context, String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Link reset password telah dikirim ke email Anda'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
      return true;
    } catch (e) {
      print('❌ Reset password error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim link reset password'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }

  // Simple logout method
  Future<void> logout(BuildContext context) async {
    try {
      // Show confirmation dialog
      bool? shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Konfirmasi Logout'),
          content: Text('Apakah Anda yakin ingin logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (shouldLogout == true) {
        // Sign out from Supabase
        await _supabase.auth.signOut();

        // Clear shared preferences (including biometric credentials)
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout berhasil'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate to login page
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      print('❌ Logout error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal logout'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Get current user info (legacy method for backward compatibility)
  Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (!isLoggedIn) return null;

      return {
        'email': prefs.getString('userEmail'),
        'userId': prefs.getString('userId'),
        'userType': prefs.getString('userType'),
        'displayName': prefs.getString('displayName'),
        'isLoggedIn': isLoggedIn,
      };
    } catch (e) {
      print('❌ Error getting user info: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateProfile(BuildContext context, String fullName) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      await _supabase.auth.updateUser(
        UserAttributes(data: {'full_name': fullName}),
      );

      // Update local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('displayName', fullName);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile berhasil diupdate'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      return true;
    } catch (e) {
      print('❌ Update profile error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal update profile'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool('isLoggedIn') ?? false;
    } catch (e) {
      return false;
    }
  }

  // Method to update user type in database (with original type restriction)
  Future<bool> updateUserTypeInDatabase(String userType) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Get original user type to check if change is allowed
      String originalUserType = await getOriginalUserType();
      
      // Only allow changes if user originally registered as Teacher
      if (originalUserType != userTypeTeacher) {
        print('❌ User type change denied - user did not register as Teacher');
        return false;
      }

      // Update user metadata in Supabase Auth (keep original_user_type unchanged)
      final response = await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'user_type': userType,
            'original_user_type': originalUserType, // Preserve original type
          },
        ),
      );

      if (response.user != null) {
        // Also update in SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userType', userType);
        // Don't change originalUserType in SharedPreferences
        print('✅ User type updated to $userType (original: $originalUserType)');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error updating user type in database: $e');
      return false;
    }
  }

    // Method to get user type from various sources

    // Add this method to retrieve the original user type from SharedPreferences
    Future<String> getOriginalUserType() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('originalUserType') ?? userTypeStudent;
    }
  }