library(sf)

#------------------------------------------------------------------------------#
# 1. ENTRADAS                                                               ####
#------------------------------------------------------------------------------#

URL_DEP = "https://datosabiertos.gob.pe/sites/default/files/DEPARTAMENTOS_LIMITES.zip"
URL_PRO = "https://datosabiertos.gob.pe/sites/default/files/PROVINCIALES_LIMITES.zip"
URL_DIS = "https://datosabiertos.gob.pe/sites/default/files/DISTRITOS_LIMITES.zip"

#------------------------------------------------------------------------------#
# 2. PROCESAMIENTO                                                          ####
#------------------------------------------------------------------------------#

# Crear carpeta temporal si no existe
if (!dir.exists("temp")) {
  dir.create("temp")
}

# Descargar archivos ZIP
download.file(URL_DEP, "temp/DEPARTAMENTOS_LIMITES.zip", mode = "wb")
download.file(URL_PRO, "temp/PROVINCIALES_LIMITES.zip", mode = "wb")
download.file(URL_DIS, "temp/DISTRITOS_LIMITES.zip", mode = "wb")

# Descomprimir archivos ZIP
unzip("temp/DEPARTAMENTOS_LIMITES.zip", exdir = "temp")
unzip("temp/PROVINCIALES_LIMITES.zip", exdir = "temp")
unzip("temp/DISTRITOS_LIMITES.zip", exdir = "temp")

# Leer archivos shapefile
departamentos <- st_read("temp/DEPARTAMENTOS.shp")
provincias <- st_read("temp/PROVINCIAS.shp")
distritos <- st_read("temp/DISTRITOS.shp")

# Exportar como geojsons
st_write(departamentos, "data/departamentos.geojson", delete_dsn = TRUE)
st_write(provincias, "data/provincias.geojson", delete_dsn = TRUE)
st_write(distritos, "data/distritos.geojson", delete_dsn = TRUE)
