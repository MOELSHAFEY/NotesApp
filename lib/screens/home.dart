import 'package:flutter/material.dart';
import 'package:sql/logic/db.dart';
import 'package:sql/models/note.dart';
import 'package:sql/screens/AddEditNote.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DatabaseHelper db = DatabaseHelper();
  late Future<List<Note>> notesFuture;
  final List<Color> cardColors = [
    const Color(0xFFE3F2FD),
    const Color(0xFFE8F5E9),
    const Color(0xFFFFF8E1),
    const Color(0xFFF3E5F5),
    const Color(0xFFE0F7FA),
    const Color(0xFFFFEBEE),
  ];

  @override
  void initState() {
    super.initState();
    refreshNotes();
  }

  void refreshNotes() {
    setState(() {
      notesFuture = db.getNotes();
    });
  }

  Color getCardColor(int index) {
    return cardColors[index % cardColors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notes App',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24)),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepPurple,
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const Addeditnote()),
          );
          refreshNotes();
        },
        label: const Text('New Note', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      body: FutureBuilder<List<Note>>(
        future: notesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}',
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: refreshNotes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Retry',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_add_outlined,
                      size: 80, color: Colors.grey.withOpacity(0.4)),
                  const SizedBox(height: 24),
                  const Text('No Notes Yet',
                      style: TextStyle(
                          fontSize: 22,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Text('Tap + to create your first note',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.5)),
                ],
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                itemCount: snapshot.data!.length,
                itemBuilder: (BuildContext context, int index) {
                  final note = snapshot.data![index];
                  return _buildNoteCard(note, context, index);
                },
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildNoteCard(Note note, BuildContext context, int index) {
    final cardColor = getCardColor(index);
    final textColor = _getTextColorBasedOnBackground(cardColor);

    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => Addeditnote(note: note)),
        );
        refreshNotes();
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      note.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withOpacity(0.8),
                      ),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: textColor.withOpacity(0.7)),
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
                onSelected: (String value) async {
                  if (value == 'edit') {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => Addeditnote(note: note)),
                    );
                    refreshNotes();
                  } else if (value == 'delete') {
                    await _showDeleteDialog(note);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTextColorBasedOnBackground(Color backgroundColor) {
    // Calculate the luminance of the background color
    final luminance = backgroundColor.computeLuminance();
    // Use white text for dark backgrounds and black for light backgrounds
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }


  Future<void> _showDeleteDialog(Note note) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Note'),
          content: const Text('This note will be permanently deleted.'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.deepPurple)),
            ),
            TextButton(
              onPressed: () async {
                await db.deleteNote(note.id!);
                refreshNotes();
                if (mounted) Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Note deleted'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                  )),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}