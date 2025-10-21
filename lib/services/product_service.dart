import 'package:dio/dio.dart';
import '../models/product.dart';
import 'api_service.dart';

class ProductService {
  final ApiService _apiService;

  ProductService(this._apiService);

  /// Obtiene todos los productos
  Future<List<Product>> getProducts({
    int? limit,
    int? offset,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiService.dio.get(
        '/products',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        // Manejar diferentes estructuras de respuesta del servidor
        dynamic responseData = response.data;
        List<dynamic> productsJson;

        if (responseData is List) {
          // Respuesta directa como lista
          productsJson = responseData;
        } else if (responseData is Map<String, dynamic>) {
          // Respuesta anidada en un objeto
          productsJson =
              responseData['products'] ??
              responseData['data'] ??
              responseData['items'] ??
              [];
        } else {
          throw Exception('Formato de respuesta inesperado del servidor');
        }

        return productsJson.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception(
          'Error al obtener productos: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('No autorizado. Inicia sesión nuevamente.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('No tienes permisos para ver los productos.');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión. Verifica tu conexión a internet.');
      } else {
        throw Exception('Error en el servidor: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Obtiene un producto por ID
  Future<Product> getProduct(int id) async {
    try {
      final response = await _apiService.dio.get('/products/$id');

      if (response.statusCode == 200) {
        // Manejar diferentes estructuras de respuesta del servidor
        dynamic responseData = response.data;
        Map<String, dynamic> productJson;

        if (responseData is Map<String, dynamic>) {
          // Si la respuesta ya es un mapa, verificar si es el producto directamente
          // o si está anidado
          if (responseData.containsKey('id') ||
              responseData.containsKey('name')) {
            productJson = responseData;
          } else {
            // Buscar el producto en campos comunes
            productJson =
                responseData['product'] ??
                responseData['data'] ??
                responseData['item'] ??
                responseData;
          }
        } else {
          throw Exception('Formato de respuesta inesperado del servidor');
        }

        return Product.fromJson(productJson);
      } else {
        throw Exception('Error al obtener producto: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Producto no encontrado.');
      } else if (e.response?.statusCode == 401) {
        throw Exception('No autorizado. Inicia sesión nuevamente.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('No tienes permisos para ver este producto.');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión. Verifica tu conexión a internet.');
      } else {
        throw Exception('Error en el servidor: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Crea un nuevo producto (solo admin)
  Future<Product> createProduct({
    required String name,
    String? description,
    required double price,
    required int stock,
  }) async {
    try {
      final productData = {
        'name': name,
        'description': description,
        'price': price,
        'stock': stock,
      };

      final response = await _apiService.dio.post(
        '/products',
        data: productData,
      );

      if (response.statusCode == 201) {
        return Product.fromJson(response.data);
      } else {
        throw Exception('Error al crear producto: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'Datos inválidos';
        throw Exception('Error de validación: $message');
      } else if (e.response?.statusCode == 401) {
        throw Exception('No autorizado. Inicia sesión nuevamente.');
      } else if (e.response?.statusCode == 403) {
        throw Exception(
          'No tienes permisos para crear productos. Solo administradores.',
        );
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión. Verifica tu conexión a internet.');
      } else {
        throw Exception('Error en el servidor: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Actualiza un producto existente (solo admin)
  Future<Product> updateProduct({
    required int id,
    required String name,
    String? description,
    required double price,
    required int stock,
  }) async {
    try {
      final productData = {
        'name': name,
        'description': description,
        'price': price,
        'stock': stock,
      };

      final response = await _apiService.dio.put(
        '/products/$id',
        data: productData,
      );

      if (response.statusCode == 200) {
        return Product.fromJson(response.data);
      } else {
        throw Exception(
          'Error al actualizar producto: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'Datos inválidos';
        throw Exception('Error de validación: $message');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Producto no encontrado.');
      } else if (e.response?.statusCode == 401) {
        throw Exception('No autorizado. Inicia sesión nuevamente.');
      } else if (e.response?.statusCode == 403) {
        throw Exception(
          'No tienes permisos para actualizar productos. Solo administradores.',
        );
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión. Verifica tu conexión a internet.');
      } else {
        throw Exception('Error en el servidor: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Elimina un producto (solo admin)
  Future<void> deleteProduct(int id) async {
    try {
      final response = await _apiService.dio.delete('/products/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Error al eliminar producto: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Producto no encontrado.');
      } else if (e.response?.statusCode == 401) {
        throw Exception('No autorizado. Inicia sesión nuevamente.');
      } else if (e.response?.statusCode == 403) {
        throw Exception(
          'No tienes permisos para eliminar productos. Solo administradores.',
        );
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión. Verifica tu conexión a internet.');
      } else {
        throw Exception('Error en el servidor: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Busca productos por nombre
  Future<List<Product>> searchProducts(String query) async {
    return getProducts(search: query);
  }

  /// Obtiene estadísticas de productos
  Future<Map<String, dynamic>> getProductStats() async {
    try {
      final products = await getProducts();

      final totalProducts = products.length;
      final inStock = products.where((p) => p.isInStock).length;
      final outOfStock = products.where((p) => p.isOutOfStock).length;
      final lowStock = products.where((p) => p.isLowStock).length;
      final totalValue = products.fold<double>(
        0,
        (sum, p) => sum + (p.price * p.stock),
      );

      return {
        'totalProducts': totalProducts,
        'inStock': inStock,
        'outOfStock': outOfStock,
        'lowStock': lowStock,
        'totalValue': totalValue,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }
}
