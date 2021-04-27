/// Command-line WebSocket client library for the Galileo framework.
library galileo_websocket.io;

import 'dart:async';
import 'dart:io';
import 'package:galileo_client/galileo_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'base_websocket_client.dart';
export 'package:galileo_client/galileo_client.dart';
export 'galileo_websocket.dart';

final RegExp _straySlashes = RegExp(r"(^/)|(/+$)");

/// Queries an Galileo server via WebSockets.
class WebSockets extends BaseWebSocketClient {
  final List<IoWebSocketsService> _services = [];

  WebSockets(baseUrl, {bool reconnectOnClose = true, Duration reconnectInterval})
      : super(http.IOClient(), baseUrl, reconnectOnClose: reconnectOnClose, reconnectInterval: reconnectInterval);

  @override
  Stream<String> authenticateViaPopup(String url, {String eventName = 'token'}) {
    throw UnimplementedError('Opening popup windows is not supported in the `dart:io` client.');
  }

  @override
  Future close() {
    for (var service in _services) {
      service.close();
    }

    return super.close();
  }

  @override
  Future<WebSocketChannel> getConnectedWebSocket() async {
    var socket = await WebSocket.connect(websocketUri.toString(),
        headers: authToken?.isNotEmpty == true ? {'Authorization': 'Bearer $authToken'} : {});
    return IOWebSocketChannel(socket);
  }

  @override
  IoWebSocketsService<Id, Data> service<Id, Data>(String path, {Type type, GalileoDeserializer<Data> deserializer}) {
    var uri = path.replaceAll(_straySlashes, '');
    return IoWebSocketsService<Id, Data>(socket, this, uri, type);
  }
}

class IoWebSocketsService<Id, Data> extends WebSocketsService<Id, Data> {
  final Type type;

  IoWebSocketsService(WebSocketChannel socket, WebSockets app, String uri, this.type) : super(socket, app, uri);
}
