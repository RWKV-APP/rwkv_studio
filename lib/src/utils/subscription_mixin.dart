import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

mixin SubscriptionManagerMixin<T> on Cubit<T> {
  final List<StreamSubscription> _subscriptions = [];

  void addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  void removeSubscription(StreamSubscription subscription) {
    _subscriptions.remove(subscription);
  }

  void disposeSubscriptions() {
    for (var e in _subscriptions) {
      e.cancel();
    }
    _subscriptions.clear();
  }

  @override
  Future<void> close() {
    disposeSubscriptions();
    return super.close();
  }
}
