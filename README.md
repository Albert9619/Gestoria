# Gestoría 🎱

**SaaS móvil para la gestión operativa de billares, bares, tabernas y negocios de entretenimiento.**

Gestoría digitaliza y centraliza la administración de tu negocio en tiempo real: mesas, clientes, ventas, inventario, turnos de meseras y reportes, todo desde el celular.

---

## ¿Qué hace la app?

### Para el Administrador
- **Dashboard** — Ventas del día, mesas ocupadas/libres y turnos activos en tiempo real
- **Mesas** — Grid visual con estado en vivo (verde = libre, ámbar = ocupada), tiempo de uso y cliente asignado
- **Inventario** — Gestión de productos físicos y servicios con barras de progreso de stock (verde / ámbar / rojo)
- **Caja** — Resumen financiero del día, gestión de turnos activos y cierre de turnos
- **Meseras** — Alta, edición y eliminación de meseras con credenciales
- **Reportes** — Estadísticas del turno con exportación a PDF
- **Stock** — Registro de entradas de mercancía

### Para la Mesera
- **Clientes** — Registro de clientes con asignación de mesa opcional
- **Cuenta del cliente** — Agregar múltiples productos de una vez con selector visual
- **Mi turno** — Resumen del turno activo

### Para el Superadmin (Gestoría)
- **Panel de control** — Lista de todos los negocios registrados
- **Suscripciones** — Extender (+30, +90, +180, +365 días) o bloquear negocios
- Control de acceso por vencimiento de suscripción

---

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| Frontend | Flutter 3.x |
| Backend | Firebase (Auth + Firestore) |
| Autenticación | Firebase Auth + REST API |
| Base de datos | Cloud Firestore (multi-tenant) |
| PDF | `pdf` + `printing` |
| Íconos | `flutter_launcher_icons` |

---

## Estructura del proyecto

```
lib/
├── core/
│   └── theme.dart           # Colores, espaciado, tipografía, radio
├── models/                  # Modelos de datos (Firestore)
├── services/                # Lógica de negocio y acceso a Firebase
├── screens/
│   ├── admin/               # Panel del administrador
│   │   └── tabs/            # Dashboard, Mesas, Productos, Caja, Stock, Reportes, Meseras
│   ├── mesera/              # App de la mesera
│   │   └── tabs/            # Clientes, Mi turno
│   ├── superadmin/          # Panel de Gestoría
│   └── auth/                # Login y registro
└── widgets/                 # Componentes reutilizables
    └── widgets.dart         # GradientFAB, AccentCard, FloatingNavBar, EmptyState...
```

---

## Roles de usuario

| Rol | Acceso |
|---|---|
| `superadmin` | Todos los negocios, suscripciones |
| `admin` | Su negocio completo |
| `mesera` | Clientes y su turno |

---

## Instalación

### Requisitos
- Flutter 3.x
- Dart 3.x
- Cuenta de Firebase con Firestore y Authentication habilitados

### Pasos

```bash
# 1. Clonar el repositorio
git clone https://github.com/Albert9619/Gestoria.git
cd gestoria

# 2. Instalar dependencias
flutter pub get

# 3. Configurar Firebase
# Reemplaza google-services.json (Android) y GoogleService-Info.plist (iOS)
# con los de tu proyecto Firebase

# 4. Correr la app
flutter run
```

---

## Modelo de datos (Firestore)

```
negocios/{negocioId}
  ├── clientes/{clienteId}
  │   └── consumos/{consumoId}
  ├── ventas/{ventaId}
  ├── productos/{productoId}
  ├── mesas/{mesaId}
  ├── turnos/{turnoId}
  ├── usuarios/{userId}
  └── entradas_stock/{entradaId}

usuarios/{userId}        # Perfil global + rol
codigos/{codigo}         # Lookup código → negocioId
```

---

## Seguridad

- Reglas de Firestore configuradas por rol (`firestore.rules`)
- Sin acceso externo: toda lectura/escritura requiere autenticación
- Admin solo accede a su negocio
- Mesera solo accede a los datos de su turno

---

## Suscripciones

Al registrarse, cada negocio recibe **15 días de prueba gratuita**.  
Si la suscripción vence, la app bloquea el acceso hasta que el superadmin extienda el plan.

---

## Colores de marca

| Color | Hex | Uso |
|---|---|---|
| Azul marino | `#1A3577` | Color primario, AppBar, botones |
| Verde | `#4DB848` | Éxito, mesas libres, stock alto |
| Ámbar | `#D97706` | Mesas ocupadas, stock bajo |
| Rojo | `#DC2626` | Errores, stock agotado |

---

*Desarrollado con Flutter + Firebase*
