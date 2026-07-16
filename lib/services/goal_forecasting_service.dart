import 'package:financial_app/services/logger_service.dart';

class GoalForecastingService {
  Map<String, dynamic> forecastGoalCompletion({
    required double targetAmount,
    required double currentAmount,
    required double monthlyContribution,
    List<Map<String, dynamic>>? historicalContributions,
  }) {
    try {
      final remaining = targetAmount - currentAmount;
      if (remaining <= 0) {
        return {
          'monthsToCompletion': 0,
          'completionDate': DateTime.now().toIso8601String(),
          'onTrack': true,
          'projectedTotal': currentAmount,
          'confidence': 1.0,
        };
      }

      double avgContribution = monthlyContribution;
      double trend = 0.0;
      double confidence = 0.7;

      if (historicalContributions != null &&
          historicalContributions.isNotEmpty) {
        final sorted = List<Map<String, dynamic>>.from(
          historicalContributions,
        )..sort((a, b) {
          final aDate =
              DateTime.tryParse(a['date']?.toString() ?? '') ?? DateTime.now();
          final bDate =
              DateTime.tryParse(b['date']?.toString() ?? '') ?? DateTime.now();
          return aDate.compareTo(bDate);
        });

        double total = 0;
        for (final c in sorted) {
          total += (c['amount'] as num?)?.toDouble() ?? 0;
        }
        avgContribution = sorted.isEmpty ? 0.0 : total / sorted.length;

        if (sorted.length >= 3) {
          final firstHalf = sorted.take(sorted.length ~/ 2);
          final secondHalf = sorted.skip(sorted.length ~/ 2);

          double firstAvg = 0;
          for (final c in firstHalf) {
            firstAvg += (c['amount'] as num?)?.toDouble() ?? 0;
          }
          firstAvg /= firstHalf.length;

          double secondAvg = 0;
          for (final c in secondHalf) {
            secondAvg += (c['amount'] as num?)?.toDouble() ?? 0;
          }
          secondAvg /= secondHalf.length;

          if (firstAvg > 0) {
            trend = ((secondAvg - firstAvg) / firstAvg) * 100;
          }

          confidence = (0.7 + (sorted.length * 0.05)).clamp(0.7, 0.95);
        }
      }

      if (avgContribution <= 0) {
        return {
          'monthsToCompletion': -1,
          'completionDate': null,
          'onTrack': false,
          'projectedTotal': currentAmount,
          'confidence': 0.0,
          'warning': 'Tidak ada kontribusi yang terdeteksi',
        };
      }

      final monthsToCompletion = (remaining / avgContribution).ceil();
      final now = DateTime.now();
      final completionDate = DateTime(
        now.year,
        now.month + monthsToCompletion,
        now.day,
      );

      double projectedTotal =
          currentAmount + (avgContribution * monthsToCompletion);

      if (trend > 10) {
        projectedTotal *= 1.05;
      } else if (trend < -10) {
        projectedTotal *= 0.9;
        confidence -= 0.1;
      }

      String? warning;
      if (monthsToCompletion > 60) {
        warning =
            'Diperlukan $monthsToCompletion bulan. Pertimbangkan untuk meningkatkan kontribusi.';
      } else if (trend < -15) {
        warning =
            'Kontribusi menurun ${trend.toStringAsFixed(0)}%. Berhati-hatilah agar tidak melewatkan target.';
      }

      return {
        'monthsToCompletion': monthsToCompletion,
        'completionDate': completionDate.toIso8601String(),
        'onTrack': monthsToCompletion <= 24,
        'projectedTotal': projectedTotal,
        'confidence': confidence.clamp(0.0, 1.0),
        'averageContribution': avgContribution,
        'trend': trend,
        'warning': warning,
      };
    } catch (e) {
      LoggerService.error('Error forecasting goal completion', error: e);
      return {
        'monthsToCompletion': -1,
        'completionDate': null,
        'onTrack': false,
        'projectedTotal': currentAmount,
        'confidence': 0.0,
        'warning': 'Gagal memproyeksikan target',
      };
    }
  }

  List<Map<String, dynamic>> generateMilestones({
    required double targetAmount,
    required int monthsToCompletion,
  }) {
    final milestones = <Map<String, dynamic>>[];
    final checkpointPercentages = [0.25, 0.5, 0.75, 1.0];

    for (final pct in checkpointPercentages) {
      final amount = targetAmount * pct;
      final month = (monthsToCompletion * pct).ceil();
      final now = DateTime.now();
      final date = DateTime(now.year, now.month + month, now.day);

      milestones.add({
        'percentage': pct,
        'amount': amount,
        'month': month,
        'date': date.toIso8601String(),
        'label': _getMilestoneLabel(pct),
      });
    }

    return milestones;
  }

  String _getMilestoneLabel(double pct) {
    if (pct == 0.25) return '25% - Awal yang bagus!';
    if (pct == 0.5) return '50% - Setengah jalan!';
    if (pct == 0.75) return '75% - Hampir selesai!';
    return '100% - Target tercapai! 🎉';
  }
}
