# Distribuição espacial da dengue no Brasil

Trabalho de Conclusão de Curso em Estatística de Lucas Batista de Oliveira, da Universidade Federal Fluminense (UFF), sobre a identificação de áreas de alto risco de dengue e suas características socioambientais, no período de 2010 a 2025.

## Documentos

A [monografia, a apresentação e os materiais de apoio em PDF](https://github.com/Grugg8/projeto-final/releases/tag/v2026.11.12) estão disponíveis para download.

## Estrutura

| Pasta | Conteúdo |
|---|---|
| `R/` | Scripts de preparação dos dados, análises e geração de resultados |
| `data/metadata/` | Fontes dos dados e definições metodológicas |
| `output/` | Figuras, tabelas, macros, logs e resultados nativos do SaTScan |
| `tex/` | Manuscrito em LaTeX, capítulos e bibliografia |
| `slides/` | Apresentação da defesa e roteiros de apoio |

## Reprodução

Abra `TCC.Rproj` na raiz do projeto. Os scripts em `R/` estão numerados na ordem de execução e utilizam o pacote `here` para resolver os caminhos. As análises exigem os pacotes declarados nos scripts e, para a varredura espacial, o SaTScan.

Os dados brutos e as bases processadas não estão incluídos neste repositório. Suas fontes e condições de reconstrução estão descritas em [data/metadata/manifesto_proveniencia.md](data/metadata/manifesto_proveniencia.md).

Para compilar a monografia e a defesa, com uma distribuição LaTeX e o `latexmk` instalados, execute a partir da raiz:

```bash
latexmk -pdf -cd -bibtexfudge- -outdir=build "tex/Projeto Final.tex"
latexmk -pdf -cd -bibtexfudge- -outdir=build "slides/Defesa TCC.tex"
```
