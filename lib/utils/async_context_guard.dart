import 'package:flutter/widgets.dart';

typedef AsyncGuardedOperation<T> = Future<T?> Function(GuardedContext context);

/// Utility to standardise mounted checks around async gaps.
class AsyncContextGuard {
  const AsyncContextGuard._();

  static Future<T?> run<T>({
    required State state,
    required AsyncGuardedOperation<T> operation,
  }) async {
    final guarded = GuardedContext._(state);
    if (!guarded.mounted) return null;
    final result = await operation(guarded);
    if (!guarded.mounted) return null;
    return result;
  }
}

class GuardedContext {
  GuardedContext._(State state)
      : _state = state,
        context = state.context;

  final State _state;

  /// Cached build context captured before any async boundary.
  final BuildContext context;

  bool get mounted => _state.mounted;

  /// Returns `true` when the widget is still mounted on the tree.
  bool ensureMounted() => mounted;
}

