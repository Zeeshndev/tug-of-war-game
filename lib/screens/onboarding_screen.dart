import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart'; // Using your custom BigButton

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentSlide = 0;
  bool _showAgeSelection = false;

  // Exact data from UC-002 Functional Requirements
  final List<Map<String, String>> _slides = [
    {
      'icon': '🔢 ❓',
      'title': 'Answer Math Questions',
      'desc': 'Type the answer as fast as you can!'
    },
    {
      'icon': '🪢 ⬅️',
      'title': 'Pull the Rope!',
      'desc': 'Every correct answer pulls the rope to your side.'
    },
    {
      'icon': '🏆 🎉',
      'title': 'Win the Match!',
      'desc': 'Pull the rope all the way across to win!'
    },
  ];

  void _onNext() {
    if (_currentSlide < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      setState(() => _showAgeSelection = true);
    }
  }

  void _onSkip() {
    setState(() => _showAgeSelection = true);
  }

  Future<void> _completeOnboarding(String ageGroup) async {
    // Save to local storage via your existing Riverpod providers
    await ref.read(profileProvider.notifier).setAgeGroup(ageGroup);
    await ref.read(profileProvider.notifier).completeOnboarding();
    
    if (mounted) context.go('/home');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F2E),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _showAgeSelection ? _buildAgeSelection() : _buildTutorialSlides(),
        ),
      ),
    );
  }

  // ── 1. The Tutorial Slides View (UC-002) ──
  Widget _buildTutorialSlides() {
    return Column(
      key: const ValueKey('slides'),
      children: [
        // Skip Button
        Align(
          alignment: Alignment.topRight,
          child: TextButton(
            onPressed: _onSkip,
            child: Text('SKIP', style: AppTheme.body(14, color: AppTheme.textSecondary, weight: FontWeight.w800)),
          ),
        ),
        
        // PageView for Slides
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentSlide = index),
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppTheme.bg2,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppTheme.blue.withOpacity(0.2), blurRadius: 40, spreadRadius: 10)],
                      ),
                      child: Text(slide['icon']!, style: const TextStyle(fontSize: 80)),
                    ),
                    const SizedBox(height: 50),
                    Text(
                      slide['title']!,
                      style: AppTheme.display(28, color: AppTheme.yellowLight),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      slide['desc']!,
                      style: AppTheme.body(16, color: AppTheme.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Bottom Controls
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          child: Column(
            children: [
              // Dots Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) => _Dot(active: i == _currentSlide)),
              ),
              const SizedBox(height: 32),
              // Next / Let's Play Button
              BigButton(
                label: _currentSlide == _slides.length - 1 ? "LET'S PLAY! 🎮" : 'NEXT ▶',
                onTap: _onNext,
                color: AppTheme.blue,
                shadowColor: const Color(0xFF1A56B8),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 2. The Age Selection View (UC-002) ──
  Widget _buildAgeSelection() {
    return Padding(
      key: const ValueKey('age_selection'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: Text('👋', style: TextStyle(fontSize: 80))),
          const SizedBox(height: 20),
          Text(
            "Who's playing?",
            style: AppTheme.display(32, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your age group for the best math challenges!',
            style: AppTheme.body(16, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 50),
          
          _AgeCard(
            emoji: '🌱', 
            title: 'Group A: Ages 5-7',
            desc: 'Addition & Subtraction, forgiving pace',
            onTap: () => _completeOnboarding('A'),
          ),
          const SizedBox(height: 20),
          
          _AgeCard(
            emoji: '🚀', 
            title: 'Group B: Ages 8-11',
            desc: 'All 4 operations, fast-paced challenge',
            onTap: () => _completeOnboarding('B'),
          ),
        ],
      ),
    );
  }
}

// ── Reusable UI Components ──

class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppTheme.yellow : AppTheme.bg3,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _AgeCard extends StatelessWidget {
  final String emoji, title, desc;
  final VoidCallback onTap;

  const _AgeCard({
    required this.emoji, required this.title, required this.desc, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.bg2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.bg3, width: 2),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.display(18, color: AppTheme.yellowLight)),
                  Text(desc, style: AppTheme.body(13, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}