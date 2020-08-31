import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;
import 'package:web_portal/main.dart';

class FileUploadApp extends StatefulWidget {
  @override
  createState() => _FileUploadAppState();
}

class _FileUploadAppState extends State<FileUploadApp> {
  List<int> _selectedFile;
  Uint8List _bytesData;
  String selected_file = '';
  int status;
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  startWebFilePicker() async {
    html.InputElement uploadInput = html.FileUploadInputElement();
    uploadInput.multiple = false;
    uploadInput.draggable = true;
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      final file = files[0];
      final reader = html.FileReader();

      reader.onLoadEnd.listen((e) {
        selected_file = uploadInput.dirName;
        print(uploadInput.name);
        _handleResult(reader.result);
      });
      reader.readAsDataUrl(file);
    });
  }

  void _handleResult(Object result) {
    setState(() {
      _bytesData = Base64Decoder().convert(result.toString().split(",").last);
      _selectedFile = _bytesData;
    });
  }

  Future<String> makeRequest() async {
    var url = Uri.parse("http://192.168.1.9:5000/file/file_upload");
    var request = http.MultipartRequest("POST", url);
    request.files.add(await http.MultipartFile.fromBytes(
        'input_file', _selectedFile,
        contentType: MediaType('application', 'octet-stream'),
        filename: "file_up"));
    request.send().then((response) {
      print("test");
      print(response.statusCode);
      status = response.statusCode;
      Pattern pattern = r'.*\.(xlsx|xls|csv)';
      RegExp regex = RegExp(pattern);
      if (regex.hasMatch(selected_file)) status = 400;
      if (response.statusCode == 201) print("Uploaded!");
    });
    showDialog(
        barrierDismissible: false,
        context: context,
        child: AlertDialog(
          title: Text("Details"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                status == 201
                    ? Text("Upload successful")
                    : Text(
                        "Either the selected file is not in valid format or the server is down."),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Done'),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => MyApp()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ));
  }

  void downloadFile() {
    html.AnchorElement anchorElement =
        html.AnchorElement(href: 'http://192.168.1.9:5000/routes/display');
    anchorElement.download = 'http://192.168.1.9:5000/routes/display';
    anchorElement.click();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('A Flutter Web file picker'),
        ),
        body: Container(
          child: Form(
            autovalidate: true,
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0, left: 28),
              child: Container(
                  width: 350,
                  child: Column(children: <Widget>[
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(selected_file),
                          MaterialButton(
                            color: Colors.pink,
                            elevation: 8,
                            highlightElevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            textColor: Colors.white,
                            child: Text('Select a file'),
                            onPressed: () {
                              startWebFilePicker();
                            },
                          ),
                          Divider(
                            color: Colors.teal,
                          ),
                          RaisedButton(
                            color: Colors.purple,
                            elevation: 8.0,
                            textColor: Colors.white,
                            onPressed: () {
                              makeRequest();
                            },
                            child: Text('Send file to server'),
                          ),
                          MaterialButton(
                            color: Colors.pink,
                            elevation: 8,
                            highlightElevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            textColor: Colors.white,
                            child: Text('Download file'),
                            onPressed: () {
                              downloadFile();
                            },
                          ),
                        ])
                  ])),
            ),
          ),
        ),
      ),
    );
  }
}
