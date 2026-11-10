import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../utils/app_colors.dart';

class DailyFlowSplashScreen extends StatefulWidget {
  const DailyFlowSplashScreen({super.key});

  @override
  State<DailyFlowSplashScreen> createState() => _DailyFlowSplashScreenState();
}

class _DailyFlowSplashScreenState extends State<DailyFlowSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _entrance;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _entrance = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('dailyflow-splash'),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AnimatedBuilder(
              animation: _entrance,
              builder: (context, child) => Opacity(
                opacity: _entrance.value,
                child: Transform.scale(
                  scale: 0.92 + (_entrance.value * 0.08),
                  child: child,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/branding/dailyflow_logo.png',
                    width: 148,
                    height: 148,
                    fit: BoxFit.contain,
                    semanticLabel: 'DailyFlow calendar and checklist logo',
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppConstants.appName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppConstants.appTagline,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
