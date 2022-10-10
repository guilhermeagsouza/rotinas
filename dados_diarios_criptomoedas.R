fold <- 'dados_criptomoedas'

# Lista todos arquivos que estão nessa pasta
f <- list.files(fold, include.dirs = F, full.names = T, recursive = T)
# Remove todos os arquivos
file.remove(f)

#https://cran.r-project.org/web/packages/BatchGetSymbols/vignettes/BatchGetSymbols-vignette.html

library(data.table)
library(quantmod)
library(tidyverse)
library(magrittr)

# Data de hoje
hoje <- lubridate::today()

portfolio <- c(
  "BTC-USD","ETH-USD","LTC-USD","XRP-USD","ADA-USD","SOL-USD", "FTM-USD",
  "AVAX-USD",'AXS-USD',"ALICE-USD", "ATOM-USD","DOGE-USD","GALA-USD","AAVE-USD",
  "DOT-USD","TRX-USD","MATIC-USD","LINK-USD","GMT-USD","ALPHA-USD","NEAR-USD",
  "XLM-USD","WAVES-USD","RUNE-USD","BEL-USD","1INCH-USD","SAND-USD",
  "DAR-USD","JASMY-USD","FTT-USD","WOO-USD","APE-USD","API3-USD","IMX-USD",
  "FLOW-USD","DUSK-USD","ANT-USD","LPT-USD","AR-USD","DASH-USD","UNI1-USD","HNT-USD",
  "MANA-USD","DYDX-USD","OP-USD","DAO-USD","LDO-USD",'GMX1-USD',"CAKE-USD","ALGO-USD",
  "1INCH-USD"
  ) %>% 
  sort()


criptos <- vector("list", length(portfolio))

for (i in seq(criptos)) {
  
  criptos[[i]] <- quantmod::getSymbols(
    portfolio[i], 
    src = 'yahoo',
    auto.assign = FALSE,
    from="2014-01-01"
    )
  
  # Nome da criptomoeda
  nome_cripto <- criptos[[i]] %>% 
    data.frame() %>% 
    dplyr::select(contains(c('Open'))) %>% 
    names() %>% 
    stringr::str_replace_all(pattern = '.USD.Open', replacement = '')
  
  # Data das criptos
  index_cripto <- zoo::index(criptos[[i]])
  
  dados <- criptos[[i]] %>% 
    data.frame() %>% 
    dplyr::mutate(index = index_cripto) %>% 
    dplyr::arrange(desc(index)) %>% 
    dplyr::select(contains(c('index','High','Low','Adjusted'))) %>% 
    na.omit() %>% 
    dplyr::filter(index != hoje)
  
  # Salvando os dados em Excel na pasta dados_criptmoedas/
  dados %>% 
    writexl::write_xlsx(paste0('dados_criptomoedas/',nome_cripto,'.xlsx'))
}

rm(list=ls())