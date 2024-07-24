import 'package:flutter/material.dart';
import 'TeacherDashboard.dart';
import 'package:firebase_database/firebase_database.dart';

class SubjectSelectionPage extends StatefulWidget {
  final String teacherId;

  SubjectSelectionPage({required this.teacherId});

  @override
  _SubjectSelectionPageState createState() => _SubjectSelectionPageState();
}

class _SubjectSelectionPageState extends State<SubjectSelectionPage> {
  String? _selectedSubjectId;
  List<String> _subjects = []; // List to store subjects fetched from Firebase

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  void _fetchSubjects() {
    final dbRef = FirebaseDatabase.instance.reference().child("users").child("teachers").child(widget.teacherId);
    dbRef.once().then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        Map<dynamic, dynamic> teacherData = snapshot.value as Map<dynamic, dynamic>;
        if (teacherData.containsKey("subject")) {
          setState(() {
            _subjects = List<String>.from(teacherData["subject"]);
          });
        }
      }
    }).catchError((error) {
      print('Error fetching subjects: $error');
      // Handle error fetching subjects
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subject Selection'),
      ),
      body: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedSubjectId,
                hint: Text('Select Subject'),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSubjectId = newValue;
                  });
                },
                items: _subjects.map((String subject) {
                  return DropdownMenuItem<String>(
                    value: subject,
                    child: Text(subject),
                  );
                }).toList(),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_selectedSubjectId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TeacherDashboard(
                          subjectId: _selectedSubjectId!,
                        ),
                      ),
                    );
                  } else {
                    // Show error if no subject is selected
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please select a subject.'),
                      ),
                    );
                  }
                },
                child: Center(child: Text('GO')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
