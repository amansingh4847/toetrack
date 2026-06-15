import 'dart:io';

import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<File> runImages = [];

  String monthName(int month) {
    const months = [
      'Jan',

      'Feb',

      'Mar',

      'Apr',

      'May',

      'Jun',

      'Jul',

      'Aug',

      'Sep',

      'Oct',

      'Nov',

      'Dec',
    ];

    return months[month - 1];
  }

  //for date
  String formatDate(File file) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(
      int.parse(file.path.split('/').last.replaceAll('.png', '')),
    );

    DateTime now = DateTime.now();

    DateTime today = DateTime(now.year, now.month, now.day);

    DateTime yesterday = today.subtract(const Duration(days: 1));

    DateTime runDay = DateTime(date.year, date.month, date.day);

    String time =
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";

    if (runDay == today) {
      return "Today • $time";
    }

    if (runDay == yesterday) {
      return "Yesterday • $time";
    }

    return "${date.day} ${monthName(date.month)} ${date.year} • $time";
  }

  Future<void> showDeleteDialog(File file) async {
    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Run?"),

          content: const Text("This cannot be undone."),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text("Cancel"),
            ),

            TextButton(
              onPressed: () async {
                await file.delete();

                Navigator.pop(context);

                loadRuns();
              },

              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    loadRuns();
  }

  Future<void> loadRuns() async {
    final directory = await getApplicationDocumentsDirectory();

    final folder = Directory('${directory.path}/runs');

    if (!await folder.exists()) return;

    List<FileSystemEntity> files = folder.listSync();

    setState(() {
      runImages = files.whereType<File>().toList();

      runImages.sort((a, b) {
        int aTime = int.parse(a.path.split('/').last.replaceAll('.png', ''));

        int bTime = int.parse(b.path.split('/').last.replaceAll('.png', ''));

        return bTime.compareTo(aTime);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Run History"), centerTitle: true),

      body: runImages.isEmpty
          ? const Center(child: Text("No runs yet 🏃"))
          : ListView.builder(
              itemCount: runImages.length,

              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(12),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        formatDate(runImages[index]),

                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.lightGreen,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),

                            child: Image.file(runImages[index]),
                          ),

                          Positioned(
                            top: 10,

                            right: 10,

                            child: CircleAvatar(
                              backgroundColor: Colors.black54,

                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,

                                  color: Colors.red,
                                ),

                                onPressed: () {
                                  showDeleteDialog(runImages[index]);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
