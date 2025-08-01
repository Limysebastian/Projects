import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Mystudent extends StatefulWidget {
  const Mystudent({super.key, required String userRole});

  @override
  State<Mystudent> createState() => _MystudentState();
}

class _MystudentState extends State<Mystudent> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Stream<QuerySnapshot>> _getStudentDataStreamForCurrentUser() async {
    final user = _auth.currentUser;

    if (user == null) {
      print('DEBUG: No user logged in.');
      return Stream.empty();
    }

    try {
      print('DEBUG: Fetching current user data for UID: ${user.uid}');
      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();

      if (docSnapshot.exists) {
        final userData = docSnapshot.data();
        final userRole = userData?['role'];
        final userDivision = userData?['division'];

        print('DEBUG: User Role: $userRole, User Division: $userDivision');

        if (userRole == 'teacher') {
          print('DEBUG: User is a teacher. Fetching all students.');
          return _firestore
              .collection('users')
              .where('role', isEqualTo: 'student')
              .orderBy('division')
              .snapshots();
        } else if (userRole == 'student' && userDivision != null && userDivision.isNotEmpty) {
          String studentMainDivision = userDivision[0];
          print('DEBUG: User is a student. Fetching students for division: $studentMainDivision');
          return _firestore
              .collection('users')
              .where('role', isEqualTo: 'student')
              .where('division', arrayContains: studentMainDivision)
              .snapshots();
        } else {
          print('DEBUG: User role not recognized or student has no division data.');
        }
      } else {
        print('DEBUG: Current user document does not exist in Firestore for UID: ${user.uid}');
      }
    } catch (e) {
      print('ERROR: Error fetching user role/division: $e');
    }

    return Stream.empty();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // White background
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Students List', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E3A8A), // Dark blue
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.2),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              FutureBuilder<Stream<QuerySnapshot>>(
                future: _getStudentDataStreamForCurrentUser(),
                builder: (context, streamFutureSnapshot) {
                  if (streamFutureSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)));
                  }
                  if (streamFutureSnapshot.hasError) {
                    print('ERROR: FutureBuilder error: ${streamFutureSnapshot.error}');
                    return Center(child: Text('Error preparing student list: ${streamFutureSnapshot.error}',
                        style: const TextStyle(color: Color(0xFF1E3A8A))));
                  }
                  if (!streamFutureSnapshot.hasData || streamFutureSnapshot.data == null) {
                    print('DEBUG: No student data stream available from FutureBuilder.');
                    return const Center(child: Text('No student data stream available.',
                        style: TextStyle(color: Color(0xFF1E3A8A))));
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: streamFutureSnapshot.data,
                    builder: (context, studentSnapshot) {
                      if (studentSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)));
                      }
                      if (studentSnapshot.hasError) {
                        print('ERROR: StreamBuilder error: ${studentSnapshot.error}');
                        return Center(child: Text('Error fetching students: ${studentSnapshot.error}',
                            style: const TextStyle(color: Color(0xFF1E3A8A))));
                      }
                      if (!studentSnapshot.hasData || studentSnapshot.data!.docs.isEmpty) {
                        print('DEBUG: StreamBuilder has no data or docs are empty.');
                        return const Center(child: Text('No students to display.',
                            style: TextStyle(color: Color(0xFF1E3A8A))));
                      }

                      final students = studentSnapshot.data!.docs;
                      print('DEBUG: Fetched ${students.length} student documents.');

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(0),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final studentData = students[index].data() as Map<String, dynamic>;

                          print('DEBUG: Displaying student: ${studentData['name']}');

                          String divisionText = 'N/A';
                          var divisionRaw = studentData['division'];
                          if (divisionRaw is List && divisionRaw.isNotEmpty) {
                            divisionText = (divisionRaw as List).join(', ');
                          } else if (divisionRaw is String) {
                            divisionText = divisionRaw;
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE), // Soft blue
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Name: ${studentData['name'] ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Division: $divisionText',
                                      style: const TextStyle(fontSize: 16, color: Color(0xFF1E3A8A)),
                                    ),
                                    Text(
                                      'Roll Number: ${studentData['rollNumber'] ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 16, color: Color(0xFF1E3A8A)),
                                    ),
                                    Text(
                                      'Guardian Name: ${studentData['guardianName'] ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 16, color: Color(0xFF1E3A8A)),
                                    ),
                                    Text(
                                      'Phone Number: ${studentData['phone'] ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 16, color: Color(0xFF1E3A8A)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}