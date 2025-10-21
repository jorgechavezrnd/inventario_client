# 📱 Sistema de Inventario - Cliente Flutter

Una aplicación Flutter completa con autenticación JWT y control de acceso basado en roles (RBAC).

## ⚡ Inicio Rápido (5 minutos)

### 1. Verificar Prerrequisitos
```bash
flutter doctor
```

### 2. Instalar y Ejecutar
```bash
flutter pub get
flutter pub run build_runner build
flutter run
```

### 3. Credenciales de Prueba
| Rol | Usuario | Contraseña | Permisos |
|-----|---------|------------|----------|
| Admin | `admin` | `admin123` | CRUD completo |
| Viewer | `viewer` | `viewer123` | Solo lectura |

### 4. Backend Esperado
```
URL Base: http://localhost:3000
Endpoints: /auth/login, /auth/refresh, /products
```

## 🏗️ Arquitectura

```
lib/
├── main.dart                    # Configuración de la app
├── models/                      # User, Product, AuthResponse
├── services/                    # API, Auth, Product services
├── providers/                   # Estado con Provider pattern
├── screens/                     # Login, Home, Products, Profile
└── widgets/                     # Componentes reutilizables
```

## 🔐 Autenticación & Seguridad

### JWT con Auto-Refresh
- **Access Token**: 15 min → **Refresh Token**: 7 días
- **Almacenamiento**: `flutter_secure_storage` (cifrado hardware)
- **Auto-renovación**: Interceptor HTTP transparente
- **Logout automático**: En caso de tokens expirados

### Control de Acceso por Roles
- **👑 Admin**: CRUD completo + estadísticas avanzadas
- **👁️ Viewer**: Solo lectura + estadísticas básicas

## 🚀 Funcionalidades

### 🏠 Dashboard
- Saludo personalizado + estadísticas tiempo real
- Acciones rápidas según rol de usuario

### 📦 Productos
- Búsqueda en tiempo real + filtros de stock
- Vista lista/cuadrícula + pull-to-refresh
- Cache local para funcionamiento offline

## �️ Comandos Útiles

### Desarrollo
```bash
flutter run                      # Ejecutar con hot reload
flutter run -d <device-id>       # Dispositivo específico
flutter devices                  # Listar dispositivos
```

### Mantenimiento
```bash
flutter clean && flutter pub get             # Limpiar cache
flutter pub run build_runner build          # Regenerar código
flutter doctor                               # Verificar setup
```

### Build Production
```bash
flutter build apk --release                 # Android APK
flutter build appbundle --release           # Android Bundle
flutter build ios --release                 # iOS (solo macOS)
```

## � Tecnologías

### Stack Principal
- **Flutter 3.9.2+** con Dart
- **Dio 5.3.2** - Cliente HTTP + interceptores JWT
- **Provider 6.1.1** - Gestión de estado
- **flutter_secure_storage 9.0+** - Almacenamiento cifrado
- **json_serializable** - Serialización automática

## 🔒 Controles de Seguridad

### Almacenamiento Seguro
- Tokens cifrados con Android Keystore/iOS Keychain
- Limpieza automática en logout
- Validación de expiración pre-uso

### Interceptores HTTP
- Inyección automática de Bearer tokens
- Renovación transparente de tokens expirados
- Logout automático en fallos de autenticación

### UI Basada en Roles
- Widgets condicionales según permisos
- Ocultación de funcionalidades no permitidas
- Sincronización cliente-servidor de roles

## 🔍 Solución de Problemas

### Error de Compilación
```bash
flutter clean && flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build
```

### Error de Conexión Backend
- Verificar servidor en `localhost:3000`
- Para emulador Android usar `10.0.2.2:3000`
- Para dispositivo físico usar IP real de la máquina

### Indicadores de Stock
- 🟢 **Verde**: Stock normal (>5 unidades)
- 🟠 **Naranja**: Stock bajo (1-5 unidades)  
- 🔴 **Rojo**: Sin stock (0 unidades)

---

**Desarrollado con fines educativos - Maestría en Desarrollo Full Stack
