library(tidyverse)
library(httr)
library(bizdays)

# set inputs and workdir --------------------------------------------------------------
#wkdir <- "~/dev_R/schedule_R/"
name_db <- "hist_coef_pre_ipca.xlsx"

#setwd(wkdir)

# load functions ----------------------------------------------------------
obter_param_ettj <- function(dt){
  
  stopifnot(is(dt,"Date"), length(dt) == 1)
  
  url <- "https://www.anbima.com.br/informacoes/est-termo/CZ-down.asp"
  
  #r <- httr::POST(url = url,
  #                body = list(Idioma = "PT",
  #                            Dt_Ref = format(dt, "%d/%m/%Y"),
  #                            saida = "csv"),
  #                encode = "multipart")
  
  r <- httr::POST(url, encode = c('multipart'))
  
  texto_puro <- base::rawToChar(content(r,as = "raw"))
  
  dados <- read_csv2(texto_puro, n_max = 15) %>% 
    dplyr::slice(4:15)
  
  dados <- dados[,1:4]
  data_new <- colnames(dados)[1]
  
  dados <- dados %>% dplyr::select(data_new, c('Beta 1', 'Beta 2', 'Beta 3'))
  
  colnames(dados) <- c('vertices', 'ettj_ipca', 'ettj_pre', 'inflacao_implicita')
  dados <- dados %>% dplyr::slice(-1)
  
  dados <- dados %>% 
  dplyr::mutate(
    vertices = as.numeric(sub(".", "", vertices, fixed = TRUE)),
    ettj_ipca = as.numeric(str_replace(ettj_ipca, pattern = ',', replacement = '.')),
    ettj_pre = as.numeric(str_replace(ettj_pre, pattern = ',', replacement = '.')),
    inflacao_implicita = as.numeric(str_replace(inflacao_implicita, pattern = ',', replacement = '.')),
    vertices = ifelse(vertices <= 10, vertices*1000, vertices),
    data = data_new
  ) %>% 
  dplyr::select(data, vertices:inflacao_implicita)
  
  
  return(dados)    
}

# get list of dates ---------------------------------------------------------------
data(holidaysANBIMA, package = 'bizdays') # load the working days by calendar of anbima
cal <- create.calendar(holidaysANBIMA, weekdays=c('saturday', 'sunday'), name='ANBIMA')

d2 = Sys.Date()
d1 = add.bizdays(d2, -6, cal = cal)
data_seq <- bizseq(d1,d2,cal)

# get data ----------------------------------------------------------------
deal_error <- 
  purrr::possibly(obter_param_ettj, 
                  otherwise = NA_real_) # deal with error

result <- purrr::map_df(data_seq[1:6], deal_error) %>% 
  dplyr::distinct() %>% 
  dplyr::mutate(data = lubridate::dmy(
    stringr::str_replace_all(data, pattern = '/',replacement = '-'))
    )

result %>% writexl::write_xlsx(glue::glue(name_db))

result %>% mutate(
  insert_sql = paste0('INSERT INTO ettjs_parametros ','VALUES (','"',data,'"',",",vertices,',',ettj_ipca,',',ettj_pre,',',inflacao_implicita,')',';')
) %>% 
  writexl::write_xlsx(glue::glue(name_db))

# save/append data --------------------------------------------------------
if (file.exists(name_db)){
  
  arquivo <- 
  
  datas_unicas <- unique(as.Date(readxl::read_xlsx(name_db)$dt, format = "%Y-%m-%d", tz = 'UTC'))
  result <- result %>% dplyr::filter(!dt %in% datas_unicas)
  
  write.table(result,
              file =  name_db,
              append = TRUE,
              row.names = FALSE,
              col.names = FALSE,
              sep = ";", 
              fileEncoding = "UTF-8")
} else {
  write.table(result, 
              file =  name_db,
              append = FALSE,
              row.names = FALSE,
              sep = ";", 
              fileEncoding = "UTF-8")
}
