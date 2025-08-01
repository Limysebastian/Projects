import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class MyDisplay extends StatefulWidget {
  final Map<String, dynamic> pet;
  final String userId;

  const MyDisplay({super.key, required this.pet, required this.userId});

  @override
  State<MyDisplay> createState() => _MyDisplayState();
}

class _MyDisplayState extends State<MyDisplay> {
  Map<String, dynamic>? _userDetails;
  bool _isLoading = false;
  String? _errorMessage;
  late SharedPreferences sp;
  List<Map<String, String>> contacts = [];

  @override
  void initState() {
    super.initState();
    _initializeSharedPreferences();
  }

  Future<void> _initializeSharedPreferences() async {
    sp = await SharedPreferences.getInstance();
    await _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? token = sp.getString('auth_token');

      if (token == null) {
        setState(() {
          _errorMessage = 'Token not found';
          _isLoading = false;
        });
        return;
      }

      final url = Uri.parse('http://192.168.1.35/Empetz/user/${widget.userId}');
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          _userDetails = data;
          _isLoading = false;
        });
        if (_userDetails?['phone'] != null) {
          await _saveContact();
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch user details: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveContact() async {
    contacts.add({
      'name': _userDetails?['firstName'] ?? 'Unknown',
      'phone': _userDetails?['phone'] ?? ''
    });
    await _saveIntoSharedPreferences();
  }

  Future<void> _saveIntoSharedPreferences() async {
    List<String> contactListString = contacts
        .map((contact) => '${contact['name']}:${contact['phone']}')
        .toList();
    await sp.setStringList('myData', contactListString);
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneLaunchUri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(phoneLaunchUri)) {
      throw 'Could not launch $phoneLaunchUri';
    }
  }

  Widget _buildDetailCard(String label, dynamic value, {IconData? icon, Color? valueColor}) {
    return Card(
      margin: EdgeInsets.all(6),
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white24, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null)
              Icon(icon, color: Colors.white70, size: 20),
            if (icon != null) SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 4),
            Text(
              value?.toString() ?? 'N/A',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildContactRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildContactInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Contact Seller",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: buildContactRow(Icons.person, _userDetails?['firstName'] ?? 'N/A'),
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white24,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white30,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.call, color: Colors.greenAccent, size: 22),
                  onPressed: () => _launchPhone(_userDetails?['phone'] ?? ''),
                ),
              ),
            ],
          ),
          buildContactRow(Icons.email, _userDetails?['email'] ?? 'N/A'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027),
              Color.fromARGB(226, 13, 176, 230),
              Color(0xFF2C5364),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Hero(
                    tag: widget.pet['imagePath'],
                    child: ClipPath(
                      clipper: BottomArcClipper(),
                      child: Image.network(
                        widget.pet['imagePath'] ?? '',
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 300,
                          color: Colors.grey,
                          child: Icon(Icons.pets, size: 100, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 275,
                    left: 20,
                    child: Text(
                      widget.pet['name'] ?? 'Unknown Pet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  Positioned(
                    top: 280,
                    right: 20,
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Color.fromARGB(179, 250, 22, 22), size: 18),
                        SizedBox(width: 4),
                        Text(
                          widget.pet['locationName'] ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
             
             
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "₹${widget.pet['price']}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildDetailCard("Breed", widget.pet['breedName'], icon: Icons.pets)),
                        SizedBox(width: 8),
                        Expanded(child: _buildDetailCard("Age", widget.pet['age'], icon: Icons.cake)),
                        SizedBox(width: 8),
                        Expanded(child: _buildDetailCard("Gender", widget.pet['gender'], icon: Icons.square)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildDetailCard("Weight", widget.pet['weight'], icon: Icons.monitor_weight)),
                        SizedBox(width: 8),
                        Expanded(child: _buildDetailCard("Height", widget.pet['height'], icon: Icons.height)),
                       
                      ],
                    ),
                    Row(
                      children: [ Expanded(child: _buildDetailCard("adress", widget.pet['address'], icon: Icons.home)), ] ),
                       Row(
                      children: [ Expanded(child: _buildDetailCard("discription", widget.pet['discription'], icon: Icons.star)), ] ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              if (_isLoading)
                Center(child: CircularProgressIndicator())
              else if (_errorMessage != null)
                Center(child: Text(_errorMessage!, style: TextStyle(color: Colors.redAccent)))
              else if (_userDetails != null)
                buildContactInfo(),
              SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}

class BottomArcClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 50);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
