import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/analytics_service.dart';

class AnalyticsRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _report(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _report(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void _report(Route<dynamic> route) {
    final ctx = navigator?.context;
    if (ctx == null) return;
    final analytics = Provider.of<AnalyticsService>(ctx, listen: false);
    String name = route.settings.name ?? route.runtimeType.toString();
    analytics.trackScreenView(name);
  }
}
