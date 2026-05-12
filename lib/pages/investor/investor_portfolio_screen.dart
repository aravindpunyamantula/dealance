import 'package:flutter/material.dart';
import '../../utils/app_palette.dart';

/// Placeholder portfolio screen for investors
class InvestorPortfolioScreen extends StatelessWidget {
  const InvestorPortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Portfolio 📊',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Revalia',
                  color: AppPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Track your invested deals',
                style: TextStyle(fontSize: 14, color: AppPalette.textSecondary),
              ),
              const Spacer(),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.pie_chart_outline, size: 64, color: AppPalette.textTerenary),
                    const SizedBox(height: 12),
                    const Text(
                      'Your portfolio will appear here',
                      style: TextStyle(fontSize: 15, color: AppPalette.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Start by exploring deals in the Deal Flow tab',
                      style: TextStyle(fontSize: 13, color: AppPalette.textTerenary),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
