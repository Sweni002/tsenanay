import 'package:flutter/material.dart';
import 'dioClient.dart'; // Assure-toi d'avoir ce fichier avec ta classe DioClient

class CreerProduitPage extends StatefulWidget {
  final Map<String, dynamic>? produit; // optionnel

  const CreerProduitPage({Key? key, this.produit}) : super(key: key);

  @override
  State<CreerProduitPage> createState() => _CreerProduitPageState();
}

class _CreerProduitPageState extends State<CreerProduitPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _prixController;
  late TextEditingController _beneficeController;
  int _qte = 0;

  bool _loading = false; // pour indiquer qu'on attend la réponse

  final DioClient dioClient = DioClient();

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.produit?["nom"] ?? "");
    _prixController = TextEditingController(
      text: widget.produit?["prix"]?.toString() ?? "",
    );
    _beneficeController = TextEditingController(
      text: widget.produit?["benefice"]?.toString() ?? "",
    );
    _qte = widget.produit?["qte"] ?? 0;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prixController.dispose();
    _beneficeController.dispose();
    super.dispose();
  }

  Widget _buildStepper(String label, int value, Function(int) onChanged) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
            IconButton(
              onPressed: () {
                if (value > 0) onChanged(value - 1);
              },
              icon: const Icon(Icons.remove_circle, color: Colors.red),
            ),
            Text(
              "$value",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: () {
                onChanged(value + 1);
              },
              icon: const Icon(Icons.add_circle, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enregistrer() async {
    if (_formKey.currentState!.validate()) {
      final prix = int.tryParse(_prixController.text) ?? 0;
      final benefice = int.tryParse(_beneficeController.text) ?? 0;

      if (benefice > prix) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Le bénéfice ne peut pas être supérieur au prix"),
          ),
        );
        return;
      }

      setState(() => _loading = true);

      final data = {
        "nom": _nomController.text.trim(),
        "qte": _qte,
        "prix": prix,
        "benefice": benefice,
      };

      try {
        Map<String, dynamic> result;

        if (widget.produit == null) {
          // Création
          result = await dioClient.addProduit(data);
          
        } else {
          // Mise à jour
          final id = widget.produit!['idproduit'];
          result = await dioClient.updateProduit(id, data);

        }

        if (mounted) {
          print("succes");
          setState(() => _loading = false);
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur du connexion")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool modeEdition = widget.produit != null;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(modeEdition ? "Modifier Produit" : "Créer un produit"),
        backgroundColor: Colors.blue,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextFormField(
                        controller: _nomController,
                        decoration: const InputDecoration(
                          labelText: "Nom du produit",
                          prefixIcon: Icon(Icons.label),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? "Entrez un nom"
                            : null,
                      ),
                    ),

                    _buildStepper("Quantité", _qte, (val) {
                      setState(() => _qte = val);
                    }),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextFormField(
                        controller: _prixController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Prix (Ar)",
                          prefixIcon: Icon(Icons.price_check),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Entrez un prix";
                          }
                          if (int.tryParse(value) == null) {
                            return "Entrez un nombre valide";
                          }
                          return null;
                        },
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextFormField(
                        controller: _beneficeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Bénéfice (Ar)",
                          prefixIcon: Icon(Icons.monetization_on),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Entrez un bénéfice";
                          }
                          if (int.tryParse(value) == null) {
                            return "Entrez un nombre valide";
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
        
      ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.blue,
                        foregroundColor: const Color.fromARGB(255, 219, 219, 219)
                      ),
                      icon: const Icon(Icons.save),
                      label: Text(
                        modeEdition ? "Mettre à jour" : "Enregistrer",
                        style: const TextStyle(fontSize: 16),
                      ),
                      onPressed: _loading ? null : _enregistrer,
                    ),
                  ],
                ),
              ),
            ),

            if (_loading)
              Container(
                color: Colors.black54,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
