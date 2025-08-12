import 'package:dio/dio.dart';

class DioClient {
  late final Dio dio;

  DioClient() {
  dio = Dio(
  BaseOptions(
    baseUrl: 'http://192.168.18.50:5000',
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

  Future<Map<String, dynamic>> updateProduit(int idproduit, Map<String, dynamic> data) async {
    final response = await dio.put('/produits/$idproduit', data: data);
    return response.data;
  }

  Future<void> deleteProduit(int idproduit) async {
    await dio.delete('/produits/$idproduit');
  }
}
