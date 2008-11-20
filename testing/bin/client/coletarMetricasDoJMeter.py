#-*-coding: utf-8

import sys
from decimal import *

      
#inicializa variaveis de arquivo
print "Processando arquivo "  + sys.argv[1] 
try:
  arquivo = sys.argv[1]
except:
  arquivo = 'Log.txt'

# Extracao do nome do cenario de teste
cenario = arquivo[arquivo.rfind("/")+1:arquivo.rfind(".")] 
print "Coletando metricas para o cenario '%s'" % cenario

# TODO Codigo fragil
arquivoOut = 'log/%s.csv' % cenario 

logJMeter = file(arquivo)
saida = file(arquivoOut,'w')

#dicionario com os meses do ano
dic = {'Jan':'01','Feb':'02','Mar':'03','Apr':'04','May':'05','Jun':'06','Jul':'07','Aug':'08','Sep':'09','Oct':'10','Nov':'11','Dec':'12'}
#lista das metricas - measurement_id
parametros = [10560, 10590, 10008, 10038, 10308, 10304, 10298, 10272, 10268, 10262, 12986, 10478, 10462, 13850, 10492, 10430, 10282]

def formataInicio (linha, meses):
  sLinha = linha.split('@')[1].split(' ')
  mes = meses[sLinha[2]]
  dia = sLinha[3]
  horas = sLinha[4].split(':')
  hora = horas[0]
  minutos = horas[1]
  segundos = horas[2]
  if hora < '12':
    turno = 'am'
  else:
    turno = 'pm'
  retorno = []
  data = '%s/%s/07 %s:%s%s' % (mes, dia, hora, minutos, turno)
  retorno.append(data)
  data = '2007/%s/%s %s:%s:%s' % (mes, dia, hora, minutos, segundos)
  retorno.append(data)
  retorno.append(sLinha[7][1:-2])
  return retorno

def formataFinal (linha, meses):
  sLinha = linha.split('@')[1].split(' ')
  mes = meses[sLinha[2]]
  dia = sLinha[3]
  horas = sLinha[4].split(':')
  hora = horas[0]
  minuto = int(horas[1])
  segundos = horas[2]
  if segundos != '00':
    minuto += 2
  minutos = '%d' % minuto
  if hora < '12':
    turno = 'am'
  else:
    turno = 'pm'
  retorno = []
  data = '%s/%s/07 %s:%s%s' % (mes, dia, hora, minutos, turno)
  retorno.append(data)
  data = '2007/%s/%s %s:%s:%s' % (mes, dia, hora, minutos, segundos)
  retorno.append(data)
  retorno.append(sLinha[7][1:-2])
  return retorno

#*********************************************************************************
# Leitura e processamento da saida do JMeter, num formato semelhante a este:
#
# ---------------------------------------------------
# SituacaoAluno - T1 - Server: 16 - Carga: 500 threads
# Created the tree successfully
# Starting the test @ Thu Jan 03 20:25:29 BRST 2008 (1199399129918)
# Tidying up ...    @ Thu Jan 03 20:26:01 BRST 2008 (1199399161439)
# ... end of run
#
# SituacaoAluno - T2 - Server: 16 - Carga: 500 threads
# Created the tree successfully
# Starting the test @ Thu Jan 03 20:26:14 BRST 2008 (1199399174116)
# Tidying up ...    @ Thu Jan 03 20:26:25 BRST 2008 (1199399185462)
# ... end of run
#
# SituacaoAluno - T3 - Server: 16 - Carga: 500 threads
# Created the tree successfully
# Starting the test @ Thu Jan 03 20:26:38 BRST 2008 (1199399198169)
# Tidying up ...    @ Thu Jan 03 20:26:49 BRST 2008 (1199399209337)
# ... end of run
#

# TODO Codigo fragil. Generaliza-lo depois.

sucessos = "?" 
erros = "?"
tempoDeProcessamento = "?"

while True:

  line=logJMeter.readline()
  if len(line) == 0:
    break
  if line.startswith("Teste"):
   
     while not line.startswith("Starting the test") and not line.startswith("Sucessos") :
           line = logJMeter.readline()

     if line.startswith("Starting the test") : 
        start = formataInicio(line, dic)
	
	while not line.startswith("Tidying up ...") and not line.startswith("Sucessos")  :
              line = logJMeter.readline()
	      
	if line.startswith("Tidying up ...") :
	   end = formataFinal(line, dic)
	else : 
	    #offset = logJMeter.tell()
	    #print "offset=",offset
	    #while not line.startswith("Starting the test") : 
            #      line = logJMeter.readline()
	    #end = formataInicio(line, dic)
	    #print "depois=",logJMeter.tell()
            #logJMeter.seek(offset)

	    end = {"?":"?"}

     while not line.startswith("Sucessos"):
           line = logJMeter.readline()

     if line.startswith("Sucessos") :
    
        sucessos = line[line.find("[")+1: line.find("]")]
        erros = line[line.rfind("[")+1: line.rfind("]")]

     try:
       t1 = int(start[2])
       t2 = int(end[2])
       tempoDeProcessamento = (t2 - t1)/1000;
     except:
        tempoDeProcessamento = "?"

     print "%s - %s segundos - %s sucessos - %s erros" % (cenario,tempoDeProcessamento, sucessos, erros)

     saida.write(str(tempoDeProcessamento) + "," + sucessos + "," + erros)
     saida.write('\n')


logJMeter.close()
saida.close()
print 'Fim da coleta de metricas a partir do log do JMeter'
