from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

from .produit import Produit
from .vente import Vente
