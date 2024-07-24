import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class StudentManagerPage extends StatefulWidget {
  @override
  _StudentManagerPageState createState() => _StudentManagerPageState();
}

class _StudentManagerPageState extends State<StudentManagerPage> {
  final TextEditingController _rollNoController = TextEditingController();
  final TextEditingController _batchController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final DatabaseReference _studentsRef =
  FirebaseDatabase.instance.reference().child('users').child('students');

  int _studentCount = 0;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _fetchStudentCount();
    _fetchStudents();
  }

  void _fetchStudentCount() {
    _studentsRef.once().then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      setState(() {
        _studentCount = snapshot.value != null ? (snapshot.value as Map).length : 0;
      });
    });
  }

  void _fetchStudents() {
    _studentsRef.once().then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
      List<Map<String, dynamic>> students = [];
      if (values != null) {
        values.forEach((key, value) {
          students.add({...value, 'rollNo': key});
        });
      }
      setState(() {
        _students = students;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Manager'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _showAddStudentDialog(context);
                },
                child: Text('Add Student'),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Existing Students:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _students.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_students[index]['name']),
                    subtitle: Text(_students[index]['username']),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        _confirmDeleteStudent(_students[index]['rollNo']);
                      },
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

  void _showAddStudentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Student'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _rollNoController,
                  decoration: InputDecoration(labelText: 'Roll No'),
                ),
                TextFormField(
                  controller: _batchController,
                  decoration: InputDecoration(labelText: 'Batch'),
                ),
                TextFormField(
                  controller: _courseController,
                  decoration: InputDecoration(labelText: 'Course'),
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(labelText: 'Username'),
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addStudentToDatabase();
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addStudentToDatabase() {
    // Get data from text controllers
    String rollNo = _rollNoController.text;
    String batch = _batchController.text;
    String course = _courseController.text;
    String name = _nameController.text;
    String username = _usernameController.text;
    String password = _passwordController.text;

    // Check if all fields are filled
    if (rollNo.isNotEmpty &&
        batch.isNotEmpty &&
        course.isNotEmpty &&
        name.isNotEmpty &&
        username.isNotEmpty &&
        password.isNotEmpty) {

      // Reference the 'students' node in the Firebase Realtime Database
      DatabaseReference studentRef = _studentsRef.child(rollNo);

      // Set student data under rollNo key
      studentRef.set({
        'batch': batch,
        'course': course,
        'name': name,
        'username': username,
        'password': password,
      }).then((_) {
        // Fetch updated list of students
        _fetchStudents();
        // Show a snackbar to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Student added successfully')),
        );
      });

      // Clear text fields after adding student
      _rollNoController.clear();
      _batchController.clear();
      _courseController.clear();
      _nameController.clear();
      _usernameController.clear();
      _passwordController.clear();
    } else {
      // Handle case when fields are not filled
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
    }
  }


  void _confirmDeleteStudent(String rollNo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Student'),
          content: Text('Are you sure you want to delete this student?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteStudent(rollNo);
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteStudent(String rollNo) {
    _studentsRef.child(rollNo).remove().then((_) {
      setState(() {
        _students.removeWhere((student) => student['rollNo'] == rollNo);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Student deleted successfully'),
      ));
    });
  }
}
