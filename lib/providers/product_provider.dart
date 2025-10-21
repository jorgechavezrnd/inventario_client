import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService;

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  Product? _selectedProduct;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  String _searchQuery = '';
  Map<String, dynamic>? _stats;

  ProductProvider(this._productService);

  // Getters
  List<Product> get products => _filteredProducts;
  List<Product> get allProducts => _products;
  Product? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  Map<String, dynamic>? get stats => _stats;
  bool get hasProducts => _products.isNotEmpty;

  /// Inicializa el provider cargando productos desde cache o servidor
  Future<void> initialize() async {
    await _loadFromCache();
    if (_products.isEmpty) {
      await loadProducts();
    } else {
      // Cargar en background para actualizar datos
      loadProducts(silent: true);
    }
  }

  /// Carga todos los productos
  Future<void> loadProducts({bool silent = false}) async {
    if (!silent) _setLoading(true);
    _clearError();

    try {
      final products = await _productService.getProducts();
      _products = products;
      _applyFilter();
      await _saveToCache();
      await _loadStats();
    } catch (e) {
      _setError(e.toString());
      // Si falla cargar del servidor, usar cache si está disponible
      if (_products.isEmpty) {
        await _loadFromCache();
      }
    } finally {
      if (!silent) _setLoading(false);
    }
  }

  /// Refresca los productos (pull-to-refresh)
  Future<void> refreshProducts() async {
    _setRefreshing(true);
    _clearError();

    try {
      final products = await _productService.getProducts();
      _products = products;
      _applyFilter();
      await _saveToCache();
      await _loadStats();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setRefreshing(false);
    }
  }

  /// Busca productos por nombre
  Future<void> searchProducts(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      _filteredProducts = List.from(_products);
    } else {
      _filteredProducts = _products
          .where(
            (product) =>
                product.name.toLowerCase().contains(query.toLowerCase()) ||
                (product.description?.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    }

    notifyListeners();
  }

  /// Carga un producto específico por ID
  Future<void> loadProduct(int id) async {
    _setLoading(true);
    _clearError();

    try {
      _selectedProduct = await _productService.getProduct(id);
    } catch (e) {
      _setError(e.toString());
      _selectedProduct = null;
    } finally {
      _setLoading(false);
    }
  }

  /// Crea un nuevo producto (solo admin)
  Future<bool> createProduct({
    required String name,
    String? description,
    required double price,
    required int stock,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final newProduct = await _productService.createProduct(
        name: name,
        description: description,
        price: price,
        stock: stock,
      );

      _products.add(newProduct);
      _applyFilter();
      await _saveToCache();
      await _loadStats();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Actualiza un producto existente (solo admin)
  Future<bool> updateProduct({
    required int id,
    required String name,
    String? description,
    required double price,
    required int stock,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedProduct = await _productService.updateProduct(
        id: id,
        name: name,
        description: description,
        price: price,
        stock: stock,
      );

      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        _products[index] = updatedProduct;
        _applyFilter();
        await _saveToCache();
        await _loadStats();

        // Actualizar producto seleccionado si es el mismo
        if (_selectedProduct?.id == id) {
          _selectedProduct = updatedProduct;
        }
      }

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Elimina un producto (solo admin)
  Future<bool> deleteProduct(int id) async {
    _setLoading(true);
    _clearError();

    try {
      await _productService.deleteProduct(id);

      _products.removeWhere((p) => p.id == id);
      _applyFilter();
      await _saveToCache();
      await _loadStats();

      // Limpiar producto seleccionado si es el eliminado
      if (_selectedProduct?.id == id) {
        _selectedProduct = null;
      }

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Carga las estadísticas de productos
  Future<void> _loadStats() async {
    try {
      _stats = await _productService.getProductStats();
      notifyListeners();
    } catch (e) {
      print('Error al cargar estadísticas: $e');
    }
  }

  /// Obtiene las estadísticas de productos
  Future<void> loadStats() async {
    await _loadStats();
  }

  /// Filtra productos por estado de stock
  void filterByStock(String filter) {
    switch (filter.toLowerCase()) {
      case 'in_stock':
        _filteredProducts = _products.where((p) => p.isInStock).toList();
        break;
      case 'low_stock':
        _filteredProducts = _products.where((p) => p.isLowStock).toList();
        break;
      case 'out_of_stock':
        _filteredProducts = _products.where((p) => p.isOutOfStock).toList();
        break;
      default:
        _filteredProducts = List.from(_products);
    }
    notifyListeners();
  }

  /// Ordena productos por criterio
  void sortProducts(String sortBy) {
    switch (sortBy.toLowerCase()) {
      case 'name':
        _filteredProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'price':
        _filteredProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'stock':
        _filteredProducts.sort((a, b) => a.stock.compareTo(b.stock));
        break;
      case 'created':
        _filteredProducts.sort((a, b) {
          if (a.createdAt == null || b.createdAt == null) return 0;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        break;
    }
    notifyListeners();
  }

  /// Aplica el filtro de búsqueda actual
  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredProducts = List.from(_products);
    } else {
      searchProducts(_searchQuery);
      return; // searchProducts ya notifica
    }
    notifyListeners();
  }

  /// Guarda productos en cache local
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final productsJson = _products.map((p) => p.toJson()).toList();
      await prefs.setString('cached_products', jsonEncode(productsJson));
      await prefs.setInt(
        'cache_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      print('Error al guardar en cache: $e');
    }
  }

  /// Carga productos desde cache local
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedProducts = prefs.getString('cached_products');
      final cacheTimestamp = prefs.getInt('cache_timestamp') ?? 0;

      // Verificar que el cache no sea muy antiguo (1 hora)
      final now = DateTime.now().millisecondsSinceEpoch;
      final cacheAge = now - cacheTimestamp;
      const maxCacheAge = 60 * 60 * 1000; // 1 hora en millisegundos

      if (cachedProducts != null && cacheAge < maxCacheAge) {
        final List<dynamic> productsJson = jsonDecode(cachedProducts);
        _products = productsJson.map((json) => Product.fromJson(json)).toList();
        _applyFilter();
      }
    } catch (e) {
      print('Error al cargar desde cache: $e');
    }
  }

  /// Limpia el cache de productos
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_products');
      await prefs.remove('cache_timestamp');
    } catch (e) {
      print('Error al limpiar cache: $e');
    }
  }

  /// Establece el estado de carga
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Establece el estado de refresh
  void _setRefreshing(bool refreshing) {
    _isRefreshing = refreshing;
    notifyListeners();
  }

  /// Establece un mensaje de error
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Limpia el mensaje de error
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Limpia el error actual
  void clearError() {
    _clearError();
  }

  /// Limpia el producto seleccionado
  void clearSelectedProduct() {
    _selectedProduct = null;
    notifyListeners();
  }

  /// Limpia la búsqueda
  void clearSearch() {
    _searchQuery = '';
    _applyFilter();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
