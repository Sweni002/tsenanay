from flask_socketio import SocketIO

socketio = SocketIO(cors_allowed_origins="*")

def init_socketio(app):
    socketio.init_app(app)

    # Exemple d’événement côté serveur
    @socketio.on("connect")
    def handle_connect():
        print("Un client est connecté au WebSocket")

    @socketio.on("disconnect")
    def handle_disconnect():
        print("Un client s'est déconnecté")

    return socketio
