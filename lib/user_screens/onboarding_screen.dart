import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<OnboardingData> onboardingData = [
    OnboardingData(
      title: 'Welcome to FabricGrid',
      description:
          'Your one-stop marketplace for all fabric services and products',
      icon: Icons.shopping_bag,
    ),
    OnboardingData(
      title: 'Find Services',
      description:
          'Discover premium fabric services from trusted providers nearby',
      icon: Icons.store,
    ),
    OnboardingData(
      title: 'Shop Quality Products',
      description:
          'Browse and purchase high-quality fabrics from our marketplace',
      icon: Icons.checkroom,
    ),
    OnboardingData(
      title: 'Easy Booking',
      description: 'Schedule services and track bookings with just a few taps',
      icon: Icons.calendar_today,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemCount: onboardingData.length,
        itemBuilder: (context, index) => OnboardingPage(data: onboardingData[index]),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingData.length,
                (index) => Container(
                  height: 8,
                  width: _currentIndex == index ? 24 : 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? AppTheme.primaryColor
                        : AppTheme.borderLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_currentIndex == onboardingData.length - 1) {
                    Get.offAllNamed('/login');
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Text(
                  _currentIndex == onboardingData.length - 1
                      ? 'Get Started'
                      : 'Next',
                ),
              ),
            ),
            if (_currentIndex > 0) const SizedBox(height: 12),
            if (_currentIndex > 0)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Get.offAllNamed('/login'),
                  child: const Text('Skip'),
                ),
              ),
          ],
        ),
      ),
    );
}

class OnboardingData {

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
  });
  final String title;
  final String description;
  final IconData icon;
}

class OnboardingPage extends StatelessWidget {

  const OnboardingPage({required this.data, super.key});
  final OnboardingData data;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.1),
              ),
              child: Icon(
                data.icon,
                size: 60,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              data.title,
              style: AppTheme.headingLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              data.description,
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
}
