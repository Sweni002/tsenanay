from flask import Blueprint

produit_bp = Blueprint('produit', __name__, url_prefix='/produits')
vente_bp = Blueprint('vente', __name__, url_prefix='/ventes')

from .produit_routes import *
from .vente_routes import *
