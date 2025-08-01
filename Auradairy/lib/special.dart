import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import 'package:scf/specialphoto.dart';

class Mysepical extends StatefulWidget {
  const Mysepical({super.key});

  @override
  State<Mysepical> createState() => _MysepicalState();
}

class _MysepicalState extends State<Mysepical> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<Map<String, dynamic>> _familyMembers = [];
  bool _isLoading = true;
  late AnimationController _controller;
  late Animation<double> _fade;
  final lightBlue = const Color(0xFF81D4FA);
  final black = const Color(0xFF000000);
  final white = const Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
    _fetchFamilyMembers();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchFamilyMembers() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not logged in', style: TextStyle(color: white)), backgroundColor: Colors.red),
        );
        return;
      }
      final querySnapshot = await _firestore.collection('user_data').doc('user123').collection('gallery').where('category', isEqualTo: 'Person').get();
      final Set<String> uniqueNames = {};
      final List<Map<String, dynamic>> uniqueMembers = [];
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final name = data['name'] as String?;
        if (name != null && !uniqueNames.contains(name)) {
          uniqueNames.add(name);
          uniqueMembers.add({
            'id': doc.id,
            ...data,
            'image_url': data['image_url'],
            'name': name,
            'dob': data['dob'],
            'wedding_anniversary': data['wedding_anniversary'],
            'death': data['death'],
            'phone_number': data['phone_number'],
            'special_occasion': data['special_occasion'],
          });
        }
      }
      uniqueMembers.sort((a, b) => _getNextUpcomingDate(a).compareTo(_getNextUpcomingDate(b)));
      setState(() {
        _familyMembers = uniqueMembers;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error fetching family members: $e\nStackTrace: $stackTrace');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e', style: TextStyle(color: white)), backgroundColor: Colors.red),
      );
    }
  }

  DateTime _getNextUpcomingDate(Map<String, dynamic> member) {
    final now = DateTime.now();
    final currentYear = now.year;
    final dob = _parseDate(member['dob']);
    final anniversary = _parseDate(member['wedding_anniversary']);
    final death = _parseDate(member['death']);
    final special = _parseDate(member['special_occasion']);
    final List<DateTime> upcomingDates = [];
    if (dob != null) {
      var nextBirthday = DateTime(currentYear, dob.month, dob.day);
      if (nextBirthday.isBefore(now)) nextBirthday = DateTime(currentYear + 1, dob.month, dob.day);
      upcomingDates.add(nextBirthday);
    }
    if (anniversary != null) {
      var nextAnniversary = DateTime(currentYear, anniversary.month, anniversary.day);
      if (nextAnniversary.isBefore(now)) nextAnniversary = DateTime(currentYear + 1, anniversary.month, anniversary.day);
      upcomingDates.add(nextAnniversary);
    }
    if (death != null && death.isAfter(now)) upcomingDates.add(death);
    if (special != null) {
      var nextSpecial = DateTime(currentYear, special.month, special.day);
      if (nextSpecial.isBefore(now)) nextSpecial = DateTime(currentYear + 1, special.month, special.day);
      upcomingDates.add(nextSpecial);
    }
    return upcomingDates.isEmpty ? DateTime(2100) : upcomingDates.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  String? _getNextUpcomingDateType(Map<String, dynamic> member) {
    final now = DateTime.now();
    final currentYear = now.year;
    final nextDate = _getNextUpcomingDate(member);
    final dob = _parseDate(member['dob']);
    final anniversary = _parseDate(member['wedding_anniversary']);
    final death = _parseDate(member['death']);
    final special = _parseDate(member['special_occasion']);
    if (dob != null) {
      var nextBirthday = DateTime(currentYear, dob.month, dob.day);
      if (nextBirthday.isBefore(now)) nextBirthday = DateTime(currentYear + 1, dob.month, dob.day);
      if (nextBirthday == nextDate) return 'dob';
    }
    if (anniversary != null) {
      var nextAnniversary = DateTime(currentYear, anniversary.month, anniversary.day);
      if (nextAnniversary.isBefore(now)) nextAnniversary = DateTime(currentYear + 1, anniversary.month, anniversary.day);
      if (nextAnniversary == nextDate) return 'anniversary';
    }
    if (death != null && death == nextDate) return 'death';
    if (special != null) {
      var nextSpecial = DateTime(currentYear, special.month, special.day);
      if (nextSpecial.isBefore(now)) nextSpecial = DateTime(currentYear + 1, special.month, special.day);
      if (nextSpecial == nextDate) return 'special';
    }
    return null;
  }

  DateTime? _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      final parts = dateString.split('/');
      if (parts.length != 3) return null;
      return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    } catch (_) {
      return null;
    }
  }

  String _getDateLabel(String type) => switch (type) {
        'dob' => 'Birthday',
        'anniversary' => 'Anniversary',
        'death' => 'Death',
        'special' => 'Special Occasion',
        _ => 'Date'
      };

  Color _getDateColor(String type) => switch (type) {
        'dob' => Colors.blue,
        'anniversary' => Colors.orange, // Changed from pink to orange
        'death' => Colors.grey,
        'special' => Colors.orange,
        _ => black
      };

  String _formatDate(DateTime date) => DateFormat('dd MMM').format(date);

  String? _calculateAgeOrYears(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    final date = _parseDate(dateString);
    if (date == null) return null;
    final now = DateTime.now();
    final difference = now.difference(date);
    final years = (difference.inDays / 365).floor();
    return years.toString();
  }

  void _showAddMemberBottomSheet() {
    final nameController = TextEditingController();
    final dobController = TextEditingController();
    final anniversaryController = TextEditingController();
    final specialController = TextEditingController();
    final deathController = TextEditingController();
    final phoneController = TextEditingController();
    XFile? pickedImage;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [lightBlue, black.withOpacity(0.05)]),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border.all(color: lightBlue.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: lightBlue.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add Family Member',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: white,
                      shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: TextStyle(color: white.withOpacity(0.7)),
                      prefixIcon: Icon(Icons.person, color: white),
                      hintStyle: TextStyle(color: white.withOpacity(0.5)),
                    ),
                    style: TextStyle(color: white),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: dobController,
                    decoration: InputDecoration(
                      labelText: 'Date of Birth (DD/MM/YYYY)',
                      labelStyle: TextStyle(color: white.withOpacity(0.7)),
                      prefixIcon: Icon(Icons.cake, color: white),
                      hintStyle: TextStyle(color: white.withOpacity(0.5)),
                    ),
                    style: TextStyle(color: white),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.dark(
                              primary: lightBlue,
                              onPrimary: white,
                              surface: black,
                              onSurface: white,
                            ),
                            dialogBackgroundColor: black,
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) dobController.text = DateFormat('dd/MM/yyyy').format(picked);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: anniversaryController,
                    decoration: InputDecoration(
                      labelText: 'Wedding Anniversary (DD/MM/YYYY)',
                      labelStyle: TextStyle(color: white.withOpacity(0.7)),
                      prefixIcon: Icon(Icons.favorite, color: white),
                      hintStyle: TextStyle(color: white.withOpacity(0.5)),
                    ),
                    style: TextStyle(color: white),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.dark(
                              primary: lightBlue,
                              onPrimary: white,
                              surface: black,
                              onSurface: white,
                            ),
                            dialogBackgroundColor: black,
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) anniversaryController.text = DateFormat('dd/MM/yyyy').format(picked);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: specialController,
                    decoration: InputDecoration(
                      labelText: 'Special Occasion'
                    ),
                    style: TextStyle(color: white),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.dark(
                              primary: lightBlue,
                              onPrimary: white,
                              surface: black,
                              onSurface: white,
                            ),
                            dialogBackgroundColor: black,
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) specialController.text = DateFormat('dd/MM/yyyy').format(picked);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: deathController,
                    decoration: InputDecoration(
                      labelText: 'Date of Death (DD/MM/YYYY)',
                      labelStyle: TextStyle(color: white.withOpacity(0.7)),
                      prefixIcon: Icon(Icons.flag, color: white),
                      hintStyle: TextStyle(color: white.withOpacity(0.5)),
                    ),
                    style: TextStyle(color: white),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.dark(
                              primary: lightBlue,
                              onPrimary: white,
                              surface: black,
                              onSurface: white,
                            ),
                            dialogBackgroundColor: black,
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) deathController.text = DateFormat('dd/MM/yyyy').format(picked);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: TextStyle(color: white.withOpacity(0.7)),
                      prefixIcon: Icon(Icons.phone, color: white),
                      hintStyle: TextStyle(color: white.withOpacity(0.5)),
                    ),
                    style: TextStyle(color: white),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(source: ImageSource.gallery);
                      setState(() => pickedImage = image);
                    },
                    icon: Icon(Icons.image, color: white),
                    label: Text('Pick Image from Gallery', style: TextStyle(color: white)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.transparent,
                      foregroundColor: white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Name is required', style: TextStyle(color: white)), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      try {
                        String? imageUrl;
                        if (pickedImage != null) {
                          final ref = _storage.ref().child('user_data/user123/gallery/${pickedImage!.name}');
                          await ref.putFile(File(pickedImage!.path));
                          imageUrl = await ref.getDownloadURL();
                        }
                        await _firestore.collection('user_data').doc('user123').collection('gallery').add({
                          'category': 'Person',
                          'name': nameController.text.trim(),
                          'dob': dobController.text.trim(),
                          'wedding_anniversary': anniversaryController.text.trim(),
                          'special_occasion': specialController.text.trim(),
                          'death': deathController.text.trim(),
                          'phone_number': phoneController.text.trim(),
                          'image_url': imageUrl,
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Member added successfully', style: TextStyle(color: white)), backgroundColor: Colors.green),
                        );
                        _fetchFamilyMembers();
                      } catch (e, stackTrace) {
                        debugPrint('Error saving member: $e\nStackTrace: $stackTrace');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error saving member: $e', style: TextStyle(color: white)), backgroundColor: Colors.red),
                        );
                      }
                    },
                    icon: Icon(Icons.save, color: white),
                    label: Text('Save Member', style: TextStyle(fontSize: 18, color: white)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.transparent,
                      foregroundColor: white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            color: black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: lightBlue.withOpacity(0.3)),
            boxShadow: [BoxShadow(color: lightBlue.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    member['name'],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: white,
                      shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(height: 12),
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: member['image_url'] != null ? NetworkImage(member['image_url']) : null,
                    child: member['image_url'] == null ? Icon(Icons.person, size: 50, color: white) : null,
                    backgroundColor: white.withOpacity(0.15),
                  ),
                  const SizedBox(height: 16),
                  if (member['dob'] != null && member['dob'].isNotEmpty)
                    _buildDetailRow(
                      icon: Icons.cake,
                      label: 'Date of Birth',
                      value: '${member['dob']} (${_calculateAgeOrYears(member['dob']) ?? 'Unknown'} years old)',
                      color: Colors.blue,
                    ),
                  if (member['wedding_anniversary'] != null && member['wedding_anniversary'].isNotEmpty)
                    _buildDetailRow(
                      icon: Icons.favorite,
                      label: 'Wedding Anniversary',
                      value: '${member['wedding_anniversary']} (${_calculateAgeOrYears(member['wedding_anniversary']) ?? 'Unknown'} years)',
                      color: Colors.orange,
                    ),
                  if (member['special_occasion'] != null && member['special_occasion'].isNotEmpty)
                    _buildDetailRow(
                      icon: Icons.event,
                      label: 'Special Occasion',
                      value: member['special_occasion'],
                      color: Colors.orange,
                    ),
                  if (member['death'] != null && member['death'].isNotEmpty)
                    _buildDetailRow(
                      icon: Icons.flag,
                      label: 'Date of Death',
                      value: '${member['death']} (${_calculateAgeOrYears(member['death']) ?? 'Unknown'} years since)',
                      color: Colors.grey,
                    ),
                  if (member['phone_number'] != null && member['phone_number'].isNotEmpty)
                    _buildDetailRow(icon: Icons.phone, label: 'Phone Number', value: member['phone_number'], color: white),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close', style: TextStyle(color: white)),
                    style: TextButton.styleFrom(
                      backgroundColor: white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildDetailRow({required IconData icon, required String label, required String value, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color ?? white),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? white)),
                Text(value, style: TextStyle(color: white)),
              ],
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: black,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [lightBlue.withOpacity(0.8), black], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
            ),
          ),
          title: Text(
            'Family Members',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: white,
              shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4)],
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.add, color: white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OccasionSelectionScreen()),
                );
              },
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [black, black.withOpacity(0.8), Colors.black87], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [lightBlue.withOpacity(0.1), white.withOpacity(0.05)]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: lightBlue.withOpacity(0.3)),
                      boxShadow: [BoxShadow(color: lightBlue.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [lightBlue, black]),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: lightBlue.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
                          ),
                          child: Icon(Icons.group, color: white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Family Members', style: TextStyle(color: white, fontSize: 16, fontWeight: FontWeight.bold)),
                              const Text('Track important dates', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? Center(child: CircularProgressIndicator(color: lightBlue))
                        : _familyMembers.isEmpty
                            ? Center(
                                child: Text(
                                  'No family members found',
                                  style: TextStyle(
                                    color: white.withOpacity(0.7),
                                    fontSize: 16,
                                    shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 2)],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _familyMembers.length,
                                itemBuilder: (context, index) {
                                  final member = _familyMembers[index];
                                  final nextDate = _getNextUpcomingDate(member);
                                  final dateType = _getNextUpcomingDateType(member);
                                  final daysUntil = nextDate.difference(DateTime.now()).inDays;
                                  return GestureDetector(
                                    onTap: () => _showDetailsDialog(context, member),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [black, lightBlue.withOpacity(0.4), black.withOpacity(0.8)]),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: white.withOpacity(0.1)),
                                        boxShadow: [BoxShadow(color: lightBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 30,
                                            backgroundImage: member['image_url'] != null ? NetworkImage(member['image_url']) : null,
                                            child: member['image_url'] == null ? Icon(Icons.person, size: 30, color: white) : null,
                                            backgroundColor: white.withOpacity(0.15),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(member['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: white)),
                                                if (dateType != null)
                                                  Text(
                                                    '${_getDateLabel(dateType)}: ${_formatDate(nextDate)} (in $daysUntil days)',
                                                    style: TextStyle(color: _getDateColor(dateType), fontWeight: FontWeight.w500, fontSize: 14),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Icon(Icons.chevron_right, color: white),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: white.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_sync_outlined, color: lightBlue, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'Data synced & secured',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddMemberBottomSheet,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [lightBlue, black], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: lightBlue.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Center(child: Icon(Icons.add, color: white, size: 24)),
          ),
        ),
      );
}