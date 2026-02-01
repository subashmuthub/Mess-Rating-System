// Virtual Tour Screen - 360 Degree Campus View

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class VirtualTourScreen extends StatefulWidget {
  const VirtualTourScreen({super.key});

  @override
  State<VirtualTourScreen> createState() => _VirtualTourScreenState();
}

class _VirtualTourScreenState extends State<VirtualTourScreen> {
  final String virtualTourUrl = 'https://nec.edu.in/360-degree-view/';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTour();
  }

  Future<void> _loadTour() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      final Uri url = Uri.parse(virtualTourUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.inAppWebView);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NEC Virtual Campus Tour'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text('Opening Virtual Tour...'),
            ] else ...[
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 20),
              const Text('Could not load virtual tour'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadTour,
                child: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
