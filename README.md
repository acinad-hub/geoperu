# Datos geográficos para Perú

Este repositorio contiene datos geográficos de Perú, incluyendo límites departamentales, provincias y distritos.

## Contenido

-   `data/departamentos.geojson`: Límites de los departamentos de Perú.

## Uso en QGIS con URL

Para utilizar estos datos en QGIS, sigue estos pasos: 

1. Abre QGIS 
2. Ve a `Capa` \> `Añadir capa` \> `Añadir capa vectorial...` 
3. En **Tipo de fuente** selecciona `Protocolo: HTTP(S), cloud, etc.`.
4. En **URI** ingresa la siguiente RAW del geojson que quieres cargar:
   ```
   Ejemplo:
   https://raw.githubusercontent.com/acinad-hub/geoperu/data/departamentos.geojson
   ```
5. Haz clic en `Añadir` y luego en `Cerrar`.

## Fuentes de datos: datosabiertos.gob.pe

-   [Límites departamentales](https://datosabiertos.gob.pe/dataset/limites-departamentales)
-   [Límites provinciales](https://datosabiertos.gob.pe/dataset/resource/ac9bc756-e41f-4c08-b4a3-a168a8874e9)
-   [Límites distritales](https://datosabiertos.gob.pe/dataset/limites-departamentale)
