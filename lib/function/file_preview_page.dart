import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FilePreviewPage extends StatelessWidget {
  final String fileUrl;
  final String fileType;

  FilePreviewPage({required this.fileUrl, required this.fileType});

  Future<void> _downloadFile() async {
    if (await canLaunch(fileUrl)) {
      await launch(fileUrl, forceSafariVC: false, forceWebView: false);
    } else {
      throw 'Could not launch $fileUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('File Preview'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _downloadFile,
          ),
        ],
      ),
      body: Center(
        child: fileType == 'image'
            ? Image.network(fileUrl)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.file_copy, size: 100),
                  SizedBox(height: 20),
                  Text('File Type: $fileType'),
                  Text('URL: $fileUrl'),
                ],
              ),
      ),
    );
  }
}