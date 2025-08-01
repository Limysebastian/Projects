import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Folder Manager',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
        home: const MyFolder(),
        navigatorKey: navigatorKey,
      );
}

class FolderData {
  String name, panNumber, panName, aadhaarNumber, aadhaarName, documentName, documentNumber, documentPath, urlName, urlLink, notes;
  DateTime createdAt;
  FolderData({
    required this.name,
    this.panNumber = '',
    this.panName = '',
    this.aadhaarNumber = '',
    this.aadhaarName = '',
    this.documentName = '',
    this.documentNumber = '',
    this.documentPath = '',
    this.urlName = '',
    this.urlLink = '',
    this.notes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'panNumber': panNumber,
        'panName': panName,
        'aadhaarNumber': aadhaarNumber,
        'aadhaarName': aadhaarName,
        'documentName': documentName,
        'documentNumber': documentNumber,
        'documentPath': documentPath,
        'urlName': urlName,
        'urlLink': urlLink,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FolderData.fromJson(Map<String, dynamic> json) => FolderData(
        name: json['name'] ?? '',
        panNumber: json['panNumber'] ?? '',
        panName: json['panName'] ?? '',
        aadhaarNumber: json['aadhaarNumber'] ?? '',
        aadhaarName: json['aadhaarName'] ?? '',
        documentName: json['documentName'] ?? '',
        documentNumber: json['documentNumber'] ?? '',
        documentPath: json['documentPath'] ?? '',
        urlName: json['urlName'] ?? '',
        urlLink: json['urlLink'] ?? '',
        notes: json['notes'] ?? '',
        createdAt: DateTime.parse(json['createdAt']),
      );

  int get documentCount => [
        panNumber.isNotEmpty,
        aadhaarNumber.isNotEmpty,
        documentName.isNotEmpty || documentNumber.isNotEmpty,
        urlLink.isNotEmpty,
        notes.isNotEmpty
      ].where((e) => e).length;
}

class MyFolder extends StatefulWidget {
  const MyFolder({super.key});
  @override
  State<MyFolder> createState() => _MyFolderState();
}

class _MyFolderState extends State<MyFolder> with TickerProviderStateMixin {
  List<FolderData> folders = [];
  late AnimationController _controller;
  late Animation<double> _fade;
  final lightBlue = const Color(0xFF81D4FA);
  final black = const Color(0xFF000000);
  final white = const Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _loadFolders();
    _controller = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadFolders() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => folders = (prefs.getStringList('folders') ?? [])
        .map((f) => FolderData.fromJson(json.decode(f)))
        .toList());
  }

  Future<void> _saveFolders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('folders', folders.map((f) => json.encode(f.toJson())).toList());
  }

  void _addFolder(FolderData folder) => setState(() {
        folders.add(folder);
        _saveFolders();
      });

  void _updateFolder(FolderData folder, int index) => setState(() {
        folders[index] = folder;
        _saveFolders();
      });

  void _deleteFolder(int index) => setState(() {
        folders.removeAt(index);
        _saveFolders();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder deleted'), backgroundColor: Colors.green),
        );
      });

  void _showCreateFolderDialog() => showDialog(
        context: context,
        builder: (_) => CreateEditFolderDialog(onFolderSaved: _addFolder),
      );

  void _showEditFolderDialog(FolderData folder, int index) => showDialog(
        context: context,
        builder: (_) => CreateEditFolderDialog(
          folderToEdit: folder,
          onFolderSaved: (f) => _updateFolder(f, index),
        ),
      );

  void _showFolderDetails(FolderData folder) => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => FolderDetailPage(
            folder: folder,
            onDeleteLink: (updatedFolder) {
              final index = folders.indexWhere((f) => f.createdAt == folder.createdAt);
              if (index != -1) {
                _updateFolder(updatedFolder, index);
              }
            },
          ),
          transitionsBuilder: (_, a, __, c) => SlideTransition(
            position: a.drive(Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)),
            child: c,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [lightBlue.withOpacity(0.8), black], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
            ),
          ),
          title: Text(
            'Folder Manager',
            style: TextStyle(
              color: white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1.2,
              shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4)],
            ),
          ),
          iconTheme: IconThemeData(color: white),
          leading: Container(
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [white.withOpacity(0.2), white.withOpacity(0.1)]),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [black, black.withOpacity(0.8), Colors.black87],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [lightBlue.withOpacity(0.1), white.withOpacity(0.05)]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: lightBlue.withOpacity(0.3)),
                      boxShadow: [BoxShadow(color: lightBlue.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [lightBlue, black]),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: lightBlue.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
                          ),
                          child: Icon(Icons.folder_open, color: white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Folder Manager', style: TextStyle(color: white, fontSize: 16, fontWeight: FontWeight.bold)),
                              const Text('Organize your documents', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: folders.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              itemCount: folders.length,
                              itemBuilder: (_, index) => _FolderCard(
                                folder: folders[index],
                                index: index,
                                onTap: _showFolderDetails,
                                onEdit: _showEditFolderDialog,
                                onDelete: _deleteFolder,
                              ),
                            ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: white.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_sync_outlined, color: lightBlue, size: 16),
                        const SizedBox(width: 8),
                        Text('Folders synced & secured', style: TextStyle(color: white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateFolderDialog,
          backgroundColor: Colors.transparent,
          elevation: 6,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [lightBlue, black], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: lightBlue.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Center(child: Icon(Icons.add, color: white, size: 24)),
          ),
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📂', style: TextStyle(fontSize: 64, color: white)),
            const SizedBox(height: 16),
            Text('No folders yet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: lightBlue, shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4)])),
            const SizedBox(height: 8),
            Text('Tap + to create your first folder', style: TextStyle(fontSize: 14, color: white.withOpacity(0.7))),
          ],
        ),
      );
}

class _FolderCard extends StatefulWidget {
  final FolderData folder;
  final int index;
  final Function(FolderData) onTap;
  final Function(FolderData, int) onEdit;
  final Function(int) onDelete;

  const _FolderCard({
    required this.folder,
    required this.index,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_FolderCard> createState() => _FolderCardState();
}

class _FolderCardState extends State<_FolderCard> {
  bool _showEdit = false;

  @override
  Widget build(BuildContext context) {
    final lightBlue = const Color(0xFF81D4FA);
    final black = const Color(0xFF000000);
    final white = const Color(0xFFFFFFFF);
    return AnimatedContainer(
      duration: Duration(milliseconds: 200 + (widget.index * 100)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: lightBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
            BoxShadow(color: black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() => _showEdit = !_showEdit);
              widget.onTap(widget.folder);
            },
            onLongPress: () => widget.onEdit(widget.folder, widget.index),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [black, lightBlue.withOpacity(0.6), black.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: white.withOpacity(0.2)),
                    ),
                    child: Icon(Icons.folder, color: white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.folder.name,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: white, shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 2)]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.folder.documentCount} item${widget.folder.documentCount != 1 ? 's' : ''}',
                          style: TextStyle(fontSize: 12, color: white.withOpacity(0.8), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (_showEdit)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.edit, color: white, size: 16),
                            onPressed: () => widget.onEdit(widget.folder, widget.index),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red, size: 16),
                          onPressed: () => widget.onDelete(widget.index),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CreateEditFolderDialog extends StatefulWidget {
  final Function(FolderData) onFolderSaved;
  final FolderData? folderToEdit;

  const CreateEditFolderDialog({super.key, required this.onFolderSaved, this.folderToEdit});

  @override
  State<CreateEditFolderDialog> createState() => _CreateEditFolderDialogState();
}

class _CreateEditFolderDialogState extends State<CreateEditFolderDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _folderNameController, _notesController;
  List<Map<String, dynamic>> cardEntries = [], documentEntries = [], urlEntries = [];
  final lightBlue = const Color(0xFF81D4FA);
  final black = const Color(0xFF000000);
  final white = const Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _folderNameController = TextEditingController(text: widget.folderToEdit?.name ?? '');
    _notesController = TextEditingController(text: widget.folderToEdit?.notes ?? '');
    if (widget.folderToEdit == null) {
      cardEntries.add({'name': '', 'number': ''});
      documentEntries.add({'name': '', 'file': '', 'path': ''});
      urlEntries.add({'name': '', 'link': ''});
    } else {
      if (widget.folderToEdit!.panNumber.isNotEmpty || widget.folderToEdit!.panName.isNotEmpty) {
        cardEntries.add({'name': widget.folderToEdit!.panName, 'number': widget.folderToEdit!.panNumber});
      }
      if (widget.folderToEdit!.aadhaarNumber.isNotEmpty || widget.folderToEdit!.aadhaarName.isNotEmpty) {
        cardEntries.add({'name': widget.folderToEdit!.aadhaarName, 'number': widget.folderToEdit!.aadhaarNumber});
      }
      if (widget.folderToEdit!.documentName.isNotEmpty || widget.folderToEdit!.documentNumber.isNotEmpty || widget.folderToEdit!.documentPath.isNotEmpty) {
        documentEntries.add({'name': widget.folderToEdit!.documentName, 'file': widget.folderToEdit!.documentNumber, 'path': widget.folderToEdit!.documentPath});
      }
      if (widget.folderToEdit!.urlName.isNotEmpty || widget.folderToEdit!.urlLink.isNotEmpty) {
        urlEntries.add({'name': widget.folderToEdit!.urlName, 'link': widget.folderToEdit!.urlLink});
      }
    }
  }

  Future<void> _pickDocument(int index) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'txt']);
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          documentEntries[index]['file'] = result.files.first.name;
          documentEntries[index]['path'] = result.files.first.path ?? '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _saveFolder() {
    if (_formKey.currentState!.validate()) {
      widget.onFolderSaved(FolderData(
        name: _folderNameController.text.trim(),
        panNumber: cardEntries.isNotEmpty ? cardEntries[0]['number'] ?? '' : '',
        panName: cardEntries.isNotEmpty ? cardEntries[0]['name'] ?? '' : '',
        aadhaarNumber: cardEntries.length > 1 ? cardEntries[1]['number'] ?? '' : '',
        aadhaarName: cardEntries.length > 1 ? cardEntries[1]['name'] ?? '' : '',
        documentName: documentEntries.isNotEmpty ? documentEntries[0]['name'] ?? '' : '',
        documentNumber: documentEntries.isNotEmpty ? documentEntries[0]['file'] ?? '' : '',
        documentPath: documentEntries.isNotEmpty ? documentEntries[0]['path'] ?? '' : '',
        urlName: urlEntries.isNotEmpty ? urlEntries[0]['name'] ?? '' : '',
        urlLink: urlEntries.isNotEmpty ? urlEntries[0]['link'] ?? '' : '',
        notes: _notesController.text.trim(),
        createdAt: widget.folderToEdit?.createdAt ?? DateTime.now(),
      ));
      Navigator.pop(context);
    }
  }

  void _addCardEntry() => setState(() => cardEntries.add({'name': '', 'number': ''}));
  void _addDocumentEntry() => setState(() => documentEntries.add({'name': '', 'file': '', 'path': ''}));
  void _addUrlEntry() => setState(() => urlEntries.add({'name': '', 'link': ''}));
  void _removeCardEntry(int index) => setState(() => cardEntries.removeAt(index));
  void _removeDocumentEntry(int index) => setState(() => documentEntries.removeAt(index));
  void _removeUrlEntry(int index) => setState(() => urlEntries.removeAt(index));

  @override
  Widget build(BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [lightBlue, black.withOpacity(0.05)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: lightBlue.withOpacity(0.3)),
            boxShadow: [BoxShadow(color: lightBlue.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.folderToEdit == null ? 'New Folder' : 'Edit Folder',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: black, shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4)]),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _folderNameController,
                    decoration: InputDecoration(
                      labelText: 'Folder Name',
                      labelStyle: TextStyle(color: black.withOpacity(0.7)),
                      filled: true,
                      fillColor: white.withOpacity(0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: lightBlue.withOpacity(0.3))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: lightBlue)),
                      prefixIcon: Icon(Icons.folder, color: black),
                    ),
                    style: TextStyle(color: black),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  ..._buildSection('Cards & IDs', cardEntries, _buildCardEntry),
                  if (cardEntries.isEmpty) _buildAddButton('Add Card/ID', _addCardEntry),
                  ..._buildSection('Documents', documentEntries, _buildDocumentEntry),
                  if (documentEntries.isEmpty) _buildAddButton('Add Document', _addDocumentEntry),
                  ..._buildSection('URL Links', urlEntries, _buildUrlEntry),
                  if (urlEntries.isEmpty) _buildAddButton('Add URL', _addUrlEntry),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      labelStyle: TextStyle(color: white.withOpacity(0.7)),
                      filled: true,
                      fillColor: white.withOpacity(0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: lightBlue.withOpacity(0.3))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: lightBlue)),
                      prefixIcon: Icon(Icons.notes, color: black),
                    ),
                    style: TextStyle(color: black),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            backgroundColor: white.withOpacity(0.1),
                            foregroundColor: white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: BorderSide(color: white.withOpacity(0.2)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveFolder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: BorderSide(color: lightBlue.withOpacity(0.3)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(widget.folderToEdit == null ? 'Create' : 'Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  List<Widget> _buildSection(String title, List<Map<String, dynamic>> entries, Widget Function(int) builder) => entries.isEmpty
      ? []
      : [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: black, shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 2)])),
          const SizedBox(height: 8),
          ...List.generate(entries.length, builder),
          _buildAddButton('Add Another', () {
            if (title.contains('Card')) _addCardEntry();
            else if (title.contains('Document')) _addDocumentEntry();
            else _addUrlEntry();
          }),
          const SizedBox(height: 12),
        ];

  Widget _buildCardEntry(int index) => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: cardEntries[index]['name'],
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: black.withOpacity(0.7)),
                    filled: true,
                    fillColor: white.withOpacity(0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: lightBlue.withOpacity(0.3))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: lightBlue)),
                  ),
                  style: TextStyle(color: black),
                  onChanged: (v) => cardEntries[index]['name'] = v,
                ),
              ),
              IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _removeCardEntry(index)),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: cardEntries[index]['number'],
            decoration: InputDecoration(
              labelText: 'Number',
              labelStyle: TextStyle(color: black.withOpacity(0.7)),
              filled: true,
              fillColor: white.withOpacity(0.1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: lightBlue.withOpacity(0.3))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: lightBlue)),
            ),
            style: TextStyle(color: black),
            onChanged: (v) => cardEntries[index]['number'] = v,
          ),
          const SizedBox(height: 12),
        ],
      );

  Widget _buildDocumentEntry(int index) => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: documentEntries[index]['name'],
                  decoration: InputDecoration(
                    labelText: 'Document Name',
                    labelStyle: TextStyle(color: black.withOpacity(0.7)),
                    filled: true,
                    fillColor: white.withOpacity(0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: lightBlue.withOpacity(0.3))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: lightBlue)),
                  ),
                  style: TextStyle(color: black),
                  onChanged: (v) => documentEntries[index]['name'] = v,
                ),
              ),
              IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _removeDocumentEntry(index)),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _pickDocument(index),
            child: IgnorePointer(
              child: TextFormField(
                controller: TextEditingController(text: documentEntries[index]['file']),
                decoration: InputDecoration(
                  labelText: documentEntries[index]['file'].isEmpty ? 'Tap to select file' : 'Selected file',
                  labelStyle: TextStyle(color: black.withOpacity(0.7)),
                  filled: true,
                  fillColor: documentEntries[index]['file'].isNotEmpty ? Colors.green.withOpacity(0.1) : white.withOpacity(0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: lightBlue.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: lightBlue)),
                  suffixIcon: Icon(Icons.attach_file, color: black),
                ),
                style: TextStyle(color: black),
              ),
            ),
          ),
          if (documentEntries[index]['path'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(documentEntries[index]['path'], style: TextStyle(color: white.withOpacity(0.7), fontSize: 12, overflow: TextOverflow.ellipsis)),
            ),
          const SizedBox(height: 12),
        ],
      );

  Widget _buildUrlEntry(int index) => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: urlEntries[index]['name'],
                  decoration: InputDecoration(
                    labelText: 'Link Name',
                    labelStyle: TextStyle(color: black.withOpacity(0.7)),
                    filled: true,
                    fillColor: white.withOpacity(0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: lightBlue.withOpacity(0.3))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: lightBlue)),
                  ),
                  style: TextStyle(color: black),
                  onChanged: (v) => urlEntries[index]['name'] = v,
                ),
              ),
              IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _removeUrlEntry(index)),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: urlEntries[index]['link'],
            decoration: InputDecoration(
              labelText: 'URL',
              labelStyle: TextStyle(color: black.withOpacity(0.7)),
              filled: true,
              fillColor: white.withOpacity(0.1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: lightBlue.withOpacity(0.3))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: lightBlue)),
            ),
            style: TextStyle(color: black),
            onChanged: (v) => urlEntries[index]['link'] = v,
          ),
          const SizedBox(height: 12),
        ],
      );

  Widget _buildAddButton(String text, VoidCallback onPressed) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(Icons.add, color: white, size: 16),
          label: Text(text, style: TextStyle(color: white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: BorderSide(color: lightBlue.withOpacity(0.3)),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          ),
        ),
      );
}

class FolderDetailPage extends StatelessWidget {
  final FolderData folder;
  final Function(FolderData)? onDeleteLink;
  final lightBlue = const Color(0xFF81D4FA);
  final black = const Color(0xFF000000);
  final white = const Color(0xFFFFFFFF);

  const FolderDetailPage({super.key, required this.folder, this.onDeleteLink});

  Future<void> _launchUrl(String url) async {
    if (!url.startsWith('http')) url = 'https://$url';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          const SnackBar(content: Text('Could not launch URL'), backgroundColor: Colors.red));
    }
  }

  Future<void> _viewDocument(String path) async {
    try {
      final result = await OpenFile.open(path);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            SnackBar(content: Text('Error: ${result.message}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _deleteLink() {
    final updatedFolder = FolderData(
      name: folder.name,
      panNumber: folder.panNumber,
      panName: folder.panName,
      aadhaarNumber: folder.aadhaarNumber,
      aadhaarName: folder.aadhaarName,
      documentName: folder.documentName,
      documentNumber: folder.documentNumber,
      documentPath: folder.documentPath,
      urlName: '',
      urlLink: '',
      notes: folder.notes,
      createdAt: folder.createdAt,
    );
    onDeleteLink?.call(updatedFolder);
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      const SnackBar(content: Text('URL deleted'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [lightBlue.withOpacity(0.8), black], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
            ),
          ),
          title: Text(
            folder.name,
            style: TextStyle(
              color: white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1.2,
              shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4)],
            ),
          ),
          iconTheme: IconThemeData(color: white),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [black, black.withOpacity(0.8), Colors.black87],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: folder.documentCount == 0
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('📄', style: TextStyle(fontSize: 48, color: white)),
                        const SizedBox(height: 16),
                        Text('No documents in this folder',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: lightBlue, shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4)])),
                        const SizedBox(height: 8),
                        Text('This folder is empty', style: TextStyle(fontSize: 14, color: white.withOpacity(0.7))),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (folder.panNumber.isNotEmpty || folder.panName.isNotEmpty)
                        _buildDetailCard('📄 ${folder.panName.isNotEmpty ? folder.panName : 'PAN Card'}', [
                          if (folder.panNumber.isNotEmpty) _buildDetailRow('Number:', folder.panNumber),
                        ]),
                      if (folder.aadhaarNumber.isNotEmpty || folder.aadhaarName.isNotEmpty)
                        _buildDetailCard('🆔 ${folder.aadhaarName.isNotEmpty ? folder.aadhaarName : 'Aadhaar'}', [
                          if (folder.aadhaarNumber.isNotEmpty) _buildDetailRow('Number:', folder.aadhaarNumber),
                        ]),
                      if (folder.documentName.isNotEmpty || folder.documentNumber.isNotEmpty || folder.documentPath.isNotEmpty)
                        _buildDetailCard('📎 ${folder.documentName.isNotEmpty ? folder.documentName : 'Document'}', [
                          if (folder.documentNumber.isNotEmpty) _buildDetailRow('File:', folder.documentNumber),
                          if (folder.documentPath.isNotEmpty)
                            InkWell(
                              onTap: () => _viewDocument(folder.documentPath),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.link, color: lightBlue),
                                    const SizedBox(width: 8),
                                    Text('View Document', style: TextStyle(color: lightBlue, decoration: TextDecoration.underline)),
                                  ],
                                ),
                              ),
                            ),
                        ]),
                      if (folder.urlName.isNotEmpty || folder.urlLink.isNotEmpty)
                        _buildDetailCard('🔗 ${folder.urlName.isNotEmpty ? folder.urlName : 'Link'}', [
                          InkWell(
                            onTap: () => _launchUrl(folder.urlLink),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(folder.urlLink, style: TextStyle(color: lightBlue, decoration: TextDecoration.underline)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: _deleteLink,
                            ),
                          ),
                        ]),
                      if (folder.notes.isNotEmpty)
                        _buildDetailCard('📝 Notes', [Text(folder.notes, style: TextStyle(color: black.withOpacity(0.7)))]),
                    ],
                  ),
          ),
        ),
      );

  Widget _buildDetailCard(String title, List<Widget> children) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: lightBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
            BoxShadow(color: black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [black, lightBlue.withOpacity(0.4), black.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, color: white, fontSize: 16, shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 2)]),
              ),
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
      );

  Widget _buildDetailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label ', style: TextStyle(fontWeight: FontWeight.bold, color: white)),
            Expanded(child: Text(value, style: TextStyle(color: white.withOpacity(0.7)))),
          ],
        ),
      );
}

final navigatorKey = GlobalKey<NavigatorState>();