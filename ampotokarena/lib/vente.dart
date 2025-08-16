import 'package:flutter/material.dart';
import 'creer_produit.dart';
import 'dioClient.dart';
import 'venteProduit.dart';
import 'package:intl/intl.dart'; // ⚡ Pour formater la date
import 'package:table_calendar/table_calendar.dart'; // ⚡ nouveau package
import 'package:intl/date_symbol_data_local.dart';
import 'FilterByDateRangePage.dart';
import 'package:dio/dio.dart';

class VentePage extends StatefulWidget {
  const VentePage({Key? key}) : super(key: key);

  @override
  State<VentePage> createState() => _VenteState();
}

class _VenteState extends State<VentePage> {
  final DioClient dioClient = DioClient();
 DateTime _selectedDate = DateTime.now(); // Date initiale
DateTime? _filterStart;
DateTime? _filterEnd;

  bool _isLoading = true;
  String? _error;
final Set<Map<String, dynamic>> _ventesSelectionnees = {};

  List<Map<String, dynamic>> _produits = [
    {"idproduit": 1, "nom": "Pomme", "qte": 10, "prix": 1500, "benefice": 500},
    {"idproduit": 2, "nom": "Banane", "qte": 20, "prix": 1200, "benefice": 300},
    {"idproduit": 3, "nom": "Orange", "qte": 15, "prix": 1000, "benefice": 200},
    {"idproduit": 4, "nom": "Mangue", "qte": 8, "prix": 2500, "benefice": 600},
  ];

  List<Map<String, dynamic>> _produitsFiltres = [];

  final TextEditingController _searchController = TextEditingController();

  // Pour gérer la sélection multiple
  final Set<Map<String, dynamic>> _produitsSelectionnes = {};
  List<Map<String, dynamic>> _ventes = [];

 Future<void> _fetchVentesParDate(DateTime date) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final data = await dioClient.getFilteredVentes(dateStr); // ⚡ Méthode à créer dans DioClient
      final ventes = List<Map<String, dynamic>>.from(data);

      setState(() {
        _ventes = ventes;
        _ventesFiltres = ventes;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur du connexion")));
 
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

Future<void> _selectDate(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: SizedBox(
          width: 300,
          height: 350,
          child: CalendarDatePicker(
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
            onDateChanged: (date) {
              setState(() {
                _selectedDate = date;
                _filterStart = date;
                _filterEnd = date;
              });
              _fetchVentesParDate(date);
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    },
  );
}

  Future<void> _fetchVentes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await dioClient.getVentes();
      final ventes = List<Map<String, dynamic>>.from(data);

      setState(() {
        _ventes = ventes; // 🔹 garde la liste complète
        _ventesFiltres = ventes; // 🔹 liste affichée (filtrée ou non)
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
Future<void> _supprimerVentesBackend() async {
  if (_ventesSelectionnees.isEmpty) return;

  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Confirmer la suppression"),
      content: Text(
        "Voulez-vous vraiment supprimer ${_ventesSelectionnees.length} vente${_ventesSelectionnees.length > 1 ? 's' : ''} ?",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Annuler"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Supprimer"),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  for (final vente in _ventesSelectionnees) {
    try {
  final message = await dioClient.deleteVente(vente['idvente']);
       ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(message)),
); // ⚡ méthode à créer
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e")),
      );
    }
  }

  setState(() {
    _ventesSelectionnees.clear();
  });

  await _fetchVentesParDate(_selectedDate); // 🔹 refresh
}

  List<Map<String, dynamic>> _ventesFiltres = [];

  void _filtrerVentes(String query) {
    if (query.isEmpty) {
      setState(() {
        _ventesFiltres = List.from(_ventes);
      });
    } else {
      setState(() {
        _ventesFiltres = _ventes.where((vente) {
          return vente['nom_produit'].toString().toLowerCase().contains(
            query.toLowerCase(),
          );
        }).toList();
      });
    }
  }
Future<void> _selectDateRange(BuildContext context) async {
  DateTimeRange? picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
    locale: const Locale('fr', 'FR'),
    initialDateRange: DateTimeRange(
      start: _selectedDate,
      end: _selectedDate,
    ),
  );

  if (picked != null) {
    setState(() {
      _selectedDate = picked.start; // optionnel : mettre à jour la date initiale
    });

    try {
      final data = await dioClient.getVentesRange(
        picked.start,
        picked.end,
      ); // ⚡ méthode à créer dans DioClient
      setState(() {
        _ventes = List<Map<String, dynamic>>.from(data);
        _ventesFiltres = _ventes;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e")),
      );
    }
  }
}

  @override
  void initState() {
    super.initState();
    
    _fetchProduits();
    _fetchVentesParDate(_selectedDate); // charger les ventes du jour initial
  // ⚡ Initialiser la locale française pour les dates
  initializeDateFormatting('fr_FR', null).then((_) {
    setState(() {}); // forcer rebuild si nécessaire
  });
    _searchController.addListener(() {
      _filtrerVentes(_searchController.text);
    });
  }

  void _faireVente(
    Map<String, dynamic> produit,
    int qte,
    double prixUnitaire,
  ) async {
    try {
      final venteData = {
        "idproduit": produit['idproduit'],
        "qte": qte,
        "prix": prixUnitaire,
        "date": DateTime.now().toIso8601String(),
      };

      await dioClient.addVente(venteData);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vente enregistrée")));

      await _fetchProduits(); // mise à jour des produits
      await _fetchVentesParDate(_selectedDate); // ✅ seulement les ventes du jour sélectionné
   } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
void _handleDioError(BuildContext context, dynamic error) {
  // Supprimer le dernier SnackBar s'il y en a un
  ScaffoldMessenger.of(context).hideCurrentSnackBar();

  String message = "Erreur inconnue";

  if (error is DioError) {
    if (error.type == DioErrorType.connectionError || 
        error.type == DioErrorType.connectionTimeout) {
      message = "Erreur de connexion";
    } else if (error.response != null) {
      message = "Erreur serveur: ${error.response?.statusCode}";
    } else {
      message = "Erreur: ${error.message}";
    }
  } else {
    message = error.toString();
  }

  // Afficher un seul SnackBar à la fois
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

  Future<void> _supprimerProduitBackend(int idproduit) async {
    try {
      await dioClient.deleteProduit(idproduit);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Suppression terminée")));
      await _fetchProduits();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Erreur du connexion")));
    }
  }

  Future<void> _fetchProduits() async {
    try {
      final data = await dioClient.getProduits();
      setState(() {
        _produits = List<Map<String, dynamic>>.from(data);
        _produitsFiltres = List.from(_produits);
        _filtrerProduits(
          _searchController.text,
        ); // 🔹 directement mettre à jour la liste filtrée
      });
    } catch (e) {
       ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur du connexion")));
 

    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final bool selectionActive = _produitsSelectionnes.isNotEmpty;

    return Scaffold(
 appBar: AppBar(
  title: _ventesSelectionnees.isNotEmpty
      ? Text("${_ventesSelectionnees.length} sélectionnée${_ventesSelectionnees.length > 1 ? 's' : ''}")
      : InkWell(
          onTap: () => _selectDate(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_month_outlined, color: Colors.teal),
              const SizedBox(width: 5),
              Text(
                (_filterStart != null && _filterEnd != null)
                    ? (_filterStart == _filterEnd
                        ? DateFormat('dd MMM yyyy', 'fr_FR').format(_filterStart!)
                        : "${DateFormat('dd MMM yyyy', 'fr_FR').format(_filterStart!)} → ${DateFormat('dd MMM yyyy', 'fr_FR').format(_filterEnd!)}")
                    : DateFormat('dd MMM yyyy', 'fr_FR').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.teal,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
  leading: null,
  actions: [
    if (_ventesSelectionnees.isNotEmpty) ...[
      IconButton(
        icon: const Icon(Icons.delete),
        onPressed: _supprimerVentesBackend,
        tooltip: "Supprimer la sélection",
      ),
      IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          setState(() {
            _ventesSelectionnees.clear();
          });
        },
        tooltip: "Annuler la sélection",
      ),
    ],
    // le menu "trier entre deux dates"
    PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.teal),
      onSelected: (value) async {
        if (value == 'trier') {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FilterByDateRangePage(),
            ),
          );

          if (result != null) {
            _filterStart = result['startDate'] as DateTime;
            _filterEnd = result['endDate'] as DateTime;

            try {
              final data = await dioClient.getVentesRange(_filterStart!, _filterEnd!);
              setState(() {
                _ventes = List<Map<String, dynamic>>.from(data);
                _ventesFiltres = _ventes;
              });
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Erreur lors du filtrage: $e")),
              );
            }
          }
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'trier',
          child: Text("Trier entre deux dates"),
        ),
      ],
    ),
  ],
)
,    body: SafeArea(
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
    itemCount: _ventesFiltres.length,
    itemBuilder: (context, index) {
      final vente = _ventesFiltres[index];
      final isSelected = _ventesSelectionnees.contains(vente);

    return AnimatedContainer(
  duration: const Duration(milliseconds: 250),
  curve: Curves.easeInOut,
  child: Card(
    color: isSelected ? Colors.teal.withOpacity(0.15) : Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: isSelected
          ? BorderSide(color: Colors.teal, width: 2)
          : BorderSide.none,
    ),
    elevation: isSelected ? 6 : 4,
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: InkWell(
      onLongPress: () {
        setState(() {
          if (isSelected) {
            _ventesSelectionnees.remove(vente);
          } else {
            _ventesSelectionnees.add(vente);
          }
        });
      },
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.teal : Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.sell,
                color: isSelected ? Colors.white : Colors.teal,
              ),
            ),
            if (isSelected)
              const Positioned(
                right: -6,
                top: -6,
                child: Icon(
                  Icons.check_circle,
                  color: Colors.teal,
                  size: 20,
                ),
              ),
          ],
        ),
        title: Text(
          vente['nom_produit'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isSelected ? Colors.teal.shade900 : Colors.black,
          ),
        ),
        subtitle: Text(
          "Prix: ${vente['prix']} Ar",
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        children: [
   Container(
  width: double.infinity,
  decoration: BoxDecoration(
    color: Colors.teal.shade50.withOpacity(0.2),
    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
  ),
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  child: Row(
    children: [
      // 📦 Carte Quantité
      Expanded(
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(10),
                child: const Icon(
                  Icons.inventory_2,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "${vente['qte']}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Text(
                "Qté",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),

      const SizedBox(width: 10),

      // 📅 Carte Date
      Expanded(
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(10),
                child: const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('dd MMM yyyy', 'fr_FR')
                    .format(DateTime.parse(vente['date'])),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Text(
                "Date",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
)
   ],
      ),
    ),
  ),
);
   },
  ),
)
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
                produits: _produits, // ⚡ ajouter ceci
                fetchProduits: _fetchProduits,
                onFaireVente: _faireVente,
                onRefreshProduit: _fetchProduits,
                onRefreshVente: _fetchVentes,
                getProduits: () =>
                    _produits, // ⚡ ton callback pour récupérer la liste
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
