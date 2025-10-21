import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Mi Perfil'),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;

          if (user == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'No se pudo cargar la información del usuario',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(context, user, authProvider),
                const SizedBox(height: 24),
                _buildUserInfo(context, user),
                const SizedBox(height: 24),
                _buildPermissions(context, user),
                const SizedBox(height: 24),
                _buildAppInfo(context),
                const SizedBox(height: 24),
                _buildActions(context, authProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    user,
    AuthProvider authProvider,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: Icon(
                user.isAdmin ? Icons.admin_panel_settings : Icons.visibility,
                size: 50,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.username,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: user.isAdmin ? Colors.red.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: user.isAdmin
                      ? Colors.red.shade200
                      : Colors.blue.shade200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    user.isAdmin
                        ? Icons.admin_panel_settings
                        : Icons.visibility,
                    size: 16,
                    color: user.isAdmin
                        ? Colors.red.shade600
                        : Colors.blue.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user.isAdmin ? 'Administrador' : 'Visualizador',
                    style: TextStyle(
                      color: user.isAdmin
                          ? Colors.red.shade600
                          : Colors.blue.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Información Personal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('ID de Usuario', user.id.toString(), Icons.tag),
            _buildInfoRow(
              'Nombre de Usuario',
              user.username,
              Icons.account_circle,
            ),
            _buildInfoRow('Rol del Sistema', user.role, Icons.security),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissions(BuildContext context, user) {
    final permissions = user.isAdmin
        ? [
            'Ver todos los productos',
            'Crear nuevos productos',
            'Editar productos existentes',
            'Eliminar productos',
            'Acceso a estadísticas completas',
            'Gestión completa del inventario',
          ]
        : [
            'Ver todos los productos',
            'Buscar y filtrar productos',
            'Ver detalles de productos',
            'Acceso a estadísticas básicas',
          ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Permisos y Accesos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...permissions.map(
              (permission) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        permission,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Información de la Aplicación',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow(
              'Aplicación',
              'Sistema de Inventario',
              Icons.inventory_2,
            ),
            _buildInfoRow('Versión', '1.0.0', Icons.info),
            _buildInfoRow('Plataforma', 'Flutter', Icons.phone_android),
            _buildInfoRow(
              'Estado',
              'Conectado',
              Icons.cloud_done,
              valueColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, AuthProvider authProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Acciones',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),

            // Refrescar información
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.blue),
              title: const Text('Actualizar Información'),
              subtitle: const Text('Sincronizar datos con el servidor'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                await authProvider.checkAuthStatus();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Información actualizada'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),

            const Divider(height: 1),

            // Cambiar contraseña (placeholder)
            ListTile(
              leading: const Icon(Icons.lock_outline, color: Colors.orange),
              title: const Text('Cambiar Contraseña'),
              subtitle: const Text('Actualizar tu contraseña de acceso'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Funcionalidad no disponible en esta versión',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),

            const Divider(height: 1),

            // Cerrar sesión
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar Sesión'),
              subtitle: const Text('Salir de la aplicación'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showLogoutDialog(context, authProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Cerrar Sesión'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que quieres cerrar sesión?\n\nTendrás que volver a iniciar sesión para acceder a la aplicación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await authProvider.logout();
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }
}
