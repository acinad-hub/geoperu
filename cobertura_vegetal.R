library(sf)
library(future.apply)
library(googledrive)
library(httr)
library(future.apply)

# %% 1. ENTRADAS --------------------------------------------------------------#

URL_COBVEG = "http://geoservidor.minam.gob.pe/wp-content/uploads/2017/06/mapa_cobertura_vegetal_2015.zip"
URL_COBVEG2 = "0By1rYqKYtPp5RUZpdHo4OHNvQkE"
URL_DEPART = "https://raw.githubusercontent.com/acinad-hub/geoperu/refs/heads/main/data/departamentos.geojson"
DLT_COBVEG = "data/cobveg_descrip.csv"

# %% 2. DESCARGA --------------------------------------------------------------#

# Crear carpeta temporal si no existe
td = tempdir()
zip_file <- file.path(td, "mapa_cobertura_vegetal_2015.zip")

# Descargar archivos ZIP
if (!file.exists(zip_file)) {
  if (status_code(HEAD(URL_COBVEG)) == 200) {
    download.file(URL_COBVEG, zip_file, mode = "wb")
  } else {
    drive_deauth()
    public_file <- drive_get(as_id(URL_COBVEG2))
    drive_download(public_file, path=zip_file, overwrite = TRUE)
  }
}

# Descomprimir archivos ZIP
unzip(zip_file, exdir = td)

# %% 3. CARGAR DATOS ----------------------------------------------------------#

shp_files <- list.files(td, pattern = "\\.shp$", full.names = TRUE, recursive = TRUE)
if (length(shp_files) == 0) {
  stop("No se encontraron archivos .shp en el directorio temporal.")
} else if (length(shp_files) > 1) {
  warning("Se encontraron múltiples archivos .shp. Se utilizará el primero encontrado.")
  shp_files <- shp_files[1]
}

cobertura_vegetal <- st_read(shp_files)
cobertura_descrip <- read.csv(DLT_COBVEG)

# %% 4. PROCESAMIENTO ---------------------------------------------------------#

## -- Convertir covertura a EPSG:4326 (World Geodetic System 1984 ensemble)
cobertura_vegetal <- st_transform(cobertura_vegetal, 4326)

## -- Revisar geometrías inválidas
invalid <- st_is_valid(cobertura_vegetal, reason = TRUE)
View(as.data.frame(table(invalid)))

## -- Corrección de solo las geometrías inválidas
invalid_idx <- which(!st_is_valid(cobertura_vegetal))
geoms_invalid <- st_geometry(cobertura_vegetal)[invalid_idx]

# -- Corregir geometrías inválidas en paralelo
n <- 4
plan(multisession, workers = n)
geoms_list <- lapply(seq_along(geoms_invalid), function(i) geoms_invalid[i])
geoms_fixed <- future_lapply(geoms_list, function(g) st_make_valid(g), 
                             future.seed = TRUE)
geoms_fixed <- do.call(c, geoms_fixed)

# Revisar si aún quedan geometrías inválidas
table(st_is_valid(geoms_fixed))

## -- Reemplazar las geometrías corregidas en el sf original
geoms <- st_geometry(cobertura_vegetal)
geoms[invalid_idx] <- geoms_fixed
cobveg_valid <- st_set_geometry(cobertura_vegetal, geoms)

## -- Cast MUlTIPOLYGON a POLYGON
cobveg_valid <- st_cast(cobveg_valid, "POLYGON")

## Verificar que todas las geometrías sean válidas
table(st_is_valid(cobveg_valid))

## Verificar que todas las geometrías sean de tipo POLYGON
table(st_geometry_type(cobveg_valid))

# %% 3. GUARDAR DATOS ---------------------------------------------------------#

## Select relevant columns
cobveg_last <- cobveg_valid |> 
  dplyr::select(code = Simbolo, geometry)

sqlite_file <- file.path(td, "cobveg_minam.sqlite")
st_write(cobveg_last, sqlite_file, layer = "cobveg",
         driver = "SQLite", delete_layer = TRUE, dataset_options = "SPATIALITE=YES")
st_write(cobertura_descrip, sqlite_file, layer = "cobveg_descrip",
         driver = "SQLite", delete_layer = TRUE)

# Crear zip del archivo SQLite
old_wd <- getwd()
setwd(td)
tar("cobveg_minam_2015.tar.gz", files = "cobveg_minam.sqlite",
    compression = "gzip", compression_level = 9)
#zip(zipfile = "cobertura_vegetal_minam.zip", files = "cobveg_minam.sqlite")
setwd(old_wd)
#file.copy(file.path(td, "cobertura_vegetal_minam.zip"), 
#          "data/cobertura_vegetal_minam.zip", overwrite = TRUE)
file.copy(file.path(td, "cobveg_minam_2015.tar.gz"), 
          "data/cobveg_minam_2015.tar.gz", overwrite = TRUE)
