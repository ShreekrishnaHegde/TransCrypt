import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './auth_service.dart';
import 'online_users_widget.dart';
import 'package:transcrypt/methods/methods.dart';
import 'package:transcrypt/models/DeviceInfoModel.dart';
import 'package:transcrypt/screens/History.dart';
import 'package:transcrypt/screens/file_share_speed.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isDarkMode = false;
  bool _showProfile = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late DeviceInfo deviceInfo;
  bool _deviceInfoLoaded = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    deviceInfo = await Methods.getDeviceInfo();
    setState(() {
      _deviceInfoLoaded = true;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleTheme() => setState(() => _isDarkMode = !_isDarkMode);

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    return Theme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _buildDrawer(),
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isDarkMode
                        ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                        : [const Color(0xFFEBF4FF), const Color(0xFFF3E8FF)],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(currentUser),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildContent(authService),
                    ),
                  ),
                ],
              ),
            ),
            if (_showProfile) _buildProfileOverlay(),
          ],
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildAppBar(user) {
    return Builder(
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: _isDarkMode
              ? const Color(0xFF1E293B).withOpacity(0.8)
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: Hero(
                tag: 'app_logo',
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF9333EA)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('T', style: TextStyle(color: Colors.white, fontSize: 24))),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF9333EA)],
              ).createShader(bounds),
              child: const Text('TransCrypt', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const Spacer(),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleTheme,
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) =>
                        RotationTransition(turns: animation, child: child),
                    child: Icon(
                      _isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                      key: ValueKey(_isDarkMode),
                      color: _isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFF64748B),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AuthService authService) {
    switch (_currentIndex) {
      case 0:
        return _buildDashboard(authService.currentUser);
      case 1:
        return FileTransferPage();
      case 2:
        return FileHistoryPage();
      case 3:
        return OnlineUsersList();
      default:
        return _buildDashboard(authService.currentUser);
    }
  }

  Widget _buildDashboard(user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Welcome Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back!', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(user?.email ?? 'User', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text('You are online', style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Device Info Cards
          if (_deviceInfoLoaded)
            _buildInfoCard(Icons.wifi, 'Network', deviceInfo.wifiName!, const Color(0xFF3B82F6)),
          if (_deviceInfoLoaded)
            _buildInfoCard(Icons.tag, 'IP Address', deviceInfo.wifiIP, const Color(0xFF9333EA)),
          if (_deviceInfoLoaded)
            _buildInfoCard(Icons.settings_ethernet, 'Port Number', deviceInfo.port.toString(), const Color(0xFF6366F1)),
          if (_deviceInfoLoaded)
            _buildInfoCard(Icons.devices, 'Device Name', deviceInfo.name!, const Color(0xFFEC4899)),

          const SizedBox(height: 16),

          // Quick Actions
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.people,
                  label: 'View Online Users',
                  color: Colors.blue,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.refresh,
                  label: 'Refresh Status',
                  color: Colors.green,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status refreshed!'), duration: Duration(seconds: 1)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF334155).withOpacity(0.5) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.white, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600])),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _isDarkMode ? Colors.white : Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      backgroundColor: _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF9333EA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.only(bottomRight: Radius.circular(32)),
              ),
              child: const Text('TransCrypt Menu', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            _buildDrawerItem(Icons.people_alt, 'Online Peer-to-Peer'),
            _buildDrawerItem(Icons.wifi_tethering, 'Online Multicast'),
            _buildDrawerItem(Icons.wifi_off, 'Offline Multicast'),
            const Divider(thickness: 0.5),
            _buildDrawerItem(Icons.settings, 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: _isDarkMode ? const Color(0xFF93C5FD) : const Color(0xFF3B82F6)),
      title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _isDarkMode ? Colors.white : Colors.black87)),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title clicked'), duration: const Duration(milliseconds: 800)));
      },
    );
  }

  Widget _buildBottomNavBar() {
    final navItems = [
      {'icon': Icons.home, 'label': 'Home'},
      {'icon': Icons.share, 'label': 'Share'},
      {'icon': Icons.history, 'label': 'History'},
      {'icon': Icons.people, 'label': 'Online Users'},
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E293B).withOpacity(0.95) : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navItems.length, (index) {
          final item = navItems[index];
          final isSelected = _currentIndex == index;
          return InkWell(
            onTap: () {
              setState(() {
                _currentIndex = index;
                _showProfile = false;
                _animationController..reset()..forward();
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item['icon'] as IconData, color: isSelected ? const Color(0xFF3B82F6) : _isDarkMode ? Colors.grey[400] : Colors.grey[600], size: 24),
                  const SizedBox(height: 4),
                  Text(item['label'] as String, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? const Color(0xFF3B82F6) : _isDarkMode ? Colors.grey[400] : Colors.grey[600])),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProfileOverlay() {
    return Positioned(
      top: 80,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : Colors.black87)),
              const SizedBox(height: 8),
              Text('User information and settings will be displayed here', style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }
}

/// Action card widget
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
