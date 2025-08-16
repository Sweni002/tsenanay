import os
from flask import Flask
from models import db, ProduitStock
from api import produit_bp, vente_bp
from config import DevelopmentConfig
from flask_migrate import Migrate
from sockets import init_socketio

app = Flask(__name__)
app.config.from_object(DevelopmentConfig)

# Init DB
db.init_app(app)
migrate = Migrate(app, db)

# Blueprints
app.register_blueprint(produit_bp)
app.register_blueprint(vente_bp)

# Init SocketIO
socketio = init_socketio(app)

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)
