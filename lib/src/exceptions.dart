import 'package:phoenix_socket/phoenix_socket.dart';

import 'events.dart';
import 'message.dart';
import 'push.dart';
import 'socket.dart';

/// Exception yield when a [PhoenixSocket] closes for unexpected reasons.
class PhoenixException implements Exception {
  /// The default constructor for this exception.
  PhoenixException({
    required this.version,
    this.socketClosed,
    this.socketError,
    this.channelEvent,
  });

  /// Phoenix socket protocol version
  final Version version;

  /// The associated error event.
  final PhoenixSocketErrorEvent? socketError;

  /// The associated close event.
  final PhoenixSocketCloseEvent? socketClosed;

  /// The associated channel event.
  final String? channelEvent;

  /// The error message for this exception.
  Message? get message {
    if (socketClosed != null) {
      return Message(version: version, event: PhoenixChannelEvent.error);
    } else if (socketError != null) {
      return Message(version: version, event: PhoenixChannelEvent.error);
    }
    return null;
  }

  @override
  String toString() {
    if (socketError != null) {
      return socketError!.error.toString();
    } else {
      return 'PhoenixException: socket closed';
    }
  }
}

/// Exception thrown when a [Push]'s reply was awaited for, and
/// the allowed delay has passed.
class ChannelTimeoutException implements Exception {
  /// Default constructor
  ChannelTimeoutException(this.response);

  /// The PushReponse containing the timeout event.
  PushResponse response;
}

class ChannelClosedError extends StateError {
  ChannelClosedError(super.message);
}
