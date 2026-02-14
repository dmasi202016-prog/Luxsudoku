import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/riverpod.dart';

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  final notifier = RouterNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this.ref);

  final Ref ref;

  String? handleRedirect(BuildContext context, GoRouterState state) {
    return null;
  }
}
