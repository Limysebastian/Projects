import 'package:flutter/material.dart';
import 'package:scf/login.dart'; // Ensure this path is correct for your LoginScreen
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Cloud Firestore



class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController panController = TextEditingController();
  final TextEditingController aadhaarController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false; // Added for loading indicator

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    panController.dispose();
    aadhaarController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Function to handle user registration
  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Show loading indicator
      });
      print('Attempting to register user...');

      try {
        // 1. Register user with Email and Password using Firebase Auth
        print('Creating user with email: ${emailController.text.trim()}');
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
        print('User created in Firebase Auth.');

        User? user = userCredential.user;

        if (user != null) {
          print('User UID: ${user.uid}');
          // 2. Save additional user details to Firestore
          print('Saving user details to Firestore...');
          await _firestore.collection('users').doc(user.uid).set({
            'name': nameController.text.trim(),
            'email': emailController.text.trim(),
            'phone': phoneController.text.trim(),
            'pan': panController.text.trim(),
            'aadhaar': aadhaarController.text.trim(),
            'createdAt': Timestamp.now(), // Store registration timestamp
          });
          print('User details saved to Firestore successfully.');

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("✅ Account created successfully!"),
              backgroundColor: Colors.lightBlue.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );

          // Navigate to LoginScreen after successful registration
          // Use pushReplacement to prevent going back to Register screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        } else {
          print('User object is null after registration. This should not happen.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("🚫 Registration failed: User object is null."),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'weak-password') {
          message = 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          message = 'An account already exists for that email.';
        } else if (e.code == 'operation-not-allowed') {
          message = 'Email/Password sign-in is not enabled. Go to Firebase Console > Authentication > Sign-in method.';
        }
        else {
          message = 'Registration failed: ${e.message} (Code: ${e.code})';
        }
        print('Firebase Auth Error: ${e.code} - ${e.message}');
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🚫 $message"),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } catch (e) {
        // Handle any other unexpected errors
        print('General Error during registration: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🚫 An unexpected error occurred: $e"),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false; // Hide loading indicator regardless of success or failure
        });
        print('Registration process finished.');
      }
    } else {
      print('Form validation failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A0A0A), // Deep black
              Color(0xFF1A1A2E), // Dark blue-black
              Color(0xFF16213E), // Dark blue
              Color(0xFF0A0A0A), // Back to deep black
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Glassmorphism Wave Header
              ClipPath(
                clipper: WaveClipper(),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.lightBlue.shade300.withOpacity(0.3),
                        Colors.lightBlue.shade100.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.lightBlue.shade200.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        "Register",
                        style: TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Cursive',
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Glassmorphism Container for Form
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.lightBlue.shade50.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 25,
                        offset: const Offset(0, 15),
                        spreadRadius: -5,
                      ),
                      BoxShadow(
                        color: Colors.lightBlue.shade200.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(-5, -5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Name field (Required)
                        customTextField(nameController, "Name", icon: Icons.person, isRequired: true),
                        const SizedBox(height: 18),

                        // Phone Number field (Optional)
                        customTextField(phoneController, "Phone Number", icon: Icons.phone, inputType: TextInputType.phone, maxLength: 10),
                        const SizedBox(height: 18),

                        // Email field (Required)
                        customTextField(emailController, "Email", icon: Icons.email, inputType: TextInputType.emailAddress, isRequired: true),
                        const SizedBox(height: 18),

                        // PAN field (Optional)
                        customTextField(panController, "PAN", icon: Icons.credit_card),
                        const SizedBox(height: 18),

                        // Aadhaar field (Required)
                        customTextField(aadhaarController, "Aadhaar", icon: Icons.badge, inputType: TextInputType.number, maxLength: 12, isRequired: true),
                        const SizedBox(height: 18),

                        // Password field (Required)
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.lightBlue.shade50.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: TextFormField(
                            controller: passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            decoration: InputDecoration(
                              labelText: "Password *",
                              labelStyle: TextStyle(color: Colors.lightBlue.shade200),
                              prefixIcon: Icon(Icons.lock, color: Colors.lightBlue.shade300),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.lightBlue.shade300,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 35),
                        
                        // Glassmorphism Register Button
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.lightBlue.shade400,
                                  Colors.lightBlue.shade600,
                                  Colors.blue.shade700,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.lightBlue.shade300.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              onPressed: _isLoading ? null : _registerUser,
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    )
                                  : const Text(
                                      "Create Account",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(0, 1),
                                            blurRadius: 2,
                                            color: Colors.black26,
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        
                        // Login Link
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => LoginScreen()),
                            );
                          },
                          child: Text(
                            "Already have an account? Log in",
                            style: TextStyle(
                              color: Colors.lightBlue.shade200,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              shadows: const [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  Widget customTextField(
      TextEditingController controller,
      String label, {
        TextInputType inputType = TextInputType.text,
        int? maxLength,
        bool obscure = false,
        IconData? icon,
        bool isRequired = false,
      }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.lightBlue.shade50.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        obscureText: obscure,
        maxLength: maxLength,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: isRequired ? "$label *" : label,
          labelStyle: TextStyle(color: Colors.lightBlue.shade200),
          prefixIcon: icon != null 
              ? Icon(icon, color: Colors.lightBlue.shade300) 
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          counterText: "",
          errorStyle: TextStyle(color: Colors.red.shade300),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return "$label is required";
          }

          // Additional validation for specific fields
          if (label.contains("Email") && value != null && value.isNotEmpty) {
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email address';
            }
          }

          if (label.contains("Aadhaar") && value != null && value.isNotEmpty) {
            if (value.length != 12) {
              return 'Aadhaar must be 12 digits';
            }
          }

          if (label.contains("Phone") && value != null && value.isNotEmpty) {
            if (value.length != 10) {
              return 'Phone number must be 10 digits';
            }
          }

          return null;
        },
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.5, size.height * 0.9);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.8, size.width, size.height * 0.9);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}