import os
from flask import Flask
from models import db
from api import produit_bp, vente_bp
from config import DevelopmentConfig
from flask_migrate import Migrate

app = Flask(__name__)
app.config.from_object(DevelopmentConfig)

db.init_app(app)
migrate = Migrate(app, db)

app.register_blueprint(produit_bp)
app.register_blueprint(vente_bp)

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(host='0.0.0.0', port=5000, debug=True)


