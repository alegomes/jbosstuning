#!/bin/sh

# TODO Verificar se a variavel ja nao existe
JMETER_HOME=/Applications/JavaTools/jakarta-jmeter-2.3.2/
JMETER_BIN=$JMETER_HOME/bin/jmeter

# Tempo de espera entre a execucao dos testes e o inicio da coleta das metricas
WAIT=1

# Prefixo dos scripts Pythons quem fazem a coleta das metricas
COLETA_PREFIX="coletarMetricasDo"

# Diretorio com as massas de testes
TESTCASESDIR=testcases

# Diretorio dos arquivos de log
LOGDIR=log


function usage {
   echo "------------------------------------------------------------------------"
   echo "USO:"
   echo
   echo "      ./testeJBoss [-R ip1,ip2,ip3,...] [-c NomeDoCenarioDeTeste] [-s sample1,sample2,...]  [-r Repeticoes] [-h?]"
   echo
   echo "OPCOES:"
   echo
   echo "-R         Indica os servidores slaves atraves dos quais o JMeter"
   echo "           devera disparar as requisicoes de teste." 
   echo "           e.g. -R 192.168.1.2,192.168.1.3"
   echo
   echo "-c         Nome do cenario de teste =)"
   echo "           e.g. -c ApacheComBalanceamentoDeCargaSemLogComCacheJSF"
   echo
   echo "-s         Nomes dos samples do jMeter a serem analisados"
   echo "           e.g. -s 'Tela de Login','Geracao de Relatorio'"
   echo
   echo "-r         Numero de repeticoes de cada teste. Bom para evitar distorcoes aleatorias."
   echo "           e.g. -r 3"
   echo
   echo "-h ou -?	Exibe esta ajuda."
   echo
   echo "------------------------------------------------------------------------"

   exit
}

function printHeader {
   echo "-----------------------------------------------------------------------"
   echo "--                                                                   --"
   echo "--               SUPER SCRIPT PARA AUTOMACAO DE TESTES               --"         
   echo "--                                                                   --"
   echo "-----------------------------------------------------------------------"
}

function error {

   echo "[ERRO] $1"
   exit -1

}

function testFiles {

   # Verifica se todos os arquivos necessarios estao presentes"

   if [ ! -e "$LOGDIR" -o ! -d "$LOGDIR" ]; then
      rm -r "$LOGDIR"
      mkdir "$LOGDIR"
   fi

   if ! [ -d "$TESTCASESDIR" ]; then
	  error "Nenhuma massa de testes encontrada.
	1. Crie uma pasta chamada 'testcases' 
	2. Para cada massa de teste a ser executada, crie uma subpasta em 'testcases'
	   (e.g. testcases/CenarioSimples)
	3. Copie seus scripts de testes (i.e. *.jmx) para a pasta criada no passo 2
	   (e.g. testcases/CenarioSimples/TestCase.jmx)"			
	fi
	
	if ! [ -f $JMETER_BIN ]; then
		error "JMeter nao localizado em $JMETER_BIN"
	fi
	
	if ! [ -x $JMETER_BIN ]; then
		error "$JMETER_BIN sem premissao de execucao"
	fi

}

function clean {

   rm log/*.jtl
}


function executarJMeter {

   if [ -z "$1" ]; then
      error "Eh preciso informar o nome do arquivo de log no qual as mensagens do JMeter serao gravadas."
   else
     CENARIO=${1%".log"}
   fi

   if [ -z "$2" ]; then
      error "Eh preciso informar o nome da massa de testes a ser executada ."
   else
      TESTCASES="$TESTCASESDIR/$2"
      if [ ! -d $TESTCASES ]; then
	  	echo "Nao existe a massa de testes '${TESTCASES}'"
	  fi
   fi

   echo "Iniciando processamento dos testes em '$TESTCASES'"

   # ATENCAO! Dependendo da massa de testes, sera necessario aumentar
   #          o limite da heap (-Xmx) do jmeter e da quantidade de file
   #          descriptors do SO (ulimit -n)
   
   IFS=$'\n'
   for T in $(ls "$TESTCASES"); do

     TESTCASE="$TESTCASES/$T"
     LOGFILEPREFIX="${CENARIO}${T%'.jmx'}"

     echo "Iniciando testes '$TESTCASE' com log em '$LOGFILE'"

     echo 
     echo "---------------------------------------------------" 
     echo "Teste $TESTCASE -  T1"
     LOGFILE="${LOGFILEPREFIX}-T1.jtl"
     $JMETER_BIN -n -t "$TESTCASE" -l "${LOGFILE}" $JMETER_ARGS
     echo "Sucessos [$(grep 's="true"' "$LOGFILE" | wc -l)] - Erros [$(grep 's="false"' "$LOGFILE" | wc -l)]"

     sleep 1

     echo "Teste $TESTCASE -  T2"
     LOGFILE="${LOGFILEPREFIX}-T2.jtl"
     $JMETER_BIN -n -t "$TESTCASE" -l "${LOGFILE}" $JMETER_ARGS
     echo "Sucessos [$(grep 's="true"' "$LOGFILE" | wc -l)] - Erros [$(grep 's="false"' "$LOGFILE" | wc -l)]"

     sleep 1

     echo "Teste $TESTCASE -  T3"
     LOGFILE="${LOGFILEPREFIX}-T3.jtl"
     $JMETER_BIN -n -t "$TESTCASE" -l "${LOGFILE}" $JMETER_ARGS
     echo "Sucessos [$(grep 's="true"' "$LOGFILE" | wc -l)] - Erros [$(grep 's="false"' "$LOGFILE" | wc -l)]"

     sleep 2
   done

   echo "Fim da execucao do JMeter"

}

#########################
#
# Inicio do script
#
#########################

clean
printHeader

# Verifica se todos os arquivos necessarios para execucao estao presentes
testFiles

# Verificar se todos os parametros foram informados corretamente


while getopts "R:c:s:rh?" OPT; do
  case "$OPT" in
      "R") JMETER_ARGS="-R $OPTARG" ;;
      "c") CENARIO="$OPTARG" ;;
      "s") JMETER_SAMPLES=$(echo $OPTARG) ;;
      "r") REPEAT="$OPTARG" ;;
      "h") usage;;
      "?") usage;;
  esac
done


echo "Samples = ${JMETER_SAMPLES}"

declare -a JMETER_SAMPLES_ARRAY
IFS=$','
i=0
for S in ${JMETER_SAMPLES}; do
	JMETER_SAMPLES_ARRAY[$i]=${S}
	echo "sample[${i}] '$S'"
	i=$((i + 1))
done

echo "Iniciando testes dos samples [$JMETER_SAMPLES] para o cenario [$CENARIO]"
echo
echo "* Coletar metricas de:" 
IFS=' '
OPTIONS="JMeter JON Sair"
select OPT in $OPTIONS; do
       
    COLETA=${COLETA_PREFIX}${OPT}".py" 
    
    # TODO Deve haver uma forma mais inteligente de se fazer isso
    if [ "$OPT" = "JMeter" -o "$OPT" = "JON" ] ; then
    
       if [ ! -e "$COLETA" ]; then

  	  echo "O arquivo $COLETA nao existe."
	  exit

       else

          break;

       fi 

    elif [ "$OPT" = "Sair" ]; then

	exit

    else

       echo "Opcao invalida."
    
    fi
done

#CENARIO="$1"
while [ -z "$CENARIO" ]; do

   echo -n "* Informe o nome do cenario a ser testado: " 
   read CENARIO

done

while [ -z "$TESTCASES" ]; do

   echo "* Informe o nome da massa de testes a ser executada (subdiretorio em 'testcases'): " 
   select TESTCASES in $(ls "$TESTCASESDIR") Nenhum; do
      echo "$TESTCASES escolhido."   

      if [ $TESTCASES = "Nenhum" ]; then
         exit
      fi

      # TODO "Verificar se uma opcao invalida foi escolhida"
      break

   done

done


LOGFILE=${CENARIO}.log
LOG="$LOGDIR/$LOGFILE"
echo "Executando os testes e gravando o log em $LOG..."
executarJMeter $LOG $TESTCASES | tee "$LOG"
echo "OK"

echo "Colhendo as metricas em $WAIT segundos..."
sleep $WAIT

echo "Coletando metricas a partir do arquivo $LOG com o script $COLETA ..."
python "$COLETA" $LOG 
echo "OK"

echo "Copie o trecho abaixo e cole na planilha"
echo "--------> corte aqui <----------"
cat log/${CENARIO}.csv
echo "--------> corte aqui <----------"
echo
echo "Acabou..."
