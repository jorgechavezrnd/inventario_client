import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'role_based_widget.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showLogout;
  final bool showUserInfo;
  final VoidCallback? onLogout;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showLogout = true,
    this.showUserInfo = true,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      actions: [
        // Mostrar información del usuario
        if (showUserInfo)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Center(child: UserRoleBadge()),
          ),

        // Acciones personalizadas
        if (actions != null) ...actions!,

        // Botón de logout
        if (showLogout)
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle),
                onSelected: (value) async {
                  switch (value) {
                    case 'profile':
                      Navigator.pushNamed(context, '/profile');
                      break;
                    case 'logout':
                      await _handleLogout(context, authProvider);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.person),
                        const SizedBox(width: 8),
                        Text('Perfil'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        const Icon(Icons.logout, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Cerrar sesión',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Future<void> _handleLogout(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
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
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await authProvider.logout();

      if (onLogout != null) {
        onLogout!();
      } else {
        // Navegar al login y limpiar stack de navegación
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// AppBar específico para pantallas de administrador
class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const AdminAppBar({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return RoleBasedWidget(
      requiredRole: 'admin',
      child: CustomAppBar(title: title, actions: actions),
      fallback: CustomAppBar(title: title, actions: actions),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// AppBar con breadcrumb de navegación
class BreadcrumbAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<String> breadcrumbs;
  final VoidCallback? onBack;

  const BreadcrumbAppBar({super.key, required this.breadcrumbs, this.onBack});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          for (int i = 0; i < breadcrumbs.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Colors.white70,
                ),
              ),
            Text(
              breadcrumbs[i],
              style: TextStyle(
                fontSize: i == breadcrumbs.length - 1 ? 18 : 14,
                fontWeight: i == breadcrumbs.length - 1
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: i == breadcrumbs.length - 1
                    ? Colors.white
                    : Colors.white70,
              ),
            ),
          ],
        ],
      ),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      leading: onBack != null
          ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack)
          : null,
      actions: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Center(child: UserRoleBadge()),
        ),
        Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await authProvider.logout();
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              },
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
