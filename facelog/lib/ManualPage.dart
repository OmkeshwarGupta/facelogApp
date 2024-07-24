import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ManualPage extends StatefulWidget {
  final String subjectId;

  ManualPage({Key? key, required this.subjectId}) : super(key: key);

  @override
  _ManualPageState createState() => _ManualPageState();
}

class _ManualPageState extends State<ManualPage> {
  late List<Map<String, dynamic>> absentStudents;
  late List<bool> studentSelections; // Track selection status of students
  late DatabaseReference _databaseReference;

  @override
  void initState() {
    super.initState();
    absentStudents = [];
    studentSelections = []; // Initialize the selection list
    _databaseReference = FirebaseDatabase.instance.reference();
    _getAbsentStudents();
  }

  void _getAbsentStudents() {
    _databaseReference
        .child('attendance')
        .child(widget.subjectId)
        .once()
        .then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        Map<dynamic, dynamic> attendanceData =
        snapshot.value as Map<dynamic, dynamic>;
        attendanceData.forEach((studentId, attendanceList) {
          List<dynamic> attendance = List.from(attendanceList);
          Map<String, dynamic> latestAttendance =
          attendance.isNotEmpty ? Map.from(attendance.last) : {};
          if (latestAttendance['status'] == 'Absent') {
            Map<String, dynamic> studentData = {
              'id': studentId,
              'name': _getStudentName(studentId),
            };
            absentStudents.add(studentData);
            studentSelections.add(false); // Initialize selection status to false
          }
        });
        setState(() {});
      }
    });
  }

  String _getStudentName(String studentId) {
    return _databaseReference
        .child('users')
        .child('students')
        .child(studentId)
        .child('name')
        .toString() ??
        '';
  }

  void _markPresent(List<Map<String, dynamic>> selectedStudents) {
    selectedStudents.forEach((student) {
      String studentId = student['id'];
      _databaseReference
          .child('attendance')
          .child(widget.subjectId)
          .child(studentId)
          .orderByChild('date_time')
          .limitToLast(1)
          .once()
          .then((DatabaseEvent event) {
        DataSnapshot snapshot = event.snapshot;
        if (snapshot.value != null) {
          Map<dynamic, dynamic> attendanceData =
          snapshot.value as Map<dynamic, dynamic>;
          attendanceData.forEach((key, value) {
            _databaseReference
                .child('attendance')
                .child(widget.subjectId)
                .child(studentId)
                .child(key)
                .update({'status': 'Present'});
          });
        }
      });
    });

    // Show SnackBar message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Attendance Updated'),
      ),
    );

    // Close the page after marking present
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Absent Students'),
      ),
      backgroundColor: Colors.deepPurple.shade100, // Set background color
      body: ListView.builder(
        itemCount: absentStudents.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('(${index + 1}) ${absentStudents[index]['id']} '),
            trailing: Checkbox(
              value: studentSelections[index],
              // Update value based on selection list
              onChanged: (bool? value) {
                setState(() {
                  studentSelections[index] =
                      value ?? false; // Update selection status
                });
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _markPresent(absentStudents
              .where((student) => studentSelections[absentStudents.indexOf(student)])
              .toList());
        },
        backgroundColor: Colors.white, // Set button color to white
        child: Icon(Icons.check),
      ),
    );
  }
}
