import 'package:face_log/AssignSubject.dart';
import 'package:flutter/material.dart';
import 'SubjectManager.dart';
import 'TeacherManager.dart';
import 'DeleteAssignSubject.dart';
import 'AddAttendanceData.dart';
import 'StudentManager.dart';

class AdminDashboard extends StatelessWidget {
  final String adminId;

  const AdminDashboard({Key? key, required this.adminId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SquareButton(
                  title: 'Teacher Manager',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TeacherManagerPage(),
                      ),
                    );
                  },
                ),
                SizedBox(width: 20),
                SquareButton(
                  title: 'Subject Manager',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubjectManagerPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SquareButton(
                  title: 'Assign Subject',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AssignSubjectPage(
                          adminId:
                              adminId, // Pass admin ID to the admin dashboard page
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(width: 20),
                SquareButton(
                  title: 'Delete Assign Subject',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DeleteAssignSubjectPage()),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SquareButton(
                  title: 'Add/Delete Attendance Data',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AttendancePage(),
                      ),
                    );
                  },
                ),
                SizedBox(width: 20),
                SquareButton(
                  title: 'Student Manager',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentManagerPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SquareButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;

  const SquareButton({
    Key? key,
    required this.title,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
