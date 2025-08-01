import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shoppingcart/attendance.dart';
import 'package:shoppingcart/changepasswor.dart';
import 'package:shoppingcart/class.dart';
import 'package:shoppingcart/login.dart';
import 'package:shoppingcart/student.dart';
import 'package:shoppingcart/test.dart';

// Define AppColors for consistent theming
class AppColors {
  static const Color darkBlue = Color(0xFF1E3A8A);
  static const Color softBlue = Color(0xFFDBEAFE);
  static const Color mediumGray = Color(0xFF6B7280);
  static const Color lightGray = Color(0xFFE5E7EB);
  static const Color white = Color(0xFFFFFFFF);

  static var shadowMedium;
  static var shadowLight;
  static var shadowDark;
}

// Extension for TimeOfDay parsing
extension TimeOfDayExtension on TimeOfDay {
  static TimeOfDay? fromFormattedString(String formattedString) {
    try {
      final parts = formattedString.split(' ');
      if (parts.length == 2) {
        final timeParts = parts[0].split(':');
        int hour = int.parse(timeParts[0]);
        int minute = int.parse(timeParts[1]);
        if (parts[1].toLowerCase() == 'pm' && hour < 12) {
          hour += 12;
        } else if (parts[1].toLowerCase() == 'am' && hour == 12) {
          hour = 0;
        }
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      debugPrint('Error parsing time string: $e');
    }
    return null;
  }
}

// --- HomePage ---
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userRole;
  String? _userName;
  String? _userEmail;
  bool _isHeaderVisible = false;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    // Trigger header animation after a short delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isHeaderVisible = true;
        });
      }
    });
  }

  Future<void> _fetchUserRole() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        setState(() {
          _userRole = userDoc['role'];
          _userName = userDoc['name'];
          _userEmail = currentUser.email;
        });
      } else {
        setState(() {
          _userRole = 'student';
          _userName = 'Guest';
          _userEmail = currentUser.email;
        });
      }
    } else {
      setState(() {
        _userRole = 'student';
        _userName = 'Guest';
        _userEmail = null;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error logging out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log out: $e'),
          backgroundColor: AppColors.darkBlue,
        ),
      );
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    if (_userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email associated with this account.'),
          backgroundColor: AppColors.darkBlue,
        ),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: _userEmail!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent to $_userEmail. Please check your inbox.'),
          backgroundColor: AppColors.darkBlue,
        ),
      );
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send password reset email: $e'),
          backgroundColor: AppColors.darkBlue,
        ),
      );
    }
  }

  Widget _buildModuleButton(String title, {VoidCallback? onPressed, bool enabled = true}) {
    return AnimatedScale(
      scale: enabled ? 1.0 : 0.95,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: enabled
                ? [AppColors.softBlue, AppColors.white]
                : [AppColors.lightGray, AppColors.lightGray],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getModuleIcon(title),
                    size: 48,
                    color: enabled ? AppColors.darkBlue : AppColors.mediumGray,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: enabled ? AppColors.darkBlue : AppColors.mediumGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!enabled && _userRole == 'student')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '(Teacher Only)',
                        style: TextStyle(fontSize: 12, color: AppColors.mediumGray),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getModuleIcon(String title) {
    switch (title) {
      case 'Attendance Module':
        return Icons.check_circle_outline;
      case 'Student Module':
        return Icons.people_outline;
      case 'Class Module':
        return Icons.class_outlined;
      case 'Test Module':
        return Icons.assignment_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userRole == null) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: const Center(child: CircularProgressIndicator(color: AppColors.darkBlue)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'School Management',
          style: TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.darkBlue),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: Drawer(
        child: Stack(
          children: [
            // Background Image
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('asset/homebackground.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Semi-transparent Overlay
            Container(
              color: Colors.black.withOpacity(0.3),
            ),
            // Drawer Content
            ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.darkBlue, AppColors.softBlue],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.white,
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: AppColors.darkBlue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _userName ?? 'Guest',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _userEmail ?? 'No email',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.lock,
                  title: 'Change Password',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help,
                  title: 'Forgot Password',
                  onTap: () {
                    Navigator.pop(context);
                    _sendPasswordResetEmail();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: () {
                    Navigator.pop(context);
                    _logout();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Background Image
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('asset/homebackground.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Semi-transparent Overlay for Readability
            Container(
              color: Colors.black.withOpacity(0.3),
            ),
            // Main Content
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    // Header Section with Animation
                    AnimatedOpacity(
                      opacity: _isHeaderVisible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 800),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.darkBlue, AppColors.softBlue],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.school_outlined,
                                color: AppColors.white,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Welcome, ${_userName ?? 'User'}!',
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkBlue,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You are logged in as a $_userRole.',
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.mediumGray,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Module Grid
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildModuleButton(
                          'Attendance Module',
                          enabled: true,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AttendancePage()),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Navigating to Attendance Module (${_userRole == 'teacher' ? 'Teacher' : 'Student'})',
                                ),
                                backgroundColor: AppColors.darkBlue,
                              ),
                            );
                          },
                        ),
                        _buildModuleButton(
                          'Student Module',
                          enabled: true,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => Mystudent(userRole: _userRole ?? 'student')),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Navigating to Student Module (${_userRole == 'teacher' ? 'Teacher' : 'Student'})',
                                ),
                                backgroundColor: AppColors.darkBlue,
                              ),
                            );
                          },
                        ),
                        _buildModuleButton(
                          'Class Module',
                          enabled: true,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const Myclass()),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Navigating to Class Module (${_userRole == 'teacher' ? 'Teacher' : 'Student'})',
                                ),
                                backgroundColor: AppColors.darkBlue,
                              ),
                            );
                          },
                        ),
                        _buildModuleButton(
                          'Test Module',
                          enabled: true,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => Mytest(userRole: _userRole ?? 'student')),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Navigating to Test Module (${_userRole == 'teacher' ? 'Teacher' : 'Student'})',
                                ),
                                backgroundColor: AppColors.darkBlue,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          leading: Icon(icon, color: AppColors.darkBlue),
          title: Text(
            title,
            style: const TextStyle(
              color: AppColors.darkBlue,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: onTap,
          hoverColor: AppColors.softBlue.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}