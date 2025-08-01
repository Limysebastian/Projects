import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:miniproject/contactus.dart';
import 'package:miniproject/myform.dart';
import 'package:miniproject/notification.dart';
import 'package:miniproject/pets.dart';
import 'package:miniproject/sellerhistory.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List catagory = [];
  String userName = 'Guest'; // Default username
  String userAvatar = 'lib/image/pet1.jpg'; // Default avatar

  @override
  void initState() {
    super.initState();
    getCatagory();
    _loadUserData();  
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // First try to get locally stored username
    String? localUsername = prefs.getString('username');
    if (localUsername != null) {
      setState(() {
        userName = localUsername;
      });
    }

    // Then try to fetch updated data from API
    String? token = prefs.getString('auth_token');
    String? userId = prefs.getString('user_id');
    
    if (token != null && userId != null) {
      try {
        final response = await http.get(
          Uri.parse("http://192.168.1.35/Empetz/user/$userId"),
          headers: {'Authorization': 'Bearer $token'},
        );
        
        if (response.statusCode == 200) {
          final userData = jsonDecode(response.body);
          setState(() {
            userName = userData['userName'] ?? userName;
          });
          // Update local storage
          await prefs.setString('username', userName);
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }
  Future<String?> getCatagory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Token not found')));
      return null;
    }

    final url = Uri.parse('http://192.168.1.35/Empetz/api/v1/category');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      setState(() {
        catagory = data;
      });
    } else {
      print(response.statusCode);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch categories')));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Mynotification()),
                );
              },
              icon: Icon(Icons.notifications),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Text(
                'BUYER',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cursive',
                ),
              ),
              Text(
                'SELLER',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cursive',
                ),
              ),
            ],
          ),
          title: Padding(
            padding: const EdgeInsets.only(left: 90.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Home",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Cursive',
                ),
              ),
            ),
          ),
          backgroundColor: Color.fromARGB(255, 3, 44, 91),
        ),
        drawer: Drawer(
          child: ListView(
            padding: const EdgeInsets.all(0),
            children: [
             DrawerHeader(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF032B57), Color(0xFF035781)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  margin: EdgeInsets.zero,
  padding: EdgeInsets.zero,
  child: SafeArea(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 42,
            backgroundImage: AssetImage(userAvatar),
          ),
        ),
        SizedBox(height: 8),
        Flexible(
          child: Text(
            userName,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cursive',
              shadows: [
               
              ],
            ),
          ),
        ),
      ],
    ),
  ),
),


             Padding(
  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
  child: Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 4,
    child: ListTile(
      leading: Icon(Icons.person, color: Color(0xFF032B57)),
      title: Text(
        'My Profile',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Cursive',
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => Profile()));
      },
    ),
  ),
),
              Padding(
  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
  child: Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 4,
    child: ListTile(
      leading: Icon(Icons.favorite, color: Color(0xFF032B57)),
      title: Text(
        'Favorite',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Cursive',
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => Favorite()));
      },
    ),
  ),
),
             Padding(
  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
  child: Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 4,
    child: ListTile(
      leading: Icon(Icons.phone, color: Color(0xFF032B57)),
      title: Text(
        'Contact',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Cursive',
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => Contact()));
      },
    ),
  ),
),

             Padding(
  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
  child: Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 4,
    child: ListTile(
      leading: Icon(Icons.book, color: Color(0xFF032B57)),
      title: Text(
        'About Us',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Cursive',
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => About()));
      },
    ),
  ),
),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // BUYER TAB - Grid view of categories
            catagory.isEmpty
                ? Center(child: CircularProgressIndicator())
                : GridView.builder(
                    itemCount: catagory.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Mypets(
                                categoryId: catagory[index]['id'].toString(),
                                categoryName: catagory[index]['name'],
                              ),
                            ),
                          );
                        },
                        child: Card(
                          child: Image.network(
                            catagory[index]['imagePath'],
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
            UserPostedPetsScreen()
          ],
        ),
      ),
    );
  }
}

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Color.fromARGB(255, 3, 44, 91),
        centerTitle: true,
        title: Text('Profile', style: TextStyle(color: Colors.white, fontFamily: 'Cursive')),
      ),
    );
  }
}

class Favorite extends StatelessWidget {
  const Favorite({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Color.fromARGB(255, 3, 44, 91),
        centerTitle: true,
        title: Text('Favorite', style: TextStyle(color: Colors.white, fontFamily: 'Cursive')),
      ),
    );
  }
}

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Color.fromARGB(255, 3, 44, 91),
        centerTitle: true,
        title: Text('About', style: TextStyle(color: Colors.white, fontFamily: 'Cursive')),
      ),
    );
  }
}