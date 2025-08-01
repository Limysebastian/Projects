import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:miniproject/petdisply.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Mypets extends StatefulWidget {
  final String categoryId; 
  final String categoryName;
  const Mypets({super.key, required this.categoryId,required this.categoryName});

  @override
  State<Mypets> createState() => _MypetsState();
}

class _MypetsState extends State<Mypets> {

   List pets=[];
    @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getPets();
    
  }
   Future<String?> getPets() async {
SharedPreferences prefs = await SharedPreferences.getInstance();
String? token =prefs.getString('auth_token');

if(token == null){
   ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('token not found')));
      
}
 final url =Uri.parse('http://192.168.1.35/Empetz/api/v1/pet/catagory?categoryid=${widget.categoryId}&PageNumber=1&PageSize=1000');
 final response = await http.get(url,
 headers: {'Content-Type': 'application/json',
 'Authorization':'Bearer $token',
 },

 );
 if(response.statusCode==200 || response.statusCode ==201){
  final data = jsonDecode(response.body);
 
setState(() {
  pets = data;
});

 }else{
  print(response.statusCode);
  ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('failed to fetch')));
 }


}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
         title: Text(widget.categoryName,
      style: TextStyle(color: Colors.white, fontFamily: 'Cursive')),
        backgroundColor: Color.fromARGB(255, 3, 44, 91),
      ),
       body: GridView.builder(
  padding: EdgeInsets.all(10),
  itemCount: pets.length,
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    childAspectRatio: 0.7,
  ),
  itemBuilder: (context, index) {
  final pet = pets[index];
  return Card(
    color: Color.fromARGB(255, 3, 44, 91),
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyDisplay(pet: pet, userId: pet['userId']   ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                pet['imagePath'],
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pet['name'] ?? '',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                "Age: ${pet['age'] ?? ''}",
                style: TextStyle(color: Colors.white),
              ),
              Text(
                "Price: ₹${pet['price'] ?? ''}",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

) 

    );
  }
}