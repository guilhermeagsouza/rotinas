#### Conexão com o banco ####
#con <- dbConnect(
#  odbc::odbc(), 
#  Driver = "SQL Server", 
#  Server = "vmintegracao", # remember \\ if your path has a \ 
#  Database = "VM_INTEGRACAO",
#  user = "MUNDIAL\\guilherme.souza", # remember \\ if your username has a \
#  Trusted_Connection = "True"
#)

# Conexão com o SQL; Não precisa de control+shift+enter para truncar o código. Os comandos abaixo permitem a conexão sem truncar!
source('scripts_dashboard_book_crm/0.conecta_banco.R', echo=TRUE, max.deparse.length=60)
