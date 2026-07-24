import 'package:flutter/material.dart';
import '../theme/soma_theme.dart';
import '../services/auth_service.dart';
import '../main.dart' show MainScreen;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;
  String? _error;

  void _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Email dan password tidak boleh kosong');
      return;
    }
    
    if (!_isLogin && _nameController.text.trim().isEmpty) {
      setState(() => _error = 'Nama tidak boleh kosong');
      return;
    }

    setState(() => _error = null);
    
    // Simpan session via AuthService
    final name = _isLogin ? 'Pak Husni' : _nameController.text.trim();
    await AuthService.login(name, email);
    
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SomaTheme.bgDeep,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [SomaTheme.teal.withOpacity(0.3), SomaTheme.bgCard]),
                    border: Border.all(color: SomaTheme.teal, width: 2),
                  ),
                  child: Icon(Icons.psychology, color: SomaTheme.tealBright, size: 40),
                ),
                const SizedBox(height: 20),
                Text('SOMA', style: TextStyle(
                  color: SomaTheme.white, fontSize: 32, fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                )),
                const SizedBox(height: 6),
                Text('Bangunkan kekuatan otak yang tidur', style: TextStyle(
                  color: SomaTheme.textMuted, fontSize: 13,
                )),
                const SizedBox(height: 40),
                
                // Toggle Login/Register
                Container(
                  decoration: BoxDecoration(
                    color: SomaTheme.bgCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isLogin = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isLogin ? SomaTheme.teal.withOpacity(0.15) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('Masuk', style: TextStyle(
                              color: _isLogin ? SomaTheme.tealBright : SomaTheme.textMuted,
                              fontWeight: FontWeight.w600, fontSize: 14,
                            ), textAlign: TextAlign.center),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isLogin = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isLogin ? SomaTheme.teal.withOpacity(0.15) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('Daftar', style: TextStyle(
                              color: !_isLogin ? SomaTheme.tealBright : SomaTheme.textMuted,
                              fontWeight: FontWeight.w600, fontSize: 14,
                            ), textAlign: TextAlign.center),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Form
                if (!_isLogin) ...[
                  _buildInput(_nameController, 'Nama Lengkap', Icons.person),
                  const SizedBox(height: 12),
                ],
                _buildInput(_emailController, 'Email', Icons.email),
                const SizedBox(height: 12),
                _buildPasswordInput(),
                
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Colors.red, fontSize: 12)),
                ],
                
                const SizedBox(height: 24),
                
                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SomaTheme.teal,
                      foregroundColor: SomaTheme.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(_isLogin ? 'Masuk' : 'Daftar Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Demo login
                TextButton(
                  onPressed: () async {
                    await AuthService.login('Demo User', 'demo@soma.app');
                    if (!mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MainScreen()),
                    );
                  },
                  child: Text('Coba Demo (demo@soma.app / soma123)', style: TextStyle(color: SomaTheme.textMuted, fontSize: 12)),
                ),
                
                const SizedBox(height: 40),
                
                // Subscription info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SomaTheme.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SomaTheme.lavender.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Text('Paket Berlangganan', style: TextStyle(color: SomaTheme.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      _buildPlan('Free', 'Rp 0', '3 fitur dasar', false),
                      _buildPlan('Premium', 'Rp 49rb/bln', 'Semua fitur + no ads', true),
                      _buildPlan('Pro', 'Rp 99rb/bln', 'Premium + AI coach', false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      style: TextStyle(color: SomaTheme.text),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: SomaTheme.teal, size: 20),
      ),
    );
  }

  Widget _buildPasswordInput() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: TextStyle(color: SomaTheme.text),
      decoration: InputDecoration(
        hintText: 'Password',
        prefixIcon: Icon(Icons.lock, color: SomaTheme.teal, size: 20),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
          child: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: SomaTheme.textMuted, size: 20),
        ),
      ),
    );
  }

  Widget _buildPlan(String name, String price, String desc, bool popular) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: popular ? SomaTheme.teal.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: popular ? Border.all(color: SomaTheme.teal.withOpacity(0.3)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(name, style: TextStyle(color: SomaTheme.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  if (popular) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: SomaTheme.teal, borderRadius: BorderRadius.circular(4)),
                      child: Text('Popular', style: TextStyle(color: SomaTheme.white, fontSize: 9, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
              Text(desc, style: TextStyle(color: SomaTheme.textMuted, fontSize: 11)),
            ],
          ),
          Text(price, style: TextStyle(color: SomaTheme.tealBright, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}