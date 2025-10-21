import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RoleBasedWidget extends StatelessWidget {
  final String?
  requiredRole; // null = cualquier usuario autenticado, 'admin' = solo admin
  final Widget child;
  final Widget? fallback;
  final bool showForViewer; // si es true, muestra para viewer también

  const RoleBasedWidget({
    super.key,
    this.requiredRole,
    required this.child,
    this.fallback,
    this.showForViewer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Si no está autenticado, mostrar fallback o nada
        if (!authProvider.isAuthenticated) {
          return fallback ?? const SizedBox.shrink();
        }

        final user = authProvider.user;
        if (user == null) {
          return fallback ?? const SizedBox.shrink();
        }

        // Si no se requiere rol específico, mostrar para cualquier usuario autenticado
        if (requiredRole == null) {
          return child;
        }

        // Si se requiere admin
        if (requiredRole == 'admin') {
          if (user.isAdmin) {
            return child;
          } else {
            return fallback ?? const SizedBox.shrink();
          }
        }

        // Si se requiere viewer
        if (requiredRole == 'viewer') {
          if (user.isViewer || (showForViewer && user.isAdmin)) {
            return child;
          } else {
            return fallback ?? const SizedBox.shrink();
          }
        }

        // Si el rol coincide exactamente
        if (user.role == requiredRole) {
          return child;
        }

        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

/// Widget que muestra contenido diferente según el rol
class RoleConditionalWidget extends StatelessWidget {
  final Widget? adminWidget;
  final Widget? viewerWidget;
  final Widget? defaultWidget;

  const RoleConditionalWidget({
    super.key,
    this.adminWidget,
    this.viewerWidget,
    this.defaultWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (!authProvider.isAuthenticated || authProvider.user == null) {
          return defaultWidget ?? const SizedBox.shrink();
        }

        final user = authProvider.user!;

        if (user.isAdmin && adminWidget != null) {
          return adminWidget!;
        }

        if (user.isViewer && viewerWidget != null) {
          return viewerWidget!;
        }

        return defaultWidget ?? const SizedBox.shrink();
      },
    );
  }
}

/// Widget para mostrar el rol actual del usuario
class UserRoleBadge extends StatelessWidget {
  final EdgeInsets? padding;
  final bool showUsername;

  const UserRoleBadge({super.key, this.padding, this.showUsername = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (!authProvider.isAuthenticated || authProvider.user == null) {
          return const SizedBox.shrink();
        }

        final user = authProvider.user!;
        final theme = Theme.of(context);

        Color badgeColor;
        IconData icon;
        String roleText;

        if (user.isAdmin) {
          badgeColor = Colors.red.shade600;
          icon = Icons.admin_panel_settings;
          roleText = 'Administrador';
        } else {
          badgeColor = Colors.blue.shade600;
          icon = Icons.visibility;
          roleText = 'Visualizador';
        }

        return Container(
          padding:
              padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: badgeColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: badgeColor),
              const SizedBox(width: 4),
              Text(
                showUsername ? '${user.username} ($roleText)' : roleText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget que verifica permisos antes de mostrar acciones
class PermissionGate extends StatelessWidget {
  final String permission; // 'read', 'write', 'delete'
  final Widget child;
  final Widget? fallback;

  const PermissionGate({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (!authProvider.isAuthenticated || authProvider.user == null) {
          return fallback ?? const SizedBox.shrink();
        }

        final user = authProvider.user!;

        // Admin tiene todos los permisos
        if (user.isAdmin) {
          return child;
        }

        // Viewer solo tiene permiso de lectura
        if (user.isViewer && permission == 'read') {
          return child;
        }

        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}
