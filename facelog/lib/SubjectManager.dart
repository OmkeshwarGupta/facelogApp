import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SubjectManagerPage extends StatefulWidget {
  @override
  _SubjectManagerPageState createState() => _SubjectManagerPageState();
}

class _SubjectManagerPageState extends State<SubjectManagerPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  TextEditingController _subjectController = TextEditingController();
  List<String> _subjects = [];

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  void _fetchSubjects() {
    _database.child('subjects').once().then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      setState(() {
        if (snapshot.value != null) {
          _subjects = List<String>.from(snapshot.value as List<dynamic>);
        } else {
          _subjects = [];
        }
      });
    });
  }

  void _addSubject(String newSubject) {
    if (newSubject.isNotEmpty) {
      // Get the current number of subjects to determine the index
      int newIndex = _subjects.length;

      // Set the new subject with the index as the key
      _database.child('subjects').child(newIndex.toString()).set(newSubject).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Subject added successfully')));
        _subjectController.clear();
        _fetchSubjects(); // Refresh the subject list after adding
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add subject')));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a subject')));
    }
  }


  void _removeSubject(String subject) {
    // Find the index of the subject to delete
    int index = _subjects.indexOf(subject);

    if (index != -1) {
      // Get the corresponding key from the database
      String key = index.toString();

      // Remove the subject using the key
      _database.child('subjects').child(key).remove().then((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Subject removed successfully')));
        _fetchSubjects(); // Refresh the subject list after removal
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove subject')));
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subject Manager'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: 'Subject Name',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _addSubject(_subjectController.text.trim()),
              child: Text('Add Subject'),
            ),
            SizedBox(height: 20),
            Text(
              'Current Subjects:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _subjects.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_subjects[index]),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _removeSubject(_subjects[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
