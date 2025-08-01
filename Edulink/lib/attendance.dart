import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Define AppColors for consistent theming
class AppColors {
  static const Color darkBlue = Color(0xFF1E3A8A);
  static const Color softBlue = Color(0xFFDBEAFE);
  static const Color mediumGray = Color(0xFF6B7280);
  static const Color lightGray = Color(0xFFE5E7EB);
  static const Color white = Color(0xFFFFFFFF);
}

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedClass = 1;
  String _selectedDivision = 'A';
  DateTime _selectedDate = DateTime.now();
  final List<String> _classNumbers = List.generate(12, (index) => (index + 1).toString());
  final List<String> _divisionLetters = ['A', 'B', 'C', 'D'];
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = false;
  String? _userRole;
  String? _selectedSubject = 'General';
  final List<String> _subjects = [
    'Mathematics', 'Science', 'English', 'Social Studies',
    'Computer Science', 'Physical Education', 'Art', 'Music', 'General'
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate all class-division combinations
  final List<String> _divisions = List.generate(
    12,
    (index) => ['A', 'B', 'C', 'D'].map((letter) => 'Class ${index + 1}-$letter').toList(),
  ).expand((element) => element).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _divisions.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() {
          _selectedClass = int.parse(_divisions[_tabController.index].split('-')[0].split(' ')[1]);
          _selectedDivision = _divisions[_tabController.index].split('-')[1];
          _fetchStudents();
        });
      }
    });
    _loadUserRole().then((_) => _fetchStudents());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    try {
      final user = _auth.currentUser;
      print('DEBUG: Current user: ${user?.uid}');
      if (user == null) {
        throw Exception('User not logged in');
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        throw Exception('User document not found');
      }

      final role = doc.data()?['role'] as String?;
      print('DEBUG: Fetched role: $role');

      if (mounted) {
        setState(() {
          _userRole = role;
        });
      }
    } catch (e) {
      print('ERROR: Error loading user role: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user role: $e'),
            backgroundColor: AppColors.darkBlue,
          ),
        );
      }
    }
  }

  Future<void> _fetchStudents() async {
    if (_userRole == null) return;

    setState(() {
      _isLoading = true;
      _students = []; // Clear previous students
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final currentClassDivision = 'Class $_selectedClass-$_selectedDivision';
      print('DEBUG: Fetching students for $currentClassDivision');

      Query query = _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('division', isEqualTo: currentClassDivision)
          .orderBy('rollNumber');

      if (_userRole == 'teacher') {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        final teacherDivisions = (userDoc.data()?['divisions'] as List<dynamic>?)?.cast<String>() ?? [];
        print('DEBUG: Teacher divisions: $teacherDivisions');

        if (!teacherDivisions.contains(currentClassDivision)) {
          setState(() {
            _students = [];
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('You don\'t have access to $currentClassDivision'),
                backgroundColor: AppColors.darkBlue,
              ),
            );
          }
          return;
        }
      } else if (_userRole == 'student') {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        final studentDivision = userDoc.data()?['division'] as String? ?? '';
        print('DEBUG: Student division: $studentDivision');

        if (studentDivision != currentClassDivision) {
          setState(() {
            _students = [];
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('You can only view students in your division: $studentDivision'),
                backgroundColor: AppColors.darkBlue,
              ),
            );
          }
          return;
        }
      }

      final QuerySnapshot snapshot = await query.get();
      print('DEBUG: Fetched ${snapshot.docs.length} student documents for $currentClassDivision');

      final List<Map<String, dynamic>> students = [];
      for (var doc in snapshot.docs) {
        final studentData = doc.data() as Map<String, dynamic>;
        students.add({
          'id': doc.id,
          'name': studentData['name'] ?? 'N/A',
          'division': studentData['division'] ?? 'N/A',
          'rollNo': studentData['rollNumber'] ?? 0,
          'guardianName': studentData['guardianName'] ?? 'N/A',
          'phone': studentData['phone'] ?? 'N/A',
          'status': 'Present',
        });
        print('DEBUG: Added student: ${studentData['name']} (Roll: ${studentData['rollNumber']})');
      }

      if (mounted) {
        setState(() {
          _students = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('ERROR: Error fetching students: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching students: $e'),
            backgroundColor: AppColors.darkBlue,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    if (_userRole != 'teacher' && _userRole != 'admin') return;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.darkBlue,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.darkBlue,
            ),
            dialogBackgroundColor: AppColors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchStudents();
    }
  }

  void _updateAttendance(int index, String status) {
    if (mounted) {
      setState(() {
        _students[index]['status'] = status;
      });
    }
  }

  Future<void> _saveAttendance() async {
    if (_userRole != 'teacher' && _userRole != 'admin') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only teachers and admins can mark attendance'),
            backgroundColor: AppColors.darkBlue,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final batch = _firestore.batch();
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final classDivision = 'Class $_selectedClass-$_selectedDivision';
      final teacherName = _auth.currentUser?.displayName ?? _auth.currentUser?.email?.split('@')[0] ?? 'Unknown Teacher';

      for (var student in _students) {
        final attendanceRef = _firestore
            .collection('daily_attendance')
            .doc('$classDivision-$dateStr-${student['id']}');

        batch.set(attendanceRef, {
          'studentId': student['id'],
          'studentName': student['name'],
          'rollNumber': student['rollNo'],
          'division': student['division'],
          'status': student['status'],
          'date': Timestamp.fromDate(_selectedDate),
          'markedBy': _auth.currentUser?.uid,
          'markedAt': FieldValue.serverTimestamp(),
          'class': _selectedClass,
          'divisionLetter': _selectedDivision,
          'divisionFull': classDivision,
          'teacherName': teacherName,
          'subject': _selectedSubject,
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance saved for $classDivision on $dateStr'),
            backgroundColor: AppColors.darkBlue,
          ),
        );
      }
    } catch (e) {
      print('ERROR: Error saving attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving attendance: $e'),
            backgroundColor: AppColors.darkBlue,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showAddStudentDialog(BuildContext context, String currentDivision) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController rollNoController = TextEditingController();
    final TextEditingController guardianNameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppColors.white,
          title: Text(
            'Add New Student to $currentDivision',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBlue,
            ),
          ),
          content: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.softBlue,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.lightGray),
                    ),
                    child: TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Student Name',
                        labelStyle: TextStyle(color: AppColors.darkBlue),
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
                      controller: rollNoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Roll Number',
                        labelStyle: TextStyle(color: AppColors.darkBlue),
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
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email (Optional)',
                        labelStyle: TextStyle(color: AppColors.darkBlue),
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
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone (Optional)',
                        labelStyle: TextStyle(color: AppColors.darkBlue),
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
                      controller: guardianNameController,
                      decoration: const InputDecoration(
                        labelText: 'Guardian Name (Optional)',
                        labelStyle: TextStyle(color: AppColors.darkBlue),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.mediumGray),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkBlue,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add Student'),
              onPressed: () async {
                final String studentName = nameController.text.trim();
                final int? rollNumber = int.tryParse(rollNoController.text.trim());
                final String guardianName = guardianNameController.text.trim();
                final String email = emailController.text.trim();
                final String phone = phoneController.text.trim();

                if (studentName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Student name cannot be empty.'),
                      backgroundColor: AppColors.darkBlue,
                    ),
                  );
                  return;
                }
                if (rollNumber == null || rollNumber <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid Roll Number.'),
                      backgroundColor: AppColors.darkBlue,
                    ),
                  );
                  return;
                }

                try {
                  final existingStudent = await _firestore
                      .collection('users')
                      .where('role', isEqualTo: 'student')
                      .where('division', isEqualTo: currentDivision)
                      .where('rollNumber', isEqualTo: rollNumber)
                      .get();
                  if (existingStudent.docs.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Roll number $rollNumber already exists in $currentDivision'),
                        backgroundColor: AppColors.darkBlue,
                      ),
                    );
                    return;
                  }

                  await _firestore.collection('users').add({
                    'name': studentName,
                    'rollNumber': rollNumber,
                    'division': currentDivision,
                    'guardianName': guardianName.isNotEmpty ? guardianName : null,
                    'email': email.isNotEmpty ? email : null,
                    'phone': phone.isNotEmpty ? phone : null,
                    'role': 'student',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$studentName added successfully!'),
                      backgroundColor: AppColors.darkBlue,
                    ),
                  );
                  _fetchStudents();
                } catch (e) {
                  print('ERROR: Failed to add student: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to add student: $e'),
                      backgroundColor: AppColors.darkBlue,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          'Attendance Management',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.darkBlue,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.2),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _divisions.map((division) => Tab(text: division)).toList(),
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withOpacity(0.7),
          indicatorColor: AppColors.white,
          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
        ),
      ),
      body: Stack(
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
          // Main Content
          _userRole == null
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkBlue))
              : Column(
                  children: [
                    // Date and Subject Selection
                    Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
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
                          const Text(
                            'Select Date and Subject to Mark Attendance',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.mediumGray,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                flex: 2,
                                child: InkWell(
                                  onTap: () => _selectDate(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.softBlue,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.lightGray),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          color: AppColors.darkBlue,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            DateFormat('yyyy-MM-dd').format(_selectedDate),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: AppColors.darkBlue,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                flex: 3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.softBlue,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.lightGray),
                                  ),
                                  child: DropdownButton<String>(
                                    value: _selectedSubject,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    items: _subjects.map<DropdownMenuItem<String>>((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(
                                          value,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.darkBlue,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (_userRole == 'teacher' || _userRole == 'admin')
                                        ? (String? newValue) {
                                            if (newValue != null && mounted) {
                                              setState(() {
                                                _selectedSubject = newValue;
                                              });
                                            }
                                          }
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Attendance Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: AppColors.softBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem('Present', Icons.check_circle, Colors.green),
                          _buildSummaryItem('Absent', Icons.cancel, Colors.red),
                          _buildSummaryItem('Leave', Icons.airplanemode_active, Colors.orange),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Student List
                    if (_isLoading)
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkBlue),
                        ),
                      )
                    else if (_userRole != 'teacher' && _userRole != 'admin' && _userRole != 'student')
                      const Expanded(
                        child: Center(
                          child: Text(
                            'You do not have permission to view this page',
                            style: TextStyle(fontSize: 16, color: AppColors.white),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: _divisions.map((division) {
                            return _students.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No students found.',
                                      style: TextStyle(fontSize: 16, color: AppColors.white),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    itemCount: _students.length,
                                    itemBuilder: (context, index) {
                                      final student = _students[index];
                                      return Card(
                                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.softBlue,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: AppColors.lightGray),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Name: ${student['name']}',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.darkBlue,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Division: ${student['division']}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: AppColors.darkBlue,
                                                  ),
                                                ),
                                                Text(
                                                  'Roll Number: ${student['rollNo']}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: AppColors.darkBlue,
                                                  ),
                                                ),
                                                Text(
                                                  'Guardian: ${student['guardianName']}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: AppColors.darkBlue,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                                Text(
                                                  'Phone: ${student['phone']}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: AppColors.darkBlue,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                if (_userRole == 'teacher' || _userRole == 'admin')
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      _buildStatusButton(
                                                        context,
                                                        'P',
                                                        'Present',
                                                        student['status'],
                                                        () => _updateAttendance(index, 'Present'),
                                                      ),
                                                      _buildStatusButton(
                                                        context,
                                                        'A',
                                                        'Absent',
                                                        student['status'],
                                                        () => _updateAttendance(index, 'Absent'),
                                                      ),
                                                      _buildStatusButton(
                                                        context,
                                                        'L',
                                                        'Leave',
                                                        student['status'],
                                                        () => _updateAttendance(index, 'Leave'),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                          }).toList(),
                        ),
                      ),

                    // Save Button
                    if (_userRole == 'teacher' || _userRole == 'admin')
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveAttendance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkBlue,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: AppColors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save Attendance',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                  ],
                ),
        ],
      ),
      floatingActionButton: (_userRole == 'teacher' || _userRole == 'admin')
          ? FloatingActionButton.extended(
              onPressed: () {
                final String currentDivision = 'Class $_selectedClass-$_selectedDivision';
                _showAddStudentDialog(context, currentDivision);
              },
              label: const Text(
                'Add Student',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              icon: const Icon(Icons.person_add, semanticLabel: 'Add Student'),
              backgroundColor: AppColors.darkBlue,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            )
          : null,
    );
  }

  Widget _buildStatusButton(
    BuildContext context,
    String label,
    String statusValue,
    String currentStatus,
    VoidCallback onPressed,
  ) {
    bool isSelected = currentStatus == statusValue;
    Color buttonColor;
    switch (statusValue) {
      case 'Present':
        buttonColor = Colors.green;
        break;
      case 'Absent':
        buttonColor = Colors.red;
        break;
      default:
        buttonColor = Colors.orange;
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: (_userRole == 'teacher' || _userRole == 'admin') ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? buttonColor : AppColors.lightGray,
            foregroundColor: isSelected ? AppColors.white : AppColors.darkBlue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            elevation: isSelected ? 2 : 0,
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, IconData icon, Color color) {
    final count = _students.where((student) => student['status'].toLowerCase() == title.toLowerCase()).length;
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkBlue),
        ),
        Text(
          '$count',
          style: const TextStyle(color: AppColors.darkBlue),
        ),
      ],
    );
  }
}