import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_klarna_payment/flutter_klarna_payment.dart';
import 'package:flutter_klarna_payment/src/controller/klarna_payment_controller_state.dart';
import 'package:rxdart/rxdart.dart';

class KlarnaPaymentController {
  KlarnaPaymentController() {
    _setupSubscription();
  }

  final _eventChannel = const EventChannel("flutter_klarna_payment_event");
  final _flutterKlarnaPaymentPlugin = FlutterKlarnaPayment();
  StreamSubscription? _subscription;
  final _stateController = BehaviorSubject<KlarnaPaymentControllerState>();
  bool _isStreamInitialized = false;
  bool _isStreamClosed = false;

  void pay() {
    _flutterKlarnaPaymentPlugin.pay();
  }

  void dispose() {
    if (_isStreamInitialized) {
      _subscription?.cancel();
      _isStreamClosed = true;
      _isStreamInitialized = false;
    }
    _stateController.close();
  }

  void resetStream() {
    if (_isStreamInitialized) {
      _subscription?.cancel();
      _stateController.close();
      _isStreamInitialized = false;
      _isStreamClosed = true;
    }
    if (_isStreamClosed) {
      _isStreamClosed = false;
      _setupSubscription();
    }
  }

  KlarnaPaymentControllerState _currentState = const KlarnaPaymentControllerState(state: KlarnaState.unknown);

  // ignore: unnecessary_getters_setters
  KlarnaPaymentControllerState get currentState => _currentState;

  // Convert the stream to a broadcast stream
  Stream<KlarnaPaymentControllerState> get stateStream => _stateController.stream;

  void _setupSubscription() {
    if (_subscription != null) {
      _subscription!.cancel();
    }
    _subscription = _eventChannel.receiveBroadcastStream().listen((event) {
      _updateState(event['state'], event['message']);
    });
    _isStreamInitialized = true;
    _isStreamClosed = false;
  }

  set currentState(KlarnaPaymentControllerState state) {
    _currentState = state;
  }

  void _updateState(String state, String? message) {
    if (_isStreamClosed) {
      return;
    }
    final newState = KlarnaPaymentControllerState(state: klarnaStateFromString(state), message: message);
    _stateController.sink.add(newState);
    currentState = newState;
  }
}
