import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Mytest extends StatefulWidget {
  const Mytest({super.key, required String userRole});

  @override
  State<Mytest> createState() => _MytestState();
}

class _MytestState extends State<Mytest> {
  // Simulate user role: true for teacher, false for student
  bool _isTeacher = true; // Set to 'false' to simulate a student view

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers for the input fields
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectNameController = TextEditingController();
  final TextEditingController _portionController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _markController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _editingDocId; // To store the ID of the document being edited

  @override
  void dispose() {
    _subjectNameController.dispose();
    _portionController.dispose();
    _venueController.dispose();
    _markController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  // Function to show the form for adding/editing details
  void _showAddEditForm({Map<String, dynamic>? initialDetails, String? docId}) {
    // Reset controllers and selected dates/times
    _subjectNameController.clear();
    _portionController.clear();
    _venueController.clear();
    _markController.clear();
    _dateController.clear();
    _timeController.clear();
    _selectedDate = null;
    _selectedTime = null;
    _editingDocId = null;

    // If initialDetails are provided, it's an edit operation
    if (initialDetails != null && docId != null) {
      _subjectNameController.text = initialDetails['subjectName'] ?? '';
      _portionController.text = initialDetails['portion'] ?? '';
      _venueController.text = initialDetails['venue'] ?? '';
      _markController.text = initialDetails['mark'] ?? '';
      _dateController.text = initialDetails['date'] ?? '';
      _timeController.text = initialDetails['time'] ?? '';
      _editingDocId = docId;

      // Attempt to parse date and time to pre-select pickers
      try {
        final parts = _dateController.text.split('/');
        if (parts.length == 3) {
          _selectedDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      } catch (e) {
        debugPrint('Error parsing initial date: $e');
      }

      try {
        final format = TimeOfDayExtension.fromFormattedString(_timeController.text);
        if (format != null) {
          _selectedTime = format;
        }
      } catch (e) {
        debugPrint('Error parsing initial time: $e');
      }
    }

    // Show the Bottom Sheet with the form
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows content to scroll and avoids keyboard overlap
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 20,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView( // Added to prevent overflow when keyboard appears
            child: Column(
              mainAxisSize: MainAxisSize.min, // Make column wrap content
              children: <Widget>[
                Text(
                  _editingDocId == null ? 'Add Subject Details' : 'Edit Subject Details',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _subjectNameController,
                  decoration: const InputDecoration(
                    labelText: 'Subject Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the subject name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _portionController,
                  decoration: const InputDecoration(
                    labelText: 'Portion',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the portion covered';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _venueController,
                  decoration: const InputDecoration(
                    labelText: 'Venue',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the venue';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _markController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Mark',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the mark';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number for mark';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _timeController,
                  readOnly: true,
                  onTap: () => _selectTime(context),
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.access_time),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a time';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveDetails,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50), // Make button full width
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _editingDocId == null ? 'Save Details' : 'Update Details',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 20), // Add some space at the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  void _saveDetails() async {
    if (_formKey.currentState!.validate()) {
      final Map<String, String> detailsToSave = {
        'subjectName': _subjectNameController.text,
        'portion': _portionController.text,
        'venue': _venueController.text,
        'mark': _markController.text,
        'date': _dateController.text,
        'time': _timeController.text,
        'timestamp': DateTime.now().toIso8601String(), // Add a timestamp for ordering
      };

      try {
        if (_editingDocId == null) {
          // Add new document
          await _firestore.collection('subjectDetails').add(detailsToSave);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Details added to Firebase!')),
          );
        } else {
          // Update existing document
          await _firestore.collection('subjectDetails').doc(_editingDocId).update(detailsToSave);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Details updated in Firebase!')),
          );
        }
        Navigator.pop(context); // Close the bottom sheet
      } catch (e) {
        debugPrint('Error saving to Firebase: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save details: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Subject Details'),
        actions: [
          IconButton(
            icon: Icon(_isTeacher ? Icons.person : Icons.school),
            tooltip: _isTeacher ? 'Teacher View (Tap to switch to Student)' : 'Student View (Tap to switch to Teacher)',
            onPressed: () {
              setState(() {
                _isTeacher = !_isTeacher;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isTeacher ? 'Switched to Teacher View' : 'Switched to Student View'),
                ),
              );
            },
          ),
        ],
      ),
      body:
      
       StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('subjectDetails').orderBy('timestamp', descending: true).snapshots(), // Order by timestamp
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No subject details added yet. Click the + button to add some!'),
            );
          }

          final subjectDetails = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: subjectDetails.length,
            itemBuilder: (context, index) {
              final doc = subjectDetails[index];
              final detail = doc.data() as Map<String, dynamic>; // Cast to Map<String, dynamic>

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 2.0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subject: ${detail['subjectName'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Portion: ${detail['portion'] ?? 'N/A'}'),
                      Text('Venue: ${detail['venue'] ?? 'N/A'}'),
                      Text('Mark: ${detail['mark'] ?? 'N/A'}'),
                      Text('Date: ${detail['date'] ?? 'N/A'}'),
                      Text('Time: ${detail['time'] ?? 'N/A'}'),
                      if (_isTeacher) // Show edit/delete buttons only for teachers
                        ButtonBar(
                          alignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'Edit Details',
                              onPressed: () {
                                _showAddEditForm(
                                  initialDetails: Map<String, String>.from(detail),
                                  docId: doc.id,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Delete Details',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirm Deletion'),
                                    content: Text('Are you sure you want to delete details for ${detail['subjectName']}?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          await _firestore.collection('subjectDetails').doc(doc.id).delete();
                                          Navigator.pop(context); // Close the dialog
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Details deleted successfully!')),
                                          );
                                        },
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _isTeacher // Show FAB only for teachers
          ? FloatingActionButton(
              onPressed: () => _showAddEditForm(), // Call the form function directly
              tooltip: 'Add Subject Details',
              child: const Icon(Icons.add),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// Extension to help parse TimeOfDay from string (simple implementation)
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
          hour = 0; // 12 AM is 0 hour
        }
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      debugPrint('Error parsing time string: $e');
    }
    return null;
  }
}