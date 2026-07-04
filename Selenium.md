# Pruebas Selenium para Habitum

Esta documentación describe todos los pasos necesarios para instalar las dependencias, configurar el entorno y ejecutar pruebas de sistema con Selenium en el proyecto `habitum_v2_final`.

---

## 1. Requisitos previos

- Python 3.13 o superior.
- Django 4.2 o superior (ya está en `requirements.txt`).
- Google Chrome instalado en el equipo.
- Un entorno virtual recomendado para aislar dependencias.

> El proyecto ya contiene carpetas `venv/` y `.venv/`. Si quieres usar uno de esos entornos, actívalo antes de instalar paquetes.

---

## 2. Activar el entorno virtual (opcional pero recomendado)

Desde PowerShell, si usas `venv`:

```powershell
cd C:\Users\JorgeCubes\Downloads\habitum_v2_final
.\venv\Scripts\Activate.ps1
```

Si usas `.venv`:

```powershell
cd C:\Users\JorgeCubes\Downloads\habitum_v2_final
.\.venv\Scripts\Activate.ps1
```

Si no usas entorno virtual, puedes continuar con Python del sistema.

---

## 3. Instalar dependencias

El proyecto ya incluye los paquetes en `requirements.txt`:

```text
Django>=4.2
Pillow
selenium
webdriver-manager
```

Instala todo con:

```powershell
python -m pip install -r requirements.txt
```

O instala directamente las dependencias de Selenium:

```powershell
python -m pip install selenium webdriver-manager
```

---

## 4. Configurar el navegador y el driver

Este proyecto usa `webdriver-manager` para descargar automáticamente un ChromeDriver compatible con Google Chrome.

No es necesario descargar manualmente el driver si el script de prueba utiliza `ChromeDriverManager()`.

---

## 5. Ubicación del archivo de prueba Selenium

El test se encuentra en:

- `habits/tests_selenium.py`

Ese archivo contiene un caso de prueba basado en:

- `django.contrib.staticfiles.testing.StaticLiveServerTestCase`
- Selenium WebDriver para Chrome en modo headless
- Autenticación de usuario y verificación del flujo de login

---

## 6. Estructura del test

El test realiza los siguientes pasos:

1. Inicia un servidor de pruebas Django con `StaticLiveServerTestCase`.
2. Instala y configura un `webdriver.Chrome` con opciones headless.
3. Crea un usuario de prueba en la base de datos.
4. Abre la URL de login usando el servidor de pruebas.
5. Rellena los campos `username` y `password`.
6. Envía el formulario de login.
7. Comprueba que la URL resultante contiene `dashboard`.

---

## 7. Ejecutar las pruebas

Para ejecutar solo el test Selenium:

```powershell
python manage.py test habits.tests_selenium
```

Para ejecutar todas las pruebas de la aplicación `habits`:

```powershell
python manage.py test habits
```

---

## 8. Consideraciones importantes

- Si el test falla porque no encuentra Chrome, asegúrate de que Chrome esté instalado y disponible en el PATH.
- Si prefieres ver el navegador mientras se ejecuta, quita o cambia la línea:

```python
options.add_argument("--headless=new")
```

- Si necesitas ejecutar pruebas en otro navegador, debes cambiar la configuración del WebDriver y el driver correspondiente.

---

## 9. Personalización y extensiones

Puedes agregar más pruebas de Selenium dentro de `habits/tests_selenium.py` para cubrir:

- Registro de usuario
- Creación de hábito
- Marcar hábito como completado
- Navegación al historial
- Edición de perfil
- Flujo de administración de catálogo

Cada caso debe usar `self.driver.get(...)`, encontrar elementos con `By.NAME`, `By.ID`, `By.CSS_SELECTOR`, rellenar formularios y validar el resultado.

---

## 10. Ejemplo de comando completo

```powershell
cd C:\Users\JorgeCubes\Downloads\habitum_v2_final
.\venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python manage.py test habits.tests_selenium
```

---

## 11. Archivos clave

- `requirements.txt`
- `habits/tests_selenium.py`
- `manage.py`
- `habitum/settings.py` (configuración Django)

---

## 12. Resultado esperado

Al ejecutar el test, Django levantará un servidor temporal, Selenium abrirá un navegador headless, completará el login y se cerrará automáticamente.

Si todo es correcto, el resultado debe ser un `OK` o `Ran 1 test` sin errores.