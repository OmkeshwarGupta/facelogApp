import 'package:flutter/material.dart';
import 'SubjectSelectionPageState.dart';
import 'StudentDashboard.dart';
import 'AdminDashboard.dart';
import 'package:firebase_database/firebase_database.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FACELOG',
          style: TextStyle(
            fontWeight: FontWeight.w600, // set the font weight to 700
          ),
        ),
      ),
      body: LoginForm(),
    );
  }
}

class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _userType = 'Teacher'; // Default user type
  bool _loading = false; // added loading indicator state

  Future<void> _login() async {
    setState(() {
      _loading = true; // set loading to true when login button is pressed
    });

    String username = _usernameController.text;
    String password = _passwordController.text;

    if (_userType == 'Teacher') {
      final dbRef = FirebaseDatabase.instance.reference().child("users").child("teachers");
      dbRef.once().then((DatabaseEvent event) {
        DataSnapshot snapshot = event.snapshot;
        if (snapshot.value != null) {
          Map<dynamic, dynamic> teachers = snapshot.value as Map<dynamic, dynamic>;
          bool found = false; // flag to check if a teacher was found
          teachers.forEach((key, value) {
            if (value['username'] == username && value['password'] == password) {
              found = true; // set the flag to true if a teacher was found
              String teacherId = key;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubjectSelectionPage(
                    teacherId: teacherId,
                  ),
                ),
              );
            }
          });
          if (!found) {
            _showErrorDialog(); // if no teacher was found, show the error dialog
          }
        } else {
          print('No data found at the specified location');
        }
      }).catchError((error) {
        print('Error: $error');
        _showErrorDialog();
      }).whenComplete(() {
        setState(() {
          _loading = false; // set loading to false after login process completes
        });
      });
    } else if (_userType == 'Student') {
      final dbRef = FirebaseDatabase.instance.reference().child("users").child("students");
      dbRef.once().then((DatabaseEvent event) {
        DataSnapshot snapshot = event.snapshot;
        if (snapshot.value != null) {
          Map<dynamic, dynamic> students = snapshot.value as Map<dynamic, dynamic>;
          bool found = false; // flag to check if a student was found
          students.forEach((key, value) {
            if (value['username'] == username && value['password'] == password) {
              found = true; // set the flag to true if a student was found
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentDashboard(
                    studentID: value['username'],
                  ),
                ),
              );
            }
          });
          if (!found) {
            _showErrorDialog(); // if no student was found, show the error dialog
          }
        } else {
          print('No data found at the specified location');
        }
      }).catchError((error) {
        print('Error: $error');
        _showErrorDialog();
      }).whenComplete(() {
        setState(() {
          _loading = false; // set loading to false after login process completes
        });
      });
    } else if (_userType == 'Admin') {
      final dbRef = FirebaseDatabase.instance.reference().child("users").child("admin");
      dbRef.once().then((DatabaseEvent event) {
        DataSnapshot snapshot = event.snapshot;
        if (snapshot.value != null) {
          Map<dynamic, dynamic> admins = snapshot.value as Map<dynamic, dynamic>;
          bool found = false; // flag to check if an admin was found
          admins.forEach((key, value) {
            if (value['username'] == username && value['password'] == password) {
              found = true; // set the flag to true if an admin was found
              String adminId = key;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminDashboard(
                    adminId: adminId, // Pass admin ID to the admin dashboard page
                  ),
                ),
              );
            }
          });
          if (!found) {
            _showErrorDialog(); // if no admin was found, show the error dialog
          }
        } else {
          print('No data found at the specified location');
        }
      }).catchError((error) {
        print('Error: $error');
        _showErrorDialog();
      }).whenComplete(() {
        setState(() {
          _loading = false; // set loading to false after login process completes
        });
      });
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text('Invalid username or password.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/face.gif',
              width: 200, // Adjust width as needed
              height: 200, // Adjust height as needed
              fit: BoxFit.cover,
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Radio(
                  value: 'Teacher',
                  groupValue: _userType,
                  onChanged: (value) {
                    setState(() {
                      _userType = value.toString();
                    });
                  },
                ),
                Text('Teacher'),
                Radio(
                  value: 'Student',
                  groupValue: _userType,
                  onChanged: (value) {
                    setState(() {
                      _userType = value.toString();
                    });
                  },
                ),
                Text('Student'),
                Radio(
                  value: 'Admin',
                  groupValue: _userType,
                  onChanged: (value) {
                    setState(() {
                      _userType = value.toString();
                    });
                  },
                ),
                Text('Admin'),
              ],
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _loading ? null : _login, // disable button when loading
              child: _loading
                  ? CircularProgressIndicator() // show loading indicator
                  : Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
