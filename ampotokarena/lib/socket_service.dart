import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  void initSocket() {
    socket = IO.io(
      'http://192.168.68.50:5000',
      IO.OptionBuilder()
          .setTransports(['websocket']) // Utilise WebSocket
          .disableAutoConnect() // on connecte manuellement
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      print('✅ Connecté au serveur SocketIO');
    });

    socket.onDisconnect((_) {
      print('❌ Déconnecté du serveur SocketIO');
    });
  }

  void onProduitAjoute(Function(dynamic) callback) {
    socket.on('produit_ajoute', callback);
  }

  void dispose() {
    socket.dispose();
  }
}
