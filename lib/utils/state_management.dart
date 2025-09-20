import 'package:flutter/material.dart';

mixin SafeState<T extends StatefulWidget> on State<T> {
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  /// Safely sets state only if the widget is still mounted
  void safeSetState(VoidCallback fn) {
    if (_isMounted) {
      setState(fn);
    }
  }

  /// Shows a snackbar safely
  void showSnackBar(String message, {bool isError = false}) {
    if (!_isMounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  /// Safely executes an async operation with loading state
  Future<void> safeAsync(
    Future<void> Function() operation, {
    String? successMessage,
    String? errorMessage,
    VoidCallback? onSuccess,
    bool showLoadingIndicator = true,
  }) async {
    if (!_isMounted) return;

    try {
      if (showLoadingIndicator) {
        safeSetState(() {});
      }

      await operation();

      if (!_isMounted) return;

      if (successMessage != null) {
        showSnackBar(successMessage);
      }

      if (onSuccess != null) {
        onSuccess();
      }
    } catch (e) {
      if (!_isMounted) return;
      showSnackBar(
        errorMessage ?? 'An error occurred: $e',
        isError: true,
      );
    } finally {
      if (_isMounted && showLoadingIndicator) {
        safeSetState(() {});
      }
    }
  }
} 