import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _taglineFadeAnim;

  @override
  void initState() {
    super.initState();
    // 1.5 seconds for the entire entrance animation sequence
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    
    // Scale up with a premium elastic bounce
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );
    
    // Smooth fade in for the main logo
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );
    
    // Tagline appears slightly after the logo settles
    _taglineFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.6, 1.0, curve: Curves.easeIn)),
    );

    _ctrl.forward();

    // Enforce the 2.5 second total display time per SRS requirements
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        final hasOnboarded = StorageService.isOnboardingComplete;
        if (hasOnboarded) {
          context.go('/home');
        } else {
          // Temporarily routing to home until we build the Onboarding screen in UC-002
          context.go('/onboarding'); 
        }
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.blue.withOpacity(0.9), AppTheme.purple.withOpacity(0.9)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnim.value,
                  child: Transform.scale(
                    scale: _scaleAnim.value,
                    child: Column(
                      children: [
                        // Core Game Identity Icon
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.yellow.withOpacity(0.4),
                                blurRadius: 40,
                                spreadRadius: 5,
                              )
                            ]
                          ),
                          child: const Text(
                            '🦸 🪢 🤖',
                            style: TextStyle(fontSize: 54, shadows: [
                              Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))
                            ]),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Main Title
                        Text(
                          'BRAIN TUG',
                          style: AppTheme.display(48, color: Colors.white).copyWith(
                            letterSpacing: 2.5,
                            shadows: const [Shadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4))]
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                return Opacity(
                  opacity: _taglineFadeAnim.value,
                  child: Text(
                    'Epic Math Battles',
                    style: AppTheme.body(18, color: AppTheme.yellowLight, weight: FontWeight.w900).copyWith(
                      letterSpacing: 2.0,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}