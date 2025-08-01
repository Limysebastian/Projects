import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:miniproject/myform.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPostedPetsScreen extends StatefulWidget {
  const UserPostedPetsScreen({super.key});

  @override
  State<UserPostedPetsScreen> createState() => _UserPostedPetsScreenState();
}

class _UserPostedPetsScreenState extends State<UserPostedPetsScreen> {
  late Future<List<Map<String, dynamic>>> _futurePets;

  @override
  void initState() {
    super.initState();
    _futurePets = fetchUserPostedPets();
  }

  Future<List<Map<String, dynamic>>> fetchUserPostedPets() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Token not found")),
      );
      return [];
    }

    final url = Uri.parse('http://192.168.1.35/Empetz/api/v1/user-posted-history');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch data: ${response.statusCode}")),
      );
      return [];
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _futurePets = fetchUserPostedPets();
    });
  }
  
 Future<void> deletePet(String petId) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      debugPrint("Token is null or empty");
      return;
    }

    final url = Uri.parse('http://192.168.1.35/Empetz/api/v1/pet/$petId'); 


    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    debugPrint("DELETE response code: ${response.statusCode}");
    debugPrint("DELETE response body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pet deleted successfully")),
      );
      _refreshData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete pet: ${response.statusCode}")),
      );
    }
  } catch (e) {
    debugPrint("Delete error: $e");
  }
}


  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futurePets,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          if (snapshot.hasError)
            return Center(child: Text("Error: ${snapshot.error}"));

          final pets = snapshot.data ?? [];

          if (pets.isEmpty) {
            return const Center(child: Text("No pets posted yet"));
          }

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView.builder(
              itemCount: pets.length,
              itemBuilder: (context, index) {
                final pet = pets[index];
                return   Card(
  margin: const EdgeInsets.all(10),
  child: ListTile(
    leading: CircleAvatar(
      radius: 30,
      backgroundImage: pet['image'] != null
          ? MemoryImage(base64Decode(pet['image']))
          : null,
    ),
    title: Text(
      pet['name'] ?? 'Unknown',
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    subtitle: Text('Price: ₹${pet['price'].toString() ?? 'N/A'}'),
    trailing: IconButton(
      icon: const Icon(Icons.delete, color: Colors.red),
      onPressed: () async {
        // Show temporary loading
        setState(() {
          pets.removeAt(index);
        });

        await deletePet(pet['id'].toString());
      },
    ),
  ),
);


              },
            ),
          );
        },
      ),
     floatingActionButton: FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) =>  Myform()),
    );
  },
  backgroundColor: const Color.fromARGB(255, 3, 44, 91),
  child: const Icon(Icons.add, color: Colors.white),
),

    );
  }
}
