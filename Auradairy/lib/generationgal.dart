import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class FamilyMemberPage extends StatefulWidget {
  final String memberId;
  final String title;

  const FamilyMemberPage({super.key, required this.memberId, required this.title});

  @override
  State createState() => _FamilyMemberPageState();
}

class _FamilyMemberPageState extends State<FamilyMemberPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> children = [{}];
  String? fatherImage;
  String? motherImage;
  List<String?> childImages = [null];
  Map<String, dynamic> fatherData = {};
  Map<String, dynamic> motherData = {};

  late Future<void> _dataFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final Color primaryBlue = const Color(0xFF03A9F4);
  final Color lightBlue = const Color(0xFF81D4FA);
  final Color darkBlue = const Color(0xFF0277BD);
  final Color blackColor = const Color(0xFF1A1A1A);
  final Color greyBlack = const Color(0xFF2D2D2D);

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
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

  Future<void> _loadData() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('family')
        .doc(widget.memberId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        children = List<Map<String, dynamic>>.from(
          (data['children'] ?? [{}]).map((c) => Map<String, dynamic>.from(c)),
        );
        childImages = List<String?>.from(data['childImages'] ?? [null]);
        fatherImage = data['fatherImage'];
        motherImage = data['motherImage'];
        fatherData = Map<String, dynamic>.from(data['fatherData'] ?? {});
        motherData = Map<String, dynamic>.from(data['motherData'] ?? {});
      });
    }
    _sortChildrenAndImages();
  }

  Future<String?> _uploadImage(File file, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref(path);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return null;
    }
  }

  void _pickImage(int? index, bool isChild) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      String path = 'users/${FirebaseAuth.instance.currentUser!.uid}/${widget.memberId}/${isChild ? (index != null ? 'child_${index}' : 'mother') : 'father'}.jpg';
      String? downloadUrl = await _uploadImage(File(pickedFile.path), path);
      if (downloadUrl != null) {
        setState(() {
          if (isChild && index != null) {
            while (childImages.length <= index) {
              childImages.add(null);
            }
            childImages[index] = downloadUrl;
          } else if (index == null) {
            if (isChild) {
              motherImage = downloadUrl;
            } else {
              fatherImage = downloadUrl;
            }
          }
        });
        await _saveToFirestore();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Image uploaded successfully'),
              backgroundColor: primaryBlue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  Future<void> _saveToFirestore() async {
    while (childImages.length < children.length) {
      childImages.add(null);
    }
    while (children.length < childImages.length) {
      children.add({});
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('family')
          .doc(widget.memberId)
          .set({
        'fatherImage': fatherImage,
        'motherImage': motherImage,
        'fatherData': fatherData,
        'motherData': motherData,
        'children': children,
        'childImages': childImages,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save data: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _sortChildrenAndImages() {
    setState(() {
      List<MapEntry<Map<String, dynamic>, String?>> combinedList = [];
      for (int i = 0; i < children.length; i++) {
        combinedList.add(MapEntry(children[i], i < childImages.length ? childImages[i] : null));
      }

      combinedList.sort((a, b) {
        int aPriority = int.tryParse(a.key['priority'] ?? '999') ?? 999;
        int bPriority = int.tryParse(b.key['priority'] ?? '999') ?? 999;
        return aPriority.compareTo(bPriority);
      });

      children = combinedList.map((e) => e.key).toList();
      childImages = combinedList.map((e) => e.value).toList();
    });
  }

  void _showDetailDialog(BuildContext context, String title, bool isChild, [int? index]) {
    var data = index != null ? children[index] : (isChild ? motherData : fatherData);
    var nameCtrl = TextEditingController(text: data['name']);
    var dobCtrl = TextEditingController(text: data['dob']);
    var weddingCtrl = TextEditingController(text: data['wedding']);
    var deathCtrl = TextEditingController(text: data['death']);
    var priorityCtrl = TextEditingController(text: data['priority']);
    String? selectedGender = data['gender'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: greyBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: primaryBlue.withOpacity(0.3)),
          ),
          title: Text(
            '$title Details',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField('Name', nameCtrl),
                _buildTextField('Date of Birth (DD/MM/YYYY)', dobCtrl, isOptional: true),
                _buildTextField('Wedding Anniversary (DD/MM/YYYY)', weddingCtrl, isOptional: true),
                _buildTextField('Date of Death (DD/MM/YYYY)', deathCtrl, isOptional: true),
                if (isChild && index != null) ...[
                  _buildTextField('Priority Number (e.g., 1, 2, 3)', priorityCtrl,
                      inputType: TextInputType.number, isOptional: true),
                  _buildDropdownField(
                    label: 'Gender',
                    value: selectedGender,
                    items: ['Male', 'Female'],
                    onChanged: (newValue) {
                      setDialogState(() {
                        selectedGender = newValue;
                      });
                    },
                    isOptional: true,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            if (isChild && index != null)
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.red, Colors.redAccent]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () async {
                    setState(() {
                      children.removeAt(index);
                      if (index < childImages.length) {
                        childImages.removeAt(index);
                      }
                    });
                    await _saveToFirestore();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Child deleted successfully'),
                          backgroundColor: primaryBlue,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [darkBlue, primaryBlue]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () async {
                  setState(() {
                    var newData = {
                      'name': nameCtrl.text,
                      'dob': dobCtrl.text,
                      'wedding': weddingCtrl.text,
                      'death': deathCtrl.text,
                      if (isChild && index != null) 'priority': priorityCtrl.text,
                      if (isChild && index != null) 'gender': selectedGender,
                    };
                    if (index != null) {
                      children[index] = newData;
                    } else if (isChild) {
                      motherData = newData;
                    } else {
                      fatherData = newData;
                    }
                    if (isChild) {
                      _sortChildrenAndImages();
                    }
                  });
                  await _saveToFirestore();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Details saved successfully'),
                        backgroundColor: primaryBlue,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                  Navigator.pop(context);
                },
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateByName(
    BuildContext context,
    String name,
    String targetMemberId,
    String defaultTitle, {
    bool isFatherToChild = false,
    bool isMotherToChild = false,
    bool isChildToRelative = false,
    int? childIndex,
  }) {
    if (name.isNotEmpty && name == widget.title) {
      Navigator.pop(context);
      return;
    }

    String newTitle = name.isNotEmpty ? name : defaultTitle;
    String newMemberId = targetMemberId;

    if (isFatherToChild) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('family')
          .doc(newMemberId)
          .set({
        'fatherData': {},
        'motherData': {},
        'children': [Map.from(fatherData)],
        'childImages': [fatherImage],
        'fatherImage': null,
        'motherImage': null,
      });
    } else if (isMotherToChild) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('family')
          .doc(newMemberId)
          .set({
        'fatherData': {},
        'motherData': {},
        'children': [Map.from(motherData)],
        'childImages': [motherImage],
        'fatherImage': null,
        'motherImage': null,
      });
    } else if (isChildToRelative && childIndex != null) {
      final child = children[childIndex];
      final childGender = child['gender'];
      final childImg = childImages[childIndex];

      Map<String, dynamic> newFatherData = {};
      Map<String, dynamic> newMotherData = {};
      String? newFatherImage = null;
      String? newMotherImage = null;

      if (childGender == 'Male') {
        newFatherData = Map.from(child);
        newFatherImage = childImg;
      } else if (childGender == 'Female') {
        newMotherData = Map.from(child);
        newMotherImage = childImg;
      }

      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('family')
          .doc(newMemberId)
          .set({
        'fatherData': newFatherData,
        'motherData': newMotherData,
        'children': [{}],
        'childImages': [null],
        'fatherImage': newFatherImage,
        'motherImage': newMotherImage,
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FamilyMemberPage(
          memberId: newMemberId,
          title: newTitle,
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType inputType = TextInputType.text, bool isOptional = false}) {
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
          validator: isOptional
              ? null
              : (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter $label';
                  }
                  return null;
                },
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool isOptional = false,
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
          validator: isOptional
              ? null
              : (value) => value == null ? 'Please select a $label' : null,
        ),
      ),
    );
  }

  Widget _buildFamilyMemberCard({
    required String label,
    String? imageUrl,
    required Map<String, dynamic> data,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
    required VoidCallback onDetails,
    required int index,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200 + (index * 50)),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: SizedBox(
        width: 200,
        height: 200,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              onLongPress: onLongPress,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [darkBlue, primaryBlue, lightBlue.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryBlue.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: imageUrl != null
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: greyBlack,
                                  child: const Icon(Icons.person, color: Colors.white, size: 50),
                                ),
                              )
                            : Container(
                                color: greyBlack,
                                child: Text(
                                  label,
                                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data['name'] ?? label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 70,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [darkBlue, primaryBlue]),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: onDetails,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [blackColor, greyBlack, const Color(0xFF3A3A3A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Center(child: CircularProgressIndicator(color: Color(0xFF03A9F4))),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
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
            title: Text(
              widget.title,
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
                child: SingleChildScrollView(
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
                              child: const Icon(Icons.group, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Family Members',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${children.length + 2} members registered',
                                    style: TextStyle(color: Colors.white70, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (children.isEmpty && fatherImage == null && motherImage == null)
                        Center(
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
                                  Icons.group,
                                  size: 60,
                                  color: primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'No family members registered',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add images for father, mother, or children',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: _buildFamilyMemberCard(
                                label: 'Father',
                                imageUrl: fatherImage,
                                data: fatherData,
                                onTap: () => fatherImage == null
                                    ? _pickImage(null, false)
                                    : _navigateByName(
                                        context,
                                        fatherData['name'] ?? '',
                                        '${widget.memberId}_father',
                                        'Father as Child',
                                        isFatherToChild: true,
                                      ),
                                onLongPress: () => _pickImage(null, false),
                                onDetails: () => _showDetailDialog(context, 'Father', false),
                                index: 0,
                              ),
                            ),
                            Expanded(
                              child: _buildFamilyMemberCard(
                                label: 'Mother',
                                imageUrl: motherImage,
                                data: motherData,
                                onTap: () => motherImage == null
                                    ? _pickImage(null, true)
                                    : _navigateByName(
                                        context,
                                        motherData['name'] ?? '',
                                        '${widget.memberId}_mother',
                                        'Mother as Child',
                                        isMotherToChild: true,
                                      ),
                                onLongPress: () => _pickImage(null, true),
                                onDetails: () => _showDetailDialog(context, 'Mother', true),
                                index: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Children',
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
                        const SizedBox(height: 10),
                        ...children.asMap().entries.map((entry) {
                          int index = entry.key;
                          String? currentChildImage = index < childImages.length ? childImages[index] : null;
                          return _buildFamilyMemberCard(
                            label: 'Child ${entry.value['priority'] ?? '${index + 1}'}',
                            imageUrl: currentChildImage,
                            data: entry.value,
                            onTap: () => currentChildImage == null
                                ? _pickImage(index, true)
                                : _navigateByName(
                                    context,
                                    entry.value['name'] ?? '',
                                    '${widget.memberId}_child_$index',
                                    'Child ${entry.value['priority'] ?? '${index + 1}'}',
                                    isChildToRelative: true,
                                    childIndex: index,
                                  ),
                            onLongPress: () => _pickImage(index, true),
                            onDetails: () => _showDetailDialog(context, 'Child ${index + 1}', true, index),
                            index: index + 2,
                          );
                        }).toList(),
                        const SizedBox(height: 10),
                        Container(
                          width: 150,
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
                            onPressed: () {
                              setState(() {
                                children.add({});
                                childImages.add(null);
                                _saveToFirestore();
                              });
                            },
                            child: const Text(
                              'Add Child',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                              'Your family data is stored securely',
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
          ),
        );
      },
    );
  }
}