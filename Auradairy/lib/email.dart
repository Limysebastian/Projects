import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // Enable offline persistence
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
    runApp(const MyApii());
  } catch (e, stackTrace) {
    print('Firebase initialization error: $e\nStackTrace: $stackTrace');
    // Optionally, show an error UI
  }
}

class MyApii extends StatelessWidget {
  const MyApii({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.lightBlue),
      home: const Myemil(),
    );
  }
}

class Myemil extends StatefulWidget {
  const Myemil({super.key});

  @override
  State<Myemil> createState() => _MyemilState();
}

class _MyemilState extends State<Myemil> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  String? _editingDocId;
  final Color primaryBlue = const Color(0xFF03A9F4);
  final Color darkBlue = const Color(0xFF0277BD);
  final Color lightBlue = const Color(0xFF81D4FA);
  final Color blackColor = const Color(0xFF1A1A1A);
  final Color greyBlack = const Color(0xFF2D2D2D);

  final _emailsCollection = FirebaseFirestore.instance.collection('user_data').doc('user123').collection('emails');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveEmailPassword() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    try {
      // Ensure parent document exists
      await FirebaseFirestore.instance.collection('user_data').doc('user123').set({'created': true}, SetOptions(merge: true));
      
      final query = await _emailsCollection.where('email', isEqualTo: email).get();
      if (_editingDocId == null) {
        if (query.docs.isNotEmpty) throw Exception('Email already exists!');
        await _emailsCollection.add({
          'email': email,
          'password': password,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        if (query.docs.isNotEmpty && query.docs.first.id != _editingDocId) {
          throw Exception('Email already exists!');
        }
        await _emailsCollection.doc(_editingDocId).update({
          'email': email,
          'password': password,
          'timestamp': FieldValue.serverTimestamp(),
        });
        setState(() => _editingDocId = null);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved successfully!'), backgroundColor: Colors.green),
      );
      _emailController.clear();
      _passwordController.clear();
    } catch (e, stackTrace) {
      print('Error saving to Firestore: $e\nStackTrace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _editEmailPassword(String docId, String email, String password) async {
    setState(() {
      _editingDocId = docId;
      _emailController.text = email;
      _passwordController.text = password;
    });
  }

  Future<void> _deleteEmailPassword(String docId) async {
    if (await _showConfirmDialog('Delete this email?')) {
      try {
        await _emailsCollection.doc(docId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deleted successfully!'), backgroundColor: Colors.green),
        );
      } catch (e, stackTrace) {
        print('Error deleting from Firestore: $e\nStackTrace: $stackTrace');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<bool> _showConfirmDialog(String message) async {
    return (await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm'),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('OK')),
            ],
          ),
        )) ??
        false;
  }

  void _launchEmailWithIntent() {
    final intent = AndroidIntent(
      action: 'android.intent.action.SENDTO',
      data: Uri.encodeFull('mailto:@gmail.com'),
      arguments: {'android.intent.extra.SUBJECT': 'Feedback', 'android.intent.extra.TEXT': 'Hello...'},
    );
    intent.launch().catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No email app found.')));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [darkBlue, primaryBlue], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
        title: const Text('Email Manager', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [blackColor, greyBlack, const Color(0xFF3A3A3A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCard([
                  TextFormField(
                    controller: _emailController,
                    decoration: _inputDecoration('Email', Icons.email, 'user@example.com'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter an email'
                        : EmailValidator.validate(value)
                            ? null
                            : 'Invalid email',
                  ),
                  const SizedBox(height: 12),
                  StatefulBuilder(
                    builder: (context, setState) => TextFormField(
                      controller: _passwordController,
                      decoration: _inputDecoration(
                        'Password',
                        Icons.lock,
                        null,
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                      ),
                      obscureText: !_isPasswordVisible,
                      validator: (value) => value == null || value.isEmpty ? 'Enter a password' : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildButton('Save', Icons.save, _saveEmailPassword, _editingDocId == null ? primaryBlue : Colors.blue),
                ]),
                const SizedBox(height: 20),
                StreamBuilder<QuerySnapshot>(
                  stream: _emailsCollection.orderBy('timestamp', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      print('StreamBuilder error: ${snapshot.error}');
                      return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) return const Text('No emails saved.', style: TextStyle(color: Colors.white70));
                    return _buildCard([
                      const Text('Saved Emails', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final docId = docs[index].id;
                          final email = data['email'] ?? '';
                          final password = data['password'] ?? '';
                          bool isSavedPasswordVisible = false;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: _launchEmailWithIntent,
                                  child: Text(
                                    email,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent),
                                  ),
                                ),
                                StatefulBuilder(
                                  builder: (context, setState) => Row(
                                    children: [
                                      const Icon(Icons.lock, color: Colors.white70, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Password: ${isSavedPasswordVisible ? password : '•' * password.length}',
                                          style: const TextStyle(fontSize: 14, color: Colors.white70),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(isSavedPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                            color: Colors.white70, size: 20),
                                        onPressed: () => setState(() => isSavedPasswordVisible = !isSavedPasswordVisible),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildSmallButton('Edit', Icons.edit, () => _editEmailPassword(docId, email, password), Colors.blue),
                                    _buildSmallButton('Delete', Icons.delete, () => _deleteEmailPassword(docId), Colors.red),
                                    _buildSmallButton(
                                      'Detail',
                                      Icons.info,
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DetailPage(
                                            userDoc: FirebaseFirestore.instance.collection('user_data').doc('user123'),
                                            emailDocId: docId,
                                          ),
                                        ),
                                      ),
                                      Colors.green,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ]);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, String? hint, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: lightBlue),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      labelStyle: const TextStyle(color: Colors.white70),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue.withOpacity(0.1), Colors.white.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryBlue.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: primaryBlue.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildButton(String label, IconData icon, VoidCallback onPressed, Color color) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ));
  }

  Widget _buildSmallButton(String label, IconData icon, VoidCallback onPressed, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: Colors.white),
        label: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
      ));
  }
}

class DetailPage extends StatefulWidget {
  final DocumentReference userDoc;
  final String emailDocId;

  const DetailPage({super.key, required this.userDoc, required this.emailDocId});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final List<Map<String, dynamic>> _twoStepEmails = [{'controller': TextEditingController(), 'docId': null}];
  final List<Map<String, dynamic>> _twoStepMobiles = [{'controller': TextEditingController(), 'docId': null}];
  final List<Map<String, dynamic>> _emailUsages = [
    {'nameController': TextEditingController(), 'passwordController': TextEditingController(), 'docId': null}
  ];
  final Color primaryBlue = const Color(0xFF03A9F4);
  final Color darkBlue = const Color(0xFF0277BD);
  final Color lightBlue = const Color(0xFF81D4FA);
  final Color blackColor = const Color(0xFF1A1A1A);
  final Color greyBlack = const Color(0xFF2D2D2D);

  @override
  void dispose() {
    for (var item in _twoStepEmails) {
      item['controller'].dispose();
    }
    for (var item in _twoStepMobiles) {
      item['controller'].dispose();
    }
    for (var item in _emailUsages) {
      item['nameController'].dispose();
      item['passwordController'].dispose();
    }
    super.dispose();
  }

  Future<void> _saveAllDetails() async {
    bool hasError = false;
    try {
      // Ensure parent document exists
      await widget.userDoc.set({'created': true}, SetOptions(merge: true));

      for (var item in _twoStepEmails) {
        final value = item['controller'].text.trim();
        if (value.isNotEmpty) {
          if (!EmailValidator.validate(value)) {
            hasError = true;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid email format'), backgroundColor: Colors.red),
            );
            continue;
          }
          final collection = widget.userDoc.collection('two_step_emails');
          if (item['docId'] != null) {
            await collection.doc(item['docId']).update({'value': value, 'timestamp': FieldValue.serverTimestamp()});
          } else {
            final query = await collection.where('value', isEqualTo: value).where('email_doc_id', isEqualTo: widget.emailDocId).get();
            if (query.docs.isEmpty) {
              await collection.add({'value': value, 'email_doc_id': widget.emailDocId, 'timestamp': FieldValue.serverTimestamp()});
            }
          }
        }
      }

      for (var item in _twoStepMobiles) {
        final value = item['controller'].text.trim();
        if (value.isNotEmpty) {
          if (!RegExp(r'^\+?[1-9]\d{9,14}$').hasMatch(value)) {
            hasError = true;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid phone format'), backgroundColor: Colors.red),
            );
            continue;
          }
          final collection = widget.userDoc.collection('two_step_mobiles');
          if (item['docId'] != null) {
            await collection.doc(item['docId']).update({'value': value, 'timestamp': FieldValue.serverTimestamp()});
          } else {
            final query = await collection.where('value', isEqualTo: value).where('email_doc_id', isEqualTo: widget.emailDocId).get();
            if (query.docs.isEmpty) {
              await collection.add({'value': value, 'email_doc_id': widget.emailDocId, 'timestamp': FieldValue.serverTimestamp()});
            }
          }
        }
      }

      for (var item in _emailUsages) {
        final name = item['nameController'].text.trim();
        final password = item['passwordController'].text.trim();
        if (name.isNotEmpty && password.isNotEmpty) {
          final collection = widget.userDoc.collection('email_usages');
          if (item['docId'] != null) {
            await collection.doc(item['docId']).update({
              'name': name,
              'password': password,
              'timestamp': FieldValue.serverTimestamp(),
            });
          } else {
            final query = await collection.where('name', isEqualTo: name).where('email_doc_id', isEqualTo: widget.emailDocId).get();
            if (query.docs.isEmpty) {
              await collection.add({
                'name': name,
                'password': password,
                'email_doc_id': widget.emailDocId,
                'timestamp': FieldValue.serverTimestamp(),
              });
            }
          }
        } else if (name.isNotEmpty || password.isNotEmpty) {
          hasError = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Both name and password are required'), backgroundColor: Colors.red),
          );
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(hasError ? 'Some entries are invalid!' : 'Saved successfully!'), backgroundColor: hasError ? Colors.red : Colors.green),
      );
      if (!hasError) {
        setState(() {
          _twoStepEmails.clear();
          _twoStepEmails.add({'controller': TextEditingController(), 'docId': null});
          _twoStepMobiles.clear();
          _twoStepMobiles.add({'controller': TextEditingController(), 'docId': null});
          _emailUsages.clear();
          _emailUsages.add({'nameController': TextEditingController(), 'passwordController': TextEditingController(), 'docId': null});
        });
        // Navigate back to the Myemil page (Saved Emails)
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      print('Error saving details: $e\nStackTrace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteDetail(String collectionName, String docId) async {
    if (await _showConfirmDialog('Delete this item?')) {
      try {
        await widget.userDoc.collection(collectionName).doc(docId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deleted successfully!'), backgroundColor: Colors.green),
        );
      } catch (e, stackTrace) {
        print('Error deleting from Firestore: $e\nStackTrace: $stackTrace');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<bool> _showConfirmDialog(String message) async {
    return (await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm'),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('OK')),
            ],
          ),
        )) ??
        false;
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue.withOpacity(0.1), Colors.white.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryBlue.withOpacity(0.3)),
          ),
          child: content,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildButton(String label, IconData icon, VoidCallback onPressed, Color color) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [darkBlue, primaryBlue], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
        title: const Text('Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [blackColor, greyBlack, const Color(0xFF3A3A3A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                'Two-Step Verification Emails',
                Column(
                  children: [
                    ..._twoStepEmails.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TextFormField(
                            controller: item['controller'],
                            decoration: _inputDecoration('Email', Icons.email, 'backup@example.com'),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        )),
                    _buildButton(
                      'Add Email',
                      Icons.add,
                      () => setState(() => _twoStepEmails.add({'controller': TextEditingController(), 'docId': null})),
                      Colors.green,
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: widget.userDoc.collection('two_step_emails').where('email_doc_id', isEqualTo: widget.emailDocId).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          print('StreamBuilder error (two_step_emails): ${snapshot.error}');
                          return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white));
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                        return Column(
                          children: (snapshot.data?.docs ?? []).map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return ListTile(
                              leading: const Icon(Icons.email, color: Colors.white70),
                              title: Text(data['value'], style: const TextStyle(color: Colors.white)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => setState(() {
                                      _twoStepEmails[0]['controller'].text = data['value'];
                                      _twoStepEmails[0]['docId'] = doc.id;
                                    }),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteDetail('two_step_emails', doc.id),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              _buildSection(
                'Two-Step Verification Mobiles',
                Column(
                  children: [
                    ..._twoStepMobiles.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TextFormField(
                            controller: item['controller'],
                            maxLength: 10,
                            decoration: _inputDecoration('Mobile', Icons.phone, '+1234567890'),
                            keyboardType: TextInputType.phone,
                          ),
                        )),
                    _buildButton(
                      'Add Mobile',
                      Icons.add,
                      () => setState(() => _twoStepMobiles.add({'controller': TextEditingController(), 'docId': null})),
                      Colors.green,
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: widget.userDoc.collection('two_step_mobiles').where('email_doc_id', isEqualTo: widget.emailDocId).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          print('StreamBuilder error (two_step_mobiles): ${snapshot.error}');
                          return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white));
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                        return Column(
                          children: (snapshot.data?.docs ?? []).map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return ListTile(
                              leading: const Icon(Icons.phone, color: Colors.white70),
                              title: Text(data['value'], style: const TextStyle(color: Colors.white)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => setState(() {
                                      _twoStepMobiles[0]['controller'].text = data['value'];
                                      _twoStepMobiles[0]['docId'] = doc.id;
                                    }),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteDetail('two_step_mobiles', doc.id),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              _buildSection(
                'Email Usages',
                Column(
                  children: [
                    ..._emailUsages.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: item['nameController'],
                                decoration: _inputDecoration('Usage Name', Icons.label, 'Facebook'),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: item['passwordController'],
                                decoration: _inputDecoration('Password', Icons.lock, 'securepassword123'),
                                obscureText: true,
                              ),
                            ],
                          ),
                        )),
                    _buildButton(
                      'Add Usage',
                      Icons.add,
                      () => setState(() => _emailUsages.add({
                            'nameController': TextEditingController(),
                            'passwordController': TextEditingController(),
                            'docId': null
                          })),
                      Colors.green,
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: widget.userDoc.collection('email_usages').where('email_doc_id', isEqualTo: widget.emailDocId).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          print('StreamBuilder error (email_usages): ${snapshot.error}');
                          return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white));
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                        return Column(
                          children: (snapshot.data?.docs ?? []).map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return ListTile(
                              leading: const Icon(Icons.vpn_key, color: Colors.white70),
                              title: Text(data['name'], style: const TextStyle(color: Colors.white)),
                              subtitle: Text('Password: ${'•' * (data['password']?.length ?? 0)}', style: const TextStyle(color: Colors.white70)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => setState(() {
                                      _emailUsages[0]['nameController'].text = data['name'];
                                      _emailUsages[0]['passwordController'].text = data['password'];
                                      _emailUsages[0]['docId'] = doc.id;
                                    }),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteDetail('email_usages', doc.id),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              _buildButton('Save All', Icons.save, _saveAllDetails, primaryBlue),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, String? hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: lightBlue),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      labelStyle: const TextStyle(color: Colors.white70),
    );
  }
}