import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyGalApp());
}

class MyGalApp extends StatelessWidget {
  const MyGalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gallery Manager',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: InputBorder.none,
          filled: true,
          fillColor: Colors.transparent,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          errorStyle: const TextStyle(color: Colors.white),
        ),
        cardTheme: CardTheme(
          color: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        dialogTheme: DialogTheme(
          backgroundColor: const Color(0xFF2D2D2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: const Color(0xFF03A9F4).withOpacity(0.3)),
          ),
        ),
      ),
      home: const Mygal(),
    );
  }
}

class Mygal extends StatefulWidget {
  const Mygal({super.key});

  @override
  State<Mygal> createState() => _MygalState();
}

class _MygalState extends State<Mygal> with TickerProviderStateMixin {
  final _galleryCollection = FirebaseFirestore.instance.collection('user_data').doc('user123').collection('gallery');
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final Color primaryBlue = const Color(0xFF03A9F4);
  final Color lightBlue = const Color(0xFF81D4FA);
  final Color darkBlue = const Color(0xFF0277BD);
  final Color blackColor = const Color(0xFF1A1A1A);
  final Color greyBlack = const Color(0xFF2D2D2D);
  int _currentFullScreenIndex = 0;

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

  void _showImageSourceOptions({String? initialName}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [greyBlack, blackColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryBlue, darkBlue]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white),
              ),
              title: Text(
                'Take Photo',
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, initialName: initialName);
              },
              tileColor: Colors.transparent,
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryBlue, darkBlue]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library, color: Colors.white),
              ),
              title: Text(
                'Choose from Gallery',
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, initialName: initialName);
              },
              tileColor: Colors.transparent,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, {String? initialName}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PhotoForm(
          imageFile: File(pickedFile.path),
          onSave: _savePhoto,
          initialName: initialName,
        ),
      );
    }
  }

  Future<void> _savePhoto({
    String? docId,
    File? imageFile,
    required String name,
    required String category,
    String? dob,
    String? anniversary,
    String? death,
    String? phoneNumber,
    String? otherDetail,
    String? description,
    String? existingImageUrl,
  }) async {
    try {
      if (dob != null && dob.isNotEmpty) {
        if (!_isValidDate(dob)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Invalid DOB format (dd/MM/yyyy)'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          return;
        }
      }
     
      if (anniversary != null && anniversary.isNotEmpty) {
        if (!_isValidDate(anniversary)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Invalid Anniversary format (dd/MM/yyyy)'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          return;
        }
      }
     
      if (death != null && death.isNotEmpty) {
        if (!_isValidDate(death)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Invalid Death format (dd/MM/yyyy)'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          return;
        }
      }

      if (category == 'Person' && dob != null && dob.isNotEmpty) {
        final duplicateQuery = await _galleryCollection
            .where('name', isEqualTo: name)
            .where('dob', isEqualTo: dob)
            .limit(1)
            .get();

        if (duplicateQuery.docs.isNotEmpty &&
            (docId == null || duplicateQuery.docs.first.id != docId)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Person with same name and DOB already exists'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          return;
        }
      }

      String? imageUrl = existingImageUrl;
      if (imageFile != null) {
        final fileName = const Uuid().v4();
        final ref = FirebaseStorage.instance.ref('gallery_images/$fileName.jpg');
        await ref.putFile(imageFile);
        imageUrl = await ref.getDownloadURL();
        if (docId != null && existingImageUrl != null) {
          await FirebaseStorage.instance.refFromURL(existingImageUrl).delete();
        }
      }
      final data = {
        'name': name,
        'category': category,
        'description': description,
        'image_url': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        if (category == 'Person') ...{
          'dob': dob,
          'wedding_anniversary': anniversary,
          'death': death,
          'phone_number': phoneNumber,
        } else
          'other_detail': otherDetail,
      };
      if (docId == null) {
        await _galleryCollection.add(data);
      } else {
        await _galleryCollection.doc(docId).update(data);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Saved successfully'),
          backgroundColor: primaryBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  bool _isValidDate(String date) {
    try {
      final parts = date.split('/');
      if (parts.length != 3) return false;
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      if (day < 1 || day > 31) return false;
      if (month < 1 || month > 12) return false;
      if (year < 1900 || year > DateTime.now().year) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  void _showFullScreenImage(String imageUrl, Map<String, dynamic> data, String docId, List<QueryDocumentSnapshot> docs, int index) {
    setState(() {
      _currentFullScreenIndex = index;
    });
   
    showDialog(
      context: context,
      builder: (context) => FullScreenImageDialog(
        imageUrl: imageUrl,
        data: data,
        docId: docId,
        allDocs: docs,
        initialIndex: index,
      ),
      barrierColor: Colors.black87,
    );
  }

  Future<void> _deleteImage(String docId, String? imageUrl) async {
    try {
      if (imageUrl != null) {
        await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      }
      await _galleryCollection.doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Deleted successfully'),
          backgroundColor: primaryBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [darkBlue, primaryBlue],
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
          'Gallery',
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
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [blackColor, greyBlack, const Color(0xFF3A3A3A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryBlue.withOpacity(0.1), Colors.white.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryBlue.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.2),
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
                          gradient: LinearGradient(colors: [primaryBlue, darkBlue]),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.photo_library, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Photo Gallery',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            StreamBuilder<QuerySnapshot>(
                              stream: _galleryCollection.snapshots(),
                              builder: (context, snapshot) {
                                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                                return Text(
                                  '$count images saved',
                                  style: TextStyle(color: Colors.white70, fontSize: 14),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _galleryCollection.orderBy('timestamp', descending: true).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading images',
                              style: TextStyle(color: Colors.red.withOpacity(0.8)),
                            ),
                          );
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFF03A9F4)));
                        }
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(30),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [primaryBlue.withOpacity(0.1), Colors.white.withOpacity(0.05)],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: primaryBlue.withOpacity(0.3)),
                                  ),
                                  child: Icon(
                                    Icons.photo_library,
                                    size: 60,
                                    color: primaryBlue,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'No images saved',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap the + button to add a new image',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            final docId = docs[index].id;
                           
                            return Slidable(
                              key: Key(docId),
                              endActionPane: ActionPane(
                                motion: const ScrollMotion(),
                                children: [
                                  SlidableAction(
                                    onPressed: (context) {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) => PhotoForm(
                                          docId: docId,
                                          data: data,
                                          onSave: _savePhoto,
                                        ),
                                      );
                                    },
                                    backgroundColor: primaryBlue,
                                    foregroundColor: Colors.white,
                                    icon: Icons.edit,
                                    label: 'Edit',
                                  ),
                                  SlidableAction(
                                    onPressed: (context) => _deleteImage(docId, data['image_url']),
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete,
                                    label: 'Delete',
                                  ),
                                ],
                              ),
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 200 + (index * 50)),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryBlue.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => _showFullScreenImage(data['image_url'], data, docId, docs, index),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              darkBlue,
                                              primaryBlue,
                                              lightBlue.withOpacity(0.8),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            data['image_url'] ?? '',
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: greyBlack,
                                              child: const Icon(
                                                Icons.error,
                                                color: Colors.white,
                                                size: 40,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.security_outlined,
                        color: lightBlue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Your images are stored securely',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [darkBlue, primaryBlue]),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showImageSourceOptions(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          tooltip: 'Add Photo',
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class PhotoForm extends StatefulWidget {
  final File? imageFile;
  final String? docId;
  final Map<String, dynamic>? data;
  final String? initialName;
  final Future<void> Function({
    String? docId,
    File? imageFile,
    required String name,
    required String category,
    String? dob,
    String? anniversary,
    String? death,
    String? phoneNumber,
    String? otherDetail,
    String? description,
    String? existingImageUrl,
  }) onSave;

  const PhotoForm({
    super.key,
    this.imageFile,
    this.docId,
    this.data,
    this.initialName,
    required this.onSave,
  });

  @override
  State<PhotoForm> createState() => _PhotoFormState();
}

class _PhotoFormState extends State<PhotoForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _dobController;
  late final TextEditingController _anniversaryController;
  late final TextEditingController _deathController;
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _otherDetailController;
  late String _category;
  File? _selectedImage;
  bool _isSaving = false;

  final Color primaryBlue = const Color(0xFF03A9F4);
  final Color lightBlue = const Color(0xFF81D4FA);
  final Color darkBlue = const Color(0xFF0277BD);
  final Color blackColor = const Color(0xFF1A1A1A);
  final Color greyBlack = const Color(0xFF2D2D2D);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? widget.data?['name']);
    _descriptionController = TextEditingController(text: widget.data?['description']);
    _dobController = TextEditingController(text: widget.data?['dob']);
    _anniversaryController = TextEditingController(text: widget.data?['wedding_anniversary']);
    _deathController = TextEditingController(text: widget.data?['death']);
    _phoneNumberController = TextEditingController(text: widget.data?['phone_number']);
    _otherDetailController = TextEditingController(text: widget.data?['other_detail']);
    _category = widget.data?['category'] ?? 'Person';
    _selectedImage = widget.imageFile;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _dobController.dispose();
    _anniversaryController.dispose();
    _deathController.dispose();
    _phoneNumberController.dispose();
    _otherDetailController.dispose();
    super.dispose();
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType inputType = TextInputType.text, bool readOnly = false, bool isOptional = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryBlue.withOpacity(0.1), Colors.white.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: primaryBlue.withOpacity(0.3)),
        ),
        child: TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
          keyboardType: inputType,
          readOnly: readOnly,
          maxLines: maxLines,
          validator: (value) {
            if (!isOptional && (value == null || value.isEmpty)) {
              return 'Please enter $label';
            }
            if (label == 'Phone Number' && value != null && value.isNotEmpty) {
              final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
              if (!phoneRegex.hasMatch(value)) {
                return 'Enter a valid phone number';
              }
            }
            return null;
          },
          onTap: readOnly
              ? () async {
                  if (label.contains('DOB') || label.contains('Anniversary') || label.contains('Death')) {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      controller.text = '${date.day}/${date.month}/${date.year}';
                    }
                  }
                }
              : null,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryBlue.withOpacity(0.1), Colors.white.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: primaryBlue.withOpacity(0.3)),
        ),
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
          value: value,
          style: const TextStyle(color: Colors.white),
          dropdownColor: greyBlack,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (value) => value == null ? 'Please select a $label' : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth / 3; // Match grid cell size

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [greyBlack, blackColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.docId == null ? 'Add Photo' : 'Edit Photo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: Offset(1, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_selectedImage != null)
                  Container(
                    width: imageSize,
                    height: imageSize,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryBlue.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: greyBlack,
                          child: const Icon(Icons.error, color: Colors.white, size: 40),
                        ),
                      ),
                    ),
                  ),
                if (widget.data?['image_url'] != null && _selectedImage == null)
                  Container(
                    width: imageSize,
                    height: imageSize,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryBlue.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.data!['image_url'],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              color: primaryBlue,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: greyBlack,
                          child: const Icon(Icons.error, color: Colors.white, size: 40),
                        ),
                      ),
                    ),
                  ),
                _buildTextField(
                  'Name',
                  _nameController,
                  readOnly: widget.initialName != null,
                ),
                _buildDropdownField(
                  label: 'Category',
                  value: _category,
                  items: ['Person', 'Other'],
                  onChanged: (value) => setState(() => _category = value!),
                ),
                if (_category == 'Person') ...[
                  _buildTextField('DOB', _dobController, readOnly: true, isOptional: true),
                  _buildTextField('Wedding Anniversary', _anniversaryController, readOnly: true, isOptional: true),
                  _buildTextField('Death', _deathController, readOnly: true, isOptional: true),
                  _buildTextField('Phone Number', _phoneNumberController, inputType: TextInputType.phone, isOptional: true),
                ] else
                  _buildTextField('Detail', _otherDetailController, isOptional: true),
                _buildTextField('Description', _descriptionController, maxLines: 3, isOptional: true),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [darkBlue, primaryBlue]),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: _isSaving ? null : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => _isSaving = true);
                              await widget.onSave(
                                docId: widget.docId,
                                imageFile: _selectedImage,
                                name: _nameController.text.trim(),
                                category: _category,
                                dob: _dobController.text,
                                anniversary: _anniversaryController.text,
                                death: _deathController.text,
                                phoneNumber: _phoneNumberController.text.trim(),
                                otherDetail: _otherDetailController.text.trim(),
                                description: _descriptionController.text.trim(),
                                existingImageUrl: widget.data?['image_url'],
                              );
                              setState(() => _isSaving = false);
                              if (mounted) Navigator.pop(context);
                            }
                          },
                          child: _isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  widget.docId == null ? 'Save' : 'Update',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
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

class FullScreenImageDialog extends StatefulWidget {
  final String imageUrl;
  final Map<String, dynamic> data;
  final String docId;
  final List<QueryDocumentSnapshot> allDocs;
  final int initialIndex;

  const FullScreenImageDialog({
    super.key,
    required this.imageUrl,
    required this.data,
    required this.docId,
    required this.allDocs,
    required this.initialIndex,
  });

  @override
  State<FullScreenImageDialog> createState() => _FullScreenImageDialogState();
}

class _FullScreenImageDialogState extends State<FullScreenImageDialog> {
  late PageController _pageController;
  int _currentIndex = 0;

  final Color primaryBlue = const Color(0xFF03A9F4);
  final Color darkBlue = const Color(0xFF0277BD);
  final Color greyBlack = const Color(0xFF2D2D2D);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.9; // Uniform size for full-screen images

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(0),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              color: Colors.black87,
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: widget.allDocs.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  final data = widget.allDocs[index].data() as Map<String, dynamic>;
                  return Center(
                    child: Container(
                      width: imageSize,
                      height: imageSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryBlue.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: InteractiveViewer(
                          minScale: 1.0,
                          maxScale: 4.0,
                          child: Image.network(
                            data['image_url'],
                            fit: BoxFit.cover, // Match grid's fit
                            width: imageSize,
                            height: imageSize,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  color: primaryBlue,
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          (loadingProgress.expectedTotalBytes ?? 1)
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: greyBlack,
                              child: const Icon(Icons.error, color: Colors.white, size: 40),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0277BD), Color(0xFF03A9F4)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF03A9F4).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white),
                onPressed: () {
                  final currentData = widget.allDocs[_currentIndex].data() as Map<String, dynamic>;
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PhotoDetailsPage(
                        docId: widget.allDocs[_currentIndex].id,
                        data: currentData,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.allDocs.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? const Color(0xFF03A9F4)
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PhotoDetailsPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  final Color primaryBlue = const Color(0xFF03A9F4);
  final Color lightBlue = const Color(0xFF81D4FA);
  final Color darkBlue = const Color(0xFF0277BD);
  final Color blackColor = const Color(0xFF1A1A1A);
  final Color greyBlack = const Color(0xFF2D2D2D);
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _anniversaryController = TextEditingController();
  final TextEditingController _deathController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _otherDetailController = TextEditingController();
  String _category = '';
  bool _isEditing = false;

  PhotoDetailsPage({super.key, required this.docId, required this.data}) {
    _nameController.text = data['name'] ?? '';
    _descriptionController.text = data['description'] ?? '';
    _dobController.text = data['dob'] ?? '';
    _anniversaryController.text = data['wedding_anniversary'] ?? '';
    _deathController.text = data['death'] ?? '';
    _phoneNumberController.text = data['phone_number'] ?? '';
    _otherDetailController.text = data['other_detail'] ?? '';
    _category = data['category'] ?? 'Person';
  }

  @override
  State<PhotoDetailsPage> createState() => _PhotoDetailsPageState();
}

class _PhotoDetailsPageState extends State<PhotoDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  final _galleryCollection = FirebaseFirestore.instance.collection('user_data').doc('user123').collection('gallery');

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        final data = {
          'name': widget._nameController.text.trim(),
          'category': widget._category,
          'description': widget._descriptionController.text.trim(),
          'image_url': widget.data['image_url'],
          'timestamp': FieldValue.serverTimestamp(),
          if (widget._category == 'Person') ...{
            'dob': widget._dobController.text,
            'wedding_anniversary': widget._anniversaryController.text,
            'death': widget._deathController.text,
            'phone_number': widget._phoneNumberController.text.trim(),
          } else
            'other_detail': widget._otherDetailController.text.trim(),
        };
       
        await _galleryCollection.doc(widget.docId).update(data);
       
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Updated successfully'),
            backgroundColor: widget.primaryBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
       
        setState(() {
          widget._isEditing = false;
          widget.data.addAll(data);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildEditableTextField(String label, TextEditingController controller,
      {bool readOnly = false, bool isOptional = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.primaryBlue.withOpacity(0.1), Colors.white.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: widget.primaryBlue.withOpacity(0.3)),
        ),
        child: TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
            enabled: widget._isEditing,
          ),
          readOnly: !widget._isEditing || readOnly,
          maxLines: maxLines,
          validator: (value) {
            if (!isOptional && (value == null || value.isEmpty)) {
              return 'Please enter $label';
            }
            if (label == 'Phone Number' && value != null && value.isNotEmpty) {
              final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
              if (!phoneRegex.hasMatch(value)) {
                return 'Enter a valid phone number';
              }
            }
            return null;
          },
          onTap: readOnly && widget._isEditing
              ? () async {
                  if (label.contains('DOB') || label.contains('Anniversary') || label.contains('Death')) {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      controller.text = '${date.day}/${date.month}/${date.year}';
                    }
                  }
                }
              : null,
        ),
      ),
    );
  }

  Widget _buildEditableDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.primaryBlue.withOpacity(0.1), Colors.white.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: widget.primaryBlue.withOpacity(0.3)),
        ),
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
          value: value,
          style: const TextStyle(color: Colors.white),
          dropdownColor: widget.greyBlack,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: widget._isEditing ? onChanged : null,
          validator: (value) => value == null ? 'Please select a $label' : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.9; // Uniform size for details page image

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.darkBlue, widget.primaryBlue],
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
        title: Text(
          widget.data['name'] ?? 'Details',
          style: const TextStyle(
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
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          if (!widget._isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => setState(() => widget._isEditing = true),
            )
          else
            IconButton(
              icon: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.save, color: Colors.white),
              onPressed: _saveChanges,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.blackColor, widget.greyBlack, const Color(0xFF3A3A3A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.primaryBlue.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: widget.primaryBlue.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.data['image_url'] ?? '',
                      fit: BoxFit.cover, // Match grid's fit
                      width: imageSize,
                      height: imageSize,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: widget.primaryBlue,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: widget.greyBlack,
                        child: const Icon(Icons.error, color: Colors.white, size: 40),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.darkBlue, widget.primaryBlue, widget.lightBlue.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: widget.primaryBlue.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEditableTextField('Name', widget._nameController),
                      _buildEditableDropdownField(
                        label: 'Category',
                        value: widget._category,
                        items: ['Person', 'Other'],
                        onChanged: (value) => setState(() => widget._category = value!),
                      ),
                      if (widget._category == 'Person') ...[
                        _buildEditableTextField('DOB', widget._dobController, readOnly: true, isOptional: true),
                        _buildEditableTextField('Wedding Anniversary', widget._anniversaryController, readOnly: true, isOptional: true),
                        _buildEditableTextField('Death', widget._deathController, readOnly: true, isOptional: true),
                        _buildEditableTextField('Phone Number', widget._phoneNumberController, isOptional: true),
                      ] else
                        _buildEditableTextField('Detail', widget._otherDetailController, isOptional: true),
                      _buildEditableTextField('Description', widget._descriptionController, maxLines: 3, isOptional: true),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Colors.red, Colors.redAccent]),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: widget.greyBlack,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: widget.primaryBlue.withOpacity(0.3)),
                            ),
                            title: const Text(
                              'Delete Photo',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            content: Text(
                              'Are you sure you want to delete this photo?',
                              style: TextStyle(color: Colors.white.withOpacity(0.8)),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Colors.red, Colors.redAccent]),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          try {
                            await FirebaseStorage.instance.refFromURL(widget.data['image_url']).delete();
                            await FirebaseFirestore.instance
                                .collection('user_data')
                                .doc('user123')
                                .collection('gallery')
                                .doc(widget.docId)
                                .delete();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Deleted successfully'),
                                backgroundColor: widget.primaryBlue,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to delete: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'Delete Photo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}