# SaTScan com ajuste por covariaveis: formulacao e implementacao

## 1. Objetivo do ajuste

A estatistica de varredura espacial procura zonas `Z` nas quais a intensidade
de casos seja maior que a esperada. No modelo Poisson sem ajuste, a expectativa
e proporcional a populacao sob risco. Se uma variavel ambiental ou
sociodemografica e espacialmente heterogenea, a varredura pode confundir a
distribuicao do risco basal com um excesso localizado. O ajuste por covariaveis
categoricas substitui a expectativa global por uma expectativa padronizada entre
estratos.

O ajuste nao transforma a varredura em um modelo causal. Ele controla apenas a
estratificacao fornecida, preservando a pergunta: existe uma zona com excesso de
casos depois de considerar a composicao dos estratos observados?

## 2. Processo pontual e unidade de analise

Considere uma regiao de estudo `G` particionada em `n` municipios. Cada municipio
`i` possui coordenada ou centroide `s_i`, exposicao `N_i` e contagem de casos
`Y_i`. O processo pontual agregado pode ser escrito como

\[
Y_i \mid N_i \sim \operatorname{Poisson}(\mu_i),
\qquad i=1,\ldots,n.
\]

Para uma varredura puramente espacial, `Z` pertence a uma colecao `mathcal{Z}`
de janelas circulares centradas nos locais observados. A janela pode crescer ate
um limite de populacao, como os 15% usados neste TCC.

Agora suponha uma covariavel categorica `K` com categorias `k=1,...,K`. Para
evitar sobreposicao de simbolos, escreva `N_{i,k}` para a populacao do municipio
`i` no estrato `k` e `Y_{i,k}` para os casos correspondentes. No caso em que
cada municipio pertence a um unico estrato, apenas uma categoria e positiva;
se os arquivos forem estratificados por idade, sexo ou outra particionamento,
varias categorias podem ser observadas no mesmo local.

O modelo nulo estratificado e

\[
Y_{i,k}\sim\operatorname{Poisson}(\lambda_k N_{i,k}),
\]

com taxas basais `lambda_k` proprias de cada categoria, mas sem efeito espacial
adicional. A hipotese nula permite que o risco basal varie entre categorias; o
que ela exclui e um multiplicador espacial adicional para uma zona.

Defina os totais globais:

\[
C_k=\sum_{i=1}^{n}Y_{i,k},\qquad
N_{G,k}=\sum_{i=1}^{n}N_{i,k},
\]

e, para uma zona candidata `Z`:

\[
C_{Z,k}=\sum_{i\in Z}Y_{i,k},\qquad
N_{Z,k}=\sum_{i\in Z}N_{i,k}.
\]

## 3. Expectativa ajustada por padronizacao indireta

Sob o modelo nulo, a taxa estimada no estrato `k` e

\[
\widehat{\lambda}_k=\frac{C_k}{N_{G,k}}.
\]

Logo, o numero esperado de casos na zona `Z` e

\[
E_Z=\sum_{k=1}^{K}C_k\frac{N_{Z,k}}{N_{G,k}}.
\]

Essa e a expressao solicitada no TCC. Ela compara a composicao populacional da
zona com a composicao da regiao inteira, mantendo a taxa observada de cada
estrato. O total esperado global e

\[
E_G=\sum_{k=1}^{K}C_k=C_G,
\]

quando os totais de casos dos estratos sao usados como estimadores das taxas.
O esperado fora da zona e `E_G-E_Z`.

Para uma unica covariavel binaria, por exemplo `COVAR_TMAX=0/1`, a formula se
reduz a

\[
E_Z=C_0\frac{N_{Z,0}}{N_{G,0}}+
    C_1\frac{N_{Z,1}}{N_{G,1}}.
\]

Se a categoria representa carga termica, `COVAR_TMAX` deve ser construida antes
da varredura a partir de uma regra meteorologica documentada. O SaTScan nao
estima um efeito continuo de temperatura a partir de uma coluna numerica
continua; a entrada categorica representa estratos.

## 4. Verossimilhanca e razao de maxima verossimilhanca

Agregue os casos na zona:

\[
C_Z=\sum_{k=1}^{K}C_{Z,k},\qquad C_G=\sum_{k=1}^{K}C_k.
\]

Depois da padronizacao, a zona tem exposicao esperada `E_Z` e o complemento tem
exposicao esperada `E_G-E_Z`. A verossimilhanca Poisson agregada sob a hipotese
alternativa, ignorando termos fatoriais que se cancelam na razao, e

\[
L_1(Z;\theta_Z,\theta_{Z^c})=
\frac{\exp(-\theta_ZE_Z)(\theta_ZE_Z)^{C_Z}}{C_Z!}
\frac{\exp[-\theta_{Z^c}(E_G-E_Z)]
      [\theta_{Z^c}(E_G-E_Z)]^{C_G-C_Z}}
     {(C_G-C_Z)!}.
\]

Sob a hipotese nula ha um unico multiplicador `theta` para toda a regiao:

\[
L_0(\theta)=
\frac{\exp(-\theta E_G)(\theta E_G)^{C_G}}{C_G!}.
\]

Condicionando pelo total `C_G`, ou maximizando os parametros de interesse, a
razao de verossimilhanca para uma zona de alto risco pode ser escrita como

\[
\lambda(Z)=
\left(\frac{C_Z}{E_Z}\right)^{C_Z}
\left(\frac{C_G-C_Z}{E_G-E_Z}\right)^{C_G-C_Z}
I\!\left(\frac{C_Z}{E_Z}>\frac{C_G-C_Z}{E_G-E_Z}\right)
\;+
I\!\left(\frac{C_Z}{E_Z}\leq
\frac{C_G-C_Z}{E_G-E_Z}\right).
\]

Na segunda parcela a razao e definida como 1: a zona nao e candidata a
*cluster* de alto risco quando a taxa padronizada interna nao supera a externa.
Em computacao e preferivel usar o logaritmo:

\[
\log\lambda(Z)=
C_Z\log\left(\frac{C_Z}{E_Z}\right)+
(C_G-C_Z)\log\left(\frac{C_G-C_Z}{E_G-E_Z}\right),
\]

quando a desigualdade de alto risco e satisfeita, adotando `0` caso contrario.
Convencoes para `0 log 0` devem retornar zero. A estatistica da varredura e

\[
\lambda^*=\max_{Z\in\mathcal{Z}}\lambda(Z),
\qquad
\widehat Z=\arg\max_{Z\in\mathcal{Z}}\lambda(Z).
\]

A significancia global e obtida por Monte Carlo, mantendo a estrutura de
estratos e repetindo a varredura em cada replicacao. Para `B` replicacoes,

\[
p=\frac{1+\sum_{b=1}^{B}I(\lambda_b^*\geq\lambda_{obs}^*)}{B+1}.
\]

## 5. Interpretacao epidemiologica

Um *cluster* detectado depois do ajuste por `Tmax` indica que a zona possui mais
casos do que o esperado depois de considerar a distribuicao dos municipios nos
estratos de exposicao termica escolhidos. Em linguagem epidemiologica, e um
excesso de risco residual em relacao ao risco basal estratificado.

Essa interpretacao tem quatro limites:

1. ela depende da categorizacao de temperatura e dos pontos de corte;
2. um ajuste categorico nao representa todo o gradiente termico nem efeitos
   defasados;
3. temperatura pode ser mediadora, marcador de clima ou correlata de urbanizacao,
   chuva, umidade e mobilidade, e nao necessariamente um confundidor;
4. a unidade municipal, a subnotificacao e a agregacao de 16 anos permanecem
   fontes de vies e nao sao eliminadas pelo ajuste.

Assim, a comparacao correta e entre a varredura sem ajuste e a varredura
ajustada: mudancas no numero, tamanho ou risco relativo dos *clusters* mostram
quanto da heterogeneidade espacial e compatível com a estratificacao termica
usada. Isso nao e uma estimativa de efeito causal da temperatura sobre dengue.

## 6. Arquivos de entrada do SaTScan

Os arquivos sao ASCII delimitados por espacos. A ordem das colunas e parte do
contrato de entrada.

### Modelo Poisson sem covariavel

Para um periodo espacial agregado, uma forma minima e:

```text
# .cas: local  casos  tempo (se o tempo for informado)
110001  120  2025
110002   80  2025
```

```text
# .pop: local  tempo  populacao
110001  2025  12345
110002  2025   9876
```

O arquivo `.geo` contem `local latitude longitude` ou a convencao equivalente
definida pelo software. Os identificadores precisam coincidir entre os tres
arquivos.

### Modelo Poisson com covariavel categorica

As covariaveis sao colunas adicionais no `.cas` e no `.pop`, com os mesmos
valores e na mesma ordem logica:

```text
# .cas: local  casos  tempo  covar_tmax
110001  120  2025  1
110002   80  2025  0
```

```text
# .pop: local  tempo  populacao  covar_tmax
110001  2025  12345  1
110002  2025   9876  0
```

Cada coluna extra deve ser categorica. Os codigos podem ser numericos ou
alfanumericos, desde que a categoria seja identica nos dois arquivos. O manual
do SaTScan descreve esse mecanismo como ajuste por covariaveis categoricas nos
arquivos de casos e populacao; nao e necessario inventar um parametro
`CovariatesFile` no `.prm` para esse modo.

Para uma implementacao em R, a mesma logica pode ser representada por uma
matriz de exposicao `N[i,k]` e uma matriz de casos `C[i,k]`, calculando:

```r
E_z <- sum(C_k * N_zk / N_gk)
```

e fornecendo ao algoritmo uma linha por combinacao local--tempo--categoria,
quando a entrada estratificada for usada. Antes de executar, validar:

```r
stopifnot(identical(cas$id, pop$id))
stopifnot(identical(cas$covar_tmax, pop$covar_tmax))
stopifnot(all(pop$population >= 0), all(cas$cases >= 0))
```

Os arquivos finais e seus hashes devem ser registrados no checkpoint. Alterar a
categoria, a fonte climatica, a janela, a semente ou o numero de replicacoes
invalida o resultado salvo.

## 7. Temperatura maxima no desenho deste TCC

O ajuste recomendado e usar uma categoria derivada de uma fonte diaria validada:

1. estimar, para cada municipio e mes, `q_0,90` da `Tmax` diaria;
2. marcar dias com `Tmax >= q_0,90`;
3. identificar sequencias de pelo menos tres dias;
4. contar dias pertencentes a sequencias (`D_i`);
5. definir `COVAR_TMAX_i` antes de gerar `.cas` e `.pop`;
6. executar a varredura sem ajuste e a ajustada com o mesmo protocolo de Monte
   Carlo.

Se apenas o painel mensal atual estiver disponivel, o script deve interromper a
varredura ajustada ou marcar explicitamente o resultado como analise de proxy.
Nao e valido chamar a media mensal de `Tmax` diaria.

## 8. Texto pronto para a Seção 2.4 do manuscrito

O bloco abaixo pode ser inserido na secao de materiais e metodos. Ele usa a
notacao do manuscrito e mantem a ressalva sobre a covariavel categorica.

```latex
\subsection{Ajuste por covariável no modelo de Poisson}
\label{subsec:scan_covariavel}

Para avaliar se a identificação dos \textit{clusters} persistia após o controle
da exposição térmica basal, considerou-se uma covariável categórica derivada da
temperatura máxima diária. Seja $k=1,\ldots,K$ uma categoria de exposição, e
sejam $C_k$ e $N_{G,k}$, respectivamente, o número total de casos e a população
sob risco no estrato $k$ em toda a região de estudo $G$. Para uma zona candidata
$Z$, denote por $N_{Z,k}$ a população do estrato $k$ contida na zona. Sob a
hipótese nula de risco espacialmente homogêneo dentro de cada estrato, a taxa
basal estimada é $\widehat{\lambda}_k=C_k/N_{G,k}$ e o número esperado de casos
na zona é obtido por padronização indireta:
\begin{equation}
 E_Z=\sum_{k=1}^{K} C_k\frac{N_{Z,k}}{N_{G,k}}.
 \label{eq:expected_covariate}
\end{equation}

Definindo $C_Z$ como o total observado na zona e $C_G$ como o total observado
na região, a razão de verossimilhança ajustada para uma alternativa de alto
risco é
\begin{equation}
 \lambda(Z)=
 \left(\frac{C_Z}{E_Z}\right)^{C_Z}
 \left(\frac{C_G-C_Z}{C_G-E_Z}\right)^{C_G-C_Z}
 I\!\left(\frac{C_Z}{E_Z}>\frac{C_G-C_Z}{C_G-E_Z}\right),
 \label{eq:lr_covariate}
\end{equation}
com valor unitário quando a taxa padronizada interna não supera a taxa externa.
A estatística de teste é $\lambda^*=\max_{Z\in\mathcal{Z}}\lambda(Z)$, e a
significância é obtida por simulações de Monte Carlo que preservam a
estratificação. No arquivo de entrada do SaTScan, a categoria térmica é
informada como coluna adicional nos arquivos `.cas` e `.pop`, com os mesmos
identificadores e valores em ambos. Portanto, o ajuste controla a composição
dos municípios segundo a categoria de temperatura, mas não representa um efeito
linear contínuo, não elimina confundimento residual e não deve ser interpretado
como evidência causal individual.
```

## Referencias tecnicas

- SaTScan. [Software for the spatial, temporal, and space-time scan statistics](https://www.satscan.org/). Consulta em 05 set. 2026.
- SaTScan. [Technical documentation and User Guide](https://www.satscan.org/techdoc.html). Consulta em 05 set. 2026.
- Kulldorff, M. A spatial scan statistic. *Communications in Statistics: Theory and Methods*, 26, 1481--1496, 1997.
- Kulldorff, M.; Nagarwalla, N. Spatial disease clusters: detection and inference. *Statistics in Medicine*, 14, 799--810, 1995.
- Ahmed, M.-S.; Genin, M. A functional-model-adjusted spatial scan statistic. arXiv:1903.01130, 2019. [Texto](https://arxiv.org/abs/1903.01130).
- SpatialEpi. [Documentacao do metodo de Kulldorff](https://search.r-project.org/CRAN/refmans/SpatialEpi/html/kulldorff.html). Consulta em 05 set. 2026.
