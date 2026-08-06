import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telephony/telephony.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isCompleting = false;

  static const _pages = [
    _OnboardingPage(
      gradientColors: [Color(0xFF66FCF1), Color(0xFF45A29E)],
      icon: Icons.account_balance_rounded,
      title: "Sri Lanka's\nFinancial Hub",
      subtitle:
          "Compare FD rates across all major banks, calculate loan EMIs, track exchange rates — everything in one trusted platform.",
      tag: 'Compare. Calculate. Decide.',
    ),
    _OnboardingPage(
      gradientColors: [Color(0xFF7E57C2), Color(0xFF512DA8)],
      icon: Icons.sms_rounded,
      title: 'Auto-Capture\nTransactions',
      subtitle:
          'SalliMate reads your bank SMS messages to automatically log transactions. No manual entry, no missed expenses.',
      tag: 'Your data stays on your device.',
    ),
    _OnboardingPage(
      gradientColors: [Color(0xFFFFA726), Color(0xFFE64A19)],
      icon: Icons.insights_rounded,
      title: 'Budgets &\nInsights',
      subtitle:
          'Set monthly budgets per category, see spending trends, and get clear insights into where your money goes.',
      tag: 'Know your money. Control it.',
    ),
  ];

  Future<void> _complete() async {
    setState(() => _isCompleting = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    // Request SMS permission — Android only; continues regardless of result on iOS
    bool smsGranted = false;
    try {
      smsGranted = await Telephony.instance.requestPhoneAndSmsPermissions ?? false;
    } catch (_) {}

    if (!mounted) return;

    // Inform the user of the permission outcome before proceeding
    if (!smsGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'SMS access not granted — you can enable it later in Settings for automatic transaction capture.',
          ),
          backgroundColor: const Color(0xFF1A1B1E),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      // Brief pause so the snackbar is visible before transitioning
      await Future.delayed(const Duration(milliseconds: 1500));
    }

    if (mounted) widget.onComplete();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  void _skip() => _complete();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isCompleting ? null : _skip,
                child: const Text(
                  'Skip',
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _buildPage(_pages[i]),
              ),
            ),

            // Bottom bar
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? _pages[_currentPage].gradientColors[0]
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Next / Get Started button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isCompleting ? null : _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].gradientColors[0],
                        foregroundColor: const Color(0xFF0B0C10),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isCompleting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF0B0C10),
                              ),
                            )
                          : Text(
                              isLastPage ? 'Get Started' : 'Next',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with gradient background
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: page.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: page.gradientColors[0].withValues(alpha: 0.3),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(page.icon, size: 56, color: const Color(0xFF0B0C10)),
          ),
          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),

          // Subtitle
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),

          // Tag pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: page.gradientColors[0].withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: page.gradientColors[0].withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              page.tag,
              style: TextStyle(
                color: page.gradientColors[0],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final List<Color> gradientColors;
  final IconData icon;
  final String title;
  final String subtitle;
  final String tag;

  const _OnboardingPage({
    required this.gradientColors,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tag,
  });
}
