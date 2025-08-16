from . import db

class Vente(db.Model):
    __tablename__ = "vente"
    idvente = db.Column(db.Integer, primary_key=True, autoincrement=True)
    idproduit = db.Column(
    db.Integer,
    db.ForeignKey("produit.idproduit", ondelete="CASCADE"),
    nullable=False
)
    date = db.Column(db.Date, nullable=False)
    qte = db.Column(db.Integer, nullable=False)
    prix = db.Column(db.Float, nullable=False)

    produit = db.relationship("Produit", back_populates="ventes")
