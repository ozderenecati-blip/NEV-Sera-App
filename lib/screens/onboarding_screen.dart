import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../providers/theme_provider.dart';
import '../widgets/modern_widgets.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<OnboardingItem> _items = [
    OnboardingItem(
      icon: Icons.account_balance_wallet,
      title: 'Kasa Yönetimi',
      description: 'Tüm nakit hareketlerinizi tek bir yerden takip edin. TL, EUR ve USD cinsinden gelir-gider kaydı yapın.',
      gradient: AppGradients.primaryGradient,
    ),
    OnboardingItem(
      icon: Icons.credit_card,
      title: 'Kredi Takibi',
      description: 'Banka kredilerinizi ve taksitlerini kolayca takip edin. Yaklaşan ödemeler için bildirim alın.',
      gradient: AppGradients.infoGradient,
    ),
    OnboardingItem(
      icon: Icons.receipt_long,
      title: 'Gider Pusulası',
      description: 'Gündelikçi ödemelerinizi kaydedin, vergi hesaplamalarınızı otomatik yapın.',
      gradient: AppGradients.accentGradient,
    ),
    OnboardingItem(
      icon: Icons.analytics,
      title: 'Raporlar & Analizler',
      description: 'Detaylı raporlarla finansal durumunuzu analiz edin. Excel\'e aktarın, paylaşın.',
      gradient: AppGradients.successGradient,
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ThemeProvider.primaryColor.withOpacity(0.1),
              ThemeProvider.surfaceLight,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip butonu
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Atla',
                      style: TextStyle(
                        color: ThemeProvider.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms),
              
              // Sayfa içeriği
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _items.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    HapticHelper.lightTap();
                  },
                  itemBuilder: (context, index) {
                    return _buildPage(_items[index], index);
                  },
                ),
              ),
              
              // Alt bölüm: Indicator ve butonlar
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    // Sayfa göstergesi
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: _items.length,
                      effect: ExpandingDotsEffect(
                        dotWidth: 10,
                        dotHeight: 10,
                        spacing: 8,
                        activeDotColor: ThemeProvider.primaryColor,
                        dotColor: ThemeProvider.primaryColor.withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Devam butonu
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticHelper.mediumTap();
                          if (_currentPage < _items.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _completeOnboarding();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeProvider.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage < _items.length - 1 
                                  ? 'Devam' 
                                  : 'Başla',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentPage < _items.length - 1 
                                  ? Icons.arrow_forward 
                                  : Icons.check,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingItem item, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // İkon container
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              gradient: item.gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: item.gradient.colors.first.withOpacity(0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Icon(
              item.icon,
              size: 80,
              color: Colors.white,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                duration: 2.seconds,
                curve: Curves.easeInOut,
              ),
          
          const SizedBox(height: 48),
          
          // Başlık
          Text(
            item.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          
          const SizedBox(height: 16),
          
          // Açıklama
          Text(
            item.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}

class OnboardingItem {
  final IconData icon;
  final String title;
  final String description;
  final Gradient gradient;

  OnboardingItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}
