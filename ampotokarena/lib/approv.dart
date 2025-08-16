import 'package:flutter/material.dart';
import 'dioClient.dart';

class ApprovPage extends StatefulWidget {
  const ApprovPage({Key? key}) : super(key: key);

  @override
  State<ApprovPage> createState() => _ApprovPageState();
}

class _ApprovPageState extends State<ApprovPage> {
  List<Map<String, dynamic>> _produits = [
    {"idproduit": 1, "nom": "Pomme", "qte": 10, "prix": 1500, "benefice": 500},
    {"idproduit": 2, "nom": "Banane", "qte": 20, "prix": 1200, "benefice": 300},
    {"idproduit": 3, "nom": "Orange", "qte": 15, "prix": 1000, "benefice": 200},
    {"idproduit": 4, "nom": "Mangue", "qte": 8, "prix": 2500, "benefice": 600},
  ];

  final DioClient dioClient = DioClient();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _produitsFiltres = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProduits();
    _searchController.addListener(() {
      _filtrerProduits(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProduits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await dioClient.getProduits();
      _produits = List<Map<String, dynamic>>.from(data);
      // Appliquer la recherche après mise à jour des produits
      _filtrerProduits(_searchController.text);
    } catch (e) {
      _error = e.toString();
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _filtrerProduits(String query) {
    if (query.isEmpty) {
      setState(() {
        _produitsFiltres = List.from(_produits);
      });
    } else {
      setState(() {
        _produitsFiltres = _produits
            .where(
              (prod) => prod["nom"].toString().toLowerCase().contains(
                query.toLowerCase(),
              ),
            )
            .toList();
      });
    }
  }

  Future<void> _approvisionnerProduit(int idproduit, int qteAjoutee) async {
    setState(() => _isLoading = true);
   
    final data = {"qte": qteAjoutee};
    try {
      Map<String, dynamic> result;
      result = await dioClient.doApprov(idproduit, data);
      if (mounted) {
        print("succes");
        setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Approvisionnent réussie")),
        );
           await _fetchProduits();
      }
    } catch (e) {
      print(e.toString());

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur du connexion")));
      }
    }
  }

  void _afficherBottomSheet(int index) {
    final produit = _produitsFiltres[index];
    final int indexOriginal = _produits.indexOf(produit);

    int qteApprovisionnee = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(

              padding:
                  MediaQuery.of(context).viewInsets +
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Wrap(
alignment: WrapAlignment.center,
                children: [
                  Center(
                    child: Container(
                      
                      width: 50,
                      height: 6,
                      margin: const EdgeInsets.only(bottom: 28),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  Text(
                    produit["nom"],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quantité actuelle dans une petite card
                  Card(
                    color: Colors.grey.shade100,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.inventory_2,
                            color: Colors.grey,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Quantité actuelle : ${produit["qte"]}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Stepper approvisionnement centré et espacé
                  Text(
                    "Quantité à approvisionner",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 38,
                        color: Colors.red.shade400,
                        icon: const Icon(Icons.remove_circle),
                        onPressed: () {
                          if (qteApprovisionnee > 1) {
                            setModalState(() {
                              qteApprovisionnee--;
                            });
                          }
                        },
                      ),
                      Container(
                        width: 60,
                        alignment: Alignment.center,
                        child: Text(
                          "$qteApprovisionnee",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        iconSize: 38,
                        color: Colors.green.shade600,
                        icon: const Icon(Icons.add_circle),
                        onPressed: () {
                          setModalState(() {
                            qteApprovisionnee++;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Center(
                    child: Text(
                      "Utilisez les boutons pour ajuster la quantité",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Bouton Approvisionner large avec ombre et arrondi
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        shadowColor: Colors.greenAccent.shade400,
                      ),
                      icon: const Icon(Icons.add_shopping_cart, size: 26),
                      label: const Text(
                        "Approvisionner",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        final id = produit['idproduit'];

                        _approvisionnerProduit(id, qteApprovisionnee);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
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
      body: SafeArea(
        child: Column(
          children: [
            // Barre de recherche
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Rechercher un produit...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),

            // Liste des produits filtrés
            Expanded(
              child: _produitsFiltres.isEmpty
                  ? const Center(
                      child: Text(
                        "Aucun produit trouvé",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _produitsFiltres.length,
                      itemBuilder: (context, index) {
                        final produit = _produitsFiltres[index];
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          shadowColor: Colors.blue.shade100,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.green.shade100,
                              child: const Icon(
                                Icons.inventory_2,
                                color: Colors.green,
                                size: 28,
                              ),
                            ),
                            title: Text(
                              produit["nom"],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Text(
                              "${produit["qte"]}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _afficherBottomSheet(index),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
