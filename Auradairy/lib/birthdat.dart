import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class BirthdayPosterScreen extends StatefulWidget {
  @override
  _BirthdayPosterScreenState createState() => _BirthdayPosterScreenState();
}

class _BirthdayPosterScreenState extends State<BirthdayPosterScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  final GlobalKey _posterKey = GlobalKey(); // Key for capturing the poster

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Birthday Poster'),
        actions: [
          // Share button in app bar
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _sharePoster,
            tooltip: 'Share Poster',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double posterWidth = constraints.maxWidth;
                    final double circleDiameter = posterWidth * 0.35;
                    final double circleRightOffset = posterWidth * 0.20;
                    final double circleTopOffset = posterWidth * 0.15;

                    // Wrap the Stack with RepaintBoundary to capture the widget
                    return RepaintBoundary(
                      key: _posterKey,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              'asset/birthday.jpeg',
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: circleTopOffset,
                            right: circleRightOffset,
                            width: circleDiameter,
                            height: circleDiameter,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.9),
                                border: Border.all(color: Colors.pink.shade300, width: 3),
                              ),
                              child: ClipOval(
                                child: _selectedImage != null
                                    ? Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                      )
                                    : Icon(
                                        Icons.add_a_photo,
                                        size: circleDiameter * 0.6,
                                        color: Colors.grey[600],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.0),
            child: FloatingActionButton.extended(
              onPressed: _pickImage,
              label: Text('Add Photo from Gallery'),
              icon: Icon(Icons.photo_library),
              backgroundColor: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _sharePoster() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add a photo first')),
      );
      return;
    }

    try {
      // Capture the poster as an image
      final imageBytes = await _capturePoster();
      if (imageBytes == null) return;

      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/birthday_poster_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(imageBytes);

      // Show sharing options
      await showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Share Poster To', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // WhatsApp
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(Icons.chat, size: 50, color: Colors.green),
                        onPressed: () => _shareToPlatform(context, file, 'WhatsApp'),
                      ),
                      Text('WhatsApp'),
                    ],
                  ),
                  // Instagram
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(Icons.camera_alt, size: 50, color: Colors.pink),
                        onPressed: () => _shareToPlatform(context, file, 'Instagram'),
                      ),
                      Text('Instagram'),
                    ],
                  ),
                  // Other apps
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(Icons.more_horiz, size: 50),
                        onPressed: () => _shareToPlatform(context, file, 'Other Apps'),
                      ),
                      Text('Other Apps'),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing poster: $e')),
      );
    }
  }

  void _shareToPlatform(BuildContext context, File file, String platform) {
    Navigator.pop(context); // Close the bottom sheet
    
    String text = 'Check out this birthday poster!';
    if (platform == 'Instagram') {
      text = 'Check out this birthday poster! 🎉 #Birthday #Poster';
    } else if (platform == 'WhatsApp') {
      text = 'Check out this birthday poster I created! 🎂';
    }

    Share.shareXFiles(
      [XFile(file.path)],
      text: text,
    );
  }

  Future<Uint8List?> _capturePoster() async {
    try {
      final boundary = _posterKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing poster: $e')),
      );
      return null;
    }
  }
}