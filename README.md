# TecnoAgro - Backend

Plataforma de e-commerce y gestión de inventario agrícola. Permite a los usuarios explorar productos, gestionar pedidos, recibir recomendaciones de tratamiento para enfermedades de cultivos, y consultar un asistente de IA especializado en el dominio agrícola.

## 🛠️ Stack tecnológico

- **Runtime:** Node.js v24+ (ESM - `import`/`export`)
- **Framework:** Express.js
- **Base de datos:** Supabase (PostgreSQL), acceso vía `@supabase/supabase-js` con clave `anon`
- **Autenticación:** JWT propio (no Supabase Auth) + bcrypt para hash de contraseñas
- **Almacenamiento de imágenes:** Cloudinary (vía Multer)
- **Asistente de IA:** Google Gemini (API de Google AI Studio, capa gratuita)
- **Testing de endpoints:** Postman

## 📁 Estructura del proyecto

```
backend/
├── config/
│   ├── supabase.js         # Cliente de conexión a Supabase
│   └── cloudinary.js       # Configuración de Multer + Cloudinary
├── controllers/
│   ├── auth.js             # Registro / login
│   ├── recuperar.js        # Recuperación de contraseña
│   ├── user.js             # CRUD de usuarios
│   ├── productoControllers.js
│   ├── pedido.js
│   └── chat.js             # Asistente de IA (Gemini)
├── models/
│   ├── user.js
│   ├── recuperar.js
│   ├── productoModel.js
│   ├── pedidoModel.js
│   └── enfermedadModel.js
├── middleware/
│   └── authMiddleware.js   # verificarToken / verificarAdmin
├── routes/
│   ├── auth.js
│   ├── user.js
│   ├── producto.js
│   ├── pedido.js
│   └── chat.js
├── utils/
│   └── sendEmail.js        # Envío de correos (confirmación de pedidos, recuperación)
└── index.js                # Registro de rutas + manejador global de errores
```

## 🗄️ Convención de nombres

Todas las tablas y columnas de la base de datos están nombradas **en español** (`usuarios`, `productos`, `enfermedades`, `pedidos`, `detalle_pedidos`, `recovery_codes`, `enfermedad_producto`, etc.). El código sigue la misma convención para mantener consistencia entre modelo, controlador y base de datos.

## 🔑 Variables de entorno

Crea un archivo `.env` en la raíz del backend con:

```env
PORT=3000
SUPABASE_URL=tu_url_de_supabase
SUPABASE_KEY=tu_clave_anon_de_supabase
JWT_SECRET=tu_secreto_jwt
CLOUDINARY_CLOUD_NAME=tu_cloud_name
CLOUDINARY_API_KEY=tu_api_key
CLOUDINARY_API_SECRET=tu_api_secret
GEMINI_API_KEY=tu_api_key_de_google_ai_studio
EMAIL_USER=tu_correo
EMAIL_PASS=tu_password_de_aplicacion
```

## 🚀 Instalación y ejecución

```bash
# Instalar dependencias
npm install

# Ejecutar en modo desarrollo (con nodemon)
npm run dev

# Ejecutar en producción
npm start
```

## 📡 Endpoints disponibles

### Autenticación (`/api/auth`)
| Método | Ruta | Descripción |
|---|---|---|
| POST | `/register` | Registro de usuario |
| POST | `/login` | Inicio de sesión (retorna JWT) |
| POST | `/forgot-password` | Solicita código de recuperación por correo |
| POST | `/verify-code` | Verifica el código y actualiza la contraseña |

### Usuarios (`/api/usuarios`)
| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| GET | `/` | Admin | Lista todos los usuarios |
| GET | `/:id` | Token | Obtiene un usuario por ID |
| PUT | `/:id` | Token | Actualiza datos del usuario (no permite cambiar rol/contraseña) |
| DELETE | `/:id` | Admin | Elimina un usuario |

### Productos (`/api/productos`)
| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| GET | `/` | Pública | Lista todos los productos |
| GET | `/:id` | Pública | Obtiene un producto por ID |
| GET | `/categoria/:categoria` | Pública | Filtra productos por categoría |
| POST | `/` | Admin | Crea un producto (con imagen vía Cloudinary) |
| PUT | `/:id` | Admin | Actualiza un producto |
| DELETE | `/:id` | Admin | Elimina un producto |

### Pedidos (`/api`)
| Método | Ruta | Descripción |
|---|---|---|
| POST | `/pedidos` | Crea un pedido con sus detalles y envía correo de confirmación |
| GET | `/mis-pedidos?usuario_id=` | Lista los pedidos de un usuario |
| GET | `/pedidos/:id` | Obtiene un pedido con sus detalles y productos |

### Asistente de IA (`/api/chat`)
| Método | Ruta | Descripción |
|---|---|---|
| POST | `/mensaje` | Envía un mensaje al asistente (Google Gemini) y recibe respuesta |

## 🧩 Módulos funcionales

- ✅ **Autenticación** — registro, login, recuperación de contraseña
- ✅ **Productos** — CRUD completo con subida de imágenes a Cloudinary
- ✅ **Enfermedades** — modelo de relación muchos-a-muchos con productos (`enfermedad_producto`) para recomendaciones de tratamiento
- ✅ **Pedidos** — creación de pedidos con detalle y notificación por correo
- ✅ **Chat IA** — integración con Gemini para consultas del usuario

## 📝 Notas técnicas importantes

- El proyecto usa autenticación JWT propia (no Supabase Auth), por lo que la conexión a Supabase se hace con la clave `anon`, no `service_role`.
- Las políticas RLS de las tablas relacionadas con el chat usan el rol `anon` de forma permisiva, ya que la autenticación real la maneja la capa de aplicación (JWT), no Supabase Auth.
- La tabla `usuarios` usa `id` tipo `bigint` (no `uuid`), por lo que cualquier tabla relacionada (como `conversations`) debe respetar ese tipo.
- Existe un manejador de errores global en `index.js` que expone los errores capturados en las rutas.

## 👥 Colaboración

Proyecto desarrollado de forma colaborativa vía Git/GitHub. Antes de actualizar rutas de importación tras un merge, verificar los nombres reales de los archivos en el sistema de archivos.

Juantorresgonzalez5931@gmail.com
Juancarlosriveratorrez18@gmail.com

