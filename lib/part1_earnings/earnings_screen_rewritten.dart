import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/utils/currency_formatter.dart';
import 'cubit/earnings_cubit.dart';
import 'cubit/earnings_state.dart';
import 'detail_screen.dart';
import 'models/earning.dart';

class RewrittenEarningsScreen extends StatelessWidget {
  const RewrittenEarningsScreen({super.key});

  Future<void> _onEarningTapped(BuildContext context, Earning earning) async {
    try {
      final detail = await context.read<EarningsCubit>().fetchDetail(earning);
      if (!context.mounted || detail == null) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(detail: detail)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load transaction details: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EarningsCubit, EarningsState>(
      listenWhen: (prev, curr) => curr.liveUpdateNotice != null,
      listener: (context, state) {
        if (state.liveUpdateNotice != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.liveUpdateNotice!),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<EarningsCubit>().clearLiveUpdateNotice();
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Earnings (Cubit)'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Reload',
                onPressed: () => context.read<EarningsCubit>().loadEarnings(),
              ),
            ],
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, EarningsState state) {
    switch (state.status) {
      case EarningsStatus.loading:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(strokeWidth: 2.5),
              SizedBox(height: 16),
              Text('Fetching earnings history...', style: AppTextStyles.subtitle),
            ],
          ),
        );

      case EarningsStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 60, color: AppColors.error),
                const SizedBox(height: 16),
                const Text('Could not load earnings', style: AppTextStyles.h1),
                const SizedBox(height: 8),
                Text(
                  state.error ?? 'Unknown error occurred.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => context.read<EarningsCubit>().loadEarnings(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        );

      case EarningsStatus.empty:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 60, color: AppColors.textMuted),
              SizedBox(height: 16),
              Text('No earnings yet', style: AppTextStyles.h1),
              SizedBox(height: 8),
              Text('Complete freelance tasks on Funngro to start earning!', style: AppTextStyles.subtitle),
            ],
          ),
        );

      case EarningsStatus.success:
        return Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.primaryLight,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Records: ${state.earnings.length}',
                    style: AppTextStyles.infoHeader.copyWith(color: AppColors.primaryDark),
                  ),
                  Text(
                    'Live Stream: Active 🟢',
                    style: AppTextStyles.infoHeader.copyWith(color: AppColors.success),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: state.earnings.length,
                itemExtent: 74.0,
                itemBuilder: (context, index) {
                  final earning = state.earnings[index];
                  final formattedAmount = AppCurrencyFormatter.formatInr(earning.amount);
                  final isTileLoading = state.loadingDetailId == earning.id;

                  return _EarningTile(
                    earning: earning,
                    formattedAmount: formattedAmount,
                    isLoading: isTileLoading,
                    onTap: () => _onEarningTapped(context, earning),
                  );
                },
              ),
            ),
          ],
        );
    }
  }
}

class _EarningTile extends StatelessWidget {
  final Earning earning;
  final String formattedAmount;
  final bool isLoading;
  final VoidCallback onTap;

  const _EarningTile({
    required this.earning,
    required this.formattedAmount,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(
          backgroundColor: AppColors.successLight,
          child: Icon(Icons.arrow_downward, color: AppColors.success, size: 18),
        ),
        title: Text(
          earning.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.title,
        ),
        subtitle: Text(
          '${earning.date.day}/${earning.date.month}/${earning.date.year} • ID: ${earning.id}',
          style: AppTextStyles.caption,
        ),
        trailing: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(formattedAmount, style: AppTextStyles.payout),
      ),
    );
  }
}
