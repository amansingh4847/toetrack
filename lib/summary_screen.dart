import 'dart:typed_data';

import 'package:flutter/material.dart';

class SummaryScreen extends StatelessWidget {
  final Uint8List image;

  final VoidCallback onDone;

  const SummaryScreen({
    super.key,
    required this.image,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,

      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,

          centerTitle: true,

          title: const Text(
            "🏁 Great Run!",
          ),
        ),

        body: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),

                  child: Image.memory(
                    image,

                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,

                height: 60,

                child: ElevatedButton(
                  onPressed: () {
                    onDone();

                    Navigator.pop(context);
                  },

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