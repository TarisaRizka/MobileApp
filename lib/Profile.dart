import 'package:finalproject_mobapp/Auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  final AuthService authService;
  final VoidCallback onProfileUpdated;

  const ProfilePage({
    Key? key,
    required this.authService,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String userType = AuthService.userTypeStudent;
  String selectedUserType = AuthService.userTypeStudent;
  String originalUserType = AuthService.userTypeStudent; // Track original registration type
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _canChangeUserType = false; // New flag to control user type editing

  @override
  void initState() {
    super.initState();
    print('ProfilePage: initState called');
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    print('ProfilePage: Loading user data...');
    try {
      final userInfo = await widget.authService.getCurrentUserInfo();

      print('ProfilePage: User info loaded: $userInfo');

      if (userInfo != null) {
        // Normalize user type to match AuthService constants
        String loadedUserType =
            userInfo['userType'] ?? AuthService.userTypeStudent;

        // Ensure it matches our constants exactly
        if (loadedUserType.toLowerCase().contains('teacher')) {
          loadedUserType = AuthService.userTypeTeacher;
        } else {
          loadedUserType = AuthService.userTypeStudent;
        }

        // Get original user type from SharedPreferences or set based on current type
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? storedOriginalType = prefs.getString('originalUserType');
        
        // If no stored original type, check if they're currently a teacher
        // and assume they registered as teacher
        if (storedOriginalType == null) {
          if (loadedUserType == AuthService.userTypeTeacher) {
            originalUserType = AuthService.userTypeTeacher;
            await prefs.setString('originalUserType', AuthService.userTypeTeacher);
          } else {
            originalUserType = AuthService.userTypeStudent;
            await prefs.setString('originalUserType', AuthService.userTypeStudent);
          }
        } else {
          originalUserType = storedOriginalType;
        }

        // Only teachers who registered as teachers can change user type
        _canChangeUserType = (originalUserType == AuthService.userTypeTeacher);

        setState(() {
          _nameController.text = userInfo['displayName'] ?? '';
          _emailController.text = userInfo['email'] ?? '';
          userType = loadedUserType;
          selectedUserType = loadedUserType;
          _isLoading = false;
        });

        print(
            'ProfilePage: State updated - userType: $userType, selectedUserType: $selectedUserType, canChangeUserType: $_canChangeUserType, originalUserType: $originalUserType');
      } else {
        print('ProfilePage: No user info found, using defaults');
        setState(() {
          userType = AuthService.userTypeStudent;
          selectedUserType = AuthService.userTypeStudent;
          originalUserType = AuthService.userTypeStudent;
          _canChangeUserType = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('ProfilePage: Error loading user data: $e');
      setState(() {
        userType = AuthService.userTypeStudent;
        selectedUserType = AuthService.userTypeStudent;
        originalUserType = AuthService.userTypeStudent;
        _canChangeUserType = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleEditMode() {
    print('ProfilePage: Toggling edit mode. Current: $_isEditing');
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        selectedUserType =
            userType; // Reset to current value when starting edit
      }
    });
    print(
        'ProfilePage: Edit mode now: $_isEditing, selectedUserType: $selectedUserType');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Profile'),
          backgroundColor: Colors.blue,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading profile...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: _toggleEditMode,
              tooltip: 'Edit Profile',
            ),
        ],
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
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Avatar
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade300, Colors.blue.shade600],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _nameController.text.isNotEmpty
                        ? _nameController.text[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),

              // User Type Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: userType == AuthService.userTypeTeacher
                      ? Colors.orange.shade100
                      : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: userType == AuthService.userTypeTeacher
                        ? Colors.orange.shade300
                        : Colors.blue.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      userType == AuthService.userTypeTeacher
                          ? Icons.school
                          : Icons.person,
                      size: 16,
                      color: userType == AuthService.userTypeTeacher
                          ? Colors.orange.shade800
                          : Colors.blue.shade800,
                    ),
                    SizedBox(width: 4),
                    Text(
                      userType,
                      style: TextStyle(
                        color: userType == AuthService.userTypeTeacher
                            ? Colors.orange.shade800
                            : Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),

              // Profile Form
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi Profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      SizedBox(height: 20),

                      // Name Field
                      _buildProfileField(
                        label: 'Nama Lengkap',
                        controller: _nameController,
                        icon: Icons.person,
                        enabled: _isEditing,
                      ),
                      SizedBox(height: 16),

                      // Email Field (readonly)
                      _buildProfileField(
                        label: 'Email',
                        controller: _emailController,
                        icon: Icons.email,
                        enabled: false,
                      ),
                      SizedBox(height: 16),

                      // User Type Field - Now conditionally editable
                      _isEditing && _canChangeUserType
                          ? _buildUserTypeDropdown()
                          : _buildInfoField(
                              label: 'Tipe User',
                              value: userType,
                              icon: Icons.badge,
                            ),
                      
                      // Show info message for students who can't change user type
                      if (_isEditing && !_canChangeUserType) ...[
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info,
                                color: Colors.amber.shade800,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tipe user tidak dapat diubah karena Anda terdaftar sebagai ${originalUserType}',
                                  style: TextStyle(
                                    color: Colors.amber.shade800,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),

              // Action Buttons
              if (_isEditing) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : () {
                                _toggleEditMode();
                                _loadUserData(); // Reset data
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Batal',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSaving
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Simpan',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _toggleEditMode,
                    icon: Icon(Icons.edit),
                    label: Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],

              // Info Card for Teacher Mode
              if (userType == AuthService.userTypeTeacher) ...[
                SizedBox(height: 20),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified,
                          color: Colors.orange,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mode Teacher Aktif',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                              Text(
                                _canChangeUserType 
                                    ? 'Anda dapat mengakses fitur Input Kuis dan mengubah mode ke Student'
                                    : 'Anda dapat mengakses fitur Input Kuis (mode permanen)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Info card for students explaining their limitations
              if (userType == AuthService.userTypeStudent && originalUserType == AuthService.userTypeStudent) ...[
                SizedBox(height: 20),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: Colors.blue,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mode Student',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              Text(
                                'Anda terdaftar sebagai Student dan tidak dapat mengubah tipe user',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeDropdown() {
    print(
        'ProfilePage: Building dropdown - selectedUserType: $selectedUserType, canChangeUserType: $_canChangeUserType');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipe User',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedUserType,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.badge, color: Colors.blue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: [
            DropdownMenuItem(
              value: AuthService.userTypeStudent,
              child: Row(
                children: [
                  Icon(Icons.school, size: 20, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(AuthService.userTypeStudent),
                ],
              ),
            ),
            DropdownMenuItem(
              value: AuthService.userTypeTeacher,
              child: Row(
                children: [
                  Icon(Icons.person_2, size: 20, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(AuthService.userTypeTeacher),
                ],
              ),
            ),
          ],
          onChanged: (String? newValue) {
            print('ProfilePage: Dropdown changed to: $newValue');
            if (newValue != null) {
              setState(() {
                selectedUserType = newValue;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.blue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: !enabled,
            fillColor: enabled ? null : Colors.grey.shade100,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade100,
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.blue),
              SizedBox(width: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveProfile() async {
    print('ProfilePage: Starting save profile...');

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nama tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      print('ProfilePage: Saving name: ${_nameController.text.trim()}');

      // Save name first
      bool nameUpdateSuccess = await widget.authService.updateProfile(
        context,
        _nameController.text.trim(),
      );

      print('ProfilePage: Name update success: $nameUpdateSuccess');

      if (nameUpdateSuccess) {
        // Update user type only if user can change it and it has changed
        if (_canChangeUserType && selectedUserType != userType) {
          print(
              'ProfilePage: Updating user type from $userType to $selectedUserType');

          bool userTypeUpdateSuccess = await widget.authService
              .updateUserTypeInDatabase(selectedUserType);

          print(
              'ProfilePage: User type update success: $userTypeUpdateSuccess');

          if (userTypeUpdateSuccess) {
            setState(() {
              userType = selectedUserType;
              _isEditing = false;
              _isSaving = false;
            });

            // Show success message with user type change info
            String message = selectedUserType == AuthService.userTypeTeacher
                ? 'Profile berhasil diupdate. Anda sekarang memiliki akses Teacher! Silakan cek tab "Input Kuis".'
                : 'Profile berhasil diupdate. Anda sekarang dalam mode Student.';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 4),
              ),
            );

            // Call the callback to refresh parent widgets
            widget.onProfileUpdated();
          } else {
            setState(() {
              _isSaving = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Nama berhasil diupdate, tetapi gagal mengubah tipe user'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          setState(() {
            _isEditing = false;
            _isSaving = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile berhasil diupdate'),
              backgroundColor: Colors.green,
            ),
          );

          widget.onProfileUpdated();
        }
      } else {
        setState(() {
          _isSaving = false;
        });
      }
    } catch (e) {
      print('ProfilePage: Error saving profile: $e');
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat menyimpan profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    print('ProfilePage: Disposing...');
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}