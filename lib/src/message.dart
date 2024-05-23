import 'package:logging/logging.dart';

import 'channel.dart';
import 'events.dart';
import 'socket.dart';
import 'version.dart';

final Logger _logger = Logger('phoenix_socket.message');

/// Class that encapsulate a message being sent or received on a
/// [PhoenixSocket].
class Message {
  /// Given a parsed JSON coming from the backend, yield a [Message] instance
  /// accordingly Phoenix socket protocol [Version].
  factory Message.fromJson(dynamic parts, Version v) {
    _logger.finest('Message decoded from $parts');
    switch (v) {
      case Version.v1:
        return Message(
          version: v,
          joinRef: parts['join_ref'],
          ref: parts['ref'],
          topic: parts['topic'],
          event: PhoenixChannelEvent.custom(parts['event']),
          payload: parts['payload'],
        );
      case Version.v2:
        return Message(
          version: v,
          joinRef: parts[0],
          ref: parts[1],
          topic: parts[2],
          event: PhoenixChannelEvent.custom(parts[3]),
          payload: parts[4],
        );
    }
  }

  /// Given a unique reference, generate a heartbeat message.
  factory Message.heartbeat(String ref, Version v) {
    return Message(
      version: v,
      topic: 'phoenix',
      event: PhoenixChannelEvent.heartbeat,
      payload: const {},
      ref: ref,
    );
  }

  /// Given a unique reference, generate a timeout message that
  /// will be used to error out a push.
  factory Message.timeoutFor(String ref, Version v) {
    return Message(
      version: v,
      event: PhoenixChannelEvent.replyFor(ref),
      payload: const {
        'status': 'timeout',
        'response': {},
      },
    );
  }

  /// Build a [Message] from its constituents.
  Message({
    required this.version,
    this.joinRef,
    this.ref,
    this.topic,
    required this.event,
    this.payload,
  });

  /// Version of the Phoenix socket protocol
  final Version version;

  /// Reference of the channel on which the message is received.
  ///
  /// Used by the [PhoenixSocket] to route the message on the proper
  /// [PhoenixChannel].
  final String? joinRef;

  /// The unique identifier for this message.
  ///
  /// This identifier is used in the reply event name, allowing us
  /// to consider a message as a reply to a previous message.
  final String? ref;

  /// The topic of the channel on which this message is sent.
  final String? topic;

  /// The event name of this message.
  final PhoenixChannelEvent event;

  /// The payload of this message.
  ///
  /// This needs to be a JSON-encodable object.
  final Map<String, dynamic>? payload;

  /// Encode a message to JSON-encodable structure accordingly to Phoenix socket
  /// protocol [version]
  Object encode() {
    switch (version) {
      case Version.v1:
        Map<String, dynamic> msg = {
          'ref': ref,
          'topic': topic,
          'event': event.value,
          'payload': payload,
        };
        _logger.finest('Message encoded to $msg');
        return msg;

      case Version.v2:
        final parts = [
          joinRef,
          ref,
          topic,
          event.value,
          payload,
        ];
        _logger.finest('Message encoded to $parts');
        return parts;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Message &&
      other.joinRef == joinRef &&
      other.ref == ref &&
      other.topic == topic &&
      other.event == event &&
      other.payload == payload;

  @override
  int get hashCode =>
      Object.hash(runtimeType, joinRef, ref, topic, event, payload);

  @override
  String toString() =>
      'Message(joinRef: $joinRef, ref: $ref, topic: $topic, event: $event, payload: $payload)';

  /// Whether the message is a reply message.
  bool get isReply => event.isReply;

  /// Return a new [Message] with the event name being that of
  /// a proper reply message.
  Message asReplyEvent() {
    return Message(
      version: version,
      ref: ref,
      payload: payload,
      event: PhoenixChannelEvent.replyFor(ref!),
      topic: topic,
      joinRef: joinRef,
    );
  }
}
