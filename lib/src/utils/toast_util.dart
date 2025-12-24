import 'dart:async';

import 'package:flutter/material.dart';

extension FutureExt<T> on Future<T> {
  Future<T> withToast(
    BuildContext context, {
    String? error,
    String? success,
  }) async {
    try {
      final r = await this;
      if (context.mounted && success != null) {
        context.toast(success);
      }
      return r;
    } catch (e) {
      if (context.mounted) {
        context.toast("${error ?? ''} $e".trim());
      }
      rethrow;
    }
  }

  Future<T> withLoading(BuildContext context) async {
    final startAt = DateTime.now();
    try {
      context.showLoading();
      return await this;
    } finally {
      final duration = DateTime.now().difference(startAt);
      if (duration.inMilliseconds < 500) {
        await Future.delayed(
          Duration(milliseconds: 500 - duration.inMilliseconds),
        );
      }
      if (context.mounted) {
        context.hideLoading();
      }
    }
  }
}

extension ContextExt on BuildContext {
  void toast(String message) {
    _ToastOverlay.show(this, message);
  }

  void showLoading() {
    _LoadingOverlay.show(this);
  }

  void hideLoading() {
    _LoadingOverlay.hide();
  }
}

class _ToastOverlay {
  static OverlayEntry? _overlayEntry;
  static Timer? _timer;

  static void show(BuildContext context, String message) {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
    }
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        left: 0,
        right: 0,
        child: Center(
          child: Material(
            color: Colors.black87,
            elevation: 3.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              constraints: const BoxConstraints(minWidth: 10, maxWidth: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                message,
                maxLines: 3,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 3), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }
}

class _LoadingOverlay {
  static OverlayEntry? _overlayEntry;

  static void show(BuildContext context) {
    if (_overlayEntry != null) {
      return;
    }
    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black26,
        child: const Center(
          child: Material(
            elevation: 3.0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12.0)),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    if (_overlayEntry == null) {
      return;
    }
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
