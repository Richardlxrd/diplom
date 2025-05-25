import 'package:flutter/material.dart';

mixin ContextMixin<T extends StatefulWidget> on State<T> {
  /// Безопасный доступ к контексту с проверкой mounted
  BuildContext get safeContext {
    if (!mounted)
      throw Exception('Attempt to use context after widget was disposed');
    return context;
  }
}
