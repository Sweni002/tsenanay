import 'package:flutter/material.dart';

class VendrePage extends StatefulWidget {
  final List<Map<String, dynamic>> produits;
  final Function(Map<String, dynamic>, int ,double) onFaireVente; // quantité ajoutée
  final VoidCallback onRefreshProduit;
  final VoidCallback onRefreshVente;
  final Future<void> Function() fetchProduits;
  // ⚡ Nouveau paramètre
  final List<Map<String, dynamic>> Function() getProduits;

  const VendrePage({
    Key? key,
    required this.fetchProduits,
    required this.onRefreshProduit,
    required this.onRefreshVente,
    required this.produits,
    required this.onFaireVente,
       required this.getProduits, // ajouter ici
  }) : super(key: key);

  @override
  State<VendrePage> createState() => _VendrePageState();
}

class _VendrePageState extends State<VendrePage> {
  List<Map<String, dynamic>> produitsFiltres = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _qteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProduits();
    _searchController.addListener(() {
      _filtrerProduits(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _qteController.dispose();
    super.dispose();
  }
Future<void> _loadProduits() async {
  await widget.fetchProduits(); // attend que le parent mette à jour sa liste
  if (!mounted) return;

  setState(() {
    produitsFiltres = List.from(widget.getProduits());
  });
}


void _filtrerProduits(String query) {
  final q = query.toLowerCase();
  setState(() {
    produitsFiltres = q.isEmpty
        ? List.from(widget.produits)
        : widget.produits.where((p) => p['nom'].toLowerCase().contains(q)).toList();
  });
}


void _showVenteBottomSheet(Map<String, dynamic> produit) {
  final TextEditingController qteActuelleController =
      TextEditingController(text: produit['qte'].toString());
  final TextEditingController qteVenteController = TextEditingController();
  final TextEditingController prixUnitaireController = TextEditingController();
  final TextEditingController prixTotalController = TextEditingController();
  
  String? erreurQte;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          void updatePrixTotal() {
            int qte = int.tryParse(qteVenteController.text) ?? 0;
            double prix = double.tryParse(prixUnitaireController.text) ?? 0;

            // Vérifier si la quantité à vendre est supérieure à la quantité actuelle
            if (qte > produit['qte']) {
              erreurQte = "La quantité à vendre dépasse le stock actuel !";
              prixTotalController.text = "";
            } else {
              erreurQte = null;
              prixTotalController.text =
                  (qte > 0 && prix > 0 ? (qte * prix).toStringAsFixed(0) : "");
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  produit['nom'],
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: qteActuelleController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Quantité actuelle",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: qteVenteController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Quantité à vendre",
                    border: const OutlineInputBorder(),
                    errorText: erreurQte,
                  ),
                  onChanged: (_) {
                    setModalState(updatePrixTotal);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: prixUnitaireController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Prix unitaire",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    setModalState(updatePrixTotal);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: prixTotalController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Prix total",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
         SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: () async {
      final qte = int.tryParse(qteVenteController.text) ?? 0;
      if (qte <= 0 || qte > produit['qte']) {
        return;
      }

      widget.onFaireVente(
        produit,
        qte,
        double.tryParse(prixTotalController.text) ?? 0,
      );

      await _loadProduits();

      qteVenteController.clear();
      prixUnitaireController.clear();
      prixTotalController.clear();

      Navigator.pop(context);
    },
    style: ElevatedButton.styleFrom(
    
      foregroundColor: Colors.white,
      backgroundColor: Colors.teal,
      padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
    ),
    child: const Text(
      "Vendre",
      style: TextStyle(fontSize: 16),
    ),
  ),
),
       ],
            ),
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vendre un produit"),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Rechercher un produit',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          Expanded(
            child: produitsFiltres.isEmpty
                ? const Center(
                    child: Text(
                      "Aucun produit trouvé",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.separated(
                    itemCount: produitsFiltres.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final produit = produitsFiltres[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          child: const Icon(
                            Icons.shopping_bag,
                            color: Colors.teal,
                          ),
                        ),
                        title: Text(
                          produit['nom'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Quantité: ${produit['qte']}",
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        onTap: () => _showVenteBottomSheet(produit),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
