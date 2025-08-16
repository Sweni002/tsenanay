import 'package:flutter/material.dart';
import 'creer_produit.dart';
import 'dioClient.dart';
import 'package:dio/dio.dart';
import 'socket_service.dart';

class ProduitPage extends StatefulWidget {
  const ProduitPage({Key? key}) : super(key: key);

  @override
  State<ProduitPage> createState() => _ProduitPageState();
}

class _ProduitPageState extends State<ProduitPage> {
  final DioClient dioClient = DioClient();
  final SocketService socketService = SocketService();


  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _produits = [
    {"idproduit": 1, "nom": "Pomme", "qte": 10, "prix": 1500, "benefice": 500},
    {"idproduit": 2, "nom": "Banane", "qte": 20, "prix": 1200, "benefice": 300},
    {"idproduit": 3, "nom": "Orange", "qte": 15, "prix": 1000, "benefice": 200},
    {"idproduit": 4, "nom": "Mangue", "qte": 8, "prix": 2500, "benefice": 600},
  ];

  List<Map<String, dynamic>> _produitsFiltres = [];

  final TextEditingController _searchController = TextEditingController();
void _handleDioError(BuildContext context, dynamic error) {
  if (error is DioError) {
    if (error.type == DioErrorType.connectionError || 
        error.type == DioErrorType.connectionTimeout) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur de connexion")),
      );
    } else if (error.response != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur serveur: ${error.response?.statusCode}")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${error.message}")),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Erreur inconnue")),
    );
  }
}

  // Pour gérer la sélection multiple
  final Set<Map<String, dynamic>> _produitsSelectionnes = {};

  @override
  void initState() {
    super.initState();
    _fetchProduits();

    _searchController.addListener(() {
      _filtrerProduits(_searchController.text);
    });
      socketService.initSocket();

    // 🔹 Écouter quand un produit est ajouté
    socketService.onProduitAjoute((data) {
      print("📢 Produit ajouté reçu: $data");
      _fetchProduits(); // recharger depuis l'API
    });
     socketService.socket.on('produit_modifie', (data) {
    print("✏️ Produit modifié: $data");
    _fetchProduits();
  });

  // 🔹 Quand un produit est supprimé
  socketService.socket.on('produit_supprime', (data) {
    print("🗑 Produit supprimé: $data");
    _fetchProduits();
  });
  }

  @override
  void dispose() {
     socketService.dispose();

    _searchController.dispose();
    super.dispose();
  }

  Future<void> _modifierProduitBackend(int idproduit, Map<String, dynamic> produit) async {
    try {
      await dioClient.updateProduit(idproduit, produit);
      await _fetchProduits();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur modification : $e")),
      );
    }
  }

 Future<void> _supprimerProduitBackend(int idproduit) async {
  try {
    await dioClient.deleteProduit(idproduit);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Suppression terminée")),
    );
    await _fetchProduits();
  } catch (e) {
    _handleDioError(context, e);
  }
}

Future<void> _fetchProduits() async {
  setState(() {
    _isLoading = true;
    _error = null;
  });

  try {
    final data = await dioClient.getProduits();
    _produits = List<Map<String, dynamic>>.from(data);
    _filtrerProduits(_searchController.text);
  } catch (e) {
    _handleDioError(context, e);
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

 void _afficherBottomSheet(int index) {
  final produit = _produitsFiltres[index];
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    backgroundColor: Colors.white,
    isScrollControlled: true,
    elevation: 8,
    builder: (context) {
      return Padding(
        padding: MediaQuery.of(context).viewInsets +
            const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Wrap(
          children: [
            Center(
              child: Container(
                width: 50,
                height: 6,
                margin: const EdgeInsets.only(bottom: 28),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
     Center(
  child: Text(
    produit["nom"],
    style: const TextStyle(
      fontSize: 23,
      fontWeight: FontWeight.bold,
      letterSpacing: 1,
      color: Colors.black87,
    ),
  ),
),
        const SizedBox(height: 30),

            // Tableau des infos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoCell("Quantité", produit["qte"].toString()),
                _infoCell("Prix", "${produit["prix"]} Ar"),
                _infoCell("Bénéfice", "${produit["benefice"]} Ar"),
              ],
            ),

            const Divider(height: 40, thickness: 1.5),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.deepOrangeAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    label: const Text(
                      "Modifier",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreerProduitPage(produit: produit),
                        ),
                      );
                      if (result == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Modification réussie")),
                        );
                        await _fetchProduits();
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    label: const Text(
                      "Supprimer",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      final id = produit['idproduit'];
                      await _supprimerProduitBackend(id);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
          ],
        ),
      );
    },
  );
}

// Cellule du tableau
Widget _infoCell(String label, String value) {
  return Expanded(
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    ),
  );
}

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.blueGrey),
        const SizedBox(width: 12),
        Text(
          "$label : ",
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 18, color: Colors.black54),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool selectionActive = _produitsSelectionnes.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectionActive
              ? "${_produitsSelectionnes.length} sélectionné${_produitsSelectionnes.length > 1 ? 's' : ''}"
              : "Liste des produits",
        ),
        actions: [
          if (selectionActive) ...[
   IconButton(
  icon: const Icon(Icons.delete),
  tooltip: "Supprimer la sélection",
  onPressed: () async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: Text(
          "Voulez-vous vraiment supprimer ${_produitsSelectionnes.length} produit${_produitsSelectionnes.length > 1 ? 's' : ''} ?"
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Supprimer")),
        ],
      ),
    );

    if (confirm == true) {
      // Appel de ta fonction pour chaque produit sélectionné
      for (final produit in _produitsSelectionnes) {
        await _supprimerProduitBackend(produit['idproduit']);
      }
      setState(() {
        _produitsSelectionnes.clear();
      });
    }
  },
),
           IconButton(
              icon: const Icon(Icons.close),
              tooltip: "Annuler la sélection",
              onPressed: () {
                setState(() {
                  _produitsSelectionnes.clear();
                });
              },
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
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
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Text(
                    "Erreur: $_error",
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              )
            else if (_produitsFiltres.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    "Aucun produit trouvé",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _produitsFiltres.length,
                  itemBuilder: (context, index) {
                    final produit = _produitsFiltres[index];
                    final bool estSelectionne = _produitsSelectionnes.contains(produit);

                    return Card(
                      color: estSelectionne ? Colors.blue.shade100 : Colors.white,
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
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(
                            Icons.shopping_cart,
                            color: Colors.blue,
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
                        subtitle:
                        
                        Text(
                          "Prix: ${produit["prix"]} Ar",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          if (selectionActive) {
                            setState(() {
                              if (estSelectionne) {
                                _produitsSelectionnes.remove(produit);
                              } else {
                                _produitsSelectionnes.add(produit);
                              }
                            });
                          } else {
                            _afficherBottomSheet(index);
                          }
                        },
                        onLongPress: () {
                          setState(() {
                            if (estSelectionne) {
                              _produitsSelectionnes.remove(produit);
                            } else {
                              _produitsSelectionnes.add(produit);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: selectionActive
          ? null
          : FloatingActionButton(
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add),
              onPressed: () async {
                final bool? succes = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreerProduitPage()),
                );
                if (succes == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Ajout réussie")),
                  );
                  await _fetchProduits();
                }
              },
            ),
    );
  }
}
