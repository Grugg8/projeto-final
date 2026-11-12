# Calor extremo: definicao conceitual e operacional

**Escopo.** Este documento organiza as definicoes institucionais e as escolhas
operacionais relevantes para um estudo ecologico municipal de dengue no Brasil.
Ele distingue calor extremo como condicao de risco, onda de calor como evento
persistente e temperatura maxima diaria (`Tmax`) como variavel meteorologica.

**Nota sobre a base versionada.** Os NetCDF atualmente versionados no projeto
contêm 192 camadas mensais de `t2m` (janeiro de 2010 a dezembro de 2025). Eles
nao contem observacoes diarias de `Tmax`. Assim, a maxima mensal do produto
mensal pode ser usada apenas como proxy descritiva; ela nao deve ser apresentada
como maxima diaria. A parametrizacao de ondas de calor abaixo exige uma fonte
diaria explicita.

## 1. Definicoes institucionais

### OMS e OMM/WMO

OMS e OMM nao estabelecem um valor universal de temperatura para definir calor
extremo. O limiar depende da climatologia local, sazonalidade, aclimatacao da
populacao, ambiente construido, umidade, vento, radiacao e vulnerabilidade.

Na orientacao conjunta *Heatwaves and health: guidance on warning-system
development*, onda de calor e tratada como um periodo de calor anormalmente
quente, seco ou umido, com inicio e terminacao relativamente graduais, duracao
de pelo menos dois ou tres dias e impacto perceptivel nas atividades humanas.
Na pratica, sistemas de alerta podem usar temperatura maxima, temperatura minima
noturna, temperatura aparente ou indices biometeorologicos. A orientacao e
deliberadamente nao prescritiva: o limiar deve ser calibrado ao contexto local e,
idealmente, a relacao temperatura--desfecho em saude.

A pagina tematica atual da OMM reforca tres pontos: (i) temperaturas iguais
podem ser extremas em um clima e usuais em outro; (ii) o excesso de calor se
acumula ao longo de dias e noites; e (iii) umidade, vento e radiacao modificam o
estresse termico. Portanto, uma sequencia de dias quentes nao e, por si so,
suficiente para caracterizar o risco fisiologico.

### IPCC

O IPCC define onda de calor, no glossario do AR6, como um periodo de tempo
anormalmente quente e observa que ha definicoes sobrepostas com *warm spells*.
No capitulo sobre extremos climaticos, o IPCC registra que os extremos podem
ser definidos por limiares relativos, como o percentil 90, ou absolutos, como
35 graus Celsius para um dia quente. A raridade e sempre dependente do lugar e
da epoca do ano.

Essa formulacao e importante para o Brasil: um limiar absoluto permite comparacao
direta de intensidade, mas mistura exposicoes de populações aclimatadas a
climas muito diferentes. Um percentil municipal preserva a ideia de anomalia
local, embora nao seja diretamente comparavel em graus Celsius entre municipios.

### Brasil: INMET e Ministerio da Saude

O glossario do Instituto Nacional de Meteorologia (INMET), reproduzindo a
definicao operacional tradicional atribuida a OMM, descreve onda de calor como
cinco ou mais dias consecutivos nos quais a temperatura maxima diaria excede a
temperatura maxima media mensal em pelo menos 5 graus Celsius. Essa regra e uma
definicao de monitoramento meteorologico; nao equivale automaticamente a um
limiar de efeito em dengue ou mortalidade.

O Ministerio da Saude trata ondas de calor e excesso de calor como riscos de
saude publica, enfatizando duracao, intensidade, umidade e vulnerabilidades.
A Nota Tecnica no 18/2023-SVSA/MS orienta a resposta do SUS durante eventos de
calor e destaca a necessidade de planos e estrategias nas tres esferas de
gestao. O painel de Excesso de Calor do Ministerio utiliza o *Excess Heat
Factor* (EHF) para classificar a severidade operacional. Isso mostra que o MS
nao reduz o risco a um unico numero absoluto de temperatura.

Em sintese, ha duas camadas institucionais complementares:

1. o INMET fornece uma regra meteorologica simples, baseada em `Tmax` e cinco
   dias consecutivos;
2. o MS utiliza uma abordagem de vigilancia e resposta que pode combinar
   intensidade, persistencia, aclimatacao e impacto em saude.

## 2. Metricas operacionais

### 2.1 Limiar absoluto

Um evento pode ser definido por

\[
H_{it}^{abs}=I(Tmax_{it}\geq c),
\]

em que `c` pode ser 32, 35 ou outro valor fixado em graus Celsius. Uma onda de
calor exige adicionalmente uma duracao minima, por exemplo dois, tres ou cinco
dias consecutivos.

**Vantagens:** comunicacao simples, interpretacao direta e comparabilidade
com alertas meteorologicos que usam graus Celsius.

**Limitacoes:** um valor como 35 graus Celsius e raro no Sul e frequente em
partes do Norte e Nordeste; a mesma categoria pode representar estresses
fisiologicos muito distintos. O limiar tambem nao incorpora umidade nem noites
quentes e pode gerar poucos eventos em locais frios ou quase todos os dias em
locais quentes.

### 2.2 Limiar relativo local

Para cada municipio `i` e periodo do ano `m`, calcula-se um quantil da serie
historica de `Tmax`:

\[
q_{i,m}(p)=Q_p\{Tmax_{i,d}:d\text{ pertence a uma janela climatologica de }m\}.
\]

Um dia e extremo quando `Tmax_{i,d} >= q_{i,m}(p)`, com `p` igual a 0,90,
0,95 ou 0,975. Uma onda e uma sequencia de pelo menos `L` dias extremos,
tipicamente `L=2` ou `L=3`; estudos tambem usam cinco dias.

Uma medida de carga municipal adequada ao recorte acumulado e

\[
D_i=\sum_{e=1}^{E_i} \text{duracao}(e),
\]

onde `E_i` e o numero de episodios que satisfazem o quantil e a duracao minima.
Tambem podem ser usados o numero de episodios, o maior episodio, a proporcao
de dias extremos ou a soma do excesso acima do limiar.

**Vantagens:** respeita a heterogeneidade climatica brasileira, evita que um
limiar absoluto classifique injustamente climas diferentes e representa melhor
o significado de anomalia local.

**Limitacoes:** exige uma serie diaria suficientemente longa e homogenea; a
estimativa de percentis pode mudar com a janela de referencia; quantis
municipais sao menos transparentes para comunicacao publica; e a comparacao
entre municipios passa a ser comparacao de anomalias, nao de temperatura bruta.

### 2.3 Indices temperatura--umidade

O *Heat Index* combina temperatura do ar e umidade relativa para aproximar a
temperatura percebida. A formula de Rothfusz e uma regressao empirica para
condicoes quentes e umidas; fora de seu dominio, o resultado pode ser instavel.
O Humidex combina temperatura e pressao de vapor. Em uma forma usual, com `T`
em graus Celsius e `e` em hPa,

\[
Humidex=T+0,5555(e-10).
\]

Outros indices, como temperatura aparente, WBGT, UTCI e EHF, incorporam
combinacoes distintas de umidade, vento, radiacao, aclimatacao e persistencia.

**Vantagens:** aproximam melhor o estresse termico humano que `Tmax` isolada,
especialmente em ambientes umidos; podem representar o efeito de noites quentes
ou de calor acumulado.

**Limitacoes:** requerem mais variaveis, dependem de formulas e dominios de
validade, podem ser dificeis de reproduzir em todos os municipios e nao sao
necessariamente a melhor medida biologica para o vetor. Para dengue, o efeito
climatico pode operar por desenvolvimento do vetor, sobrevivencia, comportamento
humano, chuva e armazenamento de agua; um indice de conforto termico humano nao
resume todos esses mecanismos.

## 3. Escolha para o TCC

### 3.1 Exposicao principal recomendada

Para um estudo nacional, a escolha mais aderente e uma definicao relativa local
baseada em `Tmax` diaria:

\[
Tmax_{i,d}\geq q_{i,m}(0,90)
\quad\text{em pelo menos tres dias consecutivos}.
\]

O percentil 90 e suficientemente sensivel para caracterizar exposicao sem
restringir o evento a poucos extremos; a duracao de tres dias representa
persistencia e e compativel com a linguagem operacional OMS/OMM. Como analise de
sensibilidade, recomenda-se repetir o calculo com percentil 95 e duracao de dois
dias. A definicao INMET de cinco dias e 5 graus acima da media mensal deve ser
reportada como referencia institucional, nao necessariamente como a unica
exposicao analitica.

Para o painel municipal acumulado, o indicador deve ser uma medida de carga,
por exemplo `D_i`, o total de dias pertencentes a episodios que satisfazem a
regra. A covariavel do SaTScan pode ser uma categoria pre-especificada dessa
carga, como `0 = nenhum dia de onda` e `1 = pelo menos um episodio`, ou uma
estratificacao em dois ou tres grupos com pontos de corte definidos antes da
varredura. A escolha deve ser registrada no arquivo de parametros e no log.

### 3.2 Por que nao usar apenas 32 ou 35 graus Celsius

Um unico limiar absoluto trataria como equivalente um municipio amazonico com
temperatura alta habitual e um municipio sulino que raramente alcanca o mesmo
valor. Para dengue, a heterogeneidade de temperatura basal e a sazonalidade sao
particularmente relevantes. O limiar relativo reduz essa distorcao e permite
interpretar o indicador como excesso termico local.

### 3.3 Por que nao usar apenas Heat Index ou Humidex

Esses indices sao uteis para risco termico humano, mas requerem umidade e, em
alguns casos, vento e radiacao. No presente TCC, a pergunta principal e a
distribuicao espacial acumulada de dengue; `Tmax` local oferece uma covariavel
mais simples, auditavel e proxima do componente de calor usado em estudos
entomologicos. Indices combinados devem ser analise de sensibilidade ou etapa
posterior, nao substituto silencioso da exposicao principal.

### 3.4 Aplicabilidade ao SaTScan

O SaTScan ajusta diretamente covariaveis categoricas. Portanto, a temperatura
diaria nao deve ser inserida como uma coluna continua sem uma etapa adicional.
O fluxo recomendado e:

1. construir o indicador diario de onda de calor com `Tmax` local;
2. agregar sua carga ao municipio no periodo 2010--2025;
3. converter a carga em categoria pre-especificada;
4. repetir a categoria no `.cas` e no `.pop`;
5. comparar a colecao ajustada com a varredura sem ajuste, mantendo os mesmos
   limites espaciais, semente e numero de replicacoes.

O resultado ajustado deve ser descrito como excesso de dengue que permanece apos
o controle da estratificacao termica adotada. Ele nao prova que o calor causa o
excesso, nao elimina confundimento residual, nao corrige subnotificacao e nao
substitui um modelo individual ou espaco-temporal.

## 4. Decisao operacional documentada

Enquanto uma fonte diaria de `Tmax` nao for incorporada ao repositorio, os
artefatos derivados dos NetCDF atuais devem usar a rotulagem honesta:

- `temp_C_media`: media mensal ou media anual do produto `t2m` mensal;
- `temp_C_max`: maxima entre medias mensais disponiveis no ano, isto e, maxima
  mensal do produto, nao maxima diaria;
- `temp_C_min`: minima entre medias mensais disponiveis no ano;
- `Tmax` diaria e ondas de calor: **nao estimadas** na base atual.

Essa separacao evita uma falsa equivalencia entre o dado observado e a metrica
solicitada. A substituicao pelo indicador principal deve ocorrer quando o arquivo
diario for disponibilizado e validado.

## Referencias institucionais consultadas

- IPCC. [AR6 WGI, Chapter 11: Weather and Climate Extreme Events in a Changing Climate](https://www.ipcc.ch/report/ar6/wg1/chapter/chapter-11/). Consulta em 05 set. 2026.
- IPCC. [AR6 Glossary](https://apps.ipcc.ch/glossary/). Consulta em 05 set. 2026.
- INMET. [Glossario: Onda de calor](https://portal.inmet.gov.br/glossario/glossario). Consulta em 05 set. 2026.
- Ministerio da Saude. [Nota Tecnica no 18/2023-SVSA/MS](https://www.gov.br/saude/pt-br/centrais-de-conteudo/publicacoes/notas-tecnicas/2023/nota-tecnica-no-18-2023-svsa-ms). Consulta em 05 set. 2026.
- Ministerio da Saude. [Excesso de Calor](https://clima.saude.gov.br/). Consulta em 05 set. 2026.
- Ministerio da Ciencia, Tecnologia e Inovacao. [Clima em sintese: estudos sobre saude e ondas de calor no Brasil (2015--2025)](https://www.gov.br/mcti/pt-br/acompanhe-o-mcti/cgcl/paginas/clima-em-sintese/clima-em-sintese_estudos-sobre-saude-e-ondas-de-calor-no-brasil-2015-2025.pdf). 2025. Consulta em 05 set. 2026.
- OMM. [Extreme Heat](https://wmo.int/themes/extreme-heat). Consulta em 05 set. 2026.
- OMS/OMM. [Heatwaves and health: guidance on warning-system development](https://www.who.int/publications/m/item/heatwaves-and-health--guidance-on-warning-system-development). 2015/2016. Consulta em 05 set. 2026.
