import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TeacherManagerPage extends StatefulWidget {
  @override
  _TeacherManagerPageState createState() => _TeacherManagerPageState();
}

class _TeacherManagerPageState extends State<TeacherManagerPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final DatabaseReference _teachersRef =
  FirebaseDatabase.instance.reference().child('users').child('teachers');

  int _teacherCount = 0;
  List<Map<String, dynamic>> _teachers = [];

  @override
  void initState() {
    super.initState();
    _fetchTeacherCount();
    _fetchTeachers();
  }

  void _fetchTeacherCount() {
    _teachersRef.once().then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      setState(() {
        _teacherCount = snapshot.value != null ? (snapshot.value as Map).length : 0;
      });
    });
  }

  void _fetchTeachers() {
    _teachersRef.once().then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
      List<Map<String, dynamic>> teachers = [];
      if (values != null) {
        values.forEach((key, value) {
          teachers.add({...value, 'id': key});
        });
      }
      setState(() {
        _teachers = teachers;
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher Manager'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _showAddTeacherDialog(context);
                },
                child: Text('Add Teacher'),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Existing Teachers:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _teachers.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_teachers[index]['name']),
                    subtitle: Text(_teachers[index]['email']),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        _confirmDeleteTeacher(_teachers[index]['id']);
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

  void _showAddTeacherDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Teacher'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
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
                _addTeacherToDatabase();
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addTeacherToDatabase() {
    String name = _nameController.text;
    String email = _emailController.text;
    String username = _usernameController.text;
    String password = _passwordController.text;

    if (name.isNotEmpty && email.isNotEmpty && username.isNotEmpty && password.isNotEmpty) {
      String newTeacherId = 'teacher_id_${(_teacherCount + 1).toString().padLeft(2, '0')}';

      _teachersRef.child(newTeacherId).set({
        'name': name,
        'email': email,
        'username': username,
        'password': password,
        // You can add more fields here if needed
      }).then((_) {
        _fetchTeachers(); // Reload the list of teachers
      });

      // Clear the text fields after adding the teacher
      _nameController.clear();
      _emailController.clear();
      _usernameController.clear();
      _passwordController.clear();
    } else {
      // Handle empty fields
      print('Please fill in all fields.');
    }
  }

  void _confirmDeleteTeacher(String teacherId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Teacher'),
          content: Text('Are you sure you want to delete this teacher?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteTeacher(teacherId);
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteTeacher(String teacherId) {
    _teachersRef.child(teacherId).remove().then((_) {
      setState(() {
        _teachers.removeWhere((teacher) => teacher['id'] == teacherId);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Teacher deleted successfully'),
      ));
    });
  }
}

