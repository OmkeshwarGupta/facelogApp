import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AttendancePage extends StatefulWidget {
  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  DatabaseReference _databaseReference = FirebaseDatabase.instance.reference();
  List<String> _subjects = [];
  String _selectedSubject = '';
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  void _fetchSubjects() {
    _databaseReference.child('subjects').once().then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        setState(() {
          _subjects = List<String>.from(snapshot.value as List<dynamic>);
          _selectedSubject = _subjects.isNotEmpty ? _subjects[0] : '';
        });
      }
    }).catchError((error) {
      print('Error fetching subjects: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modify Attendance Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _processing
            ? Center(
          child: CircularProgressIndicator(),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField(
              value: _selectedSubject,
              items: _subjects.map((subject) {
                return DropdownMenuItem(
                  value: subject,
                  child: Text(subject),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedSubject = newValue.toString();
                });
              },
              decoration: InputDecoration(
                labelText: 'Select Subject',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                addAttendance();
              },
              child: Text('Add Attendance'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                deleteAttendanceConfirmation();
              },
              child: Text('Delete Attendance'),
            ),
          ],
        ),
      ),
    );
  }

  void addAttendance() {
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please select a subject.')));
      return;
    }
    setState(() {
      _processing = true;
    });
    _databaseReference
        .child('attendance')
        .child(_selectedSubject)
        .once()
        .then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Attendance data already exists for this subject.')));
      } else {
        _databaseReference
            .child('users')
            .child('students')
            .once()
            .then((DatabaseEvent event) {
          DataSnapshot snapshot = event.snapshot;
          if (snapshot.value != null) {
            Map<dynamic, dynamic> studentsData =
            snapshot.value as Map<dynamic, dynamic>;
            List<String> studentIDs =
            studentsData.keys.toList().cast<String>();
            Map<String, dynamic> attendanceData = {};
            studentIDs.forEach((studentID) {
              attendanceData[studentID] = [
                {"date_time": DateTime.now().toString().substring(0, 19), "status": "Absent"}
              ];
            });
            _databaseReference
                .child('attendance')
                .child(_selectedSubject)
                .set(attendanceData)
                .then((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Attendance added successfully.')));
              setState(() {
                _processing = false;
              });
            }).catchError((error) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to add attendance: $error')));
              setState(() {
                _processing = false;
              });
            });
          } else {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('No students found.')));
            setState(() {
              _processing = false;
            });
          }
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error fetching student data: $error')));
          setState(() {
            _processing = false;
          });
        });
      }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking attendance data: $error')));
      setState(() {
        _processing = false;
      });
    });
  }

  void deleteAttendanceConfirmation() {
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please select a subject.')));
      return;
    }

    _databaseReference
        .child('attendance')
        .child(_selectedSubject)
        .once()
        .then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Attendance data does not exist for this subject.')));
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Confirm Deletion"),
              content: Text("Are you sure you want to delete attendance data for this subject?"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    deleteAttendance();
                    Navigator.of(context).pop();
                  },
                  child: Text("Delete"),
                ),
              ],
            );
          },
        );
      }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking attendance data: $error')));
    });
  }

  void deleteAttendance() {
    _databaseReference
        .child('attendance')
        .child(_selectedSubject)
        .remove()
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Attendance data deleted successfully.')));
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete attendance data: $error')));
    });
  }
}

class AdminPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Page'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AttendancePage()),
            );
          },
          child: Text('Modify Attendance'),
        ),
      ),
    );
  }
}
