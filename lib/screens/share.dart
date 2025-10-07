import 'dart:ui';

import 'package:flutter/material.dart';
import 'sender.dart';
import 'receive.dart';

class SharePage extends StatefulWidget {
  const SharePage({Key? key}) : super(key: key);

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> with TickerProviderStateMixin {
  late AnimationController _rocketController;
  late AnimationController _sendPulseController;
  late AnimationController _receivePulseController;
  late Animation<double> _rocketAnimation;
  bool _showHelp = false;

  @override
  void initState() {
    super.initState();
    
    // Rocket animation controller
    _rocketController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _rocketAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rocketController, curve: Curves.easeInOut),
    );

    // Send pulse animation
    _sendPulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Receive pulse animation
    _receivePulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rocketController.dispose();
    _sendPulseController.dispose();
    _receivePulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1F3A) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF252B48) : Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'T',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'TransCrypt',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              // Toggle theme - implement with provider or riverpod
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Title
                  Text(
                    'Share Files Securely',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose to send or receive files',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Send and Receive boxes with rocket animation
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Send Box
                        _buildTransferBox(
                          context: context,
                          title: 'Send',
                          icon: Icons.upload_rounded,
                          color: const Color(0xFF6C63FF),
                          pulseController: _sendPulseController,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SendPage()),
                            );
                          },
                        ),
                        
                        // Rocket Animation Area
                        SizedBox(
                          height: 120,
                          child: AnimatedBuilder(
                            animation: _rocketAnimation,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: RocketPainter(
                                  progress: _rocketAnimation.value,
                                  isDark: isDark,
                                ),
                                child: Container(),
                              );
                            },
                          ),
                        ),
                        
                        // Receive Box
                        _buildTransferBox(
                          context: context,
                          title: 'Receive',
                          icon: Icons.download_rounded,
                          color: const Color(0xFFFF6584),
                          pulseController: _receivePulseController,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ReceivePage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Help popup
          if (_showHelp)
            GestureDetector(
              onTap: () => setState(() => _showHelp = false),
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Material(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF252B48) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.help_outline,
                              size: 50,
                              color: Color(0xFF6C63FF),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'How to Use TransCrypt',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '• Tap "Send" to share files with others\n\n'
                              '• Tap "Receive" to accept incoming files\n\n'
                              '• All transfers are encrypted end-to-end\n\n'
                              '• Both devices must be on the same network\n\n'
                              '• No file size limits!',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => setState(() => _showHelp = false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C63FF),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Got it!'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _showHelp = true),
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.question_mark_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNavBar(context, isDark),
    );
  }

  Widget _buildTransferBox({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required AnimationController pulseController,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (pulseController.value * 0.05),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252B48) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 48,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title == 'Send' 
                        ? 'Share files with others'
                        : 'Accept incoming files',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavBar(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252B48) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        currentIndex: 1,
        selectedItemColor: const Color(0xFF6C63FF),
        unselectedItemColor: isDark ? Colors.white38 : Colors.black38,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.share_rounded),
            label: 'Share',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          // Handle navigation
          if (index == 0) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}

// Custom painter for rocket animation
class RocketPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  RocketPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw dotted line path
    final paint = Paint()
      ..color = isDark ? Colors.white24 : Colors.black12
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.quadraticBezierTo(
      size.width * 0.7,
      size.height / 2,
      size.width / 2,
      size.height,
    );

    // Draw dashed line
    const dashWidth = 5;
    const dashSpace = 5;
    double distance = 0;
    
    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        final nextDistance = distance + dashWidth;
        final segment = pathMetric.extractPath(distance, nextDistance);
        canvas.drawPath(segment, paint);
        distance = nextDistance + dashSpace;
      }
    }

    // Draw rocket
    final rocketPaint = Paint()..color = const Color(0xFFFF6584);
    
    final PathMetric pathMetric = path.computeMetrics().first;
    final pos = pathMetric.getTangentForOffset(pathMetric.length * progress)!;
    
    // Draw rocket emoji/icon at position
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '🚀',
        style: TextStyle(fontSize: 30),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(pos.position.dx - 15, pos.position.dy - 15),
    );
  }

  @override
  bool shouldRepaint(RocketPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}