from datetime import datetime
from . import db

class ProduitStock(db.Model):
    __tablename__ = "produit_stock"
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    idproduit = db.Column(db.Integer, db.ForeignKey('produit.idproduit'), nullable=False)
    qte = db.Column(db.Integer, nullable=False)  # toujours positive
    type_mouvement = db.Column(db.String(20), nullable=False)  # "approvisionnement" ou "vente"
    date = db.Column(db.DateTime, default=datetime.utcnow)

    produit = db.relationship("Produit", back_populates="stocks")
