import 'package:flutter/material.dart';

class CreerVentePage extends StatefulWidget {
  final Function(Map<String, dynamic>) onAjouter;

  const CreerVentePage({Key? key, required this.onAjouter}) : super(key: key);

  @override
  State<CreerVentePage> createState() => _CreerVentePageState();
}

class _CreerVentePageState extends State<CreerVentePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nomController = TextEditingController();
  final TextEditingController qteActuelleController = TextEditingController();
  final TextEditingController qteVendueController = TextEditingController();
  final TextEditingController prixController = TextEditingController();

  @override
  void dispose() {
    nomController.dispose();
    qteActuelleController.dispose();
    qteVendueController.dispose();
    prixController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final nom = nomController.text.trim();
      final qteActuelle = int.parse(qteActuelleController.text);
      final qteVendue = int.parse(qteVendueController.text);
      final prix = int.parse(prixController.text);

      final nouvelleVente = {
        "nom": nom,
        "qte": qteActuelle,
        "qte_vendue": qteVendue,
        "prix": prix,
        "date": DateTime.now(),
      };

      widget.onAjouter(nouvelleVente);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Text(
                "Ajouter une vente",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: nomController,
                decoration: InputDecoration(
                  labelText: "Nom du produit",
                  prefixIcon: const Icon(Icons.shopping_cart),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  fillColor: Colors.grey.shade100,
                  filled: true,
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? "Entrez un nom" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: qteActuelleController,
                decoration: InputDecoration(
                  labelText: "Quantité actuelle",
                  prefixIcon: const Icon(Icons.inventory_2),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  fillColor: Colors.grey.shade100,
                  filled: true,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Entrez la quantité actuelle";
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 0) {
                    return "Quantité invalide";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: qteVendueController,
                decoration: InputDecoration(
                  labelText: "Quantité vendue",
                  prefixIcon: const Icon(Icons.sell),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  fillColor: Colors.grey.shade100,
                  filled: true,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Entrez la quantité vendue";
                  }
                  int? val = int.tryParse(value);
                  int? qteActuelle = int.tryParse(qteActuelleController.text);
                  if (val == null || val <= 0) {
                    return "Quantité vendue invalide";
                  }
                  if (qteActuelle != null && val > qteActuelle) {
                    return "Quantité vendue ne peut pas dépasser la quantité actuelle";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: prixController,
                decoration: InputDecoration(
                  labelText: "Prix unitaire (Ar)",
                  prefixIcon: const Icon(Icons.price_change),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  fillColor: Colors.grey.shade100,
                  filled: true,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Entrez le prix unitaire";
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return "Prix invalide";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _submit,
                child: const Text(
                  "Ajouter la vente",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
