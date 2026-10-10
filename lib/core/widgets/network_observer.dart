import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/local_db_service.dart';
import '../services/connection_sound.dart';
import '../models/sync_summary.dart';
import '../services/network_status.dart';
import 'app_snackbar.dart';
import 'offline_status_banner.dart';

class NetworkObserver extends StatefulWidget {
  const NetworkObserver({
    super.key,
    required this.child,
    this.changes,
    this.check,
    this.sync,
    this.playSound,
  });
  final Widget child;
  final Stream<List<ConnectivityResult>>? changes;
  final Future<List<ConnectivityResult>> Function()? check;
  final Future<SyncSummary> Function()? sync;
  final Future<void> Function()? playSound;
  @override
  State<NetworkObserver> createState() => _NetworkObserverState();
}

class _NetworkObserverState extends State<NetworkObserver> {
  StreamSubscription<List<ConnectivityResult>>? _connection;
  StreamSubscription<SyncSummary>? _summaries;
  Timer? _debounce;
  bool _offline = false;
  bool _known = false;
  bool _onlineCandidate = false;
  int _revision = 0;
  @override
  void initState() {
    super.initState();
    _connection = (widget.changes ?? Connectivity().onConnectivityChanged)
        .listen(_changed, onError: (Object _) {});
    final revision = _revision;
    (widget.check?.call() ?? Connectivity().checkConnectivity())
        .then((value) {
          if (mounted && revision == _revision) _changed(value);
        })
        .catchError((Object _) {});
    _summaries = LocalDbService().syncResults.listen((summary) {
      if (mounted && !_offline && summary.attempted > 0) {
        AppSnackbar.show(
          context,
          summary.failed == 0
              ? AppSnackbar.success(summary.message)
              : AppSnackbar.error(summary.message, onRetry: _retry),
        );
      }
    });
  }

  void _retry() {
    unawaited(
      (widget.sync?.call() ?? LocalDbService().processSyncQueue(force: true)),
    );
  }

  void _changed(List<ConnectivityResult> results) {
    if (!mounted) return;
    _revision++;
    final offline =
        results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none);
    if (!_known) {
      setState(() {
        _known = true;
        _offline = offline;
      });
      networkOffline.value = offline;
      if (!offline) _retry();
      return;
    }
    if (offline) {
      _debounce?.cancel();
      _onlineCandidate = false;
      setState(() => _offline = true);
      networkOffline.value = true;
    } else if (_offline && !_onlineCandidate) {
      _onlineCandidate = true;
      _debounce = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() {
          _offline = false;
          _onlineCandidate = false;
        });
        networkOffline.value = false;
        AppSnackbar.show(context, AppSnackbar.info('Connection restored'));
        unawaited((widget.playSound?.call() ?? ConnectionSound().play()));
        _retry();
      });
    }
  }

  @override
  void dispose() {
    _connection?.cancel();
    _summaries?.cancel();
    _debounce?.cancel();
    networkOffline.value = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleBanner = OfflineStatusBanner(
      onRetry: () async {
        final results =
            await (widget.check?.call() ?? Connectivity().checkConnectivity());
        _changed(results);
        if (!results.contains(ConnectivityResult.none)) _retry();
      },
    );
    return Column(
      children: [
        SafeArea(top: _offline, bottom: false, child: visibleBanner),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: _offline,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
