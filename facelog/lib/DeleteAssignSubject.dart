import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DeleteAssignSubjectPage extends StatefulWidget {
  @override
  _DeleteAssignSubjectPageState createState() => _DeleteAssignSubjectPageState();
}

class _DeleteAssignSubjectPageState extends State<DeleteAssignSubjectPage> {
  final databaseReference = FirebaseDatabase.instance.reference();
  final DatabaseReference _teachersRef = FirebaseDatabase.instance.reference().child('users/teachers');

  List<Map<String, String>> teachers = [];
  Map<String, List<String>> teacherSubjects = {};
  String? selectedTeacherId; // Initialize as null
  List<String> subjects = [];

  @override
  void initState() {
    super.initState();
    _fetchTeachers(); // Fetch teachers when widget initializes
  }

  void _fetchTeachers() {
    _teachersRef.once().then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
      List<Map<String, String>> teacherList = [];
      if (values != null) {
        values.forEach((key, value) {
          String id = key as String;
          String name = value['name'] as String;
          teacherList.add({'id': id, 'name': name});
        });
      }
      setState(() {
        teachers = teacherList;
        if (teachers.isNotEmpty) {
          selectedTeacherId = teachers[0]['id']; // Set the default value to the first teacher's ID
          fetchSubjectsForTeacher(selectedTeacherId!); // Ensure it's non-null
        }
      });
    }).catchError((error) {
      print("Error fetching teachers: $error");
    });
  }

  void fetchSubjectsForTeacher(String teacherId) {
    DatabaseReference subjectsRef = databaseReference.child('users/teachers/$teacherId/subject');
    subjectsRef.once().then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      print("Subjects snapshot: ${snapshot.value}");
      if (snapshot.value != null) {
        List<dynamic> subjectList = snapshot.value as List<dynamic>;
        setState(() {
          subjects = subjectList.cast<String>().toList();
        });
      } else {
        setState(() {
          subjects = []; // Reset subjects list if no subjects found for the teacher
        });
      }
    }).catchError((error) {
      print("Error fetching subjects for $teacherId: $error");
    });
  }

  Future<void> deleteSubject(String teacherId, String subject) async {
    try {
      if (teacherId != null) {
        DatabaseReference teacherRef = databaseReference.child('users/teachers/$teacherId');
        teacherRef.once().then((DatabaseEvent  event) {
          DataSnapshot snapshot = event.snapshot;
          Map<dynamic, dynamic>? teacherData = snapshot.value as Map<dynamic, dynamic>?;
          if (teacherData != null && teacherData.containsKey('subject')) {
            List<dynamic> teacherSubjects = List.from(teacherData['subject']);
            if (teacherSubjects.contains(subject)) {
              teacherSubjects.remove(subject);
              teacherRef.child('subject').set(teacherSubjects).then((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Subject deleted successfully.')),
                );
                setState(() {
                  subjects.remove(subject);
                });
              }).catchError((error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete subject.')),
                );
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Subject not found for teacher.')),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No subjects found for teacher.')),
            );
          }
        }).catchError((error) {
          print("Error fetching teacher data: $error");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete subject.')),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Teacher ID is null.')),
        );
      }
    } catch (error) {
      print("Error deleting subject: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete subject.')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delete Assign Subject'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: selectedTeacherId,
              items: teachers.map((teacher) {
                return DropdownMenuItem<String>(
                  value: teacher['id']!,
                  child: Text(teacher['name']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedTeacherId = value; // No need for null assertion here
                  fetchSubjectsForTeacher(selectedTeacherId!); // Ensure it's non-null
                });
              },
              decoration: InputDecoration(
                labelText: 'Select Teacher',
              ),
            ),
            SizedBox(height: 20.0),
            Text(
              'Subjects:',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10.0),
            ListView.builder(
              shrinkWrap: true,
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(subjects[index]),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Confirm Deletion'),
                          content: Text('Are you sure you want to delete this subject?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                deleteSubject(selectedTeacherId!, subjects[index]); // Ensure it's non-null
                                setState(() {
                                  subjects.removeAt(index);
                                });
                                Navigator.pop(context);
                              },
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
