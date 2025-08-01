
import 'package:flutter/material.dart';
import 'package:newblood/second.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Myfirst extends StatefulWidget {
  const Myfirst({super.key});

  @override
  State<Myfirst> createState() => _MyfirstState();
}

class _MyfirstState extends State<Myfirst> {

  final CollectionReference doner = FirebaseFirestore.instance.collection('doner');

   Future<void> deleteDonor(String id) async {
    await doner.doc(id).delete();
  }

  Future<void> editDonor(String id, String currentName, String currentPhone) async {
    TextEditingController nameController = TextEditingController(text: currentName);
    TextEditingController phoneController = TextEditingController(text: currentPhone);
     String? _selectedItem;


    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Donor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: phoneController,
                maxLength: 10,
                decoration: InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text('Cancel')
            ),
            ElevatedButton(
              onPressed: () async {
                await doner.doc(id).update({
                  'name': nameController.text,
                  'phone': phoneController.text,
                });
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }


   
  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        backgroundColor:  Color.fromARGB(255, 120, 27, 20),
        centerTitle: true,
        title: Text('BLOOD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          bool? result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Mysecond()),
          );
          if (result == true) {
            setState(() {});
          }
        },
        child: Icon(Icons.add, color:  Color.fromARGB(255, 120, 27, 20),),
        backgroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      body: StreamBuilder(
        stream: doner.snapshots(), 
        builder: (context, AsyncSnapshot snapshot){
          if(snapshot.hasData){
           return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context,Index){
              final DocumentSnapshot donerSnap=snapshot.data.docs[Index];
              return Padding(
                padding: const EdgeInsets.all(10.0),
                child: (
                  Container(
                            height:80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white,
                              boxShadow:[
                                 BoxShadow(
                                color: const Color.fromARGB(255, 222, 220, 220),
                                blurRadius: 10,
                                spreadRadius:15 
                              )
                              ]
                            ),
                            child: Row(
                children: [
                  Container(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: Color.fromARGB(255, 120, 27, 20),
                        radius: 30,
                        child: Text(donerSnap['group'],style: TextStyle(fontSize: 18,color: Colors.white),),
                      ),
                    ),
                  ),
                
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(donerSnap['name'],style: TextStyle(fontWeight: FontWeight.bold),), 
                      Text(donerSnap['phone'].toString(),
                      style: TextStyle(fontSize: 18),
                      )
                    ],
                  ),
                  SizedBox(width: 68),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       IconButton(
                              onPressed: () => editDonor(donerSnap.id, donerSnap['name'], donerSnap['phone'].toString()),
                              icon: Icon(Icons.edit),
                              iconSize: 30,
                              color: Colors.blue,
                            ),
                            IconButton(
                              onPressed: () => deleteDonor(donerSnap.id),
                              icon: Icon(Icons.delete),
                              iconSize: 30,
                              color: Colors.red,
                            ),
                    ],
                  )
                ],
                            ),
                          )
                
                            ),
              ); }
            );
          }
          return Container();
        }),
    );
  }
}