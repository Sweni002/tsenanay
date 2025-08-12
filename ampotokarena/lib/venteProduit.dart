import 'package:flutter/material.dart';

class VendrePage extends StatefulWidget {
  final List<Map<String, dynamic>> produits;
  final Function(Map<String, dynamic>) onFaireVente;

  const VendrePage({
    Key? key,
    required this.produits,
    required this.onFaireVente,
  }) : super(key: key);

  @override
  State<VendrePage> createState() => _VendrePageState();
}

class _VendrePageState extends State<VendrePage> {
  List<Map<String, dynamic>> produitsFiltres = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    produitsFiltres = List.from(widget.produits);
    _searchController.addListener(_filtrerProduits);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrerProduits() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      produitsFiltres = widget.produits.where((produit) {
        return produit['nom'].toString().toLowerCase().contains(query);
      }).toList();
    });
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
          // Champ de recherche
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                          child: const Icon(Icons.shopping_bag, color: Colors.teal),
                        ),
                        title: Text(
                          produit['nom'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Quantité: ${produit['qte']}",
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        onTap: () {
                          // Ouvre directement le bottom sheet
                          widget.onFaireVente(produit);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
