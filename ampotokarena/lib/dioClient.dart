
import 'package:dio/dio.dart';

class DioClient {
  late final Dio dio;

  DioClient() {
  dio = Dio(
  BaseOptions(
    baseUrl: 'http://192.168.68.50:5000',
    connectTimeout: Duration(seconds: 5),  // au lieu de 5000
    receiveTimeout: Duration(seconds: 3),
    headers: {
      'Content-Type': 'application/json',
    },
  ),
);
 }

  // Exemple GET produits
   Future<List<dynamic>> getProduits() async {
    try {
      final response = await dio.get('/produits/'); // correspond à la route GET /produit/
      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw Exception('Erreur lors de la récupération des produits');
      }
    } catch (e) {
      throw Exception('Erreur du connexion');
    }
  }

  
  // Exemple POST ajout produit
 Future<Map<String, dynamic>> addProduit(Map<String, dynamic> produitData) async {
  final response = await dio.post('/produits/', data: produitData);
  return response.data;  // ici on retourne uniquement les données
}

 Future<Map<String, dynamic>> doApprov(int idproduit, Map<String, dynamic> proddata) async {
  final response = await dio.post('/produits/approvisionner/$idproduit', data: proddata);
  return response.data;  // ici on retourne uniquement les données
}


  Future<Map<String, dynamic>> updateProduit(int idproduit, Map<String, dynamic> data) async {
    final response = await dio.put('/produits/$idproduit', data: data);
    return response.data;
  }

  Future<void> deleteProduit(int idproduit) async {
    await dio.delete('/produits/$idproduit');
  }

  Future<List<dynamic>> getVentes() async {
  try {
    final response = await dio.get('/ventes/');
    if (response.statusCode == 200) {
      return response.data as List<dynamic>;
    } else {
      throw Exception('Erreur lors de la récupération des ventes');
    }
  } catch (e) {
    throw Exception('Erreur de connexion');
  }
}

Future<Map<String, dynamic>> addVente(Map<String, dynamic> venteData) async {
  try {
    final response = await dio.post('/ventes/', data: venteData);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.data;
    } else {
      throw Exception('Erreur lors de l\'ajout de la vente');
    }
  } catch (e) {
    throw Exception('Erreur de connexion');
  }
}

 Future<List<dynamic>> getFilteredVentes(String date) async {
    final response = await dio.get('/ventes/filter', queryParameters: {
      'date': date,
    });
    return response.data;
  }
    // 🔹 Nouvelle fonction : récupérer les ventes entre deux dates
  Future<List<dynamic>> getVentesRange(DateTime start, DateTime end) async {
    final response = await dio.get("/ventes/filter-range", queryParameters: {
      "start_date": "${start.year}-${start.month.toString().padLeft(2,'0')}-${start.day.toString().padLeft(2,'0')}",
      "end_date": "${end.year}-${end.month.toString().padLeft(2,'0')}-${end.day.toString().padLeft(2,'0')}",
    });
    return response.data;
  }
Future<String> deleteVente(int idVente) async {
  try {
    final response = await dio.delete('/ventes/$idVente');

    // On peut récupérer un message depuis le backend si il envoie { "message": "Vente supprimée" }
    if (response.statusCode == 200 || response.statusCode == 204) {
      // Si le backend ne renvoie rien, tu peux mettre un message par défaut
      return response.data['message'] ?? 'Vente supprimée avec succès';
    } else {
      return 'Erreur lors de la suppression';
    }
  } catch (e) {
    return 'Erreur: $e';
  }
}



}
