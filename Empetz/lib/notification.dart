import 'package:flutter/material.dart';

class Mynotification extends StatefulWidget {
  const Mynotification({super.key});

  @override
  State<Mynotification> createState() => _NotificationState();
}

class _NotificationState extends State<Mynotification> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Color.fromARGB(255, 3, 44, 91),
        title: Text('Notification',style: TextStyle(color: Colors.white,fontFamily: 'Cursive',)),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body:    Column(children: [
        Padding(
          padding: const EdgeInsets.only(left: 8,right: 8),
          child: Card(
            color: Colors.white,
            child: Column(
              children: [
               
                ListTile(
                  leading:  CircleAvatar(radius: 50,
                backgroundImage: AssetImage('lib/image/pic1.jpg'),),
                  trailing: Icon(Icons.delete),
                  title: Text('Notification 1'),
                  
                ),
              ],
            ),
          ),
        ),
         Padding(
          padding: const EdgeInsets.only(left: 8,right: 8),
          child: Card(
            color: Colors.white,
            child: ListTile(
              leading: CircleAvatar(radius: 50,
                backgroundImage: AssetImage('lib/image/pic1.jpg'),),
              trailing: Icon(Icons.delete),
              title: Text('Notification 1'),
             
            ),
          ),
        ),
         Padding(
          padding: const EdgeInsets.only(left: 8,right: 8),
          child: Card(
            color: Colors.white,
            child: ListTile(
              leading:  CircleAvatar(radius: 50,
                backgroundImage: AssetImage('lib/image/pic1.jpg'),),
              trailing: Icon(Icons.delete),
              title: Text('Notification 1'),
             
            ),
          ),
        ),
         Padding(
          padding: const EdgeInsets.only(left: 8,right: 8),
          child: Card(
            color: Colors.white,
            child: ListTile(
              leading: CircleAvatar(radius: 50,
                backgroundImage: AssetImage('lib/image/pic1.jpg'),),
              trailing: Icon(Icons.delete),
              title: Text('Notification 1'),
             
            ),
          ),
        ),
         Padding(
          padding: const EdgeInsets.only(left: 8,right: 8),
          child: Card(
            color: Colors.white,
            child: ListTile(
              leading:  CircleAvatar(radius: 50,
                backgroundImage: AssetImage('lib/image/pic1.jpg'),),
              trailing: Icon(Icons.delete),
              title: Text('Notification 1'),
             
            ),
          ),
        ),
         Padding(
          padding: const EdgeInsets.only(left: 8,right: 8),
          child: Card(
            color: Colors.white,
            child: ListTile(
              leading:  CircleAvatar(radius: 50,
                backgroundImage: AssetImage('lib/image/pic1.jpg'),),
              trailing: Icon(Icons.delete),
              title: Text('Notification 1'),
             
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8,right: 8),
          child: Card(
            color: Colors.white,
            child: ListTile(
              leading:  CircleAvatar(radius: 50,
                backgroundImage: AssetImage('lib/image/pic1.jpg'),),
              trailing: Icon(Icons.delete),
              title: Text('Notification 1'),
              
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8,right: 8),
          child: Card(
            color: Colors.white,
            child: ListTile(
              leading:  CircleAvatar(radius: 50,
                backgroundImage: AssetImage('lib/image/pic1.jpg'),),
              trailing: Icon(Icons.delete),
              title: Text('Notification 1'),
              
            ),
          ),
        ),
         ],),
 
    );
  }
}