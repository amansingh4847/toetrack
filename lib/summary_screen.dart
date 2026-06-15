import 'dart:typed_data';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:share_plus/share_plus.dart';

import 'package:flutter/material.dart';

class SummaryScreen extends StatelessWidget {
  final Uint8List image;

  final VoidCallback onDone;

  const SummaryScreen({super.key, required this.image, required this.onDone});

  Future<void> shareRun() async {
    print("Share button pressed");

    final directory = await getTemporaryDirectory();

    final file = File('${directory.path}/run.png');

    await file.writeAsBytes(image);

    print("File created");

    await Share.shareXFiles([
      XFile(file.path),
    ], text: '🏃 Shared from ToeTrack');

    print("Share completed");
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,

      child: Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false),

        body: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),

                  child: Image.memory(image, fit: BoxFit.contain),
                ),
              ),

              const SizedBox(height: 24),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,

                height: 60,

                child: ElevatedButton.icon(
                  onPressed: shareRun,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreen,
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.share),

                  label: const Text("Share Run"),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,

                height: 60,

                child: ElevatedButton(
                  onPressed: () {
                    onDone();

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreen,
                    foregroundColor: Colors.black,
                  ),

                  child: const Text("Done"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
