☕ CoffeeNow - App de Gestión de Cafetería

Aplicación completa de gestión de pedidos para una cafetería desarrollada en Flutter y Firebase.

El proyecto incluye una arquitectura escalable, gestión de roles (Admin/Cliente), persistencia de datos, geolocalización y sistemas de fidelización (Gamificación).

✨ Características Principales

👤 Gestión de Usuarios y Roles

Login/Registro: Autenticación mediante Email/Contraseña y Google Sign-In.

Roles: Sistema de roles (Admin vs Usuario) almacenado en Firestore.

Perfil: Edición de foto de perfil con persistencia.

🛍️ Catálogo y Compras

Catálogo Dinámico: Lista de productos en tiempo real desde Firestore.

Filtros Avanzados: Búsqueda por nombre, filtrado por rango de precio y ordenación (A-Z, Precio).

Control de Stock: Validación de inventario en tiempo real. Los productos agotados no se pueden comprar.

Carrito Persistente: El carrito se guarda en el dispositivo (SharedPreferences), no se pierde al cerrar la app.

🚚 Pedidos y Pagos (Checkout)

Geolocalización: Selección de dirección de entrega mediante mapa interactivo (OpenStreetMap) y conversión a dirección real (Geocoding).

Transacciones Seguras: El stock se descuenta atómicamente al confirmar el pedido para evitar errores de concurrencia.

Generación de Recibos: Descarga automática de PDF con el resumen del pedido desde el historial.

⭐ Fidelización y Extras (Gamificación)

Ruleta de Premios: Juego diario (límite de 24h) para ganar descuentos o productos gratis.

Sistema de Cupones:

Cupones globales creados por el Admin (ej: BIENVENIDO10).

Cupones personales ganados en la ruleta.

Validación de un solo uso por usuario.

Reseñas y Valoraciones: Los usuarios pueden valorar (1-5 estrellas) los productos de pedidos entregados.

💬 Soporte

Chat en Tiempo Real: Canal de comunicación directo entre Cliente y Admin integrado en la app.

🛠️ Panel de Administración

Dashboard: Vista general con estadísticas de ingresos y actividad.

Gestión Total: CRUD de Productos (con imagen y stock), Usuarios y Cupones.

Gestión de Pedidos: Cambio de estados (Pendiente -> En Preparación -> Listo -> Entregado).

📱 Tecnologías y Paquetes

El proyecto está construido con Flutter (Dart) y utiliza los siguientes paquetes clave:

Core & UI: provider (Gestión de estado), flutter_rating_bar, google_fonts.

Firebase: firebase_core, firebase_auth, cloud_firestore.

Utilidades: shared_preferences (Persistencia local), rxdart.

Mapas: flutter_map, latlong2, geocoding.

Archivos: pdf (Generación), universal_html (Descarga web).

Extras: flutter_fortune_wheel (Ruleta).

🚀 Instalación y Configuración

Requisitos

Flutter SDK (>=3.0.0)

Cuenta de Firebase configurada.

(Opcional) API Key de Google Maps para mejorar el Geocoding en Android.

Pasos

Clonar el repositorio:

git clone [https://github.com/JohaanGV07/PI2DAM]


Instalar dependencias:

flutter pub get


Configuración de Firebase:

Asegúrate de tener el archivo google-services.json (Android) o firebase_options.dart (Web/General) configurado.

Habilitar Authentication (Email y Google).

Habilitar Firestore Database.

Reglas de Firestore:
Copia las reglas de seguridad proporcionadas en firestore.rules para asegurar el funcionamiento de subcolecciones (reviews, my_prizes, chat).

Índices:
Es necesario crear índices compuestos en Firestore para:

orders: Ordenar por fecha y filtrar por usuario.

my_prizes (Collection Group): Ordenar premios por fecha.

Ejecutar:

flutter run


📂 Estructura del Proyecto

lib/
├── core/               # Lógica de negocio pura
│   ├── models/         # Modelos de datos (User, Product, Order...)
│   ├── services/       # Comunicación con Firebase (Auth, Firestore, Chat...)
│   └── providers/      # Gestión de estado (CartProvider)
├── features/           # Módulos funcionales
│   ├── cart/           # Pantallas de Carrito y Checkout
│   ├── menu/           # Catálogo, Favoritos y Detalles
│   └── orders/         # Historial de Pedidos
├── shared/             # Widgets reutilizables (ProductCard, Dialogs...)
├── admin_*.dart        # Pantallas del Panel de Administración
├── home_page.dart      # Pantalla principal y navegación (Drawer)
└── main.dart           # Punto de entrada


👨‍💻 Autor

Desarrollado por [Tu Nombre] como Proyecto Intermodular.