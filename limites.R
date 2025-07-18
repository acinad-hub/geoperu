library(sf)

#------------------------------------------------------------------------------#
# 1. ENTRADAS                                                               ####
#------------------------------------------------------------------------------#

URL_GLB = "https://public.opendatasoft.com/api/explore/v2.1/catalog/datasets/country_shapes/exports/geojson?lang=en&timezone=America%2FBogota"
URL_DEP = "https://datosabiertos.gob.pe/sites/default/files/DEPARTAMENTOS_LIMITES.zip"
URL_PRO = "https://datosabiertos.gob.pe/sites/default/files/PROVINCIALES_LIMITES.zip"
URL_DIS = "https://datosabiertos.gob.pe/sites/default/files/DISTRITOS_LIMITES.zip"

#------------------------------------------------------------------------------#
# 2. DESCARGA                                                               ####
#------------------------------------------------------------------------------#

# Crear carpeta temporal si no existe
if (!dir.exists("temp")) {
  dir.create("temp")
}

# Descargar archivos ZIP
download.file(URL_DEP, "temp/DEPARTAMENTOS_LIMITES.zip", mode = "wb")
download.file(URL_PRO, "temp/PROVINCIALES_LIMITES.zip", mode = "wb")
download.file(URL_DIS, "temp/DISTRITOS_LIMITES.zip", mode = "wb")
download.file(URL_GLB, "data/paises.geojson", mode = "wb")

# Descomprimir archivos ZIP
unzip("temp/DEPARTAMENTOS_LIMITES.zip", exdir = "temp")
unzip("temp/PROVINCIALES_LIMITES.zip", exdir = "temp")
unzip("temp/DISTRITOS_LIMITES.zip", exdir = "temp")

#------------------------------------------------------------------------------#
# 3. PROCESAMIENTO                                                          ####
#------------------------------------------------------------------------------#

# Leer archivos shapefile
departamentos <- st_read("temp/DEPARTAMENTOS.shp")
provincias <- st_read("temp/PROVINCIAS.shp")
distritos <- st_read("temp/DISTRITOS.shp")

# Separar provincias por departamento
provincias_lst <- split(provincias, provincias$DEPARTAMEN)
nombre_departamentos <- names(provincias_lst) |>
  (\(x) gsub(" ", "_", tolower(x)))()

# Separar distritos por departamento y por provincia
distritos_lst <- split(distritos, distritos$DEPARTAMEN) |> 
  lapply(\(x) split(x, x$PROVINCIA))

#------------------------------------------------------------------------------#
# 4. EXPORTRA                                                               ####
#------------------------------------------------------------------------------#

# Crear carpeta de departamentos si no existe
for (nombre in nombre_departamentos) {
  dir <- paste0("data/", tolower(nombre))
  if (!dir.exists(dir)) {
    dir.create(dir)
  }
}

# Exportar departamentos
st_write(departamentos, "data/departamentos.geojson", delete_dsn = TRUE)

# Exportar provincias
mapply(function(sf, nombre) {
  fichero <- paste0("data/", nombre, "/prov_de_", nombre, ".geojson")
  st_write(sf, fichero, delete_dsn = TRUE)
  # Retorno invisible
  return(invisible())
}, sf = provincias_lst, nombre = nombre_departamentos)

# Exportar distritos
mapply(function(sf_lst, nombre_dep) {
  mapply(function(sf, nombre) {
    nombre_prov = gsub(" ", "_", tolower(nombre))
    fichero <- paste0("data/", nombre_dep, "/dist_de_", nombre_prov, ".geojson")
    st_write(sf, fichero, delete_dsn = TRUE)
    return(invisible())
  }, sf = sf_lst, nombre = names(sf_lst))
  return(invisible())
}, sf_lst = distritos_lst, nombre_dep = nombre_departamentos)

st_write(distritos, "data/distritos.geojson", delete_dsn = TRUE)
