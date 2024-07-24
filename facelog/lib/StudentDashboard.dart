import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class StudentDashboard extends StatefulWidget {
  final String studentID;

  StudentDashboard({required this.studentID});

  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  late DatabaseReference _dbRef;
  Map<String, dynamic>? _studentInfo;
  String? _selectedTeacher;
  Map<String, dynamic>? _attendanceData;
  int? _selectedYear;
  int? _selectedMonth;
  int _totalClasses = 0;
  int _attendedClasses = 0;

  @override
  void initState() {
    super.initState();
    _dbRef =
        FirebaseDatabase.instance.reference().child("users").child("students");
    fetchStudentInfo();
  }

  void fetchStudentInfo() {
    _dbRef.child(widget.studentID).once().then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        setState(() {
          _studentInfo = Map<String, dynamic>.from(snapshot.value as Map);
        });
      }
    }).catchError((error) {
      print("Failed to fetch student info: $error");
    });
  }

  Future<List<String>> fetchTeachers() async {
    DataSnapshot snapshot =
        (await FirebaseDatabase.instance.reference().child("attendance").once())
            .snapshot;
    Map<dynamic, dynamic> teachers = snapshot.value as Map<dynamic, dynamic>;
    return teachers.keys.cast<String>().toList();
  }

  void fetchAttendance(String teacherId) {
    FirebaseDatabase.instance
        .reference()
        .child("attendance")
        .child(teacherId)
        .child(widget.studentID)
        .once()
        .then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null && snapshot.value is List) {
        setState(() {
          _attendanceData = Map.fromIterable(snapshot.value as List,
              key: (item) => item['date_time'].toString(),
              value: (item) => item['status'].toString());
          _totalClasses = _attendanceData!.length;
          print(_totalClasses);
          _attendedClasses = _attendanceData!.values
              .where((status) => status == 'Present')
              .length;
        });
      } else {
        setState(() {
          _attendanceData = null;
        });
        print("Invalid attendance data format.");
      }
    }).catchError((error) {
      print("Failed to fetch attendance: $error");
    });
  }

  double calculateAttendancePercentage() {
    if (_totalClasses == 0) {
      return 0.0;
    }
    return (_attendedClasses / _totalClasses) * 100;
  }

  List<String> filterAttendanceData() {
    if (_attendanceData == null ||
        _selectedYear == null ||
        _selectedMonth == null) {
      return [];
    }

    return _attendanceData!.keys.where((key) {
      DateTime dateTime = DateTime.parse(key);
      return dateTime.year == _selectedYear && dateTime.month == _selectedMonth;
    }).toList();
  }

  int calculateAdditionalClassesRequiredFor75Percent() {
    double desiredPercentage = 75.0;
    int additionalClassesRequired=0 ;

    if (_totalClasses == 0) {
      return 0;
    }
    double currentPercentage = calculateAttendancePercentage();
    if (currentPercentage >= desiredPercentage) {
      return 0;
    }
  additionalClassesRequired=((desiredPercentage*_totalClasses-100*_attendedClasses)/(100-desiredPercentage)).ceil();
    return additionalClassesRequired;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Dashboard'),
        backgroundColor:
            Colors.deepPurple.shade100, // Color the app bar like bg
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade100, // Background color
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display student info
              _studentInfo != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Name: ${_studentInfo!['name']}",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Student ID: ${_studentInfo!['username']}",
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          "Course: ${_studentInfo!['course']}",
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          "Batch: ${_studentInfo!['batch']}",
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 20),
                      ],
                    )
                  : Container(),
              // Fetch and display teachers dropdown
              FutureBuilder<List<String>>(
                future: fetchTeachers(),
                builder: (BuildContext context,
                    AsyncSnapshot<List<String>> snapshot) {
                  if (snapshot.hasData) {
                    return Column(
                      children: [
                        Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(10.0), // Rounded corners
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 12.0),
                          margin: EdgeInsets.only(bottom: 20.0),
                          child: DropdownButton<String>(
                            isExpanded: true, // Stretch horizontally
                            value: _selectedTeacher,
                            hint: Text('Select The Subject',
                                style: TextStyle(fontSize: 18)),
                            items: snapshot.data!.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Center(
                                    child: Text(value,
                                        style: TextStyle(fontSize: 18))),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedTeacher = newValue;
                              });
                              fetchAttendance(_selectedTeacher!);
                            },
                          ),
                        ),

                        SizedBox(height: 10),
                        // Display attendance data
                        _attendanceData != null
                            ? Column(
                                children: [
                                  Text(
                                    'Total Classes: $_totalClasses',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  Text(
                                    'Attended Classes: $_attendedClasses',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  Text(
                                    'Attendance Percentage: ${calculateAttendancePercentage().toStringAsFixed(2)}%',
                                    style: TextStyle(fontSize: 18),
                                  ),

                                  Text(
                                    'Classes Required for 75% Attendance: ${calculateAdditionalClassesRequiredFor75Percent().toString()}',
                                    style: TextStyle(fontSize: 18),
                                  ),

                                  SizedBox(height: 20),
                                  // Display year and month selection dropdowns
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width:
                                            150, // Adjust the width according to your design
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          child: DropdownButton<int>(
                                            hint: Text('Select Year'),
                                            value: _selectedYear,
                                            onChanged: (int? newValue) {
                                              setState(() {
                                                _selectedYear = newValue;
                                              });
                                            },
                                            isExpanded: true,
                                            items: List.generate(
                                                10,
                                                (index) =>
                                                    index +
                                                    DateTime.now().year -
                                                    5).map((int value) {
                                              return DropdownMenuItem<int>(
                                                value: value,
                                                child: Center(
                                                    child:
                                                        Text(value.toString())),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      SizedBox(
                                        width:
                                            150, // Adjust the width according to your design
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          child: DropdownButton<int>(
                                            hint: Text('Select Month'),
                                            value: _selectedMonth,
                                            onChanged: (int? newValue) {
                                              setState(() {
                                                _selectedMonth = newValue;
                                              });
                                            },
                                            isExpanded: true,
                                            items: List.generate(
                                                    12, (index) => index + 1)
                                                .map((int value) {
                                              return DropdownMenuItem<int>(
                                                value: value,
                                                child: Center(
                                                    child:
                                                        Text(value.toString())),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      decoration: BoxDecoration(
                                        color: Colors
                                            .white, // Table background color
                                      ),
                                      columns: const <DataColumn>[
                                        DataColumn(
                                          label: Text('Date',
                                              style: TextStyle(fontSize: 18)),
                                        ),
                                        DataColumn(
                                          label: Text('Time',
                                              style: TextStyle(fontSize: 18)),
                                        ),
                                        DataColumn(
                                          label: Text('Status',
                                              style: TextStyle(fontSize: 18)),
                                        ),
                                      ],
                                      rows: filterAttendanceData()
                                          .map((key) => DataRow(
                                                cells: <DataCell>[
                                                  DataCell(Text(
                                                      DateTime.parse(key)
                                                          .toLocal()
                                                          .toString()
                                                          .split(' ')[0],
                                                      style: TextStyle(
                                                          fontSize: 16))),
                                                  DataCell(Text(
                                                      DateTime.parse(key)
                                                          .toLocal()
                                                          .toString()
                                                          .split(' ')[1]
                                                          .substring(0, 5),
                                                      style: TextStyle(
                                                          fontSize: 16))),
                                                  DataCell(Text(
                                                      _attendanceData![key]
                                                          .toString(),
                                                      style: TextStyle(
                                                          fontSize: 16))),
                                                ],
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                ],
                              )
                            : Container(),
                      ],
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}',
                        style: TextStyle(fontSize: 18, color: Colors.red));
                  }
                  return Center(child: CircularProgressIndicator());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
