import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:transcrypt/service/SenderService.dart';

class SharePage extends StatelessWidget {
  const SharePage({super.key});

  Future<void> _sendFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      await SenderService.share(filePath, context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No file selected")));
    }
  }

  void _receiveFile(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Receive feature coming soon!"),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Share Files"),
        backgroundColor: isDarkMode
            ? const Color(0xFF1E293B)
            : const Color(0xFF3B82F6),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Send button
              _modernButton(
                context,
                label: "Send Files",
                color1: const Color(0xFF3B82F6),
                color2: const Color(0xFF9333EA),
                icon: Icons.upload_file,
                onTap: () => _sendFile(context),
              ),
              const SizedBox(height: 24),

              // Receive button
              _modernButton(
                context,
                label: "Receive Files",
                color1: const Color(0xFF10B981),
                color2: const Color(0xFF14B8A6),
                icon: Icons.download,
                onTap: () => _receiveFile(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modernButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color1,
    required Color color2,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color1.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
