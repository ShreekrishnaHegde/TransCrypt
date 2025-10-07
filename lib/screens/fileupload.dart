// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:path/path.dart' as path;
// import 'package:transcrypt/service/SenderService.dart';
//
// void main() {
//   runApp(const TransCryptApp2());
// }
//
// class TransCryptApp2 extends StatelessWidget {
//   const TransCryptApp2({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'TransCrypt',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData.light(),
//       darkTheme: ThemeData.dark(),
//       home: const FileUploadScreen(),
//     );
//   }
// }
//
// class FileUploadScreen extends StatefulWidget {
//   const FileUploadScreen({Key? key}) : super(key: key);
//
//   @override
//   State<FileUploadScreen> createState() => _FileUploadScreenState();
// }
//
// class _FileUploadScreenState extends State<FileUploadScreen> {
//   bool isDark = true;
//   int selectedIndex = 0;
//   File? _selectedFile;
//   bool _isUploading = false;
//
//   Future<void> pickFile() async {
//     final result = await FilePicker.platform.pickFiles();
//     if (result != null && result.files.single.path != null) {
//       setState(() {
//         _selectedFile = File(result.files.single.path!);
//       });
//     }
//   }
//
//   Future<void> sendFile() async {
//     if (_selectedFile == null) return;
//     await FileSender.startFileServer(_selectedFile!.path, context);
//     setState(() {
//       _isUploading = true;
//     });
//
//     // Simulate sending
//     await Future.delayed(const Duration(seconds: 2));
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('File sent successfully!')),
//     );
//
//     setState(() {
//       _isUploading = false;
//       _selectedFile = null;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
//       appBar: AppBar(
//         backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
//         elevation: 4,
//         title: Row(
//           children: [
//             Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(12),
//                 gradient: const LinearGradient(
//                   colors: [Color(0xFF3B82F6), Color(0xFF9333EA)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//               ),
//               child: const Center(
//                 child: Text(
//                   'T',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Text(
//               'TransCrypt',
//               style: TextStyle(
//                 color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           Container(
//             margin: const EdgeInsets.only(right: 16),
//             decoration: BoxDecoration(
//               color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: IconButton(
//               icon: Icon(
//                 isDark ? Icons.wb_sunny : Icons.nightlight_round,
//                 color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF475569),
//                 size: 20,
//               ),
//               onPressed: () {
//                 setState(() {
//                   isDark = !isDark;
//                 });
//               },
//             ),
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             const SizedBox(height: 20),
//
//             // File Picker Box
//             GestureDetector(
//               onTap: pickFile,
//               child: Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(32),
//                 decoration: BoxDecoration(
//                   color: isDark ? const Color(0xFF1E293B) : Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(
//                     color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
//                     width: 2,
//                     style: BorderStyle.solid,
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.1),
//                       blurRadius: 10,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Container(
//                       width: 80,
//                       height: 80,
//                       decoration: BoxDecoration(
//                         color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: Icon(
//                         _selectedFile == null ? Icons.upload_file : Icons.insert_drive_file,
//                         size: 40,
//                         color: const Color(0xFF3B82F6),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       _selectedFile == null
//                           ? 'Tap to select file'
//                           : path.basename(_selectedFile!.path),
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         color: isDark ? Colors.white : const Color(0xFF0F172A),
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       _selectedFile == null
//                           ? 'Choose a file to send'
//                           : 'File selected',
//                       style: TextStyle(
//                         color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             const Spacer(),
//
//             // Send Button
//             if (_selectedFile != null)
//               SizedBox(
//                 width: double.infinity,
//                 height: 56,
//                 child: ElevatedButton(
//                   onPressed: _isUploading ? null : sendFile,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF3B82F6),
//                     disabledBackgroundColor: const Color(0xFF64748B),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     elevation: 4,
//                   ),
//                   child: _isUploading
//                       ? const SizedBox(
//                           width: 24,
//                           height: 24,
//                           child: CircularProgressIndicator(
//                             color: Colors.white,
//                             strokeWidth: 2,
//                           ),
//                         )
//                       : const Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(Icons.send, color: Colors.white, size: 20),
//                             SizedBox(width: 8),
//                             Text(
//                               'Send File',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ],
//                         ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           color: isDark ? const Color(0xFF1E293B) : Colors.white,
//           border: Border(
//             top: BorderSide(
//               color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
//               width: 1,
//             ),
//           ),
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(vertical: 8),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _buildNavItem(Icons.home, 'Home', 0),
//                 _buildNavItem(Icons.share, 'Share', 1),
//                 _buildNavItem(Icons.history, 'History', 2),
//                 _buildNavItem(Icons.person, 'Profile', 3),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildNavItem(IconData icon, String label, int index) {
//     final isSelected = selectedIndex == index;
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           selectedIndex = index;
//         });
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         decoration: BoxDecoration(
//           color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               icon,
//               size: 20,
//               color: isSelected
//                   ? Colors.white
//                   : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//                 color: isSelected
//                     ? Colors.white
//                     : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }