from flask import request, jsonify
from . import produit_bp
from models import db, Produit , ProduitStock
from sockets import socketio  # importer l’instance

@produit_bp.route('/', methods=['GET'])
def get_produits():
    produits = Produit.query.order_by(Produit.nom.asc()).all()
    
    socketio.emit("produit_ajoute", {
        "id": produits.id,
        "nom": produits.nom,
        "qte": produits.qte
    })

    result = []
    for p in produits:
        result.append({
            'idproduit': p.idproduit,
            'nom': p.nom,
            'qte': p.qte,
              'prix': int(p.prix),
            'benefice': int(p.benefice)
        })
    return jsonify(result)

@produit_bp.route('/<int:idproduit>', methods=['DELETE'])
def delete_produit(idproduit):
    p = Produit.query.get(idproduit)
    if not p:
        return jsonify({'error': 'Produit non trouvé'}), 404

    db.session.delete(p)
    db.session.commit()

    return jsonify({'message': f'Produit  supprimée(s) avec succès.'})

@produit_bp.route('/', methods=['POST'])
def add_produit():
    data = request.json

    benefice = data.get('benefice')
    prix = data.get('prix')

    # Vérification simple que benefice et prix sont fournis
    if benefice is None or prix is None:
        return jsonify({'error': 'Les champs "benefice" et "prix" sont requis'}), 400

    # Validation
    if benefice > prix:
        return jsonify({'error': 'Le bénéfice ne peut pas être supérieur au prix'}), 400

    # Création du produit
    p = Produit(
        nom=data['nom'], 
        qte=data['qte'], 
        prix=prix, 
        benefice=benefice
    )
    db.session.add(p)
    db.session.flush()  # ⚡ Pour obtenir l'ID avant commit

    # Ajouter un mouvement initial dans ProduitStock
    if p.qte > 0:
        mouvement = ProduitStock(
            idproduit=p.idproduit,
            qte=p.qte,
            type_mouvement="approvisionnement"
        )
        db.session.add(mouvement)

    db.session.commit()

    return jsonify({
        'idproduit': p.idproduit,
        'nom': p.nom,
        'qte': p.qte,
        'prix': p.prix,
        'benefice': p.benefice
    }), 201

@produit_bp.route('/<int:idproduit>', methods=['GET'])
def get_produit_by_id(idproduit):
    p = Produit.query.get(idproduit)
    if not p:
        return jsonify({'error': 'Produit non trouvé'}), 404
    return jsonify({
        'idproduit': p.idproduit,
        'nom': p.nom,
        'qte': p.qte,
        'prix': p.prix ,
        'benefice': p.benefice
    })

@produit_bp.route('/<int:idproduit>', methods=['PUT'])
def update_produit(idproduit):
    p = Produit.query.get(idproduit)
    if not p:
        return jsonify({'error': 'Produit non trouvé'}), 404

    data = request.json

    # Si prix ou benefice sont modifiés, on prépare leur nouvelle valeur pour validation
    nouveau_prix = data.get('prix', p.prix)
    nouveau_benefice = data.get('benefice', p.benefice)

    # Validation : benefice ne peut pas être supérieur au prix
    if nouveau_benefice > nouveau_prix:
        return jsonify({'error': 'Le bénéfice ne peut pas être supérieur au prix'}), 400

    # Vérifier si la quantité change
    qte_avant = p.qte
    qte_nouvelle = data.get('qte', p.qte)

    # Mise à jour des champs
    if 'nom' in data:
        p.nom = data['nom']
    p.qte = qte_nouvelle
    p.prix = nouveau_prix
    p.benefice = nouveau_benefice

    # ⚡ Ajouter dans ProduitStock si quantité modifiée
    if qte_nouvelle != qte_avant:
        mouvement = ProduitStock(
            idproduit=p.idproduit,
            qte=qte_nouvelle - qte_avant,
            type_mouvement="mise à jour"
        )
        db.session.add(mouvement)

    db.session.commit()

    return jsonify({
        'idproduit': p.idproduit,
        'nom': p.nom,
        'qte': p.qte,
        'prix': p.prix,
        'benefice': p.benefice
    })

@produit_bp.route('/approvisionner/<int:idproduit>', methods=['POST'])
def approvisionner_produit(idproduit):
    p = Produit.query.get(idproduit)
    if not p:
        return jsonify({'error': 'Produit non trouvé'}), 404

    data = request.json
    if not data or 'qte' not in data:
        return jsonify({'error': 'Quantité (qte) à approvisionner requise'}), 400

    try:
        qte_ajoutee = int(data['qte'])
        if qte_ajoutee <= 0:
            return jsonify({'error': 'La quantité doit être un entier positif'}), 400
    except ValueError:
        return jsonify({'error': 'Quantité invalide, doit être un entier'}), 400

    # Ajout de la quantité au produit
    p.qte += qte_ajoutee

    # ⚡ Ajouter un mouvement dans ProduitStock
    mouvement = ProduitStock(
        idproduit=p.idproduit,
        qte=qte_ajoutee,
        type_mouvement="approvisionnement"
    )
    db.session.add(mouvement)

    db.session.commit()

    return jsonify({
        'message': f'Produit {p.nom} approvisionné avec succès.',
        'idproduit': p.idproduit,
        'nouvelle_qte': p.qte
    })
