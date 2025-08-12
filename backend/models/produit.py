from . import db

class Produit(db.Model):
    __tablename__ = "produit"
    idproduit = db.Column(db.Integer, primary_key=True, autoincrement=True)
    nom = db.Column(db.String(100), nullable=False)
    qte = db.Column(db.Integer, nullable=False)
    prix = db.Column(db.Double, nullable=False)
    benefice = db.Column(db.Double, nullable=True)

    ventes = db.relationship("Vente", back_populates="produit")
