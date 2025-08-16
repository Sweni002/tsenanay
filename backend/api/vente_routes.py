from flask import request, jsonify
from . import vente_bp
from models import db, Vente  ,Produit
from datetime import datetime

@vente_bp.route('/', methods=['GET'])
def get_ventes():
    ventes = Vente.query.all()
    result = []
    for v in ventes:
        result.append({
            'idvente': v.idvente,
            'nom_produit': v.produit.nom,  # accès au nom via la relation
            'qte': v.qte,
            'prix': v.prix,
            'date': v.date.isoformat()  # format YYYY-MM-DD
        })
    return jsonify(result)


@vente_bp.route('/<int:idvente>', methods=['DELETE'])
def delete_vente(idvente):
    vente = Vente.query.get(idvente)
    if not vente:
        return jsonify({'error': 'Vente non trouvée'}), 404

    db.session.delete(vente)
    db.session.commit()

    return jsonify({'message': f'Vente  supprimée(s) avec succès.'})


@vente_bp.route('/', methods=['POST'])
def add_vente():
    data = request.get_json()
    idproduit=data['idproduit']
    qte=data['qte']
    new_vente = Vente(
        idproduit=data['idproduit'],
        qte=data['qte'],
        prix=data['prix'],
        date=datetime.utcnow()
    )
    p = Produit.query.get(idproduit)
    p.qte = p.qte - qte
    nouveau_qte=p.qte
    
    if nouveau_qte < 0  :
        return  jsonify({"error": "Quantité du produit est negative"}), 400
    db.session.add(new_vente)
    db.session.commit()
    return jsonify({"message": "Vente ajoutée avec succès"}), 200


@vente_bp.route('/filter', methods=['GET'])
def filter_ventes_by_date():
    date_str = request.args.get('date')
    if not date_str:
        return jsonify({'error': 'Paramètre date requis (format YYYY-MM-DD)'}), 400

    try:
        date_obj = datetime.strptime(date_str, '%Y-%m-%d').date()
    except ValueError:
        return jsonify({'error': 'Format de date invalide, attendu YYYY-MM-DD'}), 400

    # Trier par date décroissante pour avoir le dernier ajout en premier
    ventes = Vente.query.filter(
        db.func.date(Vente.date) == date_obj
    ).order_by(Vente.idvente.desc()).all()

    result = []
    for v in ventes:
        result.append({
            'idvente': v.idvente,
            'nom_produit': v.produit.nom,
            'qte': v.qte,
            'prix': v.prix,
            'date': v.date.isoformat()
        })

    return jsonify(result)


@vente_bp.route('/filter-range', methods=['GET'])
def filter_ventes_by_date_range():
    start_date_str = request.args.get('start_date')
    end_date_str = request.args.get('end_date')

    if not start_date_str or not end_date_str:
        return jsonify({'error': 'Paramètres start_date et end_date requis (format YYYY-MM-DD)'}), 400

    try:
        start_date = datetime.strptime(start_date_str, '%Y-%m-%d').date()
        end_date = datetime.strptime(end_date_str, '%Y-%m-%d').date()
    except ValueError:
        return jsonify({'error': 'Format de date invalide, attendu YYYY-MM-DD'}), 400

    if start_date > end_date:
        return jsonify({'error': 'start_date doit être inférieur ou égal à end_date'}), 400

    ventes = Vente.query.filter(
        Vente.date >= start_date,
        Vente.date <= end_date
    ).order_by(Vente.idvente.desc()).all()

    result = []
    for v in ventes:
        result.append({
            'idvente': v.idvente,
            'nom_produit': v.produit.nom,
            'qte': v.qte,
            'prix': v.prix,
            'date': v.date.isoformat()
        })

    return jsonify(result)

