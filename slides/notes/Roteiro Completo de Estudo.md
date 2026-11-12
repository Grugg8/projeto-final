# Roteiro completo de fala da defesa

Distribuição espacial da dengue no Brasil: identificação de áreas de alto risco e características socioambientais

## Como usar o roteiro

Este roteiro acompanha a numeração da apresentação. A fala sugerida é um ponto de partida para o ensaio. Troque as palavras que não usaria numa conversa com a banca e procure guardar a sequência do raciocínio. O texto de aprofundamento serve para entender a análise e preparar respostas; não precisa ser dito por inteiro.

Antes de passar cada slide, procure responder a uma pergunta: o que a banca precisa compreender aqui para acompanhar o próximo? Nos métodos, essa resposta costuma ser o objeto calculado, a referência usada para compará-lo e a interpretação do resultado. Nos mapas, diga primeiro qual é a medida e só depois descreva o padrão territorial.

A introdução foi ampliada na fala a partir do capítulo correspondente da monografia. As notas da apresentação são uma versão curta; este documento desenvolve a fala e o material para estudo. As referências indicadas são apoio de estudo. Durante a exposição, mencione apenas os autores que ajudam a situar o argumento; não transforme a abertura em uma lista de artigos.

Dedique atenção aos slides 25 a 28: apresente a referência sem ajuste, explique a referência estratificada, percorra o exemplo com os mesmos casos observados e esclareça o papel das covariáveis. A pergunta estatística muda com a referência; a interpretação deve acompanhar essa mudança.

## Como explicar as equações

Comece pelo significado da expressão. Em vez de ler todos os índices, diga, por exemplo: eu comparo os casos que ocorreram nessa zona com os casos que esperaria encontrar ali, dado o tamanho de sua população.

Aponte o numerador e o denominador quando explicar a divisão. Faça uma pausa depois de apresentar a referência. Só acrescente detalhes de notação se eles ajudarem a interpretar a conta.

Se usar um exemplo, avise antes se ele é fictício. Depois da conta, volte ao método: diga o que aquele número permite comparar e o que ainda depende de inferência. Um RR acima de um não substitui o teste da varredura.

Ao terminar, conecte o cálculo à próxima decisão. Depois do esperado, explique como se mede o excesso; depois da razão de verossimilhança, explique como se avalia o máximo encontrado na busca.

## Como ensaiar

No primeiro ensaio, explique os métodos sem olhar o texto. Consulte o roteiro quando perceber uma lacuna no raciocínio. Refaça apenas esse trecho até conseguir explicar por que a operação é necessária.

Depois, grave uma exposição completa e cronometre. Observe se você aponta a equação enquanto fala dela, se anuncia a unidade das taxas e se dá tempo para a banca ler os mapas. Ajuste a duração ao tempo concedido para a defesa.

Treine perguntas fora da ordem dos slides. Peça que alguém interrompa com dúvidas como: qual é o denominador?, o que está sendo mantido fixo?, por que esse ajuste muda o esperado? Isso ajuda a responder pelo conceito, sem depender da frase memorizada.

## Se precisar ajustar o tempo

Se precisar encurtar a apresentação, preserve a explicação do esperado, da comparação dentro e fora da zona, da busca pelo máximo e da padronização. São os passos que dão sentido aos resultados. Os detalhes dos exemplos e das respostas de aprofundamento podem ficar para a arguição.

Na comparação das oito formulações, selecione o contraste que organiza a interpretação, sem ler todas as células. Nos mapas, descreva o padrão principal e uma ressalva necessária. A banca pode consultar as demais informações no próprio slide.

Ao receber uma pergunta, pare de avançar os slides. Responda primeiro ao ponto perguntado; recupere uma equação ou um mapa se isso ajudar. Se a pergunta pedir um efeito causal ou uma análise que não foi feita, explique o alcance do estudo e qual análise adicional seria necessária.

## Distinções para manter na fala

**Incidência anual e razão acumulada.** A primeira usa população do ano; a segunda divide os casos de todo o período pela população média. A taxa por pessoas-ano tem outro denominador.

**Moran global e LISA.** O global foi avaliado por aproximação analítica; o LISA, por simulações condicionais com valor-p bilateral pela posição da estatística observada.

**RR e significância.** O RR mede contraste. A significância da varredura considera a estatística da busca, sob a referência nula e as restrições adotadas.

**Padronização e regressão.** Nesta aplicação, as covariáveis definem estratos para os esperados; não foram ajustadas como regressoras. Há estimação de taxas basais e de contrastes espaciais, sem efeitos estimados das covariáveis.

**Calor e redução do WMAPE.** A queda de 10,2 pontos percentuais é uma redução da discrepância interna à amostra. Não quantifica uma fração causal dos casos atribuível ao calor.

**Duas recorrências.** Anos epidêmicos contam anos com incidência acima do limiar. Inclusão entre formulações conta em quantas das oito análises o município pertence a zonas significativas.

**Centro da janela.** O nome do município identifica o centro da zona candidata. Não localiza a origem da transmissão nem resume sozinho o risco de todos os municípios incluídos.

## Slide 1: Abertura

### Fala sugerida

Sou Lucas Batista de Oliveira e apresento minha monografia em Estatística, desenvolvida na Universidade Federal Fluminense, sob orientação do professor Rafael Santos Erbisti. Neste trabalho, estudei a distribuição espacial da dengue no Brasil entre 2010 e 2025, buscando identificar áreas com excesso de casos em relação à população e entender como a delimitação dessas áreas depende das escolhas da análise.

Vou começar pelo problema e pela construção da base. Depois, vou me deter nos métodos: como a vizinhança entra no cálculo da autocorrelação, como se define o número esperado de casos e como a varredura avalia uma zona candidata. A partir dessa referência, apresentarei os resultados e as comparações entre as formulações, encerrando com os limites da investigação.

### Onde apontar

Título e identificação do orientador; manter contato com a banca.

### Lembrete para a fala

Não antecipar os principais números; falar o título sem pressa.

### Se a banca perguntar

Qual é a pergunta estatística central?

Onde estão os excessos espaciais de notificações e quanto sua delimitação depende dos esperados e do período.

### Ligação com o próximo slide

Para situar essa pergunta, começo pelo contexto da dengue no território brasileiro.

## Slide 2: Dengue e heterogeneidade territorial

### Fala sugerida

Parto de um problema que é epidemiológico, mas que exige uma comparação estatística cuidadosa. A dengue faz parte de um conjunto de arboviroses que inclui Zika e chikungunya, transmitidas por vetores como o Aedes aegypti. No Brasil, essas doenças circulam em territórios muito diferentes, e a dengue apresenta epidemias recorrentes e ampla distribuição. Esse contexto torna insuficiente olhar apenas para o total nacional ou para uma lista de municípios com muitos casos.

A literatura que eu reuni na introdução discute tanto as condições ambientais quanto as desigualdades sociais. Temperatura, ocupação urbana, condições de moradia e regularidade do abastecimento de água podem acompanhar diferenças na transmissão. Isso não significa que uma única característica explique o padrão observado. Para começar a comparar os municípios, eu preciso considerar quantas pessoas estão expostas. Uma cidade com mais casos pode ter mais habitantes; por isso, a análise passa da contagem para medidas relativas à população e, depois, para a organização espacial dessas medidas.

### Onde apontar

Primeiro tópico para o contexto; segundo para as diferenças territoriais; último para a necessidade de denominador.

### Lembrete para a fala

Não transformar contexto bibliográfico em resultado causal do trabalho.

### Se a banca perguntar

Por que não comparar somente o número de casos?

Porque a contagem depende do tamanho da população. O estudo compara taxas e excessos diante de uma referência populacional.

### Ligação com o próximo slide

Essa heterogeneidade já aparece em estudos locais e nacionais; vou indicar como o meu recorte se relaciona com eles.

Referências de apoio: gould2017, parums2025, power2022, pescarini2022.

## Slide 3: Antecedentes e recorte do estudo

### Fala sugerida

Na revisão, eu encontrei estudos em escalas distintas. No Rio de Janeiro, pesquisas descreveram concentração de arboviroses em áreas socialmente mais vulneráveis e diferenças associadas à infraestrutura. Também há estudos nacionais: Lee e colaboradores e Lowe e colaboradores examinaram relações entre a distribuição da dengue, condições climáticas e urbanização. O recorte que adotei combina cobertura nacional, um período longo e recente e a comparação entre referências estatísticas.

Os métodos também respondem a perguntas diferentes. Com Moran, eu avalio se municípios vizinhos apresentam valores semelhantes; com os indicadores locais, observo onde essas associações aparecem. A varredura procura zonas com mais casos que o esperado sob uma hipótese definida. Minha contribuição está em aplicar essas abordagens ao painel nacional de 2010 a 2025 e comparar oito formulações da mesma varredura. Examino, assim, se a geografia dos excessos permanece quando altero a referência socioambiental e quando retiro o ano de 2024.

### Onde apontar

Percorrer os três itens e concluir na frase com cobertura nacional, 16 anos e oito formulações.

### Lembrete para a fala

Evitar dizer que a pesquisa é a primeira ou que não existem estudos nacionais.

### Se a banca perguntar

Qual é a lacuna se já existem estudos nacionais?

A combinação de varredura nacional em período longo e recente com comparação explícita de oito referências e sensibilidade a 2024.

### Ligação com o próximo slide

Com esse recorte, os objetivos podem ser apresentados de forma mais precisa.

Referências de apoio: 2023-souza-santos-sobral-perisse, 2021-queiroz-medronho, almeida2009, lee2021, lowe2021, moran1950, anselin1995, kulldorff1997spatial.

## Slide 4: Objetivos

### Fala sugerida

O objetivo geral que eu estabeleci foi descrever a distribuição espacial do risco de dengue no Brasil entre 2010 e 2025. Para desenvolver essa descrição, eu organizei a investigação em etapas que se complementam. Primeiro, examinei a evolução das notificações e da incidência, procurando reconhecer os anos de maior intensidade e os contrastes entre municípios.

Em seguida, avaliei a autocorrelação global e local e usei a varredura para delimitar zonas de alto risco. A comparação final pergunta quanto essas zonas mudam quando o esperado considera diferentes estratos socioambientais e quando 2024 é retirado. Não estimei efeitos individuais das covariáveis, como faria numa investigação causal. O interesse é comparar as referências e descrever o excesso que permanece em cada uma delas.

### Onde apontar

Objetivo geral e sequência dos quatro objetivos específicos.

### Lembrete para a fala

Usar os objetivos para orientar a exposição, sem ler cada item literalmente.

### Se a banca perguntar

O estudo pretende explicar as causas da dengue?

Não. A comparação é ecológica e exploratória; descreve padrões e sensibilidade das zonas às referências adotadas.

### Ligação com o próximo slide

Antes das fórmulas, preciso definir a unidade observada e o território que permaneceu constante.

## Slide 5: Desenho e unidade de análise

### Fala sugerida

Trabalhei com um estudo ecológico, no qual a unidade espacial é o município. O painel reúne 5.564 municípios observados em cada um dos 16 anos, totalizando 89.024 observações. Para que essa comparação tivesse o mesmo significado territorial ao longo da série, eu adotei a malha municipal de 2010. Os municípios criados posteriormente foram reatribuídos aos territórios de origem, e Fernando de Noronha ficou fora do painel espacial.

Essa estrutura permite duas leituras. Para acompanhar a evolução, eu uso a incidência e o Moran calculados ano a ano. Para o LISA e para a varredura, eu resumo os casos do período inteiro. A varredura continua sendo puramente espacial: ela localiza excesso acumulado, mas não determina o momento em que cada zona surgiu nem quanto tempo permaneceu ativa.

### Onde apontar

Produto 5.564 × 16 e distinção entre análises anuais e acumuladas.

### Lembrete para a fala

Dizer estudo ecológico e distinguir painel longitudinal de varredura espaço-temporal.

### Se a banca perguntar

Por que não usar a malha mais recente?

A malha fixa torna os territórios comparáveis ao longo dos anos; alterações municipais foram harmonizadas retroativamente.

### Ligação com o próximo slide

A partir dessa unidade comum, integrei fontes com periodicidades e resoluções diferentes.

## Slide 6: Fontes e compatibilização

### Fala sugerida

Para formar essa base, eu reuni fontes que medem aspectos diferentes do problema. Os casos vêm do SINAN, organizados pelo município de residência e pelo ano de notificação. O IBGE fornece a população, a malha e os indicadores censitários de saneamento. As séries climáticas incluem temperatura e umidade das reanálises e precipitação obtida de estações e espacializada para os municípios. A área urbanizada anual vem do MapBiomas.

Precisei compatibilizar todas essas informações com a mesma referência territorial. Também mantive a distinção entre o que varia anualmente e o que representa uma fotografia censitária: o saneamento corresponde a 2022, aplicado como característica fixa. Nem toda variável apresentada na descrição entra como ajuste da varredura. Chuva e umidade ajudam a caracterizar os municípios, enquanto os ajustes seguem as sete estratificações definidas nos métodos.

### Onde apontar

Coluna das fontes, depois diferenças entre séries e Censo 2022.

### Lembrete para a fala

Se perguntado, umidade de 1.000 hPa não é uma medida exatamente na superfície.

### Se a banca perguntar

Todas as variáveis foram usadas para ajustar a varredura?

Não. Chuva e umidade são descritivas; a varredura compara as sete estratificações especificadas, uma por vez.

### Ligação com o próximo slide

A integração das fontes depende de uma etapa anterior de tratamento dos registros de dengue.

## Slide 7: Dos registros ao painel espacial

### Fala sugerida

Não comecei a análise espacial diretamente dos arquivos anuais. Primeiro, apliquei os critérios de classificação dos casos, retirando descartados, outras arboviroses e registros sem classificação final válida para o painel. Também removi duplicações entre arquivos e tratei códigos municipais que precisavam de correspondência com a malha de 2010. Depois disso, agreguei as notificações por município de residência e ano.

O painel espacial resultante reúne 22.098.006 casos prováveis. Esse total é a referência dos mapas e da varredura. No texto, há também um perfil descritivo bruto, construído com uma regra mais ampla de inclusão. Mantenho esses universos separados, porque misturar um total de casos de um universo com a população de outro alteraria a interpretação das medidas. A conferência territorial e dos totais fez parte da preparação da base.

### Onde apontar

Etapas de depuração e harmonização; concluir no total do universo espacial.

### Lembrete para a fala

Não usar o total bruto como numerador da incidência espacial.

### Se a banca perguntar

Por que o perfil bruto e o painel espacial têm totais distintos?

Os critérios de classificação e de inclusão territorial são distintos. Os resultados espaciais usam o painel de 22.098.006 casos.

### Ligação com o próximo slide

Com o universo definido, posso explicar os denominadores das medidas que aparecem nos gráficos.

## Slide 8: Incidência anual e razão acumulada

### Fala sugerida

Uso duas medidas que têm numeradores e denominadores diferentes. Na incidência anual, divido os casos de um município em determinado ano pela população daquele mesmo ano e multiplico por cem mil. Isso permite comparar municípios de tamanhos diferentes e acompanhar a série. Na medida acumulada, somo os casos dos 16 anos e divido pela população média municipal do período.

A medida acumulada resume a carga ao longo da série e será usada nos mapas e na análise local. Ela não é uma taxa anual nem a porcentagem de moradores que adoeceram: uma mesma pessoa pode apresentar episódios em anos distintos. Quando uso pessoas-ano, o denominador é a soma das populações anuais. Como o painel tem 16 anos para todos os municípios, essa taxa corresponde à razão acumulada dividida por 16.

### Equação no slide

$$
TI_{it}=10^5\frac{C_{it}}{P_{it}},\qquad
TI_{i,\mathrm{acum}}=10^5\frac{\sum_{t=2010}^{2025} C_{it}}{\overline P_i}
$$

### Para entender e explicar

**O que entra em cada denominador.** Na incidência anual, casos e população se referem ao mesmo ano. Na razão acumulada, somam-se os casos dos dezesseis anos e usa-se a população média. Na taxa por pessoas-ano, o denominador soma as populações anuais.

**Por que dividir a razão acumulada por dezesseis.** No painel completo, a soma das populações anuais é dezesseis vezes a população média. Por isso, mantendo o mesmo total de casos, a taxa por pessoas-ano equivale à razão acumulada dividida por dezesseis.

### Exemplo para estudar

Exemplo didático fictício: um município mantém 10.000 habitantes por dezesseis anos e registra 100 casos em cada ano. A incidência anual é 1.000 por 100 mil habitantes. Com 1.600 casos acumulados, a razão por população média é 16.000 por 100 mil habitantes. A taxa por pessoas-ano usa 160.000 pessoas-ano e vale 1.000 por 100 mil pessoas-ano. As medidas têm escalas temporais diferentes.

### Onde apontar

Numeradores e denominadores das duas expressões; fechar na relação com pessoas-ano.

### Lembrete para a fala

Pronunciar por cem mil e diferenciar população média de soma das populações.

### Se a banca perguntar

A razão acumulada pode ser interpretada como probabilidade individual?

Não. Ela divide episódios acumulados pela população média e pode incluir adoecimentos repetidos da mesma pessoa.

### Ligação com o próximo slide

Essas medidas precisam, então, de uma definição de vizinhança para que eu examine sua organização espacial.

## Slide 9: Vizinhança e pesos espaciais

### Fala sugerida

Antes de calcular associação espacial, eu preciso definir o que vou considerar próximo. Neste trabalho, considerei vizinhos os municípios que compartilham uma fronteira ou apenas um vértice. É a contiguidade chamada queen. Apliquei essa regra sobre a mesma malha de 2010 usada em todo o estudo, para que a referência territorial não mudasse entre os anos.

Depois, dividi igualmente o peso entre os vizinhos de cada município. Assim, a soma dos pesos de cada linha é um, e a comparação com o entorno passa a usar uma média dos vizinhos. Também tratei a única unidade sem vizinho por contiguidade, atribuindo a ela o município mais próximo. Com essa definição, consigo calcular os índices para todas as unidades do painel.

### Equação no slide

$$
w_{ij}=\begin{cases}1/n_i,&j\text{ é vizinho de }i,\\0,&\text{caso contrário},\end{cases}
\qquad w_{ii}=0
$$

### Para entender e explicar

**$w_{ij}$ e $n_i$.** O primeiro é o peso do município j na vizinhança de i; o segundo é o número de vizinhos de i. Cada vizinho recebe 1 dividido por esse número. O município não é vizinho de si mesmo.

**Padronização por linha.** Ela dá o mesmo peso total às vizinhanças, embora seus tamanhos sejam diferentes. Com quatro vizinhos, cada peso é 0,25; com dez, 0,10. Isso não torna os pesos recíprocos necessariamente iguais.

**Escolha territorial.** Contiguidade é uma aproximação geográfica da proximidade. Ela não mede deslocamentos de pessoas ou conexões de transporte, nem demonstra transmissão entre os municípios.

### Lembrete para a fala

Apontar a divisão pelo número de vizinhos; evitar dizer que a matriz comprova conexões de transmissão.

### Se a banca perguntar

Por que não usar apenas a distância entre os municípios?

Eu adotei uma referência de contato territorial, mantida em todas as análises de autocorrelação. Uma matriz por distância seria uma alternativa metodológica, mas seus resultados dependeriam do limiar e dos pesos escolhidos. Não comparei essas alternativas neste trabalho.

### Ligação com o próximo slide

Com a vizinhança definida, eu posso avaliar se municípios próximos apresentam incidências semelhantes.

## Slide 10: Índice Global de Moran

### Fala sugerida

Usei o Moran global para resumir a organização espacial da incidência em cada ano. A ideia é comparar o desvio de um município em relação à média com os desvios dos seus vizinhos. Quando os dois lados estão acima da média, o produto é positivo. O mesmo acontece quando ambos estão abaixo. Quando os sinais são opostos, a contribuição é negativa.

Somo essas contribuições, considerando os pesos espaciais, e normalizo pela variação da incidência entre os municípios. Por isso, o índice descreve o padrão espacial, e não o tamanho da epidemia. Posso ter um ano de incidência relativamente baixa com associação espacial positiva. Neste estudo, eu fiz esse cálculo separadamente para cada um dos dezesseis anos.

### Equação no slide

$$
I=\frac{n}{S_0}\frac{\sum_i\sum_jw_{ij}(y_i-\bar y)(y_j-\bar y)}{\sum_i(y_i-\bar y)^2},
\qquad S_0=\sum_i\sum_jw_{ij}
$$

### Para entender e explicar

**$y_i-\bar y$.** É o desvio da incidência municipal em relação à média entre municípios naquele ano. Os municípios participam dessa média como unidades espaciais; não se trata da taxa nacional ponderada pela população.

**Numerador e denominador.** O numerador reúne produtos de desvios entre vizinhos. O denominador soma os quadrados dos desvios e ajusta a escala à dispersão total. Não se deve interpretar só o numerador.

**$n/S_0$.** n é o número de municípios e S_0 é a soma de todos os pesos. Com as linhas somando um e sem linhas vazias, essa soma coincide com n; a fórmula geral mantém o fator explícito.

### Lembrete para a fala

Apontar produtos de desvios com sinais iguais e opostos. Índice alto não é sinônimo de incidência alta.

### Se a banca perguntar

O Moran varia sempre de menos um a um?

Os limites possíveis dependem da matriz de pesos. Eu interpreto o sinal, a magnitude no contexto da mesma matriz e o teste associado; não trato o índice como uma correlação comum com limites universais de menos um e um.

### Ligação com o próximo slide

Além de calcular o índice, eu preciso avaliar se o valor observado é compatível com a referência de aleatoriedade.

Referências de apoio: moran1950.

## Slide 11: Inferência para o Moran global

### Fala sugerida

Para interpretar o Moran, eu comparo o índice observado com o que seria esperado sob aleatoriedade espacial. Essa referência não tem esperança exatamente zero: ela é ligeiramente negativa e depende do número de municípios. Retiro essa esperança do valor observado e divido pelo desvio-padrão previsto sob a hipótese nula. É essa padronização que aparece na segunda equação.

Na aplicação, eu usei uma aproximação analítica da distribuição dessa estatística, com teste unilateral para associação positiva. Minha pergunta foi se o padrão observado apresentava mais semelhança entre vizinhos do que a referência nula permitiria esperar. Repeti esse procedimento em cada ano, com nível de cinco por cento. Esses são dezesseis testes anuais, e não um único teste conjunto do período.

### Equação no slide

$$
H_0:\ \text{aleatoriedade espacial},\qquad
\mathbb E_0(I)=-\frac{1}{n-1}
$$

$$
Z_I=\frac{I-\mathbb E_0(I)}{\sqrt{\operatorname{Var}_0(I)}}
$$

### Para entender e explicar

**$\mathbb E_0(I)$.** A esperança nula é -1/(n-1). O subscrito zero indica que ela pertence à hipótese de aleatoriedade. Com milhares de municípios, o valor fica próximo de zero, mas a expressão correta foi preservada.

**$Z_I$.** Mede a distância entre o índice observado e sua esperança nula em unidades de desvio-padrão. A variância usada é a de referência do teste, não a variância simples das incidências municipais.

**Analítico e unilateral.** A referência de significância usa aproximação normal para a estatística padronizada sob aleatoriedade. A direção positiva corresponde à pergunta adotada; este procedimento difere das simulações condicionais usadas no LISA.

### Lembrete para a fala

Não dizer que o Moran global usou as 999 simulações do LISA; não interpretar valor-p como probabilidade de a hipótese nula ser verdadeira.

### Se a banca perguntar

Esses testes provam que os municípios transmitem dengue entre si?

Não. Eles avaliam a organização espacial das incidências. A associação pode acompanhar características compartilhadas ou outros processos, mas o teste não identifica mecanismos de transmissão nem separa seus efeitos.

### Ligação com o próximo slide

Esse resultado é nacional. Para localizar os padrões de associação, eu passo ao Moran local.

## Slide 12: Moran local e interpretação dos quadrantes

### Fala sugerida

No Moran local, eu mantenho a mesma ideia dos desvios, mas calculo uma contribuição para cada município. Aqui eu uso a razão acumulada do período. Observo se o município está acima ou abaixo da média e comparo esse sinal ao comportamento médio de seus vizinhos. Isso permite distinguir áreas alto-alto e baixo-baixo das áreas que contrastam com o entorno.

Para avaliar a significância, eu mantenho fixos o valor daquele município e os pesos da vizinhança. Sorteio, com reposição, valores dos demais municípios e recalculo a estatística, repetindo isso 999 vezes. A posição da estatística observada nessa distribuição fornece o valor-p bilateral. Combino essa avaliação com o quadrante, usando cinco por cento, sem correção para comparações múltiplas. Por isso, minha interpretação é exploratória.

### Equação no slide

$$
I_i=\frac{y_i-\bar y}{S^2}\sum_jw_{ij}(y_j-\bar y),
\qquad S^2=\frac1n\sum_i(y_i-\bar y)^2
$$

### Para entender e explicar

**$I_i$ e $S^2$.** O desvio local multiplica a média ponderada dos desvios vizinhos e é dividido pela variância com divisor n. O índice pode ser positivo tanto em alto-alto como em baixo-baixo; seu sinal não distingue esses quadrantes sozinho.

**Hipótese condicional.** A observação focal e os pesos ficam fixos. Os valores atribuídos às posições vizinhas são sorteados entre os demais municípios. Há reposição nesse sorteio, portanto simulação condicional descreve melhor a operação do que uma troca única de rótulos.

**Bilateral por simulação.** A implementação usa postos da estatística observada na distribuição simulada, com tratamento de empates. Não se usa a fórmula empírica de Monte Carlo da varredura nem a aproximação normal do Moran global.

### Lembrete para a fala

Não confundir alto-alto com RR alto; não anunciar cada teste municipal como confirmação independente.

### Se a banca perguntar

Um município sem significância não tem dengue ou não merece atenção?

Nenhuma dessas conclusões decorre do teste. Ele não atingiu o critério nominal de associação local com aquela referência. O município pode ter casos, incidência elevada ou outras necessidades de vigilância.

### Ligação com o próximo slide

O LISA localiza associações entre vizinhos. A varredura vai procurar zonas com excesso de casos diante de uma referência populacional.

Referências de apoio: anselin1995.

## Slide 13: Varredura espacial de Poisson

### Fala sugerida

Na varredura, mudo a pergunta. Em vez de procurar semelhança entre taxas vizinhas, eu procuro uma zona com mais casos do que seria esperado diante da população que ela reúne. Represento a contagem nessa zona por uma distribuição de Poisson, cuja média depende da exposição populacional. A contagem aleatória é indicada por Y; o número efetivamente observado vai aparecer como C.

No modelo sem ajuste, eu comparo a hipótese de uma intensidade comum dentro e fora da zona com uma alternativa de intensidade maior no interior. Examino várias zonas candidatas com esse mesmo princípio. Como a análise reúne os casos do período, ela é puramente espacial: eu localizo o excesso acumulado, sem estimar em que momento cada zona surgiu.

### Equação no slide

$$
Y_Z\sim\operatorname{Poisson}(\mu_Z),\qquad\mathbb E(Y_Z)=\mu_Z.
$$

$$
H_0:p=q,\qquad H_1:p>q\text{ para alguma }Z\in\mathcal Z,
$$

### Para entender e explicar

**$Y_Z$ e $\mu_Z$.** Y_Z representa a variável de contagem da zona; mu_Z, sua média. Na Poisson, média e variância coincidem. Essa igualdade é uma hipótese do modelo de referência, não uma propriedade demonstrada apenas porque a entrada contém números inteiros.

**$p$ e $q$.** Neste slide, p e q são intensidades dentro e fora da zona. Não são valores-p. A hipótese de igualdade se aplica ao modelo sem ajuste; na padronização, a referência basal poderá variar entre estratos.

**População sob risco.** A entrada espacial usa população média do período e casos acumulados. Não se ajusta aqui um modelo de série temporal ou uma varredura espaço-temporal com cilindros.

### Lembrete para a fala

Apresentar Poisson como hipótese de trabalho. Não afirmar que superdispersão ou independência foram comprovadas.

### Se a banca perguntar

Por que usar Poisson e não comparar diretamente os números de casos?

Eu preciso considerar que municípios e zonas têm tamanhos populacionais diferentes. O modelo permite formular uma expectativa proporcional à população e avaliar excessos de contagem em relação a essa expectativa, sob hipóteses explícitas.

### Ligação com o próximo slide

Essa referência populacional fica mais clara quando eu escrevo o número esperado de casos.

## Slide 14: Casos esperados sob risco homogêneo

### Fala sugerida

Construo o esperado a partir de uma regra simples: sob risco homogêneo, a participação de uma área nos casos deve acompanhar sua participação na população. Primeiro, calculo a fração da população nacional que está no município. Depois, multiplico essa fração pelo total nacional de casos. Para uma zona, eu somo os esperados dos municípios que ela contém.

Essa construção preserva o total de casos. O que muda é a distribuição desse total pelo território. Assim, não estou comparando a observação com um objetivo de controle da doença; estou comparando com uma hipótese estatística de distribuição. A partir dela, eu verifico se uma zona reúne mais casos do que sua participação populacional faria esperar.

### Equação no slide

$$
E_i=C_G\frac{N_i}{N_G},\qquad
E_Z=\sum_{i\in Z}E_i=C_G\frac{N_Z}{N_G}
$$

### Para entender e explicar

**$C_G$ e $N_G$.** C_G é o total nacional de casos observados no painel. N_G é a soma das populações médias municipais. A fração N_i/N_G é adimensional; multiplicada pelo total de casos, produz um esperado em número de casos.

**$E_i$ e $E_Z$.** O primeiro se refere ao município; o segundo soma os municípios da zona. A soma de todos os esperados nacionais é igual ao total observado, mas isso não exige igualdade em cada município.

**Média populacional.** Como todos os municípios têm os mesmos dezesseis anos, usar população média ou pessoas-ano resulta nas mesmas participações espaciais. Essa equivalência não transforma a razão acumulada em taxa anual.

### Lembrete para a fala

Usar a expressão sob risco homogêneo. Antecipar que o ajuste por covariáveis mudará a referência dos esperados.

### Se a banca perguntar

O esperado representa quantos casos realmente deveriam ocorrer?

Ele é o valor esperado sob a hipótese adotada. Não é uma quantidade clinicamente desejável, uma previsão independente ou o total verdadeiro de infecções, que pode diferir das notificações.

### Ligação com o próximo slide

Eu aplico essa comparação às diferentes zonas permitidas pelo desenho da busca.

## Slide 15: Janelas candidatas e desenho da busca

### Fala sugerida

Defini as zonas candidatas usando círculos centrados nos centroides municipais. Para cada centro, o raio aumenta e passa a incluir novos municípios. Em cada tamanho, eu recalculo a comparação entre casos observados e esperados. A busca, portanto, percorre várias posições e tamanhos antes de selecionar as zonas reportadas.

Usei dois limites ao mesmo tempo: no máximo dezesseis por cento da população e duzentos quilômetros de raio. Uma janela pode atingir um desses limites antes do outro. Esses valores fazem parte do desenho definido com o orientador e foram mantidos nas oito formulações. Não os estimo pelos resultados. Manter essa regra permite comparar as mudanças produzidas pelos diferentes esperados sem trocar também a escala espacial permitida.

### Para entender e explicar

**Entrada de municípios.** A inclusão ocorre quando o centro representativo de outra unidade passa a integrar o círculo. A zona reúne municípios inteiros para as contagens; ela não divide casos conforme a área geométrica coberta de cada polígono.

**Dois tetos.** O teto populacional limita o tamanho relativo da zona e o teto em quilômetros limita sua extensão geográfica. Ambos restringem as soluções possíveis; outros limites poderiam produzir outra coleção de zonas.

**Forma circular.** É uma aproximação operacional de concentração espacial. Uma zona pode incluir municípios sem excesso individual e deixar de acompanhar padrões alongados ou irregulares. O centro da janela não identifica a origem da transmissão.

### Lembrete para a fala

Apontar os dois tetos simultâneos. Evitar dizer que a janela sempre atinge ambos ou que os círculos representam fronteiras epidemiológicas reais.

### Se a banca perguntar

Por que exatamente dezesseis por cento e duzentos quilômetros?

Esses parâmetros integram o desenho acordado com o orientador para limitar a extensão das zonas. Meu estudo compara formulações sob esse desenho comum; não demonstra que esses limites sejam ótimos ou universalmente adequados.

### Ligação com o próximo slide

Para escolher entre as janelas permitidas, eu calculo uma razão de verossimilhança.

## Slide 16: Razão de verossimilhança

### Fala sugerida

Comparo quanto os dados são compatíveis com duas descrições: uma intensidade comum no território e uma intensidade maior dentro de determinada zona. Como eu condiciono ao total nacional de casos, a questão passa a ser quantos desses casos estão dentro da zona. Sob a hipótese nula, essa parcela acompanha a população; sob a alternativa, ela acompanha a proporção de casos que eu observei.

A razão entre essas compatibilidades gera a expressão do slide. Um fator representa o interior, e o outro representa o exterior. Se não há excesso, eu uso razão igual a um, porque a busca é apenas de alto risco. Calculo a razão em todas as zonas permitidas e escolho o máximo. A zona que o produz é a primária, o que não significa que ela tenha o maior RR.

### Equação no slide

$$
\lambda(Z)=\begin{cases}
\left(\dfrac{C_Z}{E_Z}\right)^{C_Z}
\left(\dfrac{C_G-C_Z}{C_G-E_Z}\right)^{C_G-C_Z},&C_Z>E_Z,\\[5pt]
1,&C_Z\leq E_Z.
\end{cases}
$$

$$
\lambda^\ast=\max_{Z\in\mathcal Z}\lambda(Z),\qquad
\widehat Z=\arg\max_{Z\in\mathcal Z}\lambda(Z).
$$

### Para entender e explicar

**Ligação entre Poisson e binomial.** Com contagens Poisson independentes sob a referência e condicionado o total, a contagem dentro de uma zona segue uma binomial. Sua probabilidade nula é N_Z/N_G; a estimativa alternativa é C_Z/C_G.

**Origem dos dois fatores.** Ao dividir as probabilidades binomiais maximizadas, o coeficiente combinatório comum cancela. Restam os contrastes observado/esperado dentro e fora, elevados às respectivas contagens.

**$\lambda(Z)$, $\lambda^\ast$ e $\widehat Z$.** A primeira avalia uma zona. A segunda é o maior valor da busca. A terceira indica qual zona o atingiu. A convenção 0^0=1 trata termos de contagem zero no limite; razão grande ainda exige avaliação de significância.

### Lembrete para a fala

Explicar a lógica dos dois fatores, sem recitar expoentes. Não confundir razão, log-razão e valor-p.

### Se a banca perguntar

Por que não selecionar a zona só pelo maior observado dividido por esperado?

Esse quociente não considera sozinho a informação do exterior nem o volume de casos. A razão de verossimilhança compara os dois ajustes e usa as contagens; depois eu avalio o máximo com uma referência que repete a busca.

### Ligação com o próximo slide

Como a melhor janela já foi escolhida entre muitas, eu preciso incorporar essa busca à avaliação de significância.

Referências de apoio: kulldorff1997spatial.

## Slide 17: Monte Carlo e significância da busca

### Fala sugerida

Não trato a janela selecionada como se ela tivesse sido escolhida antes de olhar os dados. A varredura procurou o melhor resultado em muitas janelas. Para respeitar essa seleção, eu gero réplicas sob a hipótese nula e repito a busca completa em cada uma. Em cada réplica, eu guardo o maior valor encontrado, exatamente como fiz com os dados observados.

Depois, comparo o máximo observado com os 999 máximos simulados. A fórmula empírica mostrada conta quantos deles são pelo menos tão grandes quanto o observado, acrescenta um e divide pelo total de posições possíveis. Assim, avalio quão incomum é encontrar um máximo desse tamanho sob a referência nula. O reporte usa cinco por cento e mantém zonas secundárias sem sobreposição.

### Equação no slide

$$
p_{\mathrm{MC}}=\frac{1+\sum_{b=1}^{B}\mathbf1(\lambda^\ast_b\geq\lambda^\ast_{\mathrm{obs}})}{B+1}
$$

### Para entender e explicar

**O que é preservado.** As réplicas usam a hipótese nula e o total de casos como referência. Nos ajustados, seguem a randomização do programa com os esperados padronizados; não pressupor uma permutação independente que fixe separadamente cada total de estrato.

**Indicador e correção.** O símbolo indicador vale um quando o máximo simulado atinge ou supera o observado. O acréscimo de um inclui a posição observada e evita valor-p zero na forma empírica básica.

**Resolução e reporte.** Com 999 réplicas, a fórmula tem resolução mínima de 0,001. O modo de reporte do programa e as zonas secundárias devem ser interpretados conforme sua implementação; não há demonstração aqui de controle geral de toda a coleção. Exigem-se ao menos dois casos na zona reportada.

### Lembrete para a fala

Este valor-p não é o do LISA. Não falar em probabilidade de a zona existir nem reproduzir valor-p igual a zero.

### Se a banca perguntar

Por que não comparar cada janela observada a uma janela simulada?

Porque meu resultado principal é um máximo selecionado. Compará-lo a uma janela qualquer ignoraria a vantagem de procurar entre muitas possibilidades. Por isso, a mesma seleção é repetida nas réplicas.

### Ligação com o próximo slide

A significância indica incompatibilidade com a referência; o risco relativo descreve o tamanho do contraste da zona.

## Slide 18: Risco relativo de uma zona

### Fala sugerida

Uso o risco relativo para descrever a intensidade do contraste. Na expressão do modelo sem ajuste, eu divido os casos pela população dentro da zona e faço a mesma conta no exterior. Depois, comparo essas duas taxas. Assim, um valor próximo de dois representa uma taxa interna aproximadamente duas vezes a externa, para o período e a população considerados.

Separo essa leitura da significância e da seleção da zona primária. Um contraste alto pode envolver poucos casos; uma zona de contraste menor pode reunir um volume muito maior. Nos modelos ajustados, eu interpreto o RR com a referência padronizada do programa, porque os esperados já admitem diferenças entre os estratos. Não aplico automaticamente a razão bruta a esses resultados.

### Equação no slide

$$
RR_Z=\frac{C_Z/N_Z}{(C_G-C_Z)/(N_G-N_Z)}
$$

### Para entender e explicar

**Interior e exterior.** C_G menos C_Z é a contagem fora da zona; N_G menos N_Z é a população correspondente. O exterior é parte do cálculo, não apenas um grupo omitido na comparação.

**Relação com o esperado.** Sem ajuste, substituir E_Z=C_G N_Z/N_G mostra que o RR também é a razão entre observado/esperado no interior e observado/esperado no exterior. Somente C_Z/E_Z não fornece o RR da zona.

**Limite da interpretação.** O RR se refere ao conjunto da zona, não a cada município individual nem a uma probabilidade pessoal de adoecer. Nos ajustes, mudanças de referência e composição impedem interpretar diferenças entre primários como redução causal de risco.

### Lembrete para a fala

Apontar a taxa externa; não dizer que RR igual a dois significa duzentos por cento a mais.

### Se a banca perguntar

Se o RR diminui depois do ajuste por calor, o calor explica essa redução?

Eu não posso concluir isso. O ajuste muda os esperados e pode mudar os municípios da zona. A diferença descreve sensibilidade à referência térmica, sem estimar quanto do risco foi causado pelo calor.

### Ligação com o próximo slide

Eu reuni essas contas em um exemplo fictício para mostrar como esperado, RR e verossimilhança se relacionam.

## Slide 19: Exemplo de cálculo para uma zona

### Fala sugerida

Aqui eu uso valores fictícios apenas para mostrar as contas. Imagino mil casos no país e uma zona com dez por cento da população. Sob risco homogêneo, eu espero cem casos nessa zona. Se observo cento e oitenta, o interior tem mais casos que o esperado; no exterior, sobram oitocentos e vinte observados diante de novecentos esperados.

Para calcular o RR, eu comparo esses dois contrastes e chego a aproximadamente um vírgula noventa e oito. Para a razão de verossimilhança, eu uso o logaritmo, que transforma o produto em soma e facilita a conta. O resultado é aproximadamente vinte e nove vírgula quarenta e sete. Ainda não atribuo significância a esse número: preciso compará-lo aos máximos das buscas simuladas.

### Equação no slide

$$
E_Z=1.000\times0{,}10=100
$$

$$
RR_Z=\frac{180/100}{820/900}\approx1{,}98
$$

$$
\ell(Z)=\log\lambda(Z)=180\log(1{,}8)+820\log(820/900)\approx29{,}47
$$

### Para entender e explicar

**Primeira conta.** O esperado usa a fração populacional: 1.000 multiplicado por 0,10 produz 100. O esperado externo é 1.000 menos 100, ou 900. As partes observadas e esperadas precisam somar o mesmo total nacional.

**Segunda conta.** O interior tem observado/esperado igual a 1,8. O exterior tem 820/900, aproximadamente 0,9111. Dividir 1,8 por 0,9111 produz RR aproximado de 1,9756.

**Terceira conta.** A transformação usa logaritmo natural. O termo interno é positivo e o externo, negativo. A soma é 29,46745. Esse valor é log lambda, não lambda; a transformação mantém a ordenação entre zonas.

### Exemplo para estudar

Exemplo didático fictício conferido: $E_Z=100$; $RR_Z=(180/100)/(820/900)=1{,}975609756$; $\ell(Z)=\log\lambda(Z)=180\log(1{,}8)+820\log(820/900)=29{,}467452768$.

### Lembrete para a fala

Dizer fictício antes de iniciar. Diferenciar RR, log-razão e valor-p; não transformar o exemplo em resultado do Brasil.

### Se a banca perguntar

O valor 29,47 significa que a zona é significativa?

Isoladamente, não. Ele resume a comparação de ajustes para essa zona. A inferência da busca depende de sua posição em relação aos máximos obtidos sob a hipótese nula e do procedimento de reporte.

### Ligação com o próximo slide

Com a varredura definida, eu apresento como construí as covariáveis usadas para mudar os esperados.

## Slide 20: Ondas de calor: definição do indicador

### Fala sugerida

Para caracterizar o calor, eu comecei pela série diária de temperatura de cada município. A máxima disponível é a maior entre quatro horários do dia, depois agregada pela área de interseção com o município. Não trato essa medida como se fosse a máxima obtida de todas as horas. Com a série completa, eu calculei o percentil noventa local de 2010 a 2025.

Depois, identifiquei sequências de pelo menos três dias consecutivos que atingiram ou ultrapassaram esse limiar. Só entram no indicador os dias pertencentes a uma dessas sequências. Somei esses dias ao longo do período para obter a carga térmica acumulada. O limiar local me permite descrever extremos em relação ao clima de cada município; ele não impõe uma temperatura absoluta comum ao país.

### Equação no slide

$$
q_{i,0{,}90}=P_{90}\{T^{\max}_{id}:2010\text{--}2025\}
$$

### Para entender e explicar

**$q_{i,0{,}90}$.** É o percentil noventa da distribuição empírica das máximas diárias do município. O índice d representa dia, diferentemente do índice anual t. O limiar é fixo por município e calculado com todo o período.

**Sequência e total.** Dois dias consecutivos acima do limiar, isolados de outros dias quentes, não formam episódio. Uma sequência de quatro dias qualificada acrescenta quatro a D_i. A série é processada sem interromper episódios na passagem de dezembro para janeiro.

**Sentido do indicador.** D_i conta dias em episódios. Não conta apenas o número de ondas, não mede graus-dia e não representa uma escala biológica de efeito sobre o vetor. O uso do período completo é retrospectivo.

### Lembrete para a fala

Explicar primeiro limiar, depois sequência, depois soma. Não confundir calor relativo com temperatura absoluta ou resposta causal da dengue.

### Se a banca perguntar

Por que usar percentil local em vez de uma temperatura igual em todo o Brasil?

Eu quis definir extremo em relação à distribuição municipal. Uma temperatura comum selecionaria climas diferentes de outra maneira. A definição adotada é operacional e não demonstra que qualquer dia acima do percentil tenha o mesmo efeito na transmissão.

### Ligação com o próximo slide

Para as covariáveis urbanas, eu precisei primeiro aproximar a população residente em área urbana ao longo dos anos.

## Slide 21: População urbana: interpolação entre censos

### Fala sugerida

Para construir a densidade urbana, eu precisava de uma aproximação da população urbana em cada ano. Tinha a fração de habitantes urbanos nos censos de 2010 e 2022. Entre esses dois pontos, eu usei interpolação linear: distribuo a diferença observada ao longo dos doze anos, respeitando a posição de cada ano no intervalo.

Depois, multiplico a fração estimada pela população anual do município. Assim, não suponho que a quantidade de habitantes urbanos cresceu linearmente; a aproximação linear é aplicada à fração. Para 2023 a 2025, eu mantenho a fração de 2022 e continuo usando a população anual. Também limito as frações ao intervalo de zero a um. Esse procedimento preenche a série sem apresentar estimativas anuais como medições censitárias.

### Equação no slide

$$
f_{i,t}=f_{i,2010}+\frac{t-2010}{12}\bigl(f_{i,2022}-f_{i,2010}\bigr).
$$

$$
P^{\mathrm{urb}}_{i,t}=f_{i,t}\,P_{i,t}.
$$

### Para entender e explicar

**$f_{i,t}$.** É a parcela da população residente classificada como urbana. Nos pontos censitários, vem da divisão entre população urbana e total do próprio censo. Nos anos intermediários, é aproximada pela interpolação.

**Por que dividir por doze.** Entre 2010 e 2022 há doze intervalos anuais. A parcela (t-2010)/12 indica quanto do caminho foi percorrido. O cálculo retorna a fração de 2010 no início e a de 2022 no fim.

**Aplicação à população.** A fração multiplicada pela população anual do painel produz a população urbana aproximada. Repetir a fração de 2022 depois do censo não significa repetir o número absoluto de habitantes urbanos.

### Exemplo para estudar

Exemplo didático fictício: se $f_{i,2010}=0{,}60$ e $f_{i,2022}=0{,}84$, em 2016 obtenho $0{,}60+(6/12)(0{,}24)=0{,}72$. Para população anual de 10.000, a população urbana aproximada é 7.200.

### Lembrete para a fala

Apontar o intervalo de doze anos. A interpolação é da fração, não diretamente da população urbana.

### Se a banca perguntar

Essa interpolação reproduz o crescimento urbano real ano a ano?

Não. É uma aproximação entre dois retratos censitários. Mudanças não lineares e alterações de classificação podem não ser captadas; essa incerteza acompanha a interpretação da densidade construída.

### Ligação com o próximo slide

Com a população urbana aproximada e a área urbanizada anual, eu calculo duas medidas urbanas diferentes.

## Slide 22: Densidade e proporção urbanas

### Fala sugerida

Usei duas medidas para representar dimensões diferentes da urbanização. Na densidade, eu comparo a população urbana com a área urbanizada. A pergunta é quantos habitantes urbanos há por quilômetro quadrado urbanizado. Na proporção urbana, eu comparo a área urbanizada com toda a área municipal. A pergunta passa a ser quanto do território municipal está ocupado por essa classe de uso do solo.

Faço essas divisões em cada ano e depois calculo a média dos dezesseis valores. Portanto, eu uso médias de razões anuais. A área municipal permanece fixa na malha de 2010, enquanto população e área urbanizada podem variar. Essas duas medidas não são intercambiáveis: um município pode ter uma pequena fração urbanizada e, dentro dela, uma concentração populacional elevada.

### Equação no slide

$$
d_i=\frac1{16}\sum_{t=2010}^{2025}\frac{P^{\mathrm{urb}}_{i,t}}{A^{\mathrm{urb}}_{i,t}},
\qquad
u_i=\frac1{16}\sum_{t=2010}^{2025}\frac{A^{\mathrm{urb}}_{i,t}}{A_i}.
$$

### Para entender e explicar

**$d_i$.** A média da população urbana dividida pela área urbanizada tem unidade de habitantes por km² urbanizado. Não é a densidade demográfica de toda a área municipal que aparece em descrições censitárias gerais.

**$u_i$.** É uma proporção territorial, obtida pela área urbanizada sobre a área municipal. Não tem unidade e não é a fração de pessoas que moram em área urbana. Ambas as áreas precisam estar em km².

**Ordem das operações.** Primeiro se calcula cada razão anual, depois se soma e divide por dezesseis. Em geral, a média das razões não equivale à razão entre médias quando o denominador varia; isso importa na densidade, cuja área urbanizada é anual.

### Lembrete para a fala

Apontar os denominadores distintos. Evitar chamar a proporção de área urbanizada de percentual da população urbana.

### Se a banca perguntar

Por que analisar as duas medidas se ambas se referem à urbanização?

Porque representam aspectos diferentes: concentração de habitantes na área urbanizada e ocupação do território municipal. Eu as comparo em formulações separadas para observar como cada classificação muda a referência espacial dos casos esperados.

### Ligação com o próximo slide

Eu transformei esses indicadores e os de saneamento em estratos comparáveis para a padronização.

## Slide 23: Covariáveis e formação dos estratos

### Fala sugerida

Para usar essas covariáveis na padronização, eu ordenei os municípios e dividi cada indicador em três grupos com tamanhos semelhantes. São mil oitocentos e cinquenta e cinco municípios nos dois primeiros níveis e mil oitocentos e cinquenta e quatro no terceiro. Essa organização simplifica a referência basal e permite comparar as formulações com a mesma quantidade de categorias.

Também padronizei a direção da leitura. No calor e nos indicadores urbanos, a ordem vai do menor para o maior valor. Nas coberturas de saneamento, vai da maior para a menor cobertura. Nos empates dos limites, eu mantive os tamanhos dos grupos pela ordem dos registros. Assim, um mesmo valor pode aparecer em níveis vizinhos. Não interpreto esses cortes como limiares biológicos ou causais.

### Para entender e explicar

**Tercis de municípios.** Os grupos equilibram o número de municípios, não sua população, quantidade de casos ou distribuição regional. A taxa de um estrato depende das populações e dos casos agregados de seus integrantes.

**Direção dos níveis.** Nível um significa maior cobertura em água, esgoto e lixo; em calor e nas medidas urbanas, significa menor valor. A ordenação facilita a apresentação, mas não comprova que a incidência cresça monotonicamente do primeiro ao terceiro nível.

**Categorização e perdas.** Municípios próximos de um corte podem cair em grupos diferentes. Municípios distintos dentro do mesmo tercil compartilham a mesma taxa basal de referência. Isso perde parte da variação contínua e torna os resultados dependentes da classificação escolhida.

### Lembrete para a fala

Não chamar os grupos de três populações iguais. Saneamento é o retrato de 2022; as duas medidas urbanas são médias do período.

### Se a banca perguntar

Por que os valores de calor nos limites aparecem repetidos em dois grupos?

Porque há municípios empatados e o procedimento preserva os tamanhos dos grupos. O valor inteiro de dias pode ser o máximo de um nível e o mínimo do seguinte. Não significa que o mesmo município tenha sido contado duas vezes.

### Ligação com o próximo slide

Além dos ajustes por indicador isolado, eu construí uma classificação composta a partir de cinco componentes.

## Slide 24: Índice socioambiental composto

### Fala sugerida

Construí o índice composto somando cinco componentes: dias em ondas de calor, proporção de área urbanizada e as três coberturas de saneamento, orientadas no sentido da carência. Primeiro, divido cada variável pelo seu máximo observado entre os municípios. Para calor e proporção urbana, eu mantenho esse resultado; para as coberturas, eu subtraio o resultado de um.

Depois, somo os cinco componentes com o mesmo peso e divido os municípios em tercis do escore. Um escore maior representa maior valor nessa combinação definida pelo estudo. Não estimei a importância de cada componente nem validei o escore como uma escala geral de vulnerabilidade. Ele funciona aqui como mais uma referência de estratificação para verificar a sensibilidade da geografia dos excessos.

### Equação no slide

$$
S_i=\frac{D_i}{D_{\max}}+
\left(1-\frac{e_i}{e_{\max}}\right)+\frac{u_i}{u_{\max}}
+\left(1-\frac{a_i}{a_{\max}}\right)+
\left(1-\frac{l_i}{l_{\max}}\right)
$$

### Para entender e explicar

**Ordem exata da conta.** A carência de esgoto é $1-e_i/e_{\max}$; o mesmo raciocínio vale para água e lixo. Primeiro se normaliza a cobertura pelo máximo, depois se complementa. Isso difere de normalizar a própria carência por seu máximo.

**Escala e componentes.** Cada termo está entre zero e um, então a soma está entre zero e cinco. Esses são limites possíveis; não implicam que algum município tenha atingido os extremos. Densidade urbana não participa da soma.

**Pesos iguais.** Os cinco termos entram com coeficiente um depois da transformação. Isso iguala suas escalas possíveis, sem garantir igual influência empírica, independência entre componentes ou igual relevância epidemiológica.

### Lembrete para a fala

Ler a operação, não cada fração. Destacar complementação das coberturas e ausência de densidade na soma.

### Se a banca perguntar

Por que não estimar os pesos a partir dos casos de dengue?

Eu usei uma construção descritiva previamente definida para formar estratos. Estimar pesos pelo desfecho exigiria outra estratégia de modelagem e avaliação. O escore atual não permite ordenar componentes por efeito ou importância causal.

### Ligação com o próximo slide

Com os estratos definidos, eu posso mostrar como eles entram na conta dos casos esperados.

## Slide 25: Padronização indireta por covariável

### Fala sugerida

Na padronização, eu deixo de usar uma única taxa nacional para todos os municípios. Calculo uma taxa basal para cada tercil: somo os casos daquele estrato no país e divido pela população correspondente. Para uma zona candidata, eu aplico cada uma dessas taxas à população da zona que pertence ao mesmo estrato e somo as contribuições.

A hipótese nula agora admite diferenças basais entre os grupos. A varredura procura um excesso adicional à composição da zona nesses grupos. Repito esse raciocínio em sete formulações ajustadas, cada uma com uma classificação, além do modelo sem ajuste. Não estou colocando sete variáveis simultaneamente numa regressão, e a mudança do esperado não identifica um efeito causal da covariável.

### Equação no slide

$$
r_k=\frac{C_k}{N_{G,k}},\qquad
E_Z^{\mathrm{aj}}=\sum_{k=1}^{3}r_kN_{Z,k}.
$$

### Para entender e explicar

**$r_k$.** É a taxa nacional acumulada de casos do estrato k usando sua população média. Ela é estimada nos mesmos dados analisados. Não é uma taxa externa de referência nem um coeficiente de regressão.

**$N_{Z,k}$ e $E_Z^{\mathrm{aj}}$.** A população do estrato k dentro da zona recebe a taxa basal do próprio estrato. A soma das três parcelas produz o esperado ajustado. Se houvesse um único estrato, a expressão retornaria ao esperado sem ajuste.

**Excesso residual.** Uma zona pode continuar significativa depois de mudar sua referência basal. Residual significa excesso perante essa padronização específica; não significa que todas as diferenças ambientais e sociais foram controladas.

### Exemplo para estudar

Exemplo didático fictício com três estratos: taxas basais $r_k$ de 0,01, 0,02 e 0,03 e populações $N_{Z,k}$ de 1.000, 2.000 e 1.000 produzem $E_Z^{\mathrm{aj}}=10+40+30=80$ casos. As parcelas devem usar taxas e populações do mesmo estrato.

### Lembrete para a fala

Uma estratificação por vez. No composto, a entrada também é uma classificação única em três níveis.

### Se a banca perguntar

Uma zona que desaparece após o ajuste era falsa?

Não necessariamente. Ela deixou de ser reportada sob outra hipótese de referência. As duas análises respondem a perguntas distintas sobre o esperado; desaparecer não demonstra que a covariável explique causalmente todos os casos da zona.

### Ligação com o próximo slide

Antes de comparar as coleções, vou colocar lado a lado a referência sem ajuste e a referência padronizada.

Referências de apoio: kulldorff1997spatial, jung2009glm.

## Slide 26: Sem ajuste e com padronização

### Fala sugerida

A diferença começa na hipótese de referência. Sem covariável, eu uso uma taxa nacional para todos os municípios. A população de cada área determina quantos casos eu esperaria encontrar ali, se essa taxa fosse comum a todo o território.

Com a padronização, eu admito uma taxa basal diferente para cada estrato. Um município do primeiro tercil é comparado à taxa nacional desse tercil; o mesmo vale para os outros grupos. Para uma zona, somo as parcelas de sua população sob as taxas dos respectivos estratos. A busca continua procurando excesso espacial, mas agora diante dessa referência. Portanto, o ajuste não serve para estimar quanto o calor aumenta a incidência. Ele muda a comparação usada para reconhecer um excesso.

### Para entender e explicar

**Uma taxa ou uma taxa por estrato.** Sem ajuste, $r=C_G/N_G$. Com a classificação, $r_k=C_k/N_{G,k}$. As duas referências são estimadas no próprio painel; nenhuma delas é uma meta sanitária ou uma previsão externa.

**Hipótese nula ajustada.** A referência admite diferenças entre estratos. Dentro de cada estrato, não há excesso espacial adicional sob a hipótese nula. Ela não afirma que todos os municípios têm a mesma incidência esperada por habitante.

**O que permanece.** Os casos observados, a malha e os limites espaciais da busca são os mesmos na comparação das formulações. Mudam os esperados, a estatística obtida para cada janela e, possivelmente, a coleção reportada.

### Onde apontar

Comparar primeiro as duas taxas e depois as hipóteses nulas. A coluna ajustada não deve ser lida como uma igualdade nacional de risco.

### Lembrete para a fala

Dizer referência do mesmo estrato, sem afirmar que foram removidas todas as diferenças ambientais. As taxas basais são estimadas.

### Se a banca perguntar

O município é comparado apenas aos municípios vizinhos do mesmo estrato?

A taxa basal do estrato é nacional: usa todos os municípios daquela categoria, estejam perto ou longe. A zona candidata é espacial; sua população recebe as taxas nacionais dos estratos a que pertence.

### Ligação com o próximo slide

Vou manter a mesma zona num exemplo para mostrar, em números, o que muda nessa comparação.

Referências de apoio: kulldorff1997spatial.

## Slide 27: Mesma zona, dois casos esperados

### Fala sugerida

Este exemplo é fictício. No país, os três estratos têm dez mil habitantes cada e registram cem, duzentos e trezentos casos. As taxas basais são, então, um, dois e três casos a cada cem habitantes no período. No total, são seiscentos casos para trinta mil habitantes: a taxa global é dois por cem.

A zona reúne mil habitantes e os mesmos quarenta casos em toda a comparação. Sem ajuste, multiplico mil pela taxa global e obtenho vinte casos esperados. Mas setecentos habitantes dessa zona estão no terceiro estrato, justamente o de maior taxa basal. Com a padronização, as três parcelas são um, quatro e vinte e um, somando vinte e seis esperados. Não retirei seis casos nem observei uma queda da doença. Comparei os mesmos quarenta casos a outra referência.

### Equação no slide

$$
E_Z=600\frac{1.000}{30.000}=20,\qquad
E_Z^{\mathrm{aj}}=0{,}01(100)+0{,}02(200)+0{,}03(700)=26.
$$

### Para entender e explicar

**Contas por estrato.** As populações da zona são 100, 200 e 700. Multiplicadas por 0,01, 0,02 e 0,03, produzem as contribuições 1, 4 e 21. O esperado ajustado é 26, enquanto a referência homogênea produz 20.

**Interpretação do contraste.** Os observados seguem acima dos esperados nas duas referências. Os quocientes observado/esperado são 2,00 e aproximadamente 1,54; esses quocientes não são o RR da zona, que inclui o exterior.

**Da zona para a varredura.** Uma única janela ainda não decide o resultado. Ao recalcular as estatísticas nas janelas candidatas e repetir a inferência, podem mudar o primário e as zonas secundárias. Não se conclui significância pela conta de 40 diante de 26.

### Lembrete para a fala

Anunciar fictício antes dos números. As taxas são razões na escala do período agregado; não são taxas anuais nem probabilidades individuais. O exemplo não quantifica casos atribuíveis ao calor.

### Se a banca perguntar

Por que o esperado aumentou se a população da zona não mudou?

Porque a zona reúne mais população no grupo de maior taxa basal que a composição nacional de referência homogênea reconheceria. Neste exemplo, 70% da população da zona está no terceiro estrato, contra um terço da população do país. Em outra composição, o esperado ajustado poderia diminuir ou permanecer igual.

### Ligação com o próximo slide

Essa mudança do esperado ajuda a esclarecer o papel das covariáveis e a diferença em relação a uma regressão.

## Slide 28: O papel das covariáveis nesta aplicação

### Fala sugerida

Aqui vale distinguir a distribuição usada para as contagens do procedimento de regressão. Trabalhar com Poisson não significa que eu tenha ajustado uma regressão de Poisson. Nesta aplicação, calor, saneamento e urbanização definem classificações para padronizar os esperados. Não entram como regressoras numa equação em que eu estimo coeficientes de efeito.

Eu estimo taxas basais dos estratos e depois procuro um excesso espacial em relação a elas. Assim, não tenho um coeficiente que diga quanto o risco varia a cada unidade de temperatura ou de cobertura de saneamento. Também não ajustei todas as covariáveis simultaneamente: cada rodada usa uma estratificação. O composto entra como uma única classificação em tercis. Minha comparação é entre coleções de zonas sob referências distintas, sem atribuição causal às covariáveis.

### Para entender e explicar

**A distinção é sobre a aplicação executada.** O estudo usou padronização indireta por categorias nos arquivos de casos e população. Não foi ajustado um modelo multivariado para estimar ou interpretar efeitos das sete covariáveis como preditores.

**Há estimação, mesmo sem regressão de efeitos.** As taxas basais dos estratos e os contrastes de risco da varredura são estimados. Evite dizer que o método não estima parâmetros ou que deixa de usar um modelo estatístico.

**Modelos relacionados.** Existem representações e extensões com regressão. Sua existência não muda o que foi feito neste trabalho. A formulação categórica pode ser expressa por taxas de grupos; isso não autoriza interpretar os resultados da varredura como coeficientes de efeito das covariáveis.

### Lembrete para a fala

A frase de abertura deve sair clara: nesta aplicação, covariáveis são estratos de referência e não regressoras. Se houver uma pergunta sobre equivalência matemática, reconheça a relação e explique o alcance da implementação.

### Se a banca perguntar

Essas taxas por estrato não poderiam ser representadas por uma regressão de Poisson com indicadores de categoria?

Sim. Com exposição populacional, as taxas por categoria podem ser representadas por um modelo Poisson com um fator categórico. Minha distinção é sobre o procedimento executado e a interpretação: usei a padronização para construir esperados e buscar excessos, sem ajustar e interpretar coeficientes das covariáveis como efeitos em um modelo multivariado. Extensões da varredura com modelos lineares generalizados não foram aplicadas.

### Ligação com o próximo slide

Para comparar essas referências e suas coleções de zonas, usei o WMAPE e o índice de Jaccard.

Referências de apoio: jung2009glm.

## Slide 29: WMAPE e concordância espacial

### Fala sugerida

Usei duas medidas porque comparar apenas o número de zonas deixaria de fora parte das mudanças. No WMAPE, eu calculo a diferença absoluta entre observado e esperado em cada município, somo essas diferenças e divido pelo total nacional de casos. Assim, excessos e faltas não se cancelam. Um valor menor indica que aquela padronização acompanha mais de perto a distribuição observada nos mesmos dados.

No Jaccard, eu comparo os conjuntos de municípios cobertos pelas zonas. O numerador conta os municípios presentes nas duas coleções; o denominador, os presentes em pelo menos uma. Consigo, então, distinguir coleções com contagens de zonas parecidas e composição municipal diferente. Nenhuma medida decide sozinha qual formulação é melhor, e o WMAPE não constitui validação preditiva.

### Equação no slide

$$
\mathrm{WMAPE}=100\frac{\sum_{i=1}^{N}|O_i-E_i|}{\sum_{i=1}^{N}O_i}
$$

$$
J(A,B)=\frac{|A\cap B|}{|A\cup B|}
$$

### Para entender e explicar

**$O_i$ e $E_i$.** Aqui O_i é o observado municipal e E_i é o esperado da respectiva formulação. O denominador do WMAPE é uma soma nacional; não se divide pelo observado de cada município. Por isso, municípios com zero caso podem entrar sem divisão por zero.

**Discrepância interna.** O esperado foi estimado na própria amostra. Menor erro não prova melhor previsão, causalidade ou maior validade da coleção de zonas. A análise considera conjuntamente erro e detecção de excessos.

**Interseção e união.** Jaccard varia de zero a um para os conjuntos não vazios comparados. Ele não pareia zonas, não compara seus formatos diretamente e não distingue qual coleção se aproxima mais de uma verdade desconhecida.

### Exemplo para estudar

Exemplos didáticos fictícios: com observados 80 e 20 e esperados 60 e 40, o WMAPE é 100 × (20 + 20)/100 = 40%. Se duas coleções compartilham três municípios e sua união contém cinco, o Jaccard é 3/5 = 0,60.

### Lembrete para a fala

Explicar que o erro absoluto impede cancelamento; não interpretar Jaccard como percentual de zonas idênticas.

### Se a banca perguntar

Dois modelos com o mesmo número de zonas necessariamente concordam?

Não. Eles podem incluir municípios diferentes ou repartir o território de outra maneira. O Jaccard olha a cobertura municipal compartilhada, enquanto o número de zonas descreve a quantidade de agrupamentos reportados.

### Ligação com o próximo slide

Além de mudar a referência dos esperados, eu avaliei o que acontece quando retiro o ano de maior volume de casos.

Referências de apoio: jaccard1901.

## Slide 30: Sensibilidade à retirada de 2024

### Fala sugerida

Também avaliei a influência de 2024 na análise acumulada. Esse ano reúne vinte e nove vírgula um por cento dos casos do painel, então sua retirada pode alterar bastante a distribuição espacial observada. Repeti as oito formulações mantendo 2010 a 2023 e 2025. Recalculei tanto os casos acumulados quanto a população média desses quinze anos.

Mantive os parâmetros espaciais e inferenciais e os estratos originais das covariáveis. Assim, comparo os cenários sob uma classificação comum. Depois, observo mudanças no número de zonas, no polo primário, no WMAPE e na sobreposição municipal. Interpreto isso como uma análise de sensibilidade ao peso de um ano epidêmico, sem tratar o cenário reduzido como uma base necessariamente mais verdadeira ou livre de problemas de notificação.

### Para entender e explicar

**O que foi retirado.** Saem as contagens e a população anual de 2024 na agregação do cenário reduzido. Permanecem os casos de 2010 e de 2025; a análise não passa a ser apenas 2011–2025.

**O que permanece.** As categorias, inclusive as de calor calculadas com 2010–2025, conservam a referência original. O exercício não elimina toda informação de 2024 da construção das covariáveis. Esperados e taxas basais são recalculados com os dados do cenário.

**Por que comparar coleções.** A retirada pode alterar o número e a composição das zonas em direções diferentes. Mais zonas não significa mais casos, e mudar o centro primário não demonstra deslocamento físico de uma epidemia ao longo do tempo.

### Lembrete para a fala

Dizer quinze anos não consecutivos. Manter explícito que os estratos foram preservados e que a finalidade é sensibilidade.

### Se a banca perguntar

Excluir 2024 corrige possível mistura com outras doenças?

Essa análise não estima nem corrige eventual classificação incorreta. Ela verifica a dependência dos resultados em relação a um ano muito influente. Achados de outras etiologias em estudos locais não permitem quantificar contaminação do painel nacional.

### Ligação com o próximo slide

Com essas definições, eu passo aos resultados, começando pela evolução temporal que motivou parte das comparações.

## Slide 31: Evolução anual da incidência

### Fala sugerida

Começo os resultados pela evolução anual da incidência. Ao acompanhar a curva, eu observo alternância entre anos de maior intensidade e anos com valores menores. O ponto que mais se destaca é 2024: no painel espacial, esse ano reúne 6.433.460 casos, com incidência de 3.026,4 por cem mil habitantes. Isso corresponde a 29,1% de todos os casos acumulados entre 2010 e 2025.

Esse peso ajuda a entender por que eu incluí a análise de sensibilidade apresentada nos métodos. Uma análise acumulada incorpora de forma expressiva a distribuição de um ano tão volumoso. Em 2025 há redução em relação ao pico, mas a curva não retorna automaticamente aos menores níveis históricos. Trato essa comparação como descrição da série; o gráfico, sozinho, não permite atribuir a mudança a um mecanismo específico.

### Onde apontar

Eixos da curva, pico de 2024 e ponto de 2025.

### Lembrete para a fala

Usar os dados do painel, sem misturar fotografias ministeriais publicadas durante 2024.

### Se a banca perguntar

O cenário completo representa igualmente todos os anos?

Todos entram na soma, mas anos com mais casos têm maior contribuição. 2024 concentra 29,1% do total.

### Ligação com o próximo slide

Além da diferença entre anos, examinei como os casos se distribuem dentro do calendário anual.

## Slide 32: Sazonalidade mensal

### Fala sugerida

Para examinar a sazonalidade, eu reuni os casos por mês e calculei a média de cada mês ao longo do período. Portanto, a altura de abril representa a média dos meses de abril observados na série, e não os casos de um único ano. O padrão nacional concentra os casos no primeiro semestre, com o maior valor em abril, seguido por março e maio.

Leio esse resultado como uma descrição do calendário médio de notificações. A agregação resume situações que podem variar entre anos e entre regiões, de modo que o pico nacional não deve ser atribuído automaticamente a todos os municípios. Também não significa que a transmissão desapareça no restante do ano. Essa distinção será útil ao comparar as trajetórias regionais, que mostram outra dimensão da heterogeneidade temporal.

### Onde apontar

Eixo dos meses e sequência março, abril e maio; identificar que o eixo vertical é média de casos.

### Lembrete para a fala

Não chamar média mensal de incidência quando a unidade do gráfico é número de casos.

### Se a banca perguntar

Esse gráfico mostra somente o ano de 2024?

Não. Mostra a média mensal calculada ao longo de 2010 a 2025, conforme a base mensal usada no gráfico.

### Ligação com o próximo slide

A média nacional resume calendários diversos; vou abrir agora a evolução por Grande Região.

## Slide 33: Evolução regional da incidência

### Fala sugerida

Separei a evolução anual por Grande Região para observar diferenças que a curva nacional resume. A linha tracejada oferece a referência do Brasil nos painéis regionais, e o último painel apresenta a própria série nacional. A leitura exige atenção aos eixos: as escalas verticais variam, portanto curvas de alturas parecidas podem representar taxas diferentes. Para comparar magnitudes, eu considero os valores indicados nos rótulos.

As trajetórias não são uniformes. Centro-Oeste e Sudeste apresentam incidências mais elevadas no conjunto descrito, enquanto o Sul mostra elevação na segunda metade do período. Norte e Nordeste seguem trajetórias próprias e não reproduzem todos os picos com a mesma intensidade. Por enquanto, eu me limito ao padrão observado. Possíveis relações com clima, mobilidade ou urbanização serão retomadas na discussão, sem atribuir explicação causal a essas curvas.

### Onde apontar

Referência tracejada, cinco regiões e sexto painel Brasil; indicar escalas próprias.

### Lembrete para a fala

Apontar os rótulos dos eixos antes de qualquer comparação visual.

### Se a banca perguntar

Posso comparar diretamente a altura das curvas entre painéis?

Não. Os eixos têm escalas próprias. A comparação da magnitude exige ler as taxas nos eixos.

### Ligação com o próximo slide

A abertura por UF permite localizar variações que ainda ficam escondidas dentro das Grandes Regiões.

## Slide 34: Heatmap da incidência por UF e ano

### Fala sugerida

No mapa de calor, cada posição combina uma unidade da federação com um ano. Consigo acompanhar uma UF ao longo da linha e comparar as UFs em um mesmo ano pela coluna correspondente. A cor representa a incidência em escala logarítmica. Escolhi essa escala porque há diferenças de várias ordens de grandeza e uma escala linear deixaria os valores menores pouco distinguíveis.

Essa apresentação mostra que o ano de maior incidência não é o mesmo em todo o país. Na contagem descrita no manuscrito, 2024 é o máximo em dez das 27 UFs, embora seja o maior pico nacional. Não interpreto distâncias entre cores como diferenças lineares de taxas. A legenda orienta a leitura e evita confundir um contraste visual intenso com uma diferença aritmética de tamanho fixo.

### Onde apontar

Eixos UF e ano, coluna de 2024 e classes da legenda logarítmica.

### Lembrete para a fala

Se mencionar dez UFs, associar ao máximo por UF, não ao número de UFs com epidemia.

### Se a banca perguntar

Por que a escala é logarítmica?

Para distinguir valores que variam por ordens de grandeza sem deixar toda a imagem dominada por poucos picos.

### Ligação com o próximo slide

Depois dessa abertura temporal por UF, passo à distribuição municipal acumulada.

## Slide 35: Carga acumulada municipal

### Fala sugerida

Passo agora do calendário para o território municipal. A cor deste mapa representa os casos acumulados de 2010 a 2025 divididos pela população média do município, por cem mil habitantes. É a medida acumulada que defini no início. Não estou comparando apenas o número bruto de notificações, nem mostrando a incidência de um único ano.

Os contrastes municipais se concentram sobretudo no Centro-Sul, mas a leitura relevante também envolve a proximidade entre áreas com valores semelhantes. A observação visual sugere organização territorial, porém eu não uso o mapa sozinho para concluir que existe associação espacial ou para delimitar uma zona significativa. Para isso, recorro às estatísticas que apresentei. O mapa descreve a distribuição da carga; os métodos seguintes avaliam aspectos distintos dessa organização.

### Onde apontar

Legenda da medida acumulada e distribuição no Centro-Sul.

### Lembrete para a fala

Não converter a razão acumulada em percentual de pessoas infectadas.

### Se a banca perguntar

Essa taxa é anual?

Não. O numerador soma os 16 anos e o denominador é a população média; a escala é acumulada.

### Ligação com o próximo slide

Antes de testar a associação espacial, também examinei quantas vezes cada município ultrapassou um limiar anual.

## Slide 36: Recorrência de anos epidêmicos

### Fala sugerida

Neste mapa, eu contei os anos em que cada município apresentou incidência superior a 300 casos por cem mil habitantes. Cada município pode, portanto, receber uma contagem de zero a 16. A medida acrescenta uma informação à carga acumulada: dois municípios podem somar muitos casos no período, mas um deles concentrá-los em poucos anos e o outro ultrapassar o limiar em vários anos.

No painel, 12,2% dos municípios tiveram pelo menos dez anos acima desse limiar. Interpreto esse resultado como recorrência de anos de incidência elevada, segundo uma definição descritiva. Não significa transmissão contínua entre as mesmas pessoas e não foi o critério de seleção das zonas da varredura. Também é uma contagem temporal, diferente da frequência de inclusão nas oito formulações, que aparecerá mais adiante.

### Equação no slide

$$
H_i=\sum_{t=2010}^{2025}\mathbf1(TI_{it}>300)
$$

### Onde apontar

Fórmula da contagem e classes do mapa; destacar pelo menos dez anos.

### Lembrete para a fala

Não chamar essa contagem de duração contínua de uma epidemia.

### Se a banca perguntar

O limiar de 300 definiu as zonas de alto risco?

Não. Ele serve a essa descrição de recorrência. A varredura usa contagens, população e razão de verossimilhança.

### Ligação com o próximo slide

Com a distribuição e a recorrência descritas, passo à autocorrelação espacial anual.

## Slide 37: Autocorrelação espacial nos 16 anos

### Fala sugerida

Calculei o Índice Global de Moran para a incidência municipal de cada ano, usando a mesma estrutura de vizinhança. O índice foi positivo e significativo ao nível de 5% em todos os 16 anos. Os valores variaram de 0,215 a 0,613, com o maior resultado em 2024. Isso indica que municípios próximos tendem a apresentar incidências semelhantes, segundo a vizinhança adotada.

Essa leitura precisa ser separada da magnitude da incidência. Um Moran maior descreve uma organização espacial mais associada para aquela variável e aquela matriz, mas não quer dizer, por definição, mais casos. Municípios com valores baixos próximos de outros valores baixos também contribuem para associação positiva. Como o índice resume o país num único número por ano, eu ainda preciso da análise local para observar onde se encontram as associações.

### Onde apontar

Eixo do Moran, intervalo de valores e máximo em 2024.

### Lembrete para a fala

Significância anual não é um teste conjunto único dos 16 anos.

### Se a banca perguntar

Moran alto significa incidência alta?

Não. Moran mede a associação dos desvios entre vizinhos; a magnitude da incidência é outra característica.

### Ligação com o próximo slide

A análise local permite abrir esse resumo nacional e distinguir os tipos de associação.

## Slide 38: Associação espacial local

### Fala sugerida

No LISA, eu usei a razão acumulada municipal e classifiquei o resultado combinando o quadrante com a significância nominal. Foram 857 municípios alto-alto e 1.324 baixo-baixo. As duas categorias representam associação positiva: no primeiro caso, valores acima da média próximos de valores acima da média; no segundo, valores abaixo da média próximos de outros valores baixos.

Os contrastes locais foram menos numerosos: 12 municípios alto-baixo e 29 baixo-alto. Outros 3.342 não atingiram significância nominal. Não interpreto essa última categoria como ausência de dengue. A análise se refere à associação espacial da variável, e seus testes locais não receberam correção para múltiplas comparações. Por isso, minha leitura é exploratória e considera o padrão conjunto. A referência também é diferente da varredura: aqui comparo desvios em relação à média municipal.

### Onde apontar

Legenda dos quatro quadrantes e categoria não significativa; depois contagens.

### Lembrete para a fala

Não usar associação local como evidência causal nem equiparar ausência de significância à ausência da doença.

### Se a banca perguntar

Alto-alto no LISA é a mesma coisa que zona da varredura?

Não. As referências e as estatísticas são distintas: média municipal e vizinhança no LISA, esperado populacional e busca de janelas na varredura.

### Ligação com o próximo slide

Antes das zonas, apresento as taxas nos estratos que irão modificar a referência dos esperados.

## Slide 39: Incidência por estratos das covariáveis

### Fala sugerida

Organizei esta tabela para mostrar como os casos se distribuem nos estratos usados na padronização. As taxas estão por cem mil pessoas-ano: somo os casos dos municípios do nível e divido pela soma de suas populações anuais. Não é a média simples das taxas municipais. Os grupos têm números semelhantes de municípios, mas suas populações podem ser muito diferentes.

Nos tercis de calor, observo taxas crescentes de 431,7 para 1.088,7. Na densidade urbana, o maior valor está no nível intermediário. Já nos indicadores de saneamento, os níveis seguem da maior para a menor cobertura, e as taxas são mais altas nos grupos com maior cobertura. Não tomo essas diferenças como efeitos do saneamento ou do calor. Elas descrevem a composição dos estratos e ajudam a compreender por que mudar a referência modifica os esperados.

### Onde apontar

Unidade pessoas-ano, linha de calor, linha de densidade e orientação dos níveis de saneamento.

### Lembrete para a fala

Não interpretar os três níveis como doses comparáveis entre indicadores.

### Se a banca perguntar

Por que saneamento melhor aparece com taxa maior?

A tabela é descritiva e os grupos têm composições territoriais e populacionais distintas. Ela não estima efeito causal da cobertura.

### Ligação com o próximo slide

Com essas referências definidas, começo pela varredura sem ajuste.

## Slide 40: Zonas de alto risco sem ajuste

### Fala sugerida

No modelo sem ajuste, a referência dos casos esperados depende somente da participação de cada município na população. Com os limites de 16% da população e 200 quilômetros de raio, o reporte identificou 129 zonas significativas sem sobreposição. Elas reúnem 1.907 municípios, que correspondem a 34,3% do painel espacial.

Essas zonas concentram 64,1% dos casos em 30,0% da população usada na análise. A diferença entre essas participações descreve a concentração do excesso em relação à referência populacional. No mapa, as principais zonas recebem cores distintas e as demais zonas significativas aparecem agrupadas na legenda. Interpreto a coleção como resultado dessa configuração de busca. Um município dentro de uma zona não precisa ter, isoladamente, o mesmo contraste que a zona inteira, pois a estatística é calculada para o conjunto.

### Onde apontar

Legenda das zonas e contraste entre percentuais de casos e população.

### Lembrete para a fala

Centro da janela não é origem demonstrada da transmissão.

### Se a banca perguntar

Todos os municípios dentro de uma zona têm alto risco individual significativo?

Não necessariamente. O teste se refere ao conjunto incluído na janela; a heterogeneidade interna pode permanecer.

### Ligação com o próximo slide

Vou detalhar a zona primária para relacionar os resultados às contas apresentadas nos métodos.

## Slide 41: Zona primária: Adolfo (SP)

### Fala sugerida

A zona primária do modelo sem ajuste é centrada em Adolfo, no interior de São Paulo. Ela reúne 319 municípios dentro de uma janela com raio de 197,4 quilômetros. Nesse conjunto, foram observados 2.342.103 casos, diante de 842.629 esperados sob a distribuição populacional homogênea. A diferença é calculada para a zona inteira, não apenas para o município que dá nome ao centro.

O risco relativo reportado é 2,99. Para chegar a esse valor, eu comparo a razão observado sobre esperado dentro da zona à mesma razão fora dela. Por isso, simplesmente dividir 2.342.103 por 842.629 não reproduz o RR. Adolfo identifica a janela de maior razão de verossimilhança entre as candidatas; essa definição não exige que ela tenha o maior RR de toda a coleção.

### Onde apontar

Percorrer observados, esperados e RR; voltar a municípios e raio para mostrar o tamanho da zona.

### Lembrete para a fala

Não atribuir os dois milhões de casos ao município de Adolfo.

### Se a banca perguntar

Por que observado dividido por esperado não é igual ao RR?

O RR inclui o contraste externo: divide o observado/esperado interno pelo observado/esperado no restante do território.

### Ligação com o próximo slide

A pergunta seguinte é como essa configuração muda quando a referência passa a considerar os estratos.

## Slide 42: Comparação das oito formulações

### Fala sugerida

Reuni as oito formulações na mesma tabela para comparar a detecção e a proximidade entre os esperados e os observados. O número de zonas varia de 128, sob calor, a 195, sob coleta de lixo. Os polos primários também mudam: Adolfo sem ajuste, Queluzito sob calor, Iacri em quatro ajustes e Araújos nos ajustes por densidade e pelo índice composto.

O WMAPE diminui em todas as formulações ajustadas diante da referência sem ajuste. A maior redução ocorre sob calor, de 75,1% para 64,9%, ou 10,2 pontos percentuais, permanecendo 128 zonas. Foi por essa combinação que eu detalhei o ajuste térmico. Não estou escolhendo um modelo preditivo vencedor: o indicador é interno à amostra, e tanto a redução do erro quanto a coleção residual precisam ser interpretadas junto da referência adotada.

### Onde apontar

Colunas de zonas e polos; comparar WMAPE sem ajuste e calor.

### Lembrete para a fala

Redução de 10,2 pontos percentuais, não 10,2% relativo.

### Se a banca perguntar

Por que o número de zonas pode aumentar depois de ajustar?

Os esperados mudam espacialmente. Isso pode alterar, separar ou revelar zonas de excesso; ajuste não implica redução obrigatória da contagem.

### Ligação com o próximo slide

O mapa do ajuste por calor permite observar uma mudança que a contagem quase constante esconde.

## Slide 43: Zonas após padronização por calor

### Fala sugerida

Sob a padronização por calor, eu obtive 128 zonas que concentram 63,3% dos casos. A zona primária passa a ser centrada em Queluzito, em Minas Gerais, com 362 municípios e risco relativo de 2,08. Embora a contagem nacional seja muito próxima das 129 zonas sem ajuste, a semelhança na quantidade não significa que os conjuntos municipais sejam os mesmos.

O índice de Jaccard entre a coleção sob calor e a coleção sem ajuste é de 56%. Esse valor compara a interseção à união dos municípios incluídos nas zonas, mostrando uma mudança expressiva de composição. Também não interpreto a passagem de RR 2,99 para 2,08 como redução de risco nos mesmos municípios: os primários são zonas diferentes e usam esperados diferentes. O resultado descreve excesso residual diante da referência térmica definida pelos tercis.

### Onde apontar

Localização de Queluzito e resumo à direita; destacar Jaccard de 56%.

### Lembrete para a fala

Não dizer que o calor explicou a diferença entre os RR primários.

### Se a banca perguntar

128 e 129 zonas indicam resultados praticamente iguais?

Não. A contagem é semelhante, mas o Jaccard municipal de 56% mostra diferenças na composição das coleções.

### Ligação com o próximo slide

Para examinar o contraste em escala municipal, apresento os mapas de risco relativo.

## Slide 44: Risco relativo municipal sem ajuste

### Fala sugerida

Este mapa apresenta o risco relativo municipal na formulação sem ajuste. Mudo, portanto, da leitura das zonas para a leitura de cada município. Os tons mais escuros representam contrastes mais elevados e o branco reúne valores menores ou iguais a um. A referência continua sendo a distribuição dos casos proporcional à população, sem estratificação por covariável.

Essa mudança de unidade de leitura é importante. O RR de um município não é o mesmo número que o RR agregado da zona em que ele eventualmente se encontra. Também não basta apresentar RR municipal elevado para pertencer necessariamente a uma zona reportada: a busca, a significância e a regra sem sobreposição interferem na coleção final. Uso o mapa para descrever a intensidade dos contrastes municipais, mantendo separada a decisão de detecção das janelas.

### Onde apontar

Legenda contínua, branco e áreas de tons escuros; distinguir do mapa categórico anterior.

### Lembrete para a fala

Não tratar branco como ausência de casos.

### Se a banca perguntar

Um município escuro precisa estar numa zona significativa?

Não necessariamente. Intensidade municipal e detecção de uma janela são resultados diferentes, sujeitos às regras de busca e reporte.

### Ligação com o próximo slide

No próximo mapa, a referência municipal passa a incorporar os tercis de calor.

## Slide 45: Risco relativo municipal sob calor

### Fala sugerida

Neste mapa, eu mantenho a leitura municipal, mas os casos esperados passam a considerar a classificação por dias sob ondas de calor. A mudança de cor representa o contraste diante dessa nova referência, e não uma alteração nas notificações observadas. Os casos são os mesmos do período completo; o que muda é a distribuição esperada sob a hipótese nula estratificada.

Permanecem contrastes municipais depois dessa padronização. Os descrevo como excessos residuais em relação ao esquema de estratos, sem transformar o ajuste numa decomposição causal. Também preciso fazer uma ressalva visual: os mapas individuais têm limites próprios de legenda. Uma cor parecida em duas páginas não garante o mesmo RR. Para uma comparação direta de intensidade por cor, deixei um painel com escala comum no material de apoio à arguição.

### Onde apontar

Legenda própria e áreas com contraste residual; mencionar apoio com escala comum.

### Lembrete para a fala

Casos observados não mudam entre formulações do cenário completo; mudam os esperados.

### Se a banca perguntar

As mesmas cores correspondem ao mesmo RR nos dois mapas individuais?

Não obrigatoriamente, porque os limites das legendas são próprios. O painel de apoio usa escala comum.

### Ligação com o próximo slide

A comparação do ajuste também precisa considerar que o resultado nacional pode resumir situações regionais diferentes.

## Slide 46: WMAPE nacional e diferenças regionais

### Fala sugerida

Abri o WMAPE por Grande Região para verificar como a redução nacional se distribui. Sob calor, o valor cai de 53,4% para 38,7% no Centro-Oeste, de 57,0% para 43,7% no Sudeste e de 101,9% para 80,9% no Sul. No Nordeste, permanece em 122,2% após o arredondamento. No Norte, aumenta de 183,0% para 245,9%.

Portanto, a maior proximidade nacional entre esperados e observados não ocorre de maneira uniforme. O WMAPE nacional dá maior peso às regiões com mais casos, e essa ponderação pode esconder o aumento regional. Valores superiores a cem por cento são possíveis: os esperados foram padronizados nacionalmente e não são obrigados a somar os casos observados de cada região. Leio a tabela como descrição dos desvios diante da referência, sem atribuir esse padrão a uma causa específica.

### Onde apontar

Três quedas, estabilidade arredondada do Nordeste e aumento do Norte.

### Lembrete para a fala

Não afirmar que o ajuste por calor melhora o resultado em todo o Brasil.

### Se a banca perguntar

Como um WMAPE regional pode ultrapassar 100%?

A soma dos desvios absolutos pode superar os casos regionais; os esperados nacionais não conservam necessariamente o total dentro de cada região.

### Ligação com o próximo slide

Além da discrepância, comparei a frequência com que os mesmos municípios entram nas diferentes coleções.

## Slide 47: Recorrência entre as formulações

### Fala sugerida

Contei, para cada município, em quantas das oito formulações ele pertence a uma zona significativa. Foram 3.016 municípios incluídos em pelo menos uma formulação, 1.655 em seis ou mais e 967 em todas as oito. O mapa permite observar onde a inclusão se repete mesmo quando a referência dos casos esperados muda.

Essa contagem precisa ser lida pelo que ela mede. As oito formulações usam os mesmos casos e não são experimentos independentes; cada uma recebe o mesmo peso. Uma frequência alta indica inclusão recorrente nesse conjunto de escolhas, mas não informa a intensidade do excesso nem uma probabilidade individual de adoecer. Também não descreve quantos anos o município teve epidemia. Já mostrei uma medida temporal de recorrência, enquanto esta é uma comparação entre formulações da análise acumulada.

### Onde apontar

Legenda do número de formulações e faixa das inclusões mais recorrentes.

### Lembrete para a fala

Evitar chamar a frequência de probabilidade ou de validação independente.

### Se a banca perguntar

967 municípios nas oito formulações têm necessariamente o maior risco?

Não. A contagem não pondera RR, volume ou intensidade; descreve recorrência de inclusão nas formulações testadas.

### Ligação com o próximo slide

Resta examinar outra escolha: quanto os resultados dependem de manter 2024 na série.

## Slide 48: Sensibilidade à exclusão de 2024

### Fala sugerida

Repeti as oito formulações retirando 2024 e preservando os demais anos, os estratos e os parâmetros de busca. A tabela mostra que a contagem de zonas muda em todas elas. Sem ajuste, passa de 129 para 169; sob calor, de 128 para 130. Em esgoto, água e lixo, a contagem diminui, enquanto aumenta nas demais formulações.

O Jaccard entre os cenários fica entre 51% e 63%. Portanto, não se trata apenas de acrescentar ou retirar algumas zonas de uma coleção fixa: os conjuntos municipais também mudam. O polo primário se altera em sete das oito formulações. Interpreto o resultado como sensibilidade ao período acumulado. O cenário sem 2024 tem menos casos, mas isso não determina, por si só, menos zonas; os esperados e os contrastes espaciais também são recalculados.

### Onde apontar

Duas colunas de contagem e coluna de Jaccard; sem ajuste e calor como exemplos.

### Lembrete para a fala

Manter explícito que 2010 permanece e somente 2024 é retirado.

### Se a banca perguntar

Retirar casos deveria sempre reduzir o número de zonas?

Não. O método detecta contrastes diante de esperados recalculados; a contagem de zonas não é proporcional ao total de casos.

### Ligação com o próximo slide

O mapa sem ajuste permite visualizar essa mudança de configuração.

## Slide 49: Zonas sem ajuste no cenário sem 2024

### Fala sugerida

Neste cenário, a varredura sem ajuste usa os casos de 2010 a 2023 e de 2025. Recalculo a população média para esses 15 anos e mantenho a mesma janela circular, com o teto duplo de população e raio. O resultado reúne 169 zonas, e o polo primário passa de Adolfo para Ubarana, também no interior de São Paulo.

A sobreposição municipal de 61% com o cenário completo indica que uma parte da composição permanece e outra se altera. Isso ajuda a separar uma leitura territorial ampla da delimitação específica de cada zona. Não interpreto o aumento de 129 para 169 como aumento da carga de dengue, pois o total do cenário é menor. Ele descreve como a configuração dos excessos se reorganiza diante de outro conjunto de anos e dos esperados correspondentes.

### Onde apontar

Mapa atual, polo Ubarana e resumo de Jaccard; retomar mentalmente o mapa puro completo.

### Lembrete para a fala

Sem 2024 não é uma validação fora da amostra, mas análise de sensibilidade.

### Se a banca perguntar

O cenário sem 2024 também exclui 2010?

Não. Inclui 2010 a 2023 e 2025; são 15 anos efetivamente analisados.

### Ligação com o próximo slide

Depois das comparações, posso reunir a interpretação e relacioná-la, com cautela, à literatura.

## Slide 50: Interpretação dos achados

### Fala sugerida

Ao reunir os resultados, eu observo uma distribuição espacial estruturada, tanto na autocorrelação anual quanto nas zonas acumuladas. A concentração no Centro-Sul reaparece sob referências distintas, mas as fronteiras e os polos mudam. A literatura nacional de Lee e colaboradores e de Lowe e colaboradores oferece contexto para discutir a distribuição da dengue em relação ao clima e à urbanização, inclusive mudanças no Sul.

Preciso, porém, separar essa aproximação bibliográfica do que estimei. Meu estudo não isolou efeitos de clima, infraestrutura ou conectividade. A padronização por calor foi a que mais reduziu o WMAPE nacional, mas o aumento no Norte mostra um limite dessa síntese. A exclusão de 2024 também alterou as coleções. Minha interpretação é que há heterogeneidade residual recorrente, cuja delimitação continua condicionada à referência estatística e ao período escolhido.

### Onde apontar

Tópicos de estrutura espacial, referências distintas e sensibilidade; conectar aos mapas já exibidos.

### Lembrete para a fala

Somente nesta discussão trazer a literatura explicativa; preservar a distinção entre hipótese e resultado.

### Se a banca perguntar

Pode-se concluir que o calor causou os clusters encontrados?

Não. A relação com a literatura é contextual; o desenho não identifica efeito causal nem separa mecanismos concorrentes.

### Ligação com o próximo slide

Essa interpretação depende de reconhecer os limites dos dados e dos procedimentos.

Referências de apoio: lee2021, lowe2021.

## Slide 51: Limitações

### Fala sugerida

Agrupo as limitações em dois planos. Nos dados, as notificações estão sujeitas a subnotificação, atrasos e diferenças de vigilância. A agregação por município esconde desigualdades internas, a resolução climática não capta toda a variação local e os indicadores de saneamento representam 2022, embora a série cubra 16 anos. Por isso, as zonas devem ser entendidas como contrastes relativos de notificações nessa escala.

Nos métodos, a hipótese de Poisson e a janela circular definem o que é possível detectar. Os testes locais e o reporte secundário têm leitura exploratória, e grandes contagens podem tornar pequenos excessos significativos. A categorização também perde diferenças dentro dos tercis. Não uso o WMAPE como evidência de previsão, nem extrapolo associações municipais para indivíduos. Essas restrições delimitam o alcance das conclusões e orientam possíveis etapas futuras.

### Onde apontar

Primeiros dois tópicos para dados; demais para hipóteses, inferência e alcance.

### Lembrete para a fala

Limitação não é pedido de desculpas; indicar a consequência interpretativa concreta.

### Se a banca perguntar

Uma zona significativa precisa ter um excesso epidemiologicamente grande?

Não. Com muitos casos, excessos pequenos podem ser significativos; é preciso considerar RR, volume e contexto, além do valor-p.

### Ligação com o próximo slide

Com esse alcance definido, retomo as respostas aos objetivos da monografia.

## Slide 52: Considerações finais

### Fala sugerida

Concluo que a incidência municipal apresentou associação espacial positiva nos 16 anos analisados. Na análise acumulada, a varredura identificou zonas de excesso de notificações concentradas sobretudo no Centro-Sul. A comparação entre as formulações mostrou que essa concentração ampla reaparece, mas a posição dos polos e a composição das zonas dependem da referência usada para os casos esperados.

A retirada de 2024 também modificou os resultados, mostrando que o período faz parte da interpretação. A contribuição que eu apresento é uma descrição territorial comparável, acompanhada da avaliação dessas escolhas, sem atribuição causal às covariáveis. Como continuidade, eu considero pertinente investigar modelos ecológicos explícitos e janelas mais flexíveis, conforme a pergunta futura. Agradeço ao professor orientador e à banca pela leitura e fico à disposição para discutir os métodos e os resultados.

### Onde apontar

Quatro conclusões; ao agradecer, retirar o olhar do slide e dirigir-se à banca.

### Lembrete para a fala

Não introduzir novo número ou nova hipótese no encerramento.

### Se a banca perguntar

Qual é a principal contribuição?

A descrição nacional em referência territorial comum e a comparação explícita de como estratificações e 2024 alteram os excessos detectados.

### Ligação com o próximo slide

Agradecer e abrir a arguição; usar o próximo painel apenas se a comparação de cores for solicitada.

## Slide 53: Comparação do RR em escala comum

### Fala sugerida

Neste painel de apoio, eu coloquei os mapas municipais de RR sem ajuste e sob calor na mesma escala de cores. Diferentemente dos mapas individuais apresentados durante a exposição, uma mesma cor pode ser comparada entre os dois painéis como o mesmo nível de risco relativo. A leitura da legenda continua necessária, e o branco corresponde aos municípios com RR menor ou igual a um.

O painel serve para discutir a distribuição do contraste sob as duas referências. Os casos observados não mudam entre elas; os esperados passam de uma referência populacional única para uma referência por estratos de calor. Não interpreto uma mudança de cor como redução observada de casos, nem como efeito causal do calor. Também mantenho a distinção entre o RR municipal representado e o RR agregado de cada zona primária.

### Onde apontar

Legenda compartilhada e mesma área geográfica nos dois painéis.

### Lembrete para a fala

Slide de apoio à arguição, sem obrigação de apresentá-lo após a conclusão.

### Se a banca perguntar

O que muda entre esses mapas?

A referência dos esperados e, consequentemente, o RR; os casos observados do cenário completo são os mesmos.

### Ligação com o próximo slide

Responder à pergunta da banca e retornar ao ponto solicitado; não iniciar nova exposição.

## Slide 54: Referências citadas

### Fala sugerida

As referências utilizadas na apresentação estão reunidas nesta página e detalhadas na bibliografia da monografia.

Deixo esse material disponível para a discussão de uma definição, de uma escolha de método ou de um estudo citado.

### Onde apontar

Lista bibliográfica somente se a banca solicitar.

### Lembrete para a fala

Nota curta: não ler a lista de referências em voz alta.

### Se a banca perguntar

Onde estão as referências completas?

Na bibliografia da monografia e nesta página da apresentação.

### Ligação com o próximo slide

Retomar a pergunta da banca.

## Arquivos

A versão em PDF e o LaTeX completo estão em `slides/notes/Roteiro Completo de Estudo.pdf` e `slides/notes/Roteiro Completo de Estudo.tex`. O roteiro acompanha a sequência atual dos slides; o material de aprofundamento e as respostas são apoio para o estudo, sem necessidade de leitura integral na apresentação.

Para recompilar a partir da raiz:

```bash
latexmk -pdf -cd -outdir=build "slides/notes/Roteiro Completo de Estudo.tex"
```
