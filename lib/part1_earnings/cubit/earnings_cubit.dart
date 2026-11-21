import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/currency_formatter.dart';
import '../fake_earnings_api.dart';
import '../models/earning.dart';
import 'earnings_state.dart';

class EarningsCubit extends Cubit<EarningsState> {
  final FakeEarningsApi api;
  final String userId;
  StreamSubscription<WalletUpdate>? _walletSubscription;

  EarningsCubit({required this.api, required this.userId})
      : super(const EarningsState()) {
    _subscribeWalletUpdates();
    loadEarnings();
  }

  void _subscribeWalletUpdates() {
    _walletSubscription = api.walletUpdates(userId).listen(
      (update) {
        if (isClosed) return;

        // Deduplicate updates by ID
        if (state.earningIds.contains(update.id)) return;

        final newEarning = update.toEarning();
        final updatedIds = Set<String>.from(state.earningIds)..add(update.id);
        final updatedList = [newEarning, ...state.earnings];

        emit(state.copyWith(
          status: EarningsStatus.success,
          earnings: updatedList,
          earningIds: updatedIds,
          liveUpdateNotice:
              'New Earning: +${AppCurrencyFormatter.formatInr(update.amount)}',
        ));
      },
      onError: (_) {},
    );
  }

  Future<void> loadEarnings() async {
    emit(state.copyWith(status: EarningsStatus.loading));

    try {
      final fetchedData = await api.fetchEarnings(userId);
      if (isClosed) return;

      if (fetchedData.isEmpty && state.earnings.isEmpty) {
        emit(state.copyWith(status: EarningsStatus.empty));
        return;
      }

      final updatedIds = Set<String>.from(state.earningIds);
      final mergedList = List<Earning>.from(state.earnings);

      for (final item in fetchedData) {
        if (!updatedIds.contains(item.id)) {
          updatedIds.add(item.id);
          mergedList.add(item);
        }
      }

      emit(state.copyWith(
        status: EarningsStatus.success,
        earnings: mergedList,
        earningIds: updatedIds,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        status: EarningsStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<EarningDetail?> fetchDetail(Earning earning) async {
    if (earning.detail != null) return earning.detail;

    emit(state.copyWith(loadingDetailId: earning.id));
    try {
      final detail = await api.fetchDetail(earning.id);
      earning.detail = detail;
      if (!isClosed) emit(state.copyWith(clearDetailLoading: true));
      return detail;
    } catch (e) {
      if (!isClosed) emit(state.copyWith(clearDetailLoading: true));
      rethrow;
    }
  }

  void clearLiveUpdateNotice() {
    emit(state.copyWith(clearLiveUpdateNotice: true));
  }

  @override
  Future<void> close() {
    _walletSubscription?.cancel();
    _walletSubscription = null;
    return super.close();
  }
}
