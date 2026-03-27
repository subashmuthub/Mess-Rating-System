// Virtual Tour Screen - 360 Degree Campus View

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_style.dart';

class VirtualTourScreen extends StatefulWidget {
  const VirtualTourScreen({super.key});

  @override
  State<VirtualTourScreen> createState() => _VirtualTourScreenState();
}

class _VirtualTourScreenState extends State<VirtualTourScreen> {
  static const String _virtualTourUrl = 'https://nec.edu.in/360-degree-view/';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTour();
  }

  Future<void> _loadTour() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final Uri url = Uri.parse(_virtualTourUrl);
    final launched = await launchUrl(url, mode: LaunchMode.inAppWebView);
    if (launched) {
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _openInBrowser() async {
    final Uri url = Uri.parse(_virtualTourUrl);
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppStyle.primary;

    return Scaffold(
      backgroundColor: AppStyle.pageBackground,
      appBar: AppBar(
        title: Text(
          'NEC Virtual Campus Tour',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _isLoading ? Icons.travel_explore : Icons.public_off,
                    size: 44,
                    color: _isLoading ? primary : AppStyle.danger,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _isLoading ? 'Opening Virtual Tour...' : 'Unable To Open Tour',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppStyle.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoading
                      ? 'Please wait while we launch the 360-degree campus experience.'
                      : 'Try again, or open it in your browser if in-app view is unavailable.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.5,
                    color: AppStyle.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                if (_isLoading)
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(primary),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _loadTour,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openInBrowser,
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open Browser'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primary,
                            side: BorderSide(color: primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
