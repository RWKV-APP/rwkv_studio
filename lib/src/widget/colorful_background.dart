import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fluent_ui/fluent_ui.dart';

class RandomMicaBackground extends StatefulWidget {
  final Widget? child;

  final Brightness brightness;

  final int? seed;

  final int blobCount;

  final double fogBlurSigma;

  final double noiseOpacity;

  final int tintAlpha;

  const RandomMicaBackground({
    super.key,
    this.child,
    required this.brightness,
    this.seed,
    this.blobCount = 9,
    this.fogBlurSigma = 45,
    this.noiseOpacity = 0.05,
    this.tintAlpha = 100,
  });

  @override
  State<RandomMicaBackground> createState() => _RandomMicaBackgroundState();
}

class _RandomMicaBackgroundState extends State<RandomMicaBackground> {
  late int _seed;
  late List<_Blob> _blobs;
  ui.Image? _noise;

  @override
  void initState() {
    super.initState();
    _seed = widget.seed ?? DateTime.now().millisecondsSinceEpoch;
    _blobs = const [];
    _init();
  }

  @override
  void didUpdateWidget(covariant RandomMicaBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed && widget.seed != null) {
      _seed = widget.seed!;
      _init();
    }
  }

  Future<void> _init() async {
    final b = widget.brightness ?? Brightness.dark;
    _blobs = _generateBlobs(_seed, widget.blobCount, b);

    _noise ??= await _createNoiseImage(256, 256, seed: 1337);

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final brightness = widget.brightness;
    if (_blobs.isNotEmpty && _blobs.first.forBrightness != brightness) {
      _blobs = _generateBlobs(_seed, widget.blobCount, brightness);
    }

    final baseGradient = brightness == Brightness.dark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF070A18), Color(0xFF0B1330), Color(0xFF050712)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF6F7FB), Color(0xFFEFEFF7), Color(0xFFF9FAFD)],
          );

    final tintColor = brightness == Brightness.dark
        ? Colors.black.withAlpha(widget.tintAlpha)
        : Colors.white.withAlpha(widget.tintAlpha);

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: BoxDecoration(gradient: baseGradient)),

          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: widget.fogBlurSigma,
              sigmaY: widget.fogBlurSigma,
            ),
            child: CustomPaint(painter: _BlobPainter(blobs: _blobs)),
          ),

          DecoratedBox(decoration: BoxDecoration(color: tintColor)),

          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: brightness == Brightness.dark
                    ? RadialGradient(
                        center: const Alignment(-0.2, -0.35),
                        radius: 1.1,
                        colors: [
                          Colors.white.withOpacity(0.06),
                          Colors.transparent,
                        ],
                      )
                    : RadialGradient(
                        center: const Alignment(-0.2, -0.35),
                        radius: 1.1,
                        colors: [
                          Colors.black.withOpacity(0.04),
                          Colors.transparent,
                        ],
                      ),
              ),
            ),
          ),

          if (_noise != null)
            CustomPaint(
              painter: _NoisePainter(
                noise: _noise!,
                opacity: widget.noiseOpacity,
                blendMode: brightness == Brightness.dark
                    ? BlendMode.overlay
                    : BlendMode.softLight,
              ),
            ),

          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }

  List<_Blob> _generateBlobs(int seed, int count, Brightness brightness) {
    final rnd = Random(seed);

    final paletteDark = const <Color>[
      Color(0xFF957ADE),
      Color(0xFF00E5FF),
      Color(0xFF22623C),
      Color(0xFF00E676),
      Color(0xFFFFD740),
      Color(0xFF536DFE),
    ];
    final paletteLight = const <Color>[
      Color(0xFF404C86),
      Color(0xFF5AEFFF),
      Color(0xFF7C542E),
      Color(0xFF69F0AE),
      Color(0xFFFFE57F),
      Color(0xFF8C9EFF),
    ];

    final palette = brightness == Brightness.dark ? paletteDark : paletteLight;
    final baseAlpha = brightness == Brightness.dark ? 0.22 : 0.16;

    return List.generate(count, (i) {
      final x = rnd.nextDouble();
      final y = rnd.nextDouble();
      final r = 0.18 + rnd.nextDouble() * 0.35;
      final c = palette[rnd.nextInt(palette.length)].withOpacity(
        baseAlpha + rnd.nextDouble() * 0.08,
      );

      return _Blob(
        x: x,
        y: y,
        radiusFactor: r,
        color: c,
        forBrightness: brightness,
      );
    });
  }

  Future<ui.Image> _createNoiseImage(int w, int h, {required int seed}) async {
    final rnd = Random(seed);
    final bytes = Uint8List(w * h * 4);

    for (int i = 0; i < w * h; i++) {
      final v = 128 + rnd.nextInt(41) - 20;
      final a = 22 + rnd.nextInt(18); // 22..39
      final idx = i * 4;
      bytes[idx] = v; // R
      bytes[idx + 1] = v; // G
      bytes[idx + 2] = v; // B
      bytes[idx + 3] = a; // A
    }

    final c = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      bytes,
      w,
      h,
      ui.PixelFormat.rgba8888,
      (img) => c.complete(img),
    );
    return c.future;
  }
}

class _Blob {
  final double x;
  final double y;
  final double radiusFactor;
  final Color color;
  final Brightness forBrightness;

  const _Blob({
    required this.x,
    required this.y,
    required this.radiusFactor,
    required this.color,
    required this.forBrightness,
  });
}

class _BlobPainter extends CustomPainter {
  final List<_Blob> blobs;

  _BlobPainter({required this.blobs});

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = min(size.width, size.height);

    canvas.saveLayer(Offset.zero & size, Paint()..blendMode = BlendMode.plus);

    for (final b in blobs) {
      final center = Offset(b.x * size.width, b.y * size.height);
      final r = b.radiusFactor * shortest;

      final rect = Rect.fromCircle(center: center, radius: r);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            b.color,
            b.color.withOpacity(b.color.opacity * 0.55),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

      canvas.drawCircle(center, r, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) {
    return oldDelegate.blobs != blobs;
  }
}

class _NoisePainter extends CustomPainter {
  final ui.Image noise;
  final double opacity;
  final BlendMode blendMode;

  _NoisePainter({
    required this.noise,
    required this.opacity,
    required this.blendMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shader = ui.ImageShader(
      noise,
      TileMode.repeated,
      TileMode.repeated,
      Matrix4.identity().storage,
    );

    canvas.saveLayer(Offset.zero & size, Paint());
    final paint = Paint()
      ..shader = shader
      ..blendMode = blendMode
      ..color = Colors.white.withOpacity(opacity);

    canvas.drawRect(Offset.zero & size, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) {
    return oldDelegate.opacity != opacity ||
        oldDelegate.noise != noise ||
        oldDelegate.blendMode != blendMode;
  }
}
