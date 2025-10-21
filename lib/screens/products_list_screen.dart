import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/product_card.dart';
import '../widgets/role_based_widget.dart';

class ProductsListScreen extends StatefulWidget {
  const ProductsListScreen({super.key});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  final _searchController = TextEditingController();
  String _sortBy = 'name';
  String _filterBy = 'all';
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    await productProvider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Productos'),
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          _buildSearchAndFilters(),

          // Lista de productos
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, _) {
                if (productProvider.isLoading && !productProvider.hasProducts) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Cargando productos...'),
                      ],
                    ),
                  );
                }

                if (productProvider.errorMessage != null &&
                    !productProvider.hasProducts) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          productProvider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadProducts,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                final products = productProvider.products;

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          productProvider.searchQuery.isNotEmpty
                              ? 'No se encontraron productos'
                              : 'No hay productos disponibles',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          productProvider.searchQuery.isNotEmpty
                              ? 'Prueba con otros términos de búsqueda'
                              : 'Los productos aparecerán aquí cuando se agreguen',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 16),
                        RoleBasedWidget(
                          requiredRole: 'admin',
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/product-form'),
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar Producto'),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: productProvider.refreshProducts,
                  child: _isGridView
                      ? _buildGridView(products, productProvider)
                      : _buildListView(products, productProvider),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: RoleBasedWidget(
        requiredRole: 'admin',
        child: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/product-form'),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar productos...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 12),

          // Filtros y opciones
          Row(
            children: [
              // Filtro por stock
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _filterBy,
                  decoration: InputDecoration(
                    labelText: 'Filtrar',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('Todos', style: TextStyle(fontSize: 14)),
                    ),
                    DropdownMenuItem(
                      value: 'in_stock',
                      child: Text('En stock', style: TextStyle(fontSize: 14)),
                    ),
                    DropdownMenuItem(
                      value: 'low_stock',
                      child: Text('Stock bajo', style: TextStyle(fontSize: 14)),
                    ),
                    DropdownMenuItem(
                      value: 'out_of_stock',
                      child: Text('Sin stock', style: TextStyle(fontSize: 14)),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _filterBy = value;
                      });
                      _applyFilters();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Ordenar por
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: InputDecoration(
                    labelText: 'Ordenar',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'name',
                      child: Text('Nombre', style: TextStyle(fontSize: 14)),
                    ),
                    DropdownMenuItem(
                      value: 'price',
                      child: Text('Precio', style: TextStyle(fontSize: 14)),
                    ),
                    DropdownMenuItem(
                      value: 'stock',
                      child: Text('Stock', style: TextStyle(fontSize: 14)),
                    ),
                    DropdownMenuItem(
                      value: 'created',
                      child: Text('Fecha', style: TextStyle(fontSize: 14)),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortBy = value;
                      });
                      _applySorting();
                    }
                  },
                ),
              ),
              const SizedBox(width: 4),

              // Toggle vista - sin overflow
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    _isGridView ? Icons.view_list : Icons.grid_view,
                    size: 20,
                  ),
                  tooltip: _isGridView
                      ? 'Vista de lista'
                      : 'Vista de cuadrícula',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List products, ProductProvider productProvider) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          onTap: () => Navigator.pushNamed(
            context,
            '/product-detail',
            arguments: product.id,
          ),
          onEdit: () =>
              Navigator.pushNamed(context, '/product-form', arguments: product),
          onDelete: () => _deleteProduct(product.id, productProvider),
        );
      },
    );
  }

  Widget _buildGridView(List products, ProductProvider productProvider) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          isGridView: true,
          onTap: () => Navigator.pushNamed(
            context,
            '/product-detail',
            arguments: product.id,
          ),
          onEdit: () =>
              Navigator.pushNamed(context, '/product-form', arguments: product),
          onDelete: () => _deleteProduct(product.id, productProvider),
        );
      },
    );
  }

  void _onSearchChanged(String query) {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    productProvider.searchProducts(query);
  }

  void _applyFilters() {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    productProvider.filterByStock(_filterBy);
  }

  void _applySorting() {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    productProvider.sortProducts(_sortBy);
  }

  Future<void> _deleteProduct(
    int productId,
    ProductProvider productProvider,
  ) async {
    final success = await productProvider.deleteProduct(productId);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (productProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(productProvider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
