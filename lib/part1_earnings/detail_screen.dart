import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import 'models/earning.dart';

class DetailScreen extends StatelessWidget {
  final EarningDetail detail;

  const DetailScreen({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earning Details')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified, color: AppColors.success, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      detail.status,
                      style: AppTextStyles.title.copyWith(color: AppColors.success),
                    ),
                  ],
                ),
                const Divider(height: 24, color: AppColors.divider),
                const Text('Transaction Reference', style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Text(detail.referenceNumber, style: AppTextStyles.title),
                const SizedBox(height: 16),
                const Text('Description', style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Text(detail.description, style: AppTextStyles.subtitle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
