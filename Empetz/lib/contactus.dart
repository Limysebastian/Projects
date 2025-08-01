import 'package:flutter/material.dart';

class Contact extends StatelessWidget {
  const Contact({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [
        Container(
            height: 1000,
            child: Image(
              image: AssetImage('lib/image/contactus.jpg'),
              fit: BoxFit.cover,
            )),
        Padding(
          padding: const EdgeInsets.only(top: 150.0),
          child: Padding(
            padding: const EdgeInsets.only(right: 30, left: 30, bottom: 100),
            child: Card(
              color: const Color.fromARGB(255, 78, 45, 244),
              child: ListTile(
                title: Text(
                  "8466747880",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.bold), // Change text color to black
                ),
                leading: Icon(
                  Icons.phone,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 210.0),
          child: Padding(
            padding: EdgeInsets.only(left: 30, right: 30),
            child: Card(
              color: Color.fromARGB(255, 78, 45, 244),
              child: ListTile(
                title: Text(
                  'lkkj@gmailcom',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                leading: Icon(
                  Icons.mail,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        )
      ],
    ));
  }
}
// import 'package:flutter/material.dart';

// class Contact extends StatefulWidget{
//   Contact({super.key});

//   @override
//   State<Contact> createState() => _ContactState();
// }

// class _ContactState extends State<Contact> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Container(
//           width: 350,
//           height: 600,
//           decoration: BoxDecoration(
//             color: Color.fromARGB(255, 3, 44, 91),
//             borderRadius: BorderRadius.circular(0),
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               Text('CONTACT US',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 50,
//                 fontWeight: FontWeight.bold,
//               ),),
//               Padding(padding: EdgeInsets.only(bottom: 200,right: 20,left: 20),
//               child: TextField(
                
//                 decoration: InputDecoration(
//                   prefix: Icon(Icons.phone,color: Colors.black,),
//                   filled: true,
//                   fillColor: Colors.white,
//                   labelText: '854677270',
                  
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(.0),
//                   )
                  
//                 ),
//               ),

//               ),
//               Padding(
//                 padding: const EdgeInsets.only(right: 20,left: 20),
//                 child: TextField(
//                   decoration: InputDecoration(
//                     filled: true,
//                     fillColor: Colors.white,
//                     labelText: 'limy@gmail.com',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(0.0),
//                     )
//                   ),
//                 ),
//               ),

              
              
                
               
                
               
              
//             ]    
//           ),
                
              
//           ),),
          
//         );
        
    

  
//   }}