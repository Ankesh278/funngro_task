import 'dart:async';
import 'dart:math';
import 'models/earning.dart';

class FakeEarningsApi {
  final _rng = Random();
  final StreamController<WalletUpdate> _walletController =
      StreamController<WalletUpdate>.broadcast();
  Timer? _ticker;

  FakeEarningsApi({bool enableBackgroundTicker = true}) {
    if (enableBackgroundTicker) {
      _ticker = Timer.periodic(const Duration(seconds: 12), (timer) {
        if (!_walletController.isClosed) {
          final id = 'wallet_${DateTime.now().millisecondsSinceEpoch}';
          _walletController.add(
            WalletUpdate(
              id: id,
              title: 'Live Task Payout #${timer.tick}',
              amount: (150 + _rng.nextInt(850)).toDouble(),
              timestamp: DateTime.now(),
            ),
          );
        }
      });
    }
  }

  Future<List<Earning>> fetchEarnings(String userId, {int count = 3000}) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final now = DateTime.now();

    return List.generate(count, (i) {
      return Earning(
        id: 'earn_$i',
        title: 'Project Milestone Completion #${count - i}',
        amount: (100 + (i % 25) * 50).toDouble(),
        date: now.subtract(Duration(hours: i * 2)),
      );
    });
  }

  Stream<WalletUpdate> walletUpdates(String userId) {
    return _walletController.stream;
  }

  Future<EarningDetail> fetchDetail(String earningId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return EarningDetail(
      id: earningId,
      description: 'Payment verified and transferred via Funngro Escrow.',
      referenceNumber: 'TXN-FNG-${earningId.toUpperCase()}',
      status: 'Settled to Bank Account',
    );
  }

  void dispose() {
    _ticker?.cancel();
    _walletController.close();
  }
}
