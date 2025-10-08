import 'package:flutter/material.dart';
import 'package:transcrypt/methods/methods.dart';
import 'package:transcrypt/models/DeviceInfoModel.dart';
import 'package:transcrypt/screens/file_share_speed.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:transcrypt/screens/History.dart';

// Supabase client
final supabase = Supabase.instance.client;

void main() {
  runApp(const HOME());
}

class HOME extends StatefulWidget {
  const HOME({super.key});

  @override
  State<HOME> createState() => _HOMEState();
}

class _HOMEState extends State<HOME> {
  late DeviceInfo deviceInfo;

  Future<void> _loadDeviceInfo() async {
    deviceInfo = await Methods.getDeviceInfo();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TransCrypt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with TickerProviderStateMixin {
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
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
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

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _isDarkMode
            ? const Color(0xFF0F172A)
            : const Color(0xFFF5F7FA),

        drawer: _buildDrawer(),

        body: Stack(
          children: [
            // Background gradient
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
                  // App Bar
                  _buildAppBar(),

                  // Main Content
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildContent(),
                    ),
                  ),
                ],
              ),
            ),

            // Profile Overlay
            if (_showProfile) _buildProfileOverlay(_isDarkMode)
          ],
        ),

        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildAppBar() {
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
            // T Logo → opens Drawer
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
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'T',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // App Name
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF9333EA)],
              ).createShader(bounds),
              child: const Text(
                'TransCrypt',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const Spacer(),

            // Theme toggle
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleTheme,
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isDarkMode
                        ? const Color(0xFF334155)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) =>
                        RotationTransition(turns: animation, child: child),
                    child: Icon(
                      _isDarkMode
                          ? Icons.wb_sunny
                          : Icons.nightlight_round,
                      key: ValueKey(_isDarkMode),
                      color: _isDarkMode
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFF64748B),
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

  Widget _buildContent() {
    switch (_currentIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return TransCryptApp();
      case 2:
        return FileHistoryPage();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? const Color(0xFF1E293B).withOpacity(0.8)
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Connection Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                                _isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildInfoCard(Icons.wifi, 'Network',
                    _deviceInfoLoaded ? deviceInfo.wifiName! : 'Loading...',
                    const Color(0xFF3B82F6)),
                _buildInfoCard(Icons.tag, 'IP Address',
                    _deviceInfoLoaded ? deviceInfo.wifiIP : 'Loading...',
                    const Color(0xFF9333EA)),
                _buildInfoCard(
                    Icons.settings_ethernet,
                    'Port Number',
                    _deviceInfoLoaded
                        ? deviceInfo.port.toString()
                        : 'Loading...',
                    const Color(0xFF6366F1)),
                _buildInfoCard(
                    Icons.devices,
                    'Device Name',
                    _deviceInfoLoaded ? deviceInfo.name! : 'Loading...',
                    const Color(0xFFEC4899)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? const Color(0xFF334155).withOpacity(0.5)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: _isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[600])),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      backgroundColor:
          _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF9333EA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.only(bottomRight: Radius.circular(32)),
              ),
              child: const Text(
                'TransCrypt Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
      leading: Icon(icon,
          color:
              _isDarkMode ? const Color(0xFF93C5FD) : const Color(0xFF3B82F6)),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title clicked'),
            duration: const Duration(milliseconds: 800),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? const Color(0xFF1E293B).withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Home', 0),
          _buildNavItem(Icons.share, 'Share', 1),
          _buildNavItem(Icons.history, 'History', 2),
          _buildNavItem(Icons.person, 'Profile', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    final isProfile = index == 3;

    return InkWell(
      onTap: () {
        if (isProfile) {
          setState(() => _showProfile = !_showProfile);
        } else {
          setState(() {
            _currentIndex = index;
            _showProfile = false;
          });
          _animationController
            ..reset()
            ..forward();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected || (isProfile && _showProfile)
              ? const Color(0xFF3B82F6).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected || (isProfile && _showProfile)
                  ? const Color(0xFF3B82F6)
                  : _isDarkMode
                      ? Colors.grey[400]
                      : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : _isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOverlay(bool _isDarkMode) {
    return Positioned(
      top: 80,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color:
                      _isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'User information and settings will be displayed here',
                style: TextStyle(
                    color: _isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
