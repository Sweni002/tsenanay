import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'venteProduit.dart';
class VentePage extends StatefulWidget {
  const VentePage({Key? key}) : super(key: key);

  @override
  State<VentePage> createState() => _VentePageState();
}


class _VentePageState extends State<VentePage> {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  // Simule liste des produits avec quantité dispo
  List<Map<String, dynamic>> _produits = [
    {"nom": "Pomme", "qte": 10},
    {"nom": "Banane", "qte": 20},
    {"nom": "Orange", "qte": 15},
    {"nom": "Mangue", "qte": 8},
  ];

  // Liste des ventes effectuées
  List<Map<String, dynamic>> _ventes = [
    {
      "nom": "Pomme",
      "qte": 3,
      "prix": 1500,
      "date": DateTime(2025, 8, 1),
    },
    {
      "nom": "Banane",
      "qte": 5,
      "prix": 1200,
      "date": DateTime(2025, 8, 5),
    },
  ];

  List<Map<String, dynamic>> _ventesFiltres = [];
  final TextEditingController _searchController = TextEditingController();
  DateTime? _dateDebut;
  DateTime? _dateFin;
DateTime? _dateUnique;

  bool _isDoingVente = false;

  @override
  void initState() {
    super.initState();
    _ventesFiltres = List.from(_ventes);
    _searchController.addListener(_filtrerVentes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrerVentes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _ventesFiltres = _ventes.where((vente) {
        final matchesNom = vente['nom'].toString().toLowerCase().contains(query);
        bool matchesDate = true;
        if (_dateDebut != null) {
          matchesDate = vente['date'].isAfter(_dateDebut!.subtract(const Duration(days: 1)));
        }
        if (_dateFin != null) {
          matchesDate = matchesDate && vente['date'].isBefore(_dateFin!.add(const Duration(days: 1)));
        }
        return matchesNom && matchesDate;
      }).toList();
    });
  }
Future<void> _selectUniqueDate(BuildContext context) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: _dateUnique ?? DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
    helpText: "Sélectionner une date",
  );
  if (picked != null) {
    setState(() {
      _dateUnique = picked;
      _ventesFiltres = _ventes.where((vente) {
        return _dateFormat.format(vente['date']) ==
               _dateFormat.format(_dateUnique!);
      }).toList();
    });
  }
}

  Future<void> _selectDate(BuildContext context, bool isDebut) async {
    final initialDate = isDebut ? (_dateDebut ?? DateTime.now()) : (_dateFin ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: isDebut ? "Sélectionner la date de début" : "Sélectionner la date de fin",
    );
    if (picked != null) {
      setState(() {
        if (isDebut) {
          _dateDebut = picked;
          if (_dateFin != null && _dateFin!.isBefore(_dateDebut!)) {
            _dateFin = _dateDebut;
          }
        } else {
          _dateFin = picked;
          if (_dateDebut != null && _dateFin!.isBefore(_dateDebut!)) {
            _dateDebut = _dateFin;
          }
        }
      });
      _filtrerVentes();
    }
  }

  Future<void> _exportCsv() async {
    if (_dateDebut == null || _dateFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner une période complète")),
      );
      return;
    }

    List<List<String>> csvData = [
      ["Nom", "Quantité", "Prix Unitaire (Ar)", "Prix Total (Ar)", "Date"],
      ..._ventesFiltres.map((vente) => [
            vente['nom'].toString(),
            vente['qte'].toString(),
            vente['prix'].toString(),
            (vente['qte'] * vente['prix']).toString(),
            _dateFormat.format(vente['date']),
          ]),
    ];

    final csv = const ListToCsvConverter().convert(csvData);

    try {
      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/ventes_export_${_dateFormat.format(_dateDebut!)}_to_${_dateFormat.format(_dateFin!)}.csv';
      final file = File(path);
      await file.writeAsString(csv);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Export réussi : $path")),
      );

      await Share.shareXFiles([XFile(path)], text: 'Voici le fichier CSV exporté');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'export : $e")),
      );
    }
  }

  void _faireVenteSurProduit(Map<String, dynamic> produit) {
    setState(() {
      _isDoingVente = true;
    });

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20),
          child: _VenteSurProduitSheet(
            produit: produit,
            onVenteConfirmee: (qteVendue, prixUnitaire) {
              setState(() {
                _ventes.add({
                  "nom": produit['nom'],
                  "qte": qteVendue,
                  "prix": prixUnitaire,
                  "date": DateTime.now(),
                });

                int indexProd = _produits.indexWhere((p) => p['nom'] == produit['nom']);
                if (indexProd != -1) {
                  _produits[indexProd]['qte'] -= qteVendue;
                  if (_produits[indexProd]['qte'] < 0) {
                    _produits[indexProd]['qte'] = 0;
                  }
                }

                _filtrerVentes();
              });
              Navigator.pop(context);
            },
          ),
        );
      },
    ).whenComplete(() {
      setState(() {
        _isDoingVente = false;
      });
    });
  }

  void _showAddVenteDialog() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20),
          child: _AddVenteManuelleSheet(
            onAjouter: (vente) {
              setState(() {
                _ventes.add(vente);
                _filtrerVentes();
              });
            },
          ),
        );
      },
    );
  }

  // Fonction pour supprimer une vente avec confirmation
  Future<bool?> _confirmDelete(BuildContext context, Map<String, dynamic> vente) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirmer la suppression"),
          content: Text("Voulez-vous vraiment supprimer la vente de ${vente['nom']} ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Supprimer"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
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
            // Recherche
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Rechercher un produit vendu',
                     border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            // Filtre dates
    // Filtre dates (période et date unique)
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  child: Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          icon: const Icon(Icons.date_range),
          label: Text(_dateDebut == null
              ? 'Date début'
              : _dateFormat.format(_dateDebut!)),
          onPressed: () => _selectDate(context, true),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: OutlinedButton.icon(
          icon: const Icon(Icons.date_range),
          label: Text(_dateFin == null
              ? 'Date fin'
              : _dateFormat.format(_dateFin!)),
          onPressed: () => _selectDate(context, false),
        ),
      ),
    ],
  ),
),
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  child: OutlinedButton.icon(
    icon: const Icon(Icons.calendar_today),
    label: Text(_dateUnique == null
        ? 'Filtrer par date unique'
        : _dateFormat.format(_dateUnique!)),
    onPressed: () => _selectUniqueDate(context),
  ),
),
// Bouton Export (visible seulement si 2 dates choisies)
if (_dateDebut != null && _dateFin != null)
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal.shade700,
        minimumSize: const Size.fromHeight(46),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 4,
      ),
      icon: const Icon(Icons.download),
      label: const Text(
        'Exporter les ventes (période)',
        style: TextStyle(color: Colors.white),
      ),
      onPressed: _exportCsv,
    ),
  ),

            // Bouton Export
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                icon: const Icon(Icons.download),
                label: const Text('Exporter les ventes', style: TextStyle(color: Colors.white)),
                onPressed: _exportCsv,
              ),
            ),

            const Divider(height: 1),

            // Liste des ventes avec Dismissible
            Expanded(
              child: _ventesFiltres.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucune vente trouvée',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: _ventesFiltres.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final vente = _ventesFiltres[index];
                        return Dismissible(
                          key: UniqueKey(),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          secondaryBackground: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) => _confirmDelete(context, vente),
                          onDismissed: (direction) {
                            setState(() {
                              // Supprime de la liste principale et filtrée
                              _ventes.remove(vente);
                              _filtrerVentes();

                              // Facultatif : remettre la qté dans stock si le produit est dans la liste
                              final indexProd = _produits.indexWhere((p) => p['nom'] == vente['nom']);
                              if (indexProd != -1) {
                                _produits[indexProd]['qte'] += vente['qte'];
                              }
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Vente supprimée")),
                            );
                          },
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal.shade100,
                              child: const Icon(Icons.sell, color: Colors.teal),
                            ),
                            title: Text(
                              vente['nom'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            subtitle: Text(
                              "Quantité: ${vente['qte']} • Prix unitaire: ${vente['prix']} Ar\nDate: ${_dateFormat.format(vente['date'])}",
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey.shade700),
                            ),
                            trailing: Text(
                              "${vente['qte'] * vente['prix']} Ar",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.teal),
                            ),
                            onTap: () {
                              final produit = _produits.firstWhere(
                                  (p) => p['nom'] == vente['nom'],
                                  orElse: () => {});
                              if (produit.isNotEmpty) {
                                _faireVenteSurProduit(produit);
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
  floatingActionButton: FloatingActionButton(
  backgroundColor: Colors.teal,
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VendrePage(
          produits: _produits,
          onFaireVente: (produit) {
            _faireVenteSurProduit(produit);
          },
        ),
      ),
    );
  },
  child: const Icon(Icons.add),
),
    );
  }
}

// Widget bottom sheet pour vente sur un produit existant
class _VenteSurProduitSheet extends StatefulWidget {
  final Map<String, dynamic> produit;
  final Function(int qteVendue, int prixUnitaire) onVenteConfirmee;

  const _VenteSurProduitSheet({
    Key? key,
    required this.produit,
    required this.onVenteConfirmee,
  }) : super(key: key);

  @override
  State<_VenteSurProduitSheet> createState() => _VenteSurProduitSheetState();
}

class _VenteSurProduitSheetState extends State<_VenteSurProduitSheet> {
  final _formKey = GlobalKey<FormState>();
  final qteVendueController = TextEditingController();
  final prixController = TextEditingController();

  @override
  void dispose() {
    qteVendueController.dispose();
    prixController.dispose();
    super.dispose();
  }

  void _valider() {
    if (_formKey.currentState!.validate()) {
      final qteVendue = int.parse(qteVendueController.text);
      final prix = int.parse(prixController.text);
      widget.onVenteConfirmee(qteVendue, prix);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
            Text(
              "Vente de ${widget.produit['nom']}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            TextFormField(
              initialValue: widget.produit['qte'].toString(),
              decoration: const InputDecoration(
                labelText: "Quantité actuelle",
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: qteVendueController,
              decoration: const InputDecoration(
                labelText: "Quantité vendue",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return "Entrez la quantité vendue";
                }
                final qte = int.tryParse(val);
                if (qte == null || qte <= 0) {
                  return "Quantité invalide";
                }
                if (qte > widget.produit['qte']) {
                  return "Quantité vendue > quantité disponible";
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: prixController,
              decoration: const InputDecoration(
                labelText: "Prix unitaire (Ar)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return "Entrez le prix unitaire";
                }
                final prix = int.tryParse(val);
                if (prix == null || prix <= 0) {
                  return "Prix invalide";
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _valider,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Valider la vente",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Widget bottom sheet pour ajouter une vente manuelle (produit libre)
class _AddVenteManuelleSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onAjouter;

  const _AddVenteManuelleSheet({Key? key, required this.onAjouter})
      : super(key: key);

  @override
  State<_AddVenteManuelleSheet> createState() => _AddVenteManuelleSheetState();
}

class _AddVenteManuelleSheetState extends State<_AddVenteManuelleSheet> {
  final _formKey = GlobalKey<FormState>();
  final nomController = TextEditingController();
  final qteController = TextEditingController();
  final prixController = TextEditingController();

  @override
  void dispose() {
    nomController.dispose();
    qteController.dispose();
    prixController.dispose();
    super.dispose();
  }

  void _valider() {
    if (_formKey.currentState!.validate()) {
      widget.onAjouter({
        "nom": nomController.text.trim(),
        "qte": int.parse(qteController.text),
        "prix": int.parse(prixController.text),
        "date": DateTime.now(),
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
              "Ajouter une vente manuelle",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: nomController,
              decoration: const InputDecoration(
                labelText: "Nom du produit",
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return "Entrez le nom du produit";
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: qteController,
              decoration: const InputDecoration(
                labelText: "Quantité",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return "Entrez la quantité";
                }
                final qte = int.tryParse(val);
                if (qte == null || qte <= 0) {
                  return "Quantité invalide";
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: prixController,
              decoration: const InputDecoration(
                labelText: "Prix unitaire (Ar)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return "Entrez le prix unitaire";
                }
                final prix = int.tryParse(val);
                if (prix == null || prix <= 0) {
                  return "Prix invalide";
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _valider,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Ajouter la vente",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Utilitaire CSV (simple)
class ListToCsvConverter {
  const ListToCsvConverter();

  String convert(List<List<String>> data) {
    return data.map((row) {
      return row.map((item) {
        final escaped = item.replaceAll('"', '""');
        if (escaped.contains(',') || escaped.contains('"') || escaped.contains('\n')) {
          return '"$escaped"';
        }
        return escaped;
      }).join(',');
    }).join('\n');
  }
}
