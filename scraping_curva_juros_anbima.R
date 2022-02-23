# Inspirado e adaptado por https://augustocl.github.io/AugustoLeal/post/2021-05-22-criando-bd-webscraping/
# Criando um arquivo .bat: https://www.softdownload.com.br/como-automatizar-execucao-de-programas.html

# Pacotes necessários
library(tidyverse)
library(httr)
library(bizdays)

# Nome do input
name_db <- paste0("hist_coef_pre_ipca_",Sys.Date(),".xlsx")

# Função de scraping
obter_param_ettj <- function(dt) {
  
  stopifnot(is(dt, "Date"), length(dt) == 1)
  
  url <- "https://www.anbima.com.br/informacoes/est-termo/CZ-down.asp"
  
  r <- httr::POST(
    url = url, 
    encode = c("multipart")
    )
  
  texto_puro <- base::rawToChar(content(r, as = "raw"))
  
  dados <- read_csv2(texto_puro, n_max = 15) %>%
    dplyr::slice(4:15)
  
  dados <- dados[, 1:4]
  # Extrai a data que as informações foram extraídas
  data_new <- colnames(dados)[1]
  
  dados <- dados %>% dplyr::select(data_new, c("Beta 1", "Beta 2", "Beta 3"))
  
  colnames(dados) <- c("vertices", "ettj_ipca", "ettj_pre", "inflacao_implicita")
  dados <- dados %>% dplyr::slice(-1)
  
  dados <- dados %>%
    dplyr::mutate(
      vertices = as.numeric(sub(".", "", vertices, fixed = TRUE)),
      ettj_ipca = as.numeric(str_replace(ettj_ipca, pattern = ",", replacement = ".")),
      ettj_pre = as.numeric(str_replace(ettj_pre, pattern = ",", replacement = ".")),
      inflacao_implicita = as.numeric(str_replace(inflacao_implicita, pattern = ",", replacement = ".")),
      vertices = ifelse(vertices <= 10, vertices * 1000, vertices),
      data = data_new
    ) %>%
    dplyr::select(data, vertices:inflacao_implicita)
  
  return(dados)
}

# Lista de datas
data(holidaysANBIMA, package = "bizdays") # load the working days by calendar of anbima
cal <- bizdays::create.calendar(holidaysANBIMA, weekdays = c("saturday", "sunday"), name = "ANBIMA")

d2 <- Sys.Date()
d1 <- bizdays::add.bizdays(d2, -6, cal = cal)
data_seq <- bizdays::bizseq(d1, d2, cal)

# get data ----------------------------------------------------------------
deal_error <-
  purrr::possibly(
    obter_param_ettj,
    otherwise = NA_real_
  ) # deal with error

result <- purrr::map_df(data_seq[1:6], deal_error) %>%
  dplyr::distinct() %>%
  dplyr::mutate(data = lubridate::dmy(
    stringr::str_replace_all(data, pattern = "/", replacement = "-")
  ))

# Salva o arquivo no formato Excel
result %>% writexl::write_xlsx(paste0(getwd(),"//",glue::glue(name_db)))

# Salvando o arquivo no formato Excel xlsx com uma coluna já preparada para subir os dados no SQL Lite
#result %>%
#  mutate(
#    insert_sql = paste0("INSERT INTO ettjs_parametros ", "VALUES (", '"', data, '"', ",", vertices, ",", ettj_ipca, ",", ettj_pre, ",", inflacao_implicita, ")", ";")
#  ) %>%
#  writexl::write_xlsx(glue::glue(name_db))

# Verifica se a data a ser inserida já se encontra no banco de dados. Se a resposta for não, a tabela é atualizada.
# save/append data --------------------------------------------------------
#if (file.exists(name_db)) {
#  arquivo <-
#    datas_unicas <- unique(as.Date(readxl::read_xlsx(name_db)$dt, format = "%Y-%m-%d", tz = "UTC"))
#  result <- result %>% dplyr::filter(!dt %in% datas_unicas)
#  
#  write.table(result,
#              file = name_db,
#              append = TRUE,
#              row.names = FALSE,
#              col.names = FALSE,
#              sep = ";",
#              fileEncoding = "UTF-8"
#  )
#} else {
#  write.table(result,
#              file = name_db,
#              append = FALSE,
#              row.names = FALSE,
#              sep = ";",
#              fileEncoding = "UTF-8"
#  )
#}
#
