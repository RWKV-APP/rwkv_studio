import 'dart:async';
import 'dart:collection';
import 'dart:math';

class SpeedMetrics {
  /// Filtered speed, as the primary value exposed to consumers.
  final double speed;
  /// Raw speed calculated directly from the fixed time window.
  final double rawSpeed;
  final Duration window;
  final DateTime timestamp;

  const SpeedMetrics({
    required this.speed,
    required this.rawSpeed,
    required this.window,
    required this.timestamp,
  });
}

typedef Sampler<T> = double Function(T);

class StreamSpeedSampler {
  static StreamTransformer<T, SpeedMetrics> createTransformer<T>({
    required Duration window,
    required Duration maxSampleRate,
    required Sampler<T> counter,
    int volatilityWindow = 5,
    double smoothingAlpha = 0.35,
    bool enableSmoothing = true,
  }) {
    assert(!window.isNegative && window != Duration.zero, 'window must > 0');
    assert(
      !maxSampleRate.isNegative && maxSampleRate != Duration.zero,
      'maxSampleRate must > 0',
    );
    assert(volatilityWindow > 0, 'volatilityWindow must > 0');
    assert(
      smoothingAlpha >= 0 && smoothingAlpha <= 1,
      'smoothingAlpha must be in [0, 1]',
    );

    return StreamTransformer<T, SpeedMetrics>.fromBind((Stream<T> source) {
      late final StreamController<SpeedMetrics> controller;
      StreamSubscription<T>? subscription;
      Timer? ticker;

      final Queue<_Bucket> buckets = Queue<_Bucket>();
      final Queue<double> rawHistory = Queue<double>();

      double totalInWindow = 0.0;
      double? filteredSpeed;
      DateTime? lastEmitAt;

      void prune(DateTime now) {
        final cutoff = now.subtract(window);
        while (buckets.isNotEmpty && buckets.first.time.isBefore(cutoff)) {
          totalInWindow -= buckets.removeFirst().value;
        }
        if (totalInWindow < 0) {
          totalInWindow = 0;
        }
      }

      double applyFilter(double raw) {
        if (!enableSmoothing) {
          return raw;
        }

        rawHistory.addLast(raw);
        while (rawHistory.length > volatilityWindow) {
          rawHistory.removeFirst();
        }

        final List<double> sorted = rawHistory.toList()..sort();
        final int mid = sorted.length ~/ 2;
        final double median =
            sorted.length.isOdd
                ? sorted[mid]
                : (sorted[mid - 1] + sorted[mid]) / 2.0;

        filteredSpeed =
            filteredSpeed == null
                ? median
                : (smoothingAlpha * median) +
                    ((1 - smoothingAlpha) * filteredSpeed!);

        return filteredSpeed!;
      }

      void emitSample(DateTime now) {
        if (controller.isClosed) {
          return;
        }

        prune(now);
        final double seconds = max(
          window.inMilliseconds / Duration.millisecondsPerSecond,
          1e-9,
        );
        final double raw = totalInWindow / seconds;
        final double smoothed = applyFilter(raw);
        lastEmitAt = now;

        controller.add(
          SpeedMetrics(
            speed: smoothed,
            rawSpeed: raw,
            window: window,
            timestamp: now,
          ),
        );
      }

      void maybeEmit(DateTime now) {
        if (lastEmitAt == null ||
            now.difference(lastEmitAt!) >= maxSampleRate) {
          emitSample(now);
        }
      }

      void startTicker() {
        ticker?.cancel();
        ticker = Timer.periodic(maxSampleRate, (_) {
          maybeEmit(DateTime.now());
        });
      }

      void stopTicker() {
        ticker?.cancel();
        ticker = null;
      }

      controller = StreamController<SpeedMetrics>(
        onListen: () {
          subscription = source.listen(
            (T event) {
              final DateTime now = DateTime.now();
              double value;
              try {
                value = counter(event);
              } catch (e, st) {
                controller.addError(e, st);
                return;
              }

              if (!value.isFinite || value < 0) {
                return;
              }
              if (value > 0) {
                buckets.addLast(_Bucket(now, value));
                totalInWindow += value;
              }
              prune(now);
              maybeEmit(now);
            },
            onError: controller.addError,
            onDone: () {
              emitSample(DateTime.now());
              stopTicker();
              controller.close();
            },
            cancelOnError: false,
          );

          startTicker();
        },
        onPause: () {
          stopTicker();
          subscription?.pause();
        },
        onResume: () {
          subscription?.resume();
          startTicker();
        },
        onCancel: () async {
          stopTicker();
          await subscription?.cancel();
        },
      );

      return controller.stream;
    });
  }
}

class _Bucket {
  final DateTime time;
  final double value;

  const _Bucket(this.time, this.value);
}
