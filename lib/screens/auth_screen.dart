// File: lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/database_service.dart';
import '../models/user.dart';

class AuthScreen extends StatefulWidget {
  final Function(AppUser) onLoginSuccess;

  const AuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();

  // Login controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginObscurePassword = true;
  bool _isLoggingIn = false;

  // Signup controllers
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();
  bool _signupObscurePassword = true;
  bool _signupObscureConfirmPassword = true;
  bool _isSigningUp = false;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    setState(() => _isLoggingIn = true);

    final result = await _authService.login(email, password);

    if (!mounted) return;
    setState(() => _isLoggingIn = false);

    if (result.success && result.user != null) {
      await _promptEnableBiometric(result.user!);
      if (mounted) widget.onLoginSuccess(result.user!);
    } else {
      _showError(result.message ?? 'Login failed');
    }
  }

  Future<void> _handleSignup() async {
    final name = _signupNameController.text.trim();
    final email = _signupEmailController.text.trim();
    final password = _signupPasswordController.text;
    final confirmPassword = _signupConfirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }

    if (!_agreedToTerms) {
      _showError('Please agree to the Terms & Conditions');
      return;
    }

    final passwordError = AuthService.validatePassword(password);
    if (passwordError != null) {
      _showError(passwordError);
      return;
    }

    setState(() => _isSigningUp = true);

    final result = await _authService.signup(name, email, password);

    if (!mounted) return;
    setState(() => _isSigningUp = false);

    if (result.success && result.user != null) {
      _showSuccess('Welcome to SalliMate, $name!');
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      await _promptEnableBiometric(result.user!);
      if (mounted) widget.onLoginSuccess(result.user!);
    } else {
      _showError(result.message ?? 'Signup failed');
    }
  }

  Future<void> _promptEnableBiometric(AppUser user) async {
    final biometric = BiometricService();
    if (user.isBiometricEnabled) return;
    final available = await biometric.isAvailable();
    if (!available || !mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1B1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF66FCF1).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.fingerprint_rounded, color: Color(0xFF66FCF1), size: 30),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enable Biometric Login?',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use Face ID or fingerprint to unlock SalliMate faster next time.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white54,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Not Now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      user.isBiometricEnabled = true;
                      await DatabaseService().updateUser(user);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF66FCF1),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Enable', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Logo
                _buildLogo(),
                const SizedBox(height: 40),
                // Tab bar
                _buildTabBar(),
                const SizedBox(height: 32),
                // Tab content
                SizedBox(
                  height: 500,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLoginForm(),
                      _buildSignupForm(),
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

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF66FCF1), Color(0xFF45A29E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF66FCF1).withValues(alpha:0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'SM',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0B0C10),
                letterSpacing: -2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'SalliMate',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your Smart Financial Assistant',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha:0.5),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF66FCF1).withValues(alpha:0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: const Color(0xFF66FCF1),
        unselectedLabelColor: Colors.white.withValues(alpha:0.4),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'Login'),
          Tab(text: 'Sign Up'),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email
        TextField(
          controller: _loginEmailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration(
            label: 'Email',
            hint: 'Enter your email',
            icon: Icons.email_outlined,
          ),
        ),
        const SizedBox(height: 16),

        // Password
        TextField(
          controller: _loginPasswordController,
          obscureText: _loginObscurePassword,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration(
            label: 'Password',
            hint: 'Enter your password',
            icon: Icons.lock_outlined,
            suffix: IconButton(
              icon: Icon(
                _loginObscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.white.withValues(alpha:0.4),
              ),
              onPressed: () => setState(() => _loginObscurePassword = !_loginObscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Login button
        ElevatedButton(
          onPressed: _isLoggingIn ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF66FCF1),
            foregroundColor: const Color(0xFF0B0C10),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: _isLoggingIn
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0B0C10)),
                )
              : const Text(
                  'Login',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(height: 20),

        // Test accounts hint
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF66FCF1).withValues(alpha:0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            '💡 First time? Switch to Sign Up tab to create an account.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Name
        TextField(
          controller: _signupNameController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration(
            label: 'Full Name',
            hint: 'Enter your full name',
            icon: Icons.person_outline,
          ),
        ),
        const SizedBox(height: 16),

        // Email
        TextField(
          controller: _signupEmailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration(
            label: 'Email',
            hint: 'Enter your email',
            icon: Icons.email_outlined,
          ),
        ),
        const SizedBox(height: 16),

        // Password
        TextField(
          controller: _signupPasswordController,
          obscureText: _signupObscurePassword,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration(
            label: 'Password',
            hint: 'Min 6 chars, 1 uppercase, 1 number',
            icon: Icons.lock_outlined,
            suffix: IconButton(
              icon: Icon(
                _signupObscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.white.withValues(alpha:0.4),
              ),
              onPressed: () => setState(() => _signupObscurePassword = !_signupObscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Confirm Password
        TextField(
          controller: _signupConfirmPasswordController,
          obscureText: _signupObscureConfirmPassword,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration(
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            icon: Icons.lock_outlined,
            suffix: IconButton(
              icon: Icon(
                _signupObscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.white.withValues(alpha:0.4),
              ),
              onPressed: () => setState(() => _signupObscureConfirmPassword = !_signupObscureConfirmPassword),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Terms checkbox
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _agreedToTerms,
                onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                activeColor: const Color(0xFF66FCF1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.white.withValues(alpha:0.6), fontSize: 12),
                  children: const [
                    TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms & Conditions',
                      style: TextStyle(color: Color(0xFF66FCF1)),
                    ),
                    TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(color: Color(0xFF66FCF1)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Sign up button
        ElevatedButton(
          onPressed: _isSigningUp ? null : _handleSignup,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF66FCF1),
            foregroundColor: const Color(0xFF0B0C10),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: _isSigningUp
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0B0C10)),
                )
              : const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha:0.3)),
      labelStyle: TextStyle(color: Colors.white.withValues(alpha:0.5)),
      prefixIcon: Icon(icon, color: Colors.white.withValues(alpha:0.4)),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF1A1A2E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF66FCF1), width: 1),
      ),
    );
  }
}