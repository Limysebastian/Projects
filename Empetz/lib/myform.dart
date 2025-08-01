import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:miniproject/pets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Myform extends StatefulWidget {
  const Myform({super.key});

  @override
  State<Myform> createState() => _MyformState();
}

class _MyformState extends State<Myform> {
  List<dynamic> petsname = [];
  String? selectedCategoryId;
  String? selectedCategoryName;
  List<dynamic> breedsname = [];
  String? selectedBreedId;
  String? selectedBreedName;
  List<dynamic> locations = [];
  String? selectedLocationId;
  String? selectedLocationName;

  final TextEditingController NameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController vaccinatedController = TextEditingController();
  final TextEditingController petController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController adressController = TextEditingController();

  String? NameError;
  String? ageError;
  String? heightError;
  String? weightdError;
  String? petdError;
  String? pricedError;
  String? adressError;

  List<String> _locations1 = ['Male', 'Female'];
  String? _selectedLocation1;

 File? _pickedImage; // Image file

  final picker = ImagePicker(); // ImagePicker instance


  @override
  void initState() {
    super.initState();
    getpetsname();
    getlocation();
  }

  Future<void> getpetsname() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('token not found')));
      return;
    }
    final url = Uri.parse('http://192.168.1.35/Empetz/api/v1/category');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      setState(() => petsname = data);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('failed to fetch categories')));
    }
  }

  Future<void> getbreedsname(String categoryId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('token not found')));
      return;
    }
    final url = Uri.parse('http://192.168.1.35/Empetz/api/v1/breed/category/$categoryId');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      setState(() {
        breedsname = data;
        selectedBreedId = null;
        selectedBreedName = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('failed to fetch breeds')));
    }
  }

  Future<void> getlocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('token not found')));
      return;
    }
    final url = Uri.parse('http://192.168.1.35/Empetz/api/v1/location');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      setState(() {
        locations = data;
        selectedLocationId = null;
        selectedLocationName = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('failed to fetch locations')));
    }
  }

 Future<void> senddata() async {
  final url = Uri.parse("http://192.168.1.35/Empetz/api/v1/pet");
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('auth_token');

  if (token == null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Token not found')));
    return;
  }

  var request = http.MultipartRequest('POST', url)
    ..headers['Authorization'] = 'Bearer $token'
    ..fields['Name'] = NameController.text.trim()
    ..fields['height'] = heightController.text.trim()
    ..fields['Price'] = priceController.text.trim()
    ..fields['Address'] = adressController.text.trim()
    ..fields['Discription'] = petController.text.trim()
    ..fields['weight'] = weightController.text.trim()
    ..fields['Age'] = ageController.text.trim()
    ..fields['BreedId'] = selectedBreedId!
    ..fields['LocationId'] = selectedLocationId!
    ..fields['CategoryId'] = selectedCategoryId!
    ..fields['Gender'] = _selectedLocation1!;

  
   if (_pickedImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath('ImageFile', _pickedImage!.path),
      );
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        showSnack('Pet data submitted successfully!');
      } else {
        print('Failed with status: ${response.statusCode}');
        print('Response: ${response.body}');
        showSnack('Failed to submit data!');
      }
    } catch (e) {
      print('Error: $e');
      showSnack('Something went wrong!');
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  void showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Color.fromARGB(255, 3, 44, 91),
        title: Text('Add Pet Details', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Center(
            child: Column(
              children: [
                 Container(
                height: 300,
                width: double.infinity,
                color: Colors.grey,
                child: Center(
                  child: _pickedImage == null
                      ? IconButton(
                          onPressed: pickImage,
                          icon: Icon(Icons.add_a_photo_outlined),
                        )
                      : Image.file(
                          _pickedImage!,
                          width: double.infinity,
                          height: 300,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              ],
            ),
          ),
          SizedBox(height: 20),
          TextField(
            controller: NameController,
            decoration: InputDecoration(
              labelText: 'Enter Name',
              errorText: NameError,
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => NameError = validatedname(value)),
          ),
          SizedBox(height: 20),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(border: OutlineInputBorder()),
            hint: Text('Category'),
            value: selectedCategoryName,
            onChanged: (newValue) {
              if (newValue != null) {
                final selectedCategory = petsname.firstWhere(
                  (category) => category['name'] == newValue,
                  orElse: () => {'id': null, 'name': null},
                );
                if (selectedCategory['id'] != null) {
                  setState(() {
                    selectedCategoryName = newValue;
                    selectedCategoryId = selectedCategory['id'];
                  });
                  getbreedsname(selectedCategory['id']);
                }
              }
            },
            items: petsname.map<DropdownMenuItem<String>>((category) {
              return DropdownMenuItem<String>(
                value: category['name']?.toString(),
                child: Text(category['name']?.toString() ?? ''),
              );
            }).toList(),
          ),
          SizedBox(height: 20),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(border: OutlineInputBorder()),
            hint: Text('Breed'),
            value: selectedBreedName,
            onChanged: breedsname.isEmpty
                ? null
                : (newValue) {
                    if (newValue != null) {
                      final selectedBreed = breedsname.firstWhere(
                        (breed) => breed['name'] == newValue,
                        orElse: () => {'id': null, 'name': null},
                      );
                      if (selectedBreed['id'] != null) {
                        setState(() {
                          selectedBreedName = newValue;
                          selectedBreedId = selectedBreed['id'];
                        });
                      }
                    }
                  },
            items: breedsname.map<DropdownMenuItem<String>>((breed) {
              return DropdownMenuItem<String>(
                value: breed['name']?.toString(),
                child: Text(breed['name']?.toString() ?? ''),
              );
            }).toList(),
          ),
          SizedBox(height: 20),
          TextField(
            keyboardType: TextInputType.number,
            controller: ageController,
            decoration: InputDecoration(
              labelText: 'Age',
              errorText: ageError,
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => ageError = validatedage(value)),
          ),
          SizedBox(height: 20),
          DropdownButtonFormField(
            decoration: InputDecoration(border: OutlineInputBorder()),
            hint: Text('Gender'),
            value: _selectedLocation1,
            onChanged: (newValue) => setState(() => _selectedLocation1 = newValue),
            items: _locations1.map((location) {
              return DropdownMenuItem(value: location, child: Text(location));
            }).toList(),
          ),
          SizedBox(height: 20),
          TextField(
            keyboardType: TextInputType.number,
            controller: heightController,
            decoration: InputDecoration(
              labelText: 'Height',
              errorText: heightError,
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => heightError = validatedheight(value)),
          ),
          SizedBox(height: 20),
          TextField(
            keyboardType: TextInputType.number,
            controller: weightController,
            decoration: InputDecoration(
              labelText: 'Weight',
              errorText: weightdError,
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => weightdError = validatedweight(value)),
          ),
          SizedBox(height: 20),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(border: OutlineInputBorder()),
            hint: Text('Location'),
            value: selectedLocationName,
            onChanged: (newValue) {
              if (newValue != null) {
                final selectedLocation = locations.firstWhere(
                  (location) => location['name'] == newValue,
                  orElse: () => {'id': null, 'name': null},
                );
                if (selectedLocation['id'] != null) {
                  setState(() {
                    selectedLocationName = newValue;
                    selectedLocationId = selectedLocation['id'];
                  });
                }
              }
            },
            items: locations.map<DropdownMenuItem<String>>((location) {
              return DropdownMenuItem<String>(
                value: location['name']?.toString(),
                child: Text(location['name']?.toString() ?? ''),
              );
            }).toList(),
          ),
           SizedBox(height: 20),
          
TextField(
  controller: adressController,
  maxLines: 5, 
  minLines: 3,
  decoration: InputDecoration(
    labelText: 'Adress',
    errorText: petdError,
    border: OutlineInputBorder(),
    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  ),
  onChanged: (value) => setState(() => petdError = validatedpet(value)),
),

SizedBox(height: 20),


TextField(
  controller: petController,
  maxLines: 5, // Keeps it taller than regular fields
  minLines: 3,
  decoration: InputDecoration(
    labelText: 'Description',
    errorText: petdError,
    border: OutlineInputBorder(),
    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  ),
  onChanged: (value) => setState(() => petdError = validatedpet(value)),
),
          SizedBox(height: 20),
          TextField(
            keyboardType: TextInputType.number,
            controller: priceController,
            decoration: InputDecoration(
              labelText: 'Price',
              errorText: pricedError,
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => pricedError = validatedprice(value)),
          ),
          SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                fixedSize: Size(250, 50),
                backgroundColor: Color.fromARGB(255, 3, 44, 91),
              ),
              onPressed: () async {
                setState(() {
                  NameError = validatedname(NameController.text);
                  ageError = validatedage(ageController.text);
                  heightError = validatedheight(heightController.text);
                  weightdError = validatedweight(weightController.text);
                  petdError = validatedpet(petController.text);
                  pricedError = validatedprice(priceController.text);
                });

                if ([NameError, ageError, heightError, weightdError, adressError, petdError, pricedError].every((e) => e == null) &&
    selectedCategoryId != null &&
    selectedBreedId != null &&
    _selectedLocation1 != null &&
    selectedLocationId != null &&
    ImagePicker != null) {
  
  // First send data
  await senddata();

  // Then navigate to Mypets page with category ID and name
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => Mypets(
        categoryId: selectedCategoryId!,
        categoryName: selectedCategoryName ?? '',
      ),
    ),
  );
} else {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all fields")));
}

              },
              child: Text("Submit", style: TextStyle(color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }

  String? validatedname(String name) {
    if (name.isEmpty) return 'Name cannot be empty';
    if (RegExp(r'[!@#<>?":_~;[\]\\|=+(*&^%0-9-)]').hasMatch(name)) {
      return 'Name must not contain special characters or numbers';
    }
    return null;
  }

  String? validatedage(String age) => age.isEmpty ? 'Age cannot be empty' : null;
  String? validatedheight(String height) => height.isEmpty ? 'Height cannot be empty' : null;
  String? validatedweight(String weight) => weight.isEmpty ? 'Weight cannot be empty' : null;
  String? validatedpet(String pet) {
    if (pet.isEmpty) return 'Pet name cannot be empty';
    if (RegExp(r'[!@#<>?":_~;[\]\\|=+(*&^%0-9-)]').hasMatch(pet)) {
      return 'Pet name must not contain special characters or numbers';
    }
    return null;
  }

  String? validatedprice(String price) => price.isEmpty ? 'Price cannot be empty' : null;
  String? validatedvaccinated(String Vaccinated) => Vaccinated.isEmpty ? 'Cannot be empty' : null;
  String? validatedadress(String adress) => adress.isEmpty ? 'Address cannot be empty' : null;
}
