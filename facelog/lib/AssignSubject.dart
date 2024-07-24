import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AssignSubjectPage extends StatefulWidget {
  final String adminId;

  const AssignSubjectPage({Key? key, required this.adminId}) : super(key: key);

  @override
  _AssignSubjectPageState createState() => _AssignSubjectPageState();
}

class _AssignSubjectPageState extends State<AssignSubjectPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  List<String> subjects = [];
  String? selectedSubject;
  String? selectedTeacher;
  Map<String, dynamic> teachers = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    _database.child('subjects').once().then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        setState(() {
          subjects = List<String>.from(snapshot.value as List<dynamic>);
        });
      }
    });

    _database.child('users').child('teachers').once().then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        setState(() {
          teachers = Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
        });
      }
    });
  }


  void _assignSubjectToTeacher() {
    if (selectedSubject != null && selectedTeacher != null) {
      // Check if the teacher exists in the database
      if (teachers.containsKey(selectedTeacher)) {
        // Check if the subject is already assigned to the teacher
        if (teachers[selectedTeacher!]!.containsKey('subject')) {
          List<dynamic> teacherSubjects = List.from(teachers[selectedTeacher!]!['subject']);
          if (teacherSubjects.contains(selectedSubject)) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Subject already assigned to the teacher')));
            return;
          }
          teacherSubjects.add(selectedSubject);
          _database
              .child('users')
              .child('teachers')
              .child(selectedTeacher!)
              .child('subject')
              .set(teacherSubjects)
              .then((_) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Subject assigned successfully')));
          }).catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to assign subject')));
          });
        } else {
          _database
              .child('users')
              .child('teachers')
              .child(selectedTeacher!)
              .child('subject')
              .set([selectedSubject])
              .then((_) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Subject assigned successfully')));
          }).catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to assign subject')));
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected teacher does not exist')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select both subject and teacher')));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assign Subject'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Subject:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: selectedSubject,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedSubject = newValue;
                  });
                },
                items: subjects.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              Text(
                'Select Teacher:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: selectedTeacher,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedTeacher = newValue;
                  });
                },
                items: teachers.keys.map<DropdownMenuItem<String>>((String teacherId) {
                  return DropdownMenuItem<String>(
                    value: teacherId,
                    child: Text(teachers[teacherId]['name']),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _assignSubjectToTeacher,
                child: Text('Assign Subject'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
