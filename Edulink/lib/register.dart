import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shoppingcart/login.dart';

// Define AppColors for consistent theming
class AppColors {
  static const Color darkBlue = Color(0xFF1E3A8A);
  static const Color softBlue = Color(0xFFDBEAFE);
  static const Color mediumGray = Color(0xFF6B7280);
  static const Color lightGray = Color(0xFFE5E7EB);
  static const Color white = Color(0xFFFFFFFF);
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _rollNumberController = TextEditingController();
  final TextEditingController _guardianNameController = TextEditingController();
  final List<TextEditingController> _divisionControllers = [TextEditingController()];
  String? _selectedRole = 'student';

  // Class and division selection
  final List<String> _classNumbers = List.generate(12, (index) => (index + 1).toString());
  final List<String> _divisionLetters = ['A', 'B', 'C', 'D'];
  String? _selectedClassNumber = '1';
  String? _selectedDivisionLetter = 'A';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _addDivisionField() {
    setState(() {
      _divisionControllers.add(TextEditingController());
    });
  }

  void _removeDivisionField(int index) {
    setState(() {
      if (_divisionControllers.length > 1) {
        _divisionControllers[index].dispose();
        _divisionControllers.removeAt(index);
      } else {
        _divisionControllers[0].clear();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _rollNumberController.dispose();
    _guardianNameController.dispose();
    for (var controller in _divisionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _registerUser() async {
    // Basic validation
    if (_usernameController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email and Password cannot be empty.'),
          backgroundColor: AppColors.darkBlue,
        ),
      );
      return;
    }

    if (_selectedRole == 'student') {
      if (_rollNumberController.text.trim().isEmpty || int.tryParse(_rollNumberController.text.trim()) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid Roll Number.'),
            backgroundColor: AppColors.darkBlue,
          ),
        );
        return;
      }
      if (_selectedClassNumber == null || _selectedDivisionLetter == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select both Class and Division.'),
            backgroundColor: AppColors.darkBlue,
          ),
        );
        return;
      }
    } else if (_selectedRole == 'teacher') {
      if (_divisionControllers.every((c) => c.text.trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter at least one Division for the teacher.'),
            backgroundColor: AppColors.darkBlue,
          ),
        );
        return;
      }
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      List<String> divisions = _divisionControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      Map<String, dynamic> userData = {
        'name': _nameController.text.trim(),
        'email': _usernameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_selectedRole == 'student') {
        userData['division'] = 'Class $_selectedClassNumber-$_selectedDivisionLetter';
        userData['rollNumber'] = int.parse(_rollNumberController.text.trim());
        userData['guardianName'] = _guardianNameController.text.trim();
      } else if (_selectedRole == 'teacher') {
        userData['divisions'] = divisions;
      }

      await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please log in.'),
            backgroundColor: AppColors.darkBlue,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      } else {
        message = 'Registration failed: ${e.message}';
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.darkBlue,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: AppColors.darkBlue,
          ),
        );
      }
    }
  }

  // Parse division string (e.g., "Class 1-A") into class number and division letter
  Map<String, String> _parseDivision(String division) {
    try {
      final parts = division.split('-');
      if (parts.length == 2) {
        final classNum = parts[0].replaceAll('Class ', '').trim();
        final divLetter = parts[1].trim();
        return {'class': classNum, 'division': divLetter};
      }
    } catch (e) {
      print('ERROR: Failed to parse division: $division, Error: $e');
    }
    return {'class': 'Unknown', 'division': 'Unknown'};
  }

  // Group students by class and division
  Map<String, Map<String, List<Map<String, dynamic>>>> _groupStudents(List<QueryDocumentSnapshot> docs) {
    final grouped = <String, Map<String, List<Map<String, dynamic>>>>{};
    for (var doc in docs) {
      final studentData = doc.data() as Map<String, dynamic>;
      final division = studentData['division'] as String? ?? 'Unknown';
      final parsed = _parseDivision(division);
      final classNum = parsed['class']!;
      final divLetter = parsed['division']!;

      if (!grouped.containsKey(classNum)) {
        grouped[classNum] = {};
      }
      if (!grouped[classNum]!.containsKey(divLetter)) {
        grouped[classNum]![divLetter] = [];
      }
      grouped[classNum]![divLetter]!.add(studentData);
    }

    // Sort students within each division by name
    grouped.forEach((classNum, divisions) {
      divisions.forEach((divLetter, students) {
        students.sort((a, b) => (a['name'] ?? 'N/A').compareTo(b['name'] ?? 'N/A'));
      });
    });

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 60),
                // Logo/Title Section
                Container(
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.darkBlue,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.school_outlined,
                          color: AppColors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign up to get started',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                // Form Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Full Name Field
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.softBlue,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.lightGray),
                        ),
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            labelStyle: TextStyle(color: AppColors.darkBlue),
                            prefixIcon: Icon(Icons.person, color: AppColors.darkBlue),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Email Field
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.softBlue,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.lightGray),
                        ),
                        child: TextField(
                          controller: _usernameController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email (Used for Login)',
                            labelStyle: TextStyle(color: AppColors.darkBlue),
                            prefixIcon: Icon(Icons.email_outlined, color: AppColors.darkBlue),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Phone Number Field
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.softBlue,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.lightGray),
                        ),
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            labelStyle: TextStyle(color: AppColors.darkBlue),
                            prefixIcon: Icon(Icons.phone, color: AppColors.darkBlue),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Password Field
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.softBlue,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.lightGray),
                        ),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(color: AppColors.darkBlue),
                            prefixIcon: Icon(Icons.lock_outlined, color: AppColors.darkBlue),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Role Selection
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.softBlue,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.lightGray),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedRole,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Select Role',
                            labelStyle: TextStyle(color: AppColors.darkBlue),
                            prefixIcon: Icon(Icons.group, color: AppColors.darkBlue),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'student', child: Text('Student')),
                            DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                          ],
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedRole = newValue;
                              for (var controller in _divisionControllers) {
                                controller.dispose();
                              }
                              _divisionControllers.clear();
                              _divisionControllers.add(TextEditingController());
                              _rollNumberController.clear();
                              _guardianNameController.clear();
                              _selectedClassNumber = '1';
                              _selectedDivisionLetter = 'A';
                            });
                          },
                          dropdownColor: AppColors.softBlue,
                          menuMaxHeight: 200,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_selectedRole == 'teacher') ...[
                        const Text(
                          'Divisions you teach:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.3,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: _divisionControllers.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.softBlue,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppColors.lightGray),
                                        ),
                                        child: DropdownButtonFormField<String>(
                                          value: _divisionControllers[index].text.isEmpty
                                              ? null
                                              : _divisionControllers[index].text,
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                            labelText: 'Division ${index + 1}',
                                            labelStyle: const TextStyle(color: AppColors.darkBlue),
                                            border: InputBorder.none,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                          ),
                                          items: _classNumbers.expand((classNum) =>
                                              _divisionLetters.map((divLetter) {
                                                final value = 'Class $classNum-$divLetter';
                                                return DropdownMenuItem(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              })).toList(),
                                          onChanged: (String? newValue) {
                                            if (newValue != null) {
                                              _divisionControllers[index].text = newValue;
                                            }
                                          },
                                          dropdownColor: AppColors.softBlue,
                                          menuMaxHeight: 200,
                                        ),
                                      ),
                                    ),
                                    if (_divisionControllers.length > 1)
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.darkBlue),
                                        onPressed: () => _removeDivisionField(index),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _addDivisionField,
                            icon: const Icon(Icons.add, color: AppColors.white),
                            label: const Text(
                              'Add Another Division',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.darkBlue,
                              foregroundColor: AppColors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ] else if (_selectedRole == 'student') ...[
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.softBlue,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.lightGray),
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: _selectedClassNumber,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Class',
                                    labelStyle: TextStyle(color: AppColors.darkBlue),
                                    prefixIcon: Icon(Icons.school_outlined, color: AppColors.darkBlue),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                  items: _classNumbers
                                      .map((classNum) => DropdownMenuItem(
                                            value: classNum,
                                            child: Text('Class $classNum'),
                                          ))
                                      .toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedClassNumber = newValue;
                                    });
                                  },
                                  dropdownColor: AppColors.softBlue,
                                  menuMaxHeight: 200,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.softBlue,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.lightGray),
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: _selectedDivisionLetter,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Division',
                                    labelStyle: TextStyle(color: AppColors.darkBlue),
                                    prefixIcon: Icon(Icons.groups, color: AppColors.darkBlue),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                  items: _divisionLetters
                                      .map((divLetter) => DropdownMenuItem(
                                            value: divLetter,
                                            child: Text('Division $divLetter'),
                                          ))
                                      .toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedDivisionLetter = newValue;
                                    });
                                  },
                                  dropdownColor: AppColors.softBlue,
                                  menuMaxHeight: 200,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.softBlue,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.lightGray),
                          ),
                          child: TextField(
                            controller: _rollNumberController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Roll Number',
                              labelStyle: TextStyle(color: AppColors.darkBlue),
                              prefixIcon: Icon(Icons.format_list_numbered, color: AppColors.darkBlue),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.softBlue,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.lightGray),
                          ),
                          child: TextField(
                            controller: _guardianNameController,
                            keyboardType: TextInputType.text,
                            decoration: const InputDecoration(
                              labelText: 'Guardian Name',
                              labelStyle: TextStyle(color: AppColors.darkBlue),
                              prefixIcon: Icon(Icons.people, color: AppColors.darkBlue),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _registerUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkBlue,
                            foregroundColor: AppColors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Register',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Registered Students Section
                const Text(
                  'Registered Students',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('users')
                      .where('role', isEqualTo: 'student')
                      .orderBy('division')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.darkBlue));
                    }
                    if (snapshot.hasError) {
                      print('ERROR: StreamBuilder error: ${snapshot.error}');
                      return Center(
                        child: Text(
                          'Error fetching students: ${snapshot.error}',
                          style: const TextStyle(color: AppColors.darkBlue),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      print('DEBUG: No students to display.');
                      return const Center(
                        child: Text(
                          'No students registered.',
                          style: TextStyle(color: AppColors.darkBlue),
                        ),
                      );
                    }

                    final students = snapshot.data!.docs;
                    print('DEBUG: Fetched ${students.length} student documents.');

                    // Group students by class and division
                    final groupedStudents = _groupStudents(students);

                    // Sort classes numerically
                    final sortedClasses = groupedStudents.keys.toList()
                      ..sort((a, b) {
                        if (a == 'Unknown') return 1;
                        if (b == 'Unknown') return -1;
                        return int.parse(a).compareTo(int.parse(b));
                      });

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedClasses.length,
                      itemBuilder: (context, classIndex) {
                        final classNum = sortedClasses[classIndex];
                        final divisions = groupedStudents[classNum]!;
                        final sortedDivisions = divisions.keys.toList()..sort();

                        return ExpansionTile(
                          title: Text(
                            'Class $classNum',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkBlue,
                            ),
                          ),
                          children: sortedDivisions.map((divLetter) {
                            final studentsInDivision = divisions[divLetter]!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                  child: Text(
                                    'Division $divLetter',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.darkBlue,
                                    ),
                                  ),
                                ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: studentsInDivision.length,
                                  itemBuilder: (context, studentIndex) {
                                    final studentData = studentsInDivision[studentIndex];
                                    print('DEBUG: Displaying student: ${studentData['name']}');
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                                      child: Text(
                                        studentData['name'] ?? 'N/A',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: AppColors.darkBlue,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          }).toList(),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: AppColors.mediumGray, fontSize: 15),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: AppColors.darkBlue,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}