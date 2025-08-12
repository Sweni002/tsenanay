from flask import request, jsonify
from . import produit_bp
from models import db, Produit

@produit_bp.route('/', methods=['GET'])
def get_produits():
    produits = Produit.query.all()
    result = []
    for p in produits:
        result.append({
            'idproduit': p.idproduit,
            'nom': p.nom,
            'qte': p.qte,
            # Convertir en int pour éviter la virgule
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

    return jsonify({'message': f'Produit {idproduit} supprimé avec succès.'})

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

    p = Produit(nom=data['nom'], qte=data['qte'], prix=prix, benefice=benefice)
    db.session.add(p)
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

    # Mise à jour des champs si présents
    if 'nom' in data:
        p.nom = data['nom']
    if 'qte' in data:
        p.qte = data['qte']
    p.prix = nouveau_prix
    p.benefice = nouveau_benefice

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

    # Ajout de la quantité
    p.qte += qte_ajoutee
    db.session.commit()

    return jsonify({
        'message': f'Produit {idproduit} approvisionné avec succès.',
        'idproduit': p.idproduit,
        'nouvelle_qte': p.qte
    })
