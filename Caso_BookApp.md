# Caso: BookApp

Un equipo especializado en contenidos digitales ha decidido lanzar **BookApp**, una aplicación móvil orientada a la exploración de un catálogo de libros y a la gestión de una biblioteca personal de lectura, que incluye libros favoritos y una lista de lectura creada por el usuario.

La aplicación busca ofrecer una experiencia intuitiva y práctica, donde los usuarios puedan:
*   Explorar libros disponibles en el catálogo.
*   Consultar información relevante de cada libro.
*   Organizar sus libros preferidos mediante un sistema de favoritos, almacenado localmente.
*   Gestionar una lista de libros para leer, donde el usuario puede agregar o quitar libros, gestionada en línea.

---

## 🔗 Documentación de la API
La documentación detallada de los endpoints se encuentra disponible en el siguiente enlace:
*   **Swagger / API Docs:** [https://bookapp-gveteaa0dqf0eycn.eastus-01.azurewebsites.net/api-docs](https://bookapp-gveteaa0dqf0eycn.eastus-01.azurewebsites.net/api-docs)

---

## 📱 Funcionalidades Principales

### 1. Login
*   Pantalla inicial para ingresar **correo** y **contraseña**.
*   Si el inicio de sesión es exitoso, permite acceder a la pantalla de **Home**.

### 2. Home
Pantalla principal de la aplicación que debe contar con un sistema de navegación de **tres pestañas (tabs)**:
*   **Libros:** Lista todos los libros disponibles en el catálogo general.
*   **Favoritos:** Muestra los libros que el usuario ha marcado como favoritos (almacenados localmente).
*   **Lista de lectura:** Muestra los libros que el usuario ha agregado a su lista de lectura personal (gestionada en línea).

### 3. Libros (Catálogo)
Pestaña que muestra el listado de libros obtenidos desde el endpoint correspondiente.
*   **Información a mostrar por libro:**
    *   Portada
    *   Título
    *   Autor
    *   Género
    *   Calificación
*   **Interacción:** Al seleccionar un libro del listado, se debe navegar a su pantalla de **Detalle de libro**.

### 4. Detalle de Libro
Pantalla que presenta la ficha técnica completa del libro seleccionado.
*   **Datos del libro a mostrar:**
    *   Portada
    *   Título
    *   Autor
    *   Editorial
    *   Año de publicación
    *   Género
    *   Descripción
    *   Calificación
*   **Acciones disponibles:**
    *   Agregar o quitar el libro de **Favoritos** (Persistencia Local).
    *   Agregar o quitar el libro de la **Lista de lectura** (Persistencia remota/API).

### 5. Favoritos
Pestaña que lista los libros guardados localmente.
*   **Información a mostrar por libro:**
    *   Portada, título, autor, género y calificación.
*   **Acciones disponibles:**
    *   El usuario podrá eliminar o quitar libros marcados como favoritos directamente desde esta vista.

### 6. Lista de Lectura
Pestaña que muestra los libros que el usuario ha agregado a su lista de lectura en línea.
*   **Información a mostrar por libro:**
    *   Portada
    *   Título
    *   Autor
    *   Género
    *   Calificación
    *   Fecha en la que el libro fue agregado a la lista.
*   **Acciones disponibles:**
    *   Retirar o quitar libros de la lista de lectura.

---

## 💾 Persistencia Local (Favoritos)
*   Los libros marcados como favoritos deben almacenarse localmente utilizando una base de datos local (por ejemplo, **SQLite** mediante el paquete `sqflite`, u otra dependencia equivalente como `drift` o `hive`).
*   Los datos deben conservarse intactos incluso al cerrar y volver a abrir la aplicación.

---

## 🔑 Reglas de Acceso (Usuario)
Cada alumno cuenta con credenciales previamente creadas y cargadas en el sistema:
*   **Usuario (correo):** Su correo institucional UPC (ej. `u202300999@upc.edu.pe`).
*   **Contraseña:** Generada automáticamente siguiendo la siguiente regla:
    *   *Primera letra del primer nombre + primer apellido*, todo en minúsculas, sin tildes ni la letra ñ.
    *   *Ejemplo ficticio:*
        *   **Alumno:** Valeria Sofía Mendoza Torres
        *   **Correo:** `u202300999@upc.edu.pe`
        *   **Contraseña:** `vmendoza`

---

## 💡 Recomendaciones para el Examen
1.  **Probar antes de integrar:** Usa Postman, Thunder Client o Swagger para verificar el comportamiento de los endpoints antes de implementar la lógica de integración en Flutter.
2.  **Manejo de Errores:** Muestra mensajes claros, amigables e intuitivos en caso de fallos (por ejemplo, "Credenciales inválidas" durante el Login, o fallos de conexión a internet).
3.  **Preparación de la entrega:** Realiza pruebas completas de flujo antes de empaquetar el proyecto. No olvides ejecutar el comando `flutter clean` en la terminal antes de generar el archivo comprimido `.zip` final para evitar incluir archivos de caché pesados.

---

## 📐 Consideraciones de Evaluación (Criterios de Rúbrica)
Durante la revisión se evaluará estrictamente:
*   **Estado ejecutable:** La aplicación debe compilar y ejecutarse correctamente sin errores fatales.
*   **Funcionalidad:** Cumplimiento total de todas las características solicitadas en el caso.
*   **Estándares de código:** Uso de estándares de nomenclatura e identificadores en **inglés** (*naming conventions*).
*   **Interfaz de Usuario (UI):** Diseño moderno basado en los principios de **Material Design 3**.
*   **Calidad del código:** Claridad, modularidad y eficiencia en la lógica implementada.
*   **Arquitectura:** Correcta organización de las clases y estructuración limpia en paquetes/carpetas.
*   **Gestión de Estado:** Es de uso obligatorio **BLOC** (paquete `flutter_bloc`) para el manejo de los estados de la aplicación.
