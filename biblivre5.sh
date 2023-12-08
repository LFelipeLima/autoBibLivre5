#!/usr/bin/env bash
# Adiciona repositório que contém o PostgresSQL 9.1 (obsoleto)
echo "Adicionando repositório que contém o PostgresSQL 9.1 (obsoleto)"
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Adiciona repositório que contém o Tomcat 7 (obsoleto)
echo "Adicionando repositório que contém o Tomcat 7 (obsoleto)"
sudo sh -c 'echo "deb http://br.archive.ubuntu.com/ubuntu/ xenial main" > /etc/apt/sources.list.d/tomcat7.list'
sudo sh -c 'echo "deb http://br.archive.ubuntu.com/ubuntu/ xenial universe" >> /etc/apt/sources.list.d/tomcat7.list'
sudo sh -c 'echo "deb http://us.archive.ubuntu.com/ubuntu/ xenial main" > /etc/apt/sources.list.d/tomcat7.list'
sudo sh -c 'echo "deb http://us.archive.ubuntu.com/ubuntu/ xenial universe" > /etc/apt/sources.list.d/tomcat7.list'

# Instala chave de segurança do PostgreSQL
echo "Instalando chave de segurança do PostgreSQL"
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Atualiza repositórios
echo "Atualizando repositórios"
sudo apt-get update

# Instala pacotes PostgreSQL 9.1 e Tomcat 7 e OpenJDK 8 (opcional)
echo "Instalando PostgreSQL 9.1, Tomcat 7 e Open JDK 8"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql-9.1 tomcat7 openjdk-8-jdk-headless pv

# Cria a senha padrão para o usuário postgres
echo "Criando senha padrão para o PostgreSQL"
sudo su postgres -c "psql -o /dev/null -U postgres -c "'"'"ALTER USER postgres WITH PASSWORD 'abracadabra'"'"'"";

# Cria usuário biblivre e o banco de dados básico biblivre4
echo "Criando estrutura básica do banco de dados"
sudo su postgres -c "wget --quiet -O - https://raw.githubusercontent.com/cleydyr/biblivre/master/sql/createdatabase.sql | pv -s 406 | psql -o /dev/null -U postgres"

# Cria o esquema básico do Biblivre
echo "Criando esquemas e populando dados para primeira instalação Biblivre 5"
sudo su postgres -c "wget --quiet -O - https://raw.githubusercontent.com/cleydyr/biblivre/master/sql/biblivre4.sql | pv -s 1455347 | psql -o /dev/null -U postgres -d biblivre4"

# Aumenta o tamanho máximo do heap do Tomcat 7 de 128m (padrão) para 1G
echo "Aumentando o tamanho máximo do heap do Tomcat 7 para 1 GiB"
sudo sed -i 's/-Xmx128m/-Xmx1G/' /etc/default/tomcat7

# Baixa o driver JDBC do PostgreSQL 9.1
echo "Baixando o driver JDBC 4 do PostgreSQL 9.1"
sudo wget -O /usr/share/tomcat7/lib/postgresql-9.1-903.jdbc4.jar https://jdbc.postgresql.org/download/postgresql-9.1-903.jdbc4.jar

# Baixa a release mais recente do repositório e implanta no Tomcat 7
echo "Baixando e implantando a release mais recente do Biblivre 5"
echo 'https://github.com/cleydyr/biblivre/releases/download'`wget -SO-  https://github.com/cleydyr/biblivre/releases/latest 2>&1 >/dev/null | grep Location | head -n1 | sed 's/^ *//;s/ *$//' | cut -f2 -d " " | egrep -o "/v.*$"`"/Biblivre4.war" | tr -d "\r" | xargs wget
sudo mv Biblivre4.war /var/lib/tomcat7/webapps/Biblivre4.war

# Reinicia o serviço do Tomcat para carregar o driver e efetuar as mudanças do tamanho do heap
echo "Reiniciando do serviço do Tomcat 7"
sudo systemctl restart tomcat7

# Cria e dá permissões ao usuário Tomcat para a pasta Biblivre na pasta home do usuário Tomcat.
# Isso é necessário para se armazenar arquivos de backup, por exemplo.
tomcat7_home_folder=`getent passwd "tomcat7" | cut -d: -f6`/Biblivre
sudo mkdir $tomcat7_home_folder
sudo chown tomcat7 $tomcat7_home_folder

echo "Tudo pronto! Abrindo http://localhost:8080/Biblivre4"
sensible-browser http://localhost:8080/Biblivre4
