import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:newblood/first.dart';

class Mysecond extends StatefulWidget {
  const Mysecond({super.key});

  @override
  State<Mysecond> createState() => _MysecondState();
}

class _MysecondState extends State<Mysecond> {

  TextEditingController nameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();

 
  String? nameError;
  String? phoneNumberError;
  String? _selectedItem;

  

  

 

  String? validateName(String name) {
    if (name.isEmpty) return 'Name cannot be empty';
    if (RegExp(r'[!@#<>?":_~;[\]\\|=+(*&^%0-9-)]').hasMatch(name)) {
      return 'Name must not contain special characters or numbers';
    }
    return null;
  }

  String? validatePhoneNumber(String phoneNumber) {
    if (!RegExp(r'^\d{10}$').hasMatch(phoneNumber)) {
      return 'Phone number must be exactly 10 digits';
    }
    return null;
  }

  final CollectionReference doner = FirebaseFirestore.instance.collection('doner');

  

  void addDonor(){
    final data ={
      'name':nameController.text,
      'phone':phoneNumberController.text,
      'group':_selectedItem
    };
    doner.add(data);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        
        backgroundColor:  Color.fromARGB(255, 120, 27, 20),
        centerTitle: true,
        title: Text('DONOR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),

      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Enter Name',
                errorText: nameError,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => nameError = validateName(value)),
            ),
            SizedBox(height: 15),
            TextField(
              controller: phoneNumberController,
              keyboardType: TextInputType.number,
              maxLength: 10,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                errorText: phoneNumberError,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  phoneNumberError = validatePhoneNumber(value);
                });
              },
            ),
            DropdownButton<String>(
              value: _selectedItem,
              items: ['A+', 'B+', 'AB+', 'O+', 'A-', 'B-', 'AB-', 'O-']
                  .map((String value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
              hint: Text('Select Blood Group'),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedItem = newValue;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async { addDonor();
              Navigator.push(
    context,
    MaterialPageRoute(builder: (context) =>  Myfirst()),
  );
                setState(() {
                  nameError = validateName(nameController.text);
                  phoneNumberError = validatePhoneNumber(phoneNumberController.text);
                });

                if (nameError == null && phoneNumberError == null && _selectedItem != null) {
                 
                }
              },
              child: Text('Save', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor:  Color.fromARGB(255, 120, 27, 20),),
            ),
          ],
        ),
      ),
    );
  }
}