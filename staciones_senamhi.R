library(rvest)
library(stringr)
library(jsonlite)
library(sf)

URL = "https://www.senamhi.gob.pe/mapas/mapa-estaciones-2/"
STN_JSON = "data/estaciones_senamhi.geojson"

# - Leer el sitio web
pagina <- read_html(URL)

# - Extraer la tabla de estaciones
scripts <- page %>% html_elements("script") %>% html_text()
target <- scripts[str_detect(scripts, "var PruebaTest")]

# - Extraer solo la parte del JSON
json_txt <- str_match(target, "(?s)var PruebaTest = (\\[.*?\\]);")[,2]

# - Corrige los números mal formateados y carateres extra
json_txt_fixed <- gsub(": -\\.", ": -0.", json_txt) |> 
  (\(x) gsub(",\\s*]", "]", x))() 
estaciones_senamhi_df <- jsonlite::fromJSON(json_txt_fixed)

# - Nombre de columnas y convertir a sf
estaciones_senamhi_sf <- estaciones_senamhi_df |>
  dplyr::rename(nombre=nom, categoria=cate, codigo=cod, codigo_old = cod_old) |>
  st_as_sf(coords = c("lon", "lat"), crs = 4326)

st_write(estaciones_senamhi_sf, STN_JSON, delete_dsn = TRUE)
