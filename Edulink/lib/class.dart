import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

class Myclass extends StatefulWidget {
  const Myclass({super.key});

  @override
  State<Myclass> createState() => _MyclassState();
}

class _MyclassState extends State<Myclass> {
  int _selectedIndex = 0;
  List<Map<String, String>> _selectedFiles = []; // Store list of PDFs (name, path)
  List<Map<String, String>> _announcements = []; // Store list of announcements (id, details, date)
  String? _userRole; // Store user role (teacher or student)

  @override
  void initState() {
    super.initState();
    _loadUserRole(); // Load user role
    _loadSavedFiles(); // Load previously saved files
    _loadAnnouncementsFromFirestore(); // Load announcements from Firestore
  }

  // Load user role from Firestore
  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (mounted) {
          setState(() {
            _userRole = userDoc.data()?['role'] as String? ?? 'student';
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading user role: $e'),
              backgroundColor: const Color(0xFF1E3A8A),
            ),
          );
        }
      }
    }
  }

  // Load saved files from SharedPreferences
  Future<void> _loadSavedFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final String? filesJson = prefs.getString('selectedFiles');
    if (filesJson != null) {
      final List<dynamic> filesList = jsonDecode(filesJson);
      if (mounted) {
        setState(() {
          _selectedFiles = filesList.map((item) => Map<String, String>.from(item as Map)).toList();
        });
      }
    }
  }

  // Load announcements from Firestore
  Future<void> _loadAnnouncementsFromFirestore() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('announcements').get();
      if (mounted) {
        setState(() {
          _announcements = querySnapshot.docs.map((doc) {
            return {
              'id': doc.id,
              'details': doc['details'] as String,
              'date': doc['date'] as String,
            };
          }).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading announcements: $e'),
            backgroundColor: const Color(0xFF1E3A8A),
          ),
        );
      }
    }
  }

  // Save files to SharedPreferences
  Future<void> _saveFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final String filesJson = jsonEncode(_selectedFiles);
    await prefs.setString('selectedFiles', filesJson);
  }

  // Copy file to app's local storage
  Future<String?> _copyFileToLocalStorage(PlatformFile file) async {
    if (kIsWeb || file.path == null) return null;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final localPath = '${appDir.path}/${file.name}';
      final localFile = File(localPath);
      await File(file.path!).copy(localPath);
      return localPath;
    } catch (e) {
      return null;
    }
  }

  // List of pages for the bottom navigation
  final List<Widget> _pages = [
    // Upload page
    Builder(builder: (context) {
      final state = context.findAncestorStateOfType<_MyclassState>();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: state!._selectedFiles.isEmpty
              ? const Text(
                  'No PDFs available',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: state._selectedFiles.length,
                  itemBuilder: (context, index) {
                    final file = state._selectedFiles[index];
                    return Card(
                      elevation: 2,
                      shadowColor: Colors.black.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          file['name'] ?? 'Unknown PDF',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        trailing: (file['path'] != null && (Platform.isAndroid || Platform.isIOS))
                            ? IconButton(
                                icon: const Icon(
                                  Icons.visibility,
                                  color: Color(0xFF1E3A8A),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PDFViewerPage(filePath: file['path']!),
                                    ),
                                  );
                                },
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ),
      );
    }),
    // Announcement page
    Builder(builder: (context) {
      final state = context.findAncestorStateOfType<_MyclassState>();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: state!._announcements.isEmpty
              ? const Text(
                  'No announcements',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: state._announcements.length,
                  itemBuilder: (context, index) {
                    final announcement = state._announcements[index];
                    return Card(
                      elevation: 2,
                      shadowColor: Colors.black.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          announcement['details'] ?? 'No details',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        subtitle: Text(
                          announcement['date'] ?? 'No date',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        trailing: state._userRole == 'teacher'
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                    onPressed: () {
                                      state._editAnnouncement(context, announcement);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      state._deleteAnnouncement(announcement['id']!);
                                    },
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ),
      );
    }),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Function to handle adding or editing an announcement
  Future<void> _showAnnouncementDialog(BuildContext context, {Map<String, String>? announcement}) async {
    if (!mounted) return;
    final TextEditingController detailsController = TextEditingController(
        text: announcement != null ? announcement['details'] : '');
    DateTime? selectedDate = announcement != null
        ? DateTime.tryParse(announcement['date']!) ?? DateTime.now()
        : DateTime.now();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        title: Text(
          announcement != null ? 'Edit Announcement' : 'Add Announcement',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: TextFormField(
                    controller: detailsController,
                    decoration: const InputDecoration(
                      labelText: 'Details',
                      labelStyle: TextStyle(color: Color(0xFF1E3A8A)),
                      hintText: 'Enter announcement details',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter details';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        labelStyle: TextStyle(color: Color(0xFF1E3A8A)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      child: Text(
                        DateFormat('yyyy-MM-dd').format(selectedDate!),
                        style: const TextStyle(fontSize: 16, color: Color(0xFF1E3A8A)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final announcementData = {
                  'details': detailsController.text,
                  'date': DateFormat('yyyy-MM-dd').format(selectedDate!),
                };
                try {
                  if (announcement != null) {
                    await FirebaseFirestore.instance
                        .collection('announcements')
                        .doc(announcement['id'])
                        .update(announcementData);
                  } else {
                    await FirebaseFirestore.instance.collection('announcements').add(announcementData);
                  }
                  await _loadAnnouncementsFromFirestore();
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(announcement != null ? 'Announcement updated' : 'Announcement saved'),
                      backgroundColor: const Color(0xFF1E3A8A),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error saving announcement: $e'),
                      backgroundColor: const Color(0xFF1E3A8A),
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Color(0xFF1E3A8A)),
            ),
          ),
        ],
      ),
    );
  }

  // Function to handle editing an announcement
  void _editAnnouncement(BuildContext context, Map<String, String> announcement) {
    _showAnnouncementDialog(context, announcement: announcement);
  }

  // Function to handle deleting an announcement
  Future<void> _deleteAnnouncement(String id) async {
    try {
      await FirebaseFirestore.instance.collection('announcements').doc(id).delete();
      await _loadAnnouncementsFromFirestore();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Announcement deleted'),
          backgroundColor: Color(0xFF1E3A8A),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting announcement: $e'),
          backgroundColor: const Color(0xFF1E3A8A),
        ),
      );
    }
  }

  // Function to handle FloatingActionButton press
  Future<void> _onFabPressed(BuildContext context) async {
    if (_selectedIndex == 0) {
      // Upload page action - Pick a PDF file
      try {
        await FilePicker.platform.clearTemporaryFiles();
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          allowMultiple: true,
        );

        if (!mounted) return;

        if (result != null && result.files.isNotEmpty) {
          List<Map<String, String>> newFiles = [];
          for (var file in result.files) {
            if (file.name != null && file.path != null && !kIsWeb) {
              final localPath = await _copyFileToLocalStorage(file);
              if (localPath != null) {
                newFiles.add({
                  'name': file.name,
                  'path': localPath,
                });
              }
            }
          }

          if (newFiles.isNotEmpty) {
            setState(() {
              _selectedFiles.addAll(newFiles);
            });
            await _saveFiles();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Saved ${newFiles.length} PDF(s) locally'),
                backgroundColor: const Color(0xFF1E3A8A),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No valid files saved'),
                backgroundColor: Color(0xFF1E3A8A),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No file selected'),
              backgroundColor: Color(0xFF1E3A8A),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: const Color(0xFF1E3A8A),
          ),
        );
      }
    } else {
      // Announcement page action - Show dialog to add announcement
      await _showAnnouncementDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Class',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.2),
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
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E3A8A)))
              : _pages[_selectedIndex],
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.upload),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.announcement),
            label: 'Announcement',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1E3A8A),
        unselectedItemColor: const Color(0xFF6B7280),
        backgroundColor: Colors.white,
        elevation: 2,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _userRole == 'teacher'
          ? FloatingActionButton(
              onPressed: () => _onFabPressed(context),
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tooltip: _selectedIndex == 0 ? 'Upload File' : 'Add Announcement',
              child: Icon(_selectedIndex == 0 ? Icons.upload_file : Icons.add),
            )
          : null,
    );
  }
}

// Widget to display the PDF
class PDFViewerPage extends StatelessWidget {
  final String filePath;

  const PDFViewerPage({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text(
          'View PDF',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.2),
      ),
      body: PDFView(
        filePath: filePath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading PDF: $error'),
              backgroundColor: const Color(0xFF1E3A8A),
            ),
          );
        },
      ),
    );
  }
}