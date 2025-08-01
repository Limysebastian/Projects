import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scf/changepassword.dart';
import 'package:scf/dairy.dart';
import 'package:scf/drawer.dart';
import 'package:scf/gallery.dart';
import 'package:scf/email.dart';
import 'package:scf/login.dart';
import 'package:scf/nomine.dart';
import 'package:scf/phone.dart';
import 'package:scf/bank.dart';
import 'package:scf/document.dart';
import 'package:scf/folder.dart';
import 'package:scf/general.dart';
import 'package:scf/links.dart';
import 'package:scf/income.dart';
import 'package:scf/kuth.dart';
import 'package:scf/special.dart';
import 'package:scf/viewnominee.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(MaterialApp(
    home: const Myhome(),
    debugShowCheckedModeBanner: false,
  ));
}

class Myhome extends StatefulWidget {
  const Myhome({super.key});

  @override
  State<Myhome> createState() => _MyhomeState();
}

class _MyhomeState extends State<Myhome> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final Color primaryRed = Colors.lightBlue;
  final Color darkRed = const Color.fromARGB(255, 117, 208, 250);
  final Color accentRed = const Color.fromARGB(255, 3, 116, 168);
  final Color blackColor = const Color(0xFF1A1A1A);
  final Color greyBlack = const Color(0xFF2D2D2D);
  final Color white = const Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> homeButtons = [
    {'label': 'Dairy', 'icon': Icons.book_outlined, 'page': const Mysecond()},
    {'label': 'Gallery', 'icon': Icons.photo_library_outlined, 'page': const TailwindGalleryUI()},
    {'label': 'Email', 'icon': Icons.email_outlined, 'page': const Myemil()},
    {'label': 'Phone', 'icon': Icons.phone_outlined, 'page': const ContactUI()},
    {'label': 'Bank', 'icon': Icons.account_balance_outlined, 'page': const Mybank()},
    {'label': 'Document', 'icon': Icons.folder_open_outlined, 'page': const Mydocu()},
    {'label': 'Folder', 'icon': Icons.folder_outlined, 'page': MyFolder()},
    {'label': 'General', 'icon': Icons.category_outlined, 'page': const Mygeneral()},
    {'label': 'Links', 'icon': Icons.link, 'page': const Mylink()},
    {'label': 'Daily Expense/Income', 'icon': Icons.currency_rupee_outlined, 'page': const Myincom()},
    {'label': 'Kuth Book', 'icon': Icons.menu_book_outlined, 'page': const Mykuth()},
    {'label': 'Special Days', 'icon': Icons.celebration_outlined, 'page': const Mysepical()},
  ];

  Widget _buildModernDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [blackColor, greyBlack],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(
              height: 160, // Fixed height for drawer header
              child: AccountDrawerHeader(
                primaryColor: Colors.lightBlue,
                backgroundColor: Color(0xFF2D2D2D),
              ),
            ),
            _buildDrawerTile(Icons.person_outline, 'Nominee Name', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const Mynomini()));
            }),
            _buildDrawerTile(Icons.visibility_outlined, 'View Nominee', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const Myview(nominees: [])));
            }),
            _buildDivider(),
            _buildDrawerTile(Icons.lock_outline, 'Change Password', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
            }),
            _buildDrawerTile(Icons.vpn_key_off_outlined, 'Forgot Password', () {
              Navigator.pop(context);
              AuthUtils.showForgotPasswordDialog(context);
            }),
            _buildDivider(),
            _buildDrawerTile(Icons.info_outline, 'About App', () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('About App functionality not implemented yet.'), backgroundColor: primaryRed),
              );
            }),
            _buildDrawerTile(Icons.logout_outlined, 'Logout', () async {
              try {
                await FirebaseAuth.instance.signOut();
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Logged out successfully'), backgroundColor: primaryRed),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logout failed: $e'), backgroundColor: Colors.red),
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryRed.withOpacity(0.2), primaryRed.withOpacity(0.1)],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primaryRed, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        hoverColor: primaryRed.withOpacity(0.1),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, primaryRed.withOpacity(0.3), Colors.transparent],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [darkRed, primaryRed],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        title: const Text(
          'My Organizer',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.5,
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: Offset(1, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Settings clicked'),
                    backgroundColor: primaryRed,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      drawer: _buildModernDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              blackColor,
              greyBlack,
              const Color(0xFF3A3A3A),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Welcome Section
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryRed.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryRed.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: primaryRed.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryRed, darkRed],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryRed.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.dashboard, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome Back!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Organize your digital life',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Grid Section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: homeButtons.length,
                      itemBuilder: (context, index) {
                        final buttonData = homeButtons[index];
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 200 + (index * 50)),
                          child: ModernGridButton(
                            label: buttonData['label'],
                            icon: buttonData['icon'],
                            onPressed: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => buttonData['page'],
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return SlideTransition(
                                      position: animation.drive(
                                        Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
                                      ),
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                            primaryRed: primaryRed,
                            darkRed: darkRed,
                            index: index,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AccountDrawerHeader extends StatefulWidget {
  final Color primaryColor;
  final Color backgroundColor;

  const AccountDrawerHeader({
    Key? key,
    required this.primaryColor,
    required this.backgroundColor,
  }) : super(key: key);

  @override
  State<AccountDrawerHeader> createState() => _AccountDrawerHeaderState();
}

class _AccountDrawerHeaderState extends State<AccountDrawerHeader> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  String? _userName;
  String? _userEmail;
  String? _userPan;
  String? _userAadhaar;
  String? _profileImageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        
        if (doc.exists) {
          setState(() {
            _userName = doc['name'] ?? 'No Name';
            _userEmail = doc['email'] ?? user.email ?? 'No Email';
            _userPan = doc['pan'] ?? 'Not Provided';
            _userAadhaar = doc['aadhaar'] ?? 'Not Provided';
            _profileImageUrl = doc['profile_image'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Failed to load user data: ${e.toString()}');
    }
  }

  Future<void> _updateProfileImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        setState(() => _isLoading = true);
        final user = _auth.currentUser;
        
        if (user != null) {
          final ref = _storage.ref('profile_images/${user.uid}.jpg');
          await ref.putFile(File(pickedFile.path));
          final downloadUrl = await ref.getDownloadURL();
          
          await _firestore.collection('users').doc(user.uid).update({
            'profile_image': downloadUrl,
          });
          
          setState(() {
            _profileImageUrl = downloadUrl;
            _isLoading = false;
          });
          
          _showSuccessSnackbar('Profile image updated successfully');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Failed to update image: ${e.toString()}');
    }
  }

  void _showAccountDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.primaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: const Text(
            'Account Details',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('Name:', _userName ?? 'Loading...'),
              _buildDetailItem('Email:', _userEmail ?? 'Loading...'),
              _buildDetailItem('PAN:', _userPan ?? 'Not Provided'),
              _buildDetailItem('Aadhaar:', _userAadhaar ?? 'Not Provided'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: widget.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: widget.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.primaryColor.withOpacity(0.2), widget.backgroundColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _updateProfileImage,
              child: _isLoading
                  ? CircularProgressIndicator(color: widget.primaryColor)
                  : CircleAvatar(
                      radius: 30,
                      backgroundImage: _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : null,
                      child: _profileImageUrl == null
                          ? Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.white,
                            )
                          : null,
                      backgroundColor: widget.primaryColor.withOpacity(0.2),
                    ),
            ),
            const SizedBox(height: 10),
            Text(
              _userName ?? 'Loading...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: _showAccountDetails,
              child: GestureDetector(
                child: Text(
                  'Manage Account',
                  style: TextStyle(
                    color: widget.primaryColor,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
                onTap: (){ Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AccountDetailsPage()),
    );},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModernGridButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color primaryRed;
  final Color darkRed;
  final int index;

  const ModernGridButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.primaryRed,
    required this.darkRed,
    required this.index,
  });

  @override
  State<ModernGridButton> createState() => _ModernGridButtonState();
}

class _ModernGridButtonState extends State<ModernGridButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: widget.primaryRed.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onPressed,
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.darkRed,
                    widget.primaryRed,
                    widget.primaryRed.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
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
}

class AuthUtils {
  static void showForgotPasswordDialog(BuildContext context) {
    final TextEditingController forgotPasswordEmailController = TextEditingController();
    final Color primaryRed = const Color.fromARGB(255, 229, 73, 62);
    final Color darkRed = const Color.fromARGB(255, 28, 161, 185);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [darkRed, primaryRed]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Reset Password',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your email to receive a password reset link:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: forgotPasswordEmailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: TextStyle(color: primaryRed),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryRed),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryRed, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final email = forgotPasswordEmailController.text.trim();
                if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please enter a valid email address'),
                      backgroundColor: primaryRed,
                    ),
                  );
                  return;
                }

                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Password reset link sent to your email.'),
                      backgroundColor: primaryRed,
                    ),
                  );
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                } on FirebaseAuthException catch (e) {
                  String message = e.code == 'user-not-found' 
                      ? 'No user found for that email.' 
                      : 'Error sending reset link: ${e.message}';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("🚫 $message"), backgroundColor: Colors.red),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("🚫 An unexpected error occurred: $e"), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Send Reset Link', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ).then((_) => forgotPasswordEmailController.dispose());
  }
}