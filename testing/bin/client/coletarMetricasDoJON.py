#-*-coding: utf-8

import sys
import psycopg2 as pg
from decimal import *

#faz a conexao com o BD
try:
  conn = pg.connect("dbname='hqdb' user='hqadmin' host='172.25.0.16' port='9432' password='hqadmin'")
except:
  print "Nao conectou"
  sys.exit()

#pega o cursor da conexao
cursor = conn.cursor()
      
#inicializa variaveis de arquivo
print "Processando arquivo "  + sys.argv[1] 
try:
  arquivo = sys.argv[1]
except:
  arquivo = 'log.txt'
arquivoOut = 'log/Metrica %s.csv' % arquivo[4:-4]
arquivoOut2 = 'log/Metrica %s.txt' % arquivo[4:-4]
log = file(arquivo)
saida = file(arquivoOut,'w')
#saida2 = file(arquivoOut2, 'w')
#saidasql = file('log/sqls.txt','w')
#saidaParametros = file('log/parametros.txt','w')

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

def imprime(cabecalho, inicio, final):
  escreve = '# ---------------------------------------------------------\n'
  escreve = escreve + '# %s' % cabecalho
  escreve = escreve + '# ---------------------------------------------------------\n\n'
  escreve = escreve + 'echo\necho CPU Usage\necho\nmetric list -value 10008 -from "%s" -to "%s"\n\n' % (inicio, final)
  escreve = escreve + 'echo\necho Used Memory\necho\nmetric list -value 10038 -from "%s" -to "%s"\n\n' % (inicio, final)
  escreve = escreve + 'echo\necho JVM Total Memory\necho\nmetric list -value 10272 -from "%s" -to "%s"\n\n' % (inicio, final)
  escreve = escreve + 'echo\necho JVM Free Memory\necho\nmetric list -value 10268 -from "%s" -to "%s"\n\n' % (inicio, final)
  escreve = escreve + 'echo\necho Active Thread Count\necho\nmetric list -value 10262 -from "%s" -to "%s"' % (inicio, final)
  saida.write(escreve)
  saida.write('\n\n')


#*********************************************************************************
def consultaBanco(parametro, inicio, final):
  start = int(inicio)
  end = int(final)
  sql = "select avg(value) from eam_measurement_data where measurement_id = %d and timestamp > %d and timestamp < %d;" % (parametro, start, end)

  #saidasql.write(sql)
  #saidasql.write('\n')

  #executa o sql
  cursor.execute(sql)

  #pega resultados
  mediaSQL = cursor.fetchall()

  #transforma para string
  avg  = str(mediaSQL[0][0])

  #retorna a media
  return avg

#*********************************************************************************
def consultaParametros(parametro):
  sql = "select templ.name from eam_measurement_templ as templ, eam_measurement as eam where templ.id = eam.template_id and eam.id = %d;" % parametro

  #executa o sql
  cursor.execute(sql)

  #pega resultados
  nome = cursor.fetchall()

  #transforma para string
  name  = str(nome[0][0])
  
  #retorna a media
  return name

#*********************************************************************************

#leitura de um arquivo
while True:
  line=log.readline()
  if len(line) == 0:
    break
  if line[0:13] == 'SituacaoAluno':
    #garbage = log.readline() #---------------------------------------------------------
    garbage = log.readline() #Created the tree successfully
    print line
    start = formataInicio(log.readline(), dic)
    end = formataFinal(log.readline(), dic)
    #imprime(line, start[0], end[0])
    media = []
    for p in parametros:
      md = consultaBanco(p, start[2], end[2])
      media.append(md)
      #saida2.write('Teste: '+line+' Parametro: '+str(p)+' Inicio: '+str(start[2])+' Final: '+str(end[2])+'\n')
      #saida2.write('     Media coletada: '+str(md)+'\n')
    linha = "" 
    for m in media:
      linha = linha + "%s, " % m
    saida.write(linha[:len(linha)-2])
    saida.write('\n')

#for p in parametros:
  #nm = consultaParametros(p)
  #saidaParametros.write('Parametro: '+str(p)+' Nome: '+nm+'\n')

log.close()
saida.close()
#saidaParametros.close()
#saida2.close()
#saidasql.close()
print 'Acabou...'
