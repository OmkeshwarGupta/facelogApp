import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart' as dio;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ManualPage.dart';

class TeacherDashboard extends StatefulWidget {
  final String subjectId;

  const TeacherDashboard({Key? key, required this.subjectId}) : super(key: key);

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  String? _imageData;
  File? _selectedImage;
  bool _isLoading = false;
  int? _presentStudents;
  int? _absentStudents;

  Future<void> _addImageForRecognition(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 100,
    );

    if (pickedFile != null) {
      final extension = pickedFile.path.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png'].contains(extension)) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _imageData = null;
        });
      } else {
        _showErrorDialog('Unsupported file type. Please select a JPG, JPEG, or PNG image.');
      }
    }
  }

  Future<void> _performFaceRecognitionAndAddAttendance() async {
    if (_selectedImage == null) {
      _showErrorDialog('No image selected.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:5000/attendance'),
      );

      request.fields['teacher_id'] = widget.subjectId;
      request.files.add(
        await http.MultipartFile.fromBytes(
          'image',
          await _selectedImage!.readAsBytes(),
          filename: 'image.jpg',
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final imageData = responseData['image'];
        final presentStudents = responseData['present_students'];
        final absentStudents = responseData['absent_students'];

        if (imageData.isNotEmpty) {
          setState(() {
            _imageData = imageData.split(',')[1];
            _presentStudents = presentStudents;
            _absentStudents = absentStudents;
            _isLoading = false;
          });
          _showAttendancePopup();
          print('Image sent and processed successfully.');
        } else {
          _showErrorDialog('Received empty image data from server.');
        }
      } else {
        _showErrorDialog('Error sending image: ${response.reasonPhrase}');
        print('Error sending image: ${response.reasonPhrase}');
        print('Response Body: ${response.body}');
      }
    } catch (e) {
      _showErrorDialog('Exception occurred while sending image: $e');
      print('Exception occurred while sending image: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAttendancePopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Attendance Summary'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Present Students: $_presentStudents'),
              Text('Absent Students: $_absentStudents'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(errorMessage),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _addNewClass() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var response = await http.post(
        Uri.parse('http://10.0.2.2:5000/new_class'),
        body: {'subject_id': widget.subjectId},
      );

      if (response.statusCode == 200) {
        print('New class added successfully');
        final responseData = jsonDecode(response.body);
        final message = responseData['message'];
        _showSuccessDialog(message);
      } else {
        print('Failed to add new class: ${response.reasonPhrase}');
        _showErrorDialog('Failed to add new class: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Exception occurred while adding new class: $e');
      _showErrorDialog('Exception occurred while adding new class: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToManualAttendancePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ManualPage(subjectId: widget.subjectId)),
    );
  }

  Future<void> _downloadAttendance() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await dio.Dio().get(
        'http://10.0.2.2:5000/download_attendance',
        queryParameters: {'teacher_id': widget.subjectId},
        options: dio.Options(responseType: dio.ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        final appDir = await getApplicationDocumentsDirectory();
        final file = File('${appDir.path}/attendance_data.xlsx');
        await file.writeAsBytes(response.data);

        print('Attendance data downloaded successfully');
        print('File saved to: ${file.path}');
      } else {
        print('Failed to download attendance: ${response.statusCode}');
        _showErrorDialog('Failed to download attendance: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception occurred while downloading attendance: $e');
      _showErrorDialog('Exception occurred while downloading attendance: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> requestStoragePermission() async {
    if (await Permission.storage.request().isGranted) {
      // Permission granted
    } else {
      // Permission denied, handle accordingly
      _showErrorDialog('Storage permission denied. Please grant storage permission to download attendance data.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Teacher Dashboard'),
      ),
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade100,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _addNewClass,
                    child: Text('Add New Class'),
                  ),
                  SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Choose Image Source'),
                            content: SingleChildScrollView(
                              child: ListBody(
                                children: <Widget>[
                                  GestureDetector(
                                    child: Text('Gallery'),
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      _addImageForRecognition(ImageSource.gallery);
                                    },
                                  ),
                                  SizedBox(height: 10),
                                  GestureDetector(
                                    child: Text('Camera'),
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      _addImageForRecognition(ImageSource.camera);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Text('Add Image'),
                  ),
                  SizedBox(height: 20.0),
                  if (_imageData != null)
                    Image.memory(
                      base64Decode(_imageData!),
                      width: MediaQuery.of(context).size.width,
                      fit: BoxFit.scaleDown,
                    )
                  else if (_selectedImage != null)
                    Image.file(_selectedImage!)
                  else
                    Container(),
                  SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: _selectedImage != null ? _performFaceRecognitionAndAddAttendance : null,
                    child: Text('Perform Face Recognition and Add Attendance'),
                  ),
                  SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: _navigateToManualAttendancePage,
                    child: Text('Manual Attendance'),
                  ),
                  SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: _downloadAttendance,
                    child: Text('Download Attendance'),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
