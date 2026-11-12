# Dengue e epidemiologia espacial

Trabalho de Conclusão de Curso em Estatística de Lucas Batista de Oliveira, Universidade Federal Fluminense, sobre a distribuição espacial da dengue no Brasil, 2010–2025.

## Estrutura

| Pasta | Conteúdo |
|---|---|
| `R/` | Pipeline R numerado na ordem de execução |
| `data/raw/` | Insumos originais, sem edição |
| `data/processed/` | Bases harmonizadas e intermediários |
| `data/metadata/` | Proveniência e definições |
| `output/figures/`, `output/tables/` | Figuras, tabelas e TSVs |
| `output/models/` | Modelos persistidos e arquivos nativos SaTScan |
| `output/macros/`, `output/logs/` | Macros LaTeX e logs científicos |
| `tex/` | Manuscrito, capítulos, bibliografia, classe e logos |
| `slides/` | Defesa, roteiros e apresentações de reunião |
| `docs/` | Bibliografia, auditorias e arquivos históricos |
| `revisar_descarte/` | Arquivos preservados para avaliação de exclusão |

## Execução em R

Abrir `TCC.Rproj` na raiz. O pacote `here` ancora os caminhos por `here::i_am()` em cada script executável. Não executar todos os scripts apenas para testar caminhos: downloads, ETL e modelos podem atualizar saídas existentes.

| Ordem | Script |
|---|---|
| 01 | `R/01_etl_censo_2022.R` |
| 02 | `R/02_extracao_clima_era5.R` |
| 03 | `R/03_download_era5land_diario.R` |
| 04 | `R/04_ondas_calor_era5land.R` |
| 05 | `R/05_consolidacao_dataset.R` |
| 06 | `R/06_covar_composta.R` |
| 07 | `R/07_covar_individuais.R` |
| 08 | `R/08_analises_descritivas.R` |
| 09 | `R/09_heatmap_uf_ano.R` |
| 10 | `R/10_varredura_satscan.R` |
| 11 | `R/11_wmape_satscan.R` |
| 12 | `R/12_mapas_pranchas.R` |
| 13 | `R/13_mapas_slides.R` |
| 14 | `R/14_gerar_legenda_rr_slides.R` |
| 15 | `R/15_gerar_series_regionais_slides.R` |

Exemplo de execução deliberada, a partir da raiz:

```bash
Rscript --vanilla "R/08_analises_descritivas.R"
```

O download diário requer `CDS_EMAIL` no ambiente. A varredura requer SaTScan em `$HOME/bin` e escolha explícita de `SATSCAN_AJUSTE_TERMICO` (`nao`, `sim`, `comp5`, `esgoto`, `densurb`, `propurb`, `agua` ou `lixo`) e `SATSCAN_PERIODO` (`completo` ou `sem2024`). São oito formulações em dois cenários; manter os sufixos próprios de cada rodada.

```bash
SATSCAN_AJUSTE_TERMICO=nao SATSCAN_PERIODO=completo Rscript --vanilla "R/10_varredura_satscan.R"
```

Os três scripts históricos recebidos com os dados permanecem intactos em `data/raw/`. Eles não fazem parte desta esteira e podem conter caminhos relativos antigos ou caminhos Windows.

## Compilação

Executar da raiz. `-cd` faz a compilação operar na pasta do mestre; `build/` recebe PDF e auxiliares. A opção `-bibtexfudge-` mantém o BibTeX na pasta do mestre, permitindo compartilhar a bibliografia de `tex/` sem copiá-la:

```bash
latexmk -pdf -cd -bibtexfudge- -outdir=build "tex/Projeto Final.tex"
latexmk -pdf -cd -bibtexfudge- -outdir=build "slides/Defesa TCC.tex"
latexmk -pdf -cd -bibtexfudge- -outdir=build "slides/notes/Roteiro Defesa TCC.tex"
latexmk -pdf -cd -bibtexfudge- -outdir=build "slides/notes/Roteiro Completo de Estudo.tex"
latexmk -pdf -cd -bibtexfudge- -outdir=build "slides/notes/Consulta Rápida da Defesa.tex"
```

O PDF anterior da monografia está em `output/documents/Projeto Final.pdf`; os PDFs anteriores da defesa e das notas foram preservados ao lado dos respectivos fontes. O manuscrito carrega apenas as macros SaTScan do modelo puro.

## Dados, preservação e migração

O painel analítico deve conter 5.564 municípios e 16 anos, totalizando 89.024 observações. A malha bruta inclui Fernando de Noronha; a restrição é aplicada na harmonização analítica.

Os dados locais não acompanham necessariamente um clone. Consultar `data/metadata/manifesto_proveniencia.md` e `data/metadata/organizacao_repositorio.md` para reconstrução. O `.gitignore` preserva a separação dos dados locais e lista explicitamente os caminhos maiores que 50 MB existentes na migração; ele não consegue selecionar automaticamente futuros arquivos pelo tamanho.

A reorganização autorizada de 12/11/2026 tem registros locais em `docs/audits/reorganizacao_2026-11-12/`. Após avaliação, foram excluídos somente 58 auxiliares autorizados; cinco logs e o inventário permanecem em `revisar_descarte/`. Esses registros de recuperação não integram a versão pública. Dados e duplicatas científicas foram preservados.

## GitHub e transferência para mídia física

O repositório público está em [Grugg8/projeto-final](https://github.com/Grugg8/projeto-final). A versão publicada contém os scripts ativos, fontes do manuscrito e defesa, notas de apoio, bibliografia BibTeX, logos, figuras usadas nesses documentos, tabelas, macros, logs selecionados e resultados nativos atuais do SaTScan.

Dados brutos e processados, RDS de modelos, PDFs compilados, bibliografia em PDF, exportações duplicadas, materiais históricos, configurações de agentes e cópias de recuperação ficam locais. Os dados precisam ser obtidos ou transferidos separadamente para executar a análise; os fontes LaTeX atuais podem ser compilados com os artefatos publicados.

Para baixar a versão leve, usar o botão **Code → Download ZIP** no GitHub ou clonar o repositório. Isso não constitui um backup integral dos dados. Orientações de publicação, espaço e cópia física em [docs/publicacao_e_backup.md](docs/publicacao_e_backup.md).
