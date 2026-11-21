import '../models/earning.dart';

enum EarningsStatus { loading, success, error, empty }

class EarningsState {
  final EarningsStatus status;
  final List<Earning> earnings;
  final Set<String> earningIds;
  final String? error;
  final String? loadingDetailId;
  final String? liveUpdateNotice;

  const EarningsState({
    this.status = EarningsStatus.loading,
    this.earnings = const [],
    this.earningIds = const {},
    this.error,
    this.loadingDetailId,
    this.liveUpdateNotice,
  });

  EarningsState copyWith({
    EarningsStatus? status,
    List<Earning>? earnings,
    Set<String>? earningIds,
    String? error,
    String? loadingDetailId,
    String? liveUpdateNotice,
    bool clearDetailLoading = false,
    bool clearLiveUpdateNotice = false,
  }) {
    return EarningsState(
      status: status ?? this.status,
      earnings: earnings ?? this.earnings,
      earningIds: earningIds ?? this.earningIds,
      error: error ?? this.error,
      loadingDetailId: clearDetailLoading ? null : (loadingDetailId ?? this.loadingDetailId),
      liveUpdateNotice: clearLiveUpdateNotice ? null : (liveUpdateNotice ?? this.liveUpdateNotice),
    );
  }
}
