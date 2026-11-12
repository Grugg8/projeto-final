# Organização do repositório

Atualizada após a reorganização autorizada de 12 de novembro de 2026.

## Fontes e artefatos

- `tex/Projeto Final.tex`, `tex/sections/`, `tex/referencias.bib`, `tex/abnt.cls`, `tex/cvs-id.def` e `tex/assets/` compõem o manuscrito.
- `slides/Defesa TCC.tex`, `slides/notes/` e `slides/meetings/` contêm a apresentação e seus apoios.
- `R/01_etl_censo_2022.R` a `R/15_gerar_series_regionais_slides.R` formam a esteira numerada, detalhada em `README.md` e `AGENTS.md`.
- `data/metadata/` contém proveniência e definições metodológicas.
- `output/figures/`, `output/tables/`, `output/macros/` e `output/logs/` separam as categorias geradas.
- `output/models/` contém os objetos persistidos; `output/models/satscan/` preserva entradas e saídas nativas por rodada. `output/models/params/` guarda cópias de auditoria dos parâmetros.
- `TCC.Rproj` permanece na raiz e os scripts usam `here::i_am()` para ancoragem.

## Dados e arquivos locais

Os insumos originais estão em `data/raw/`; objetos harmonizados e intermediários, em `data/processed/`. Os RDS brutos de respostas SIDRA permanecem em `raw/`, conforme sua proveniência. Todos os componentes de um shapefile devem permanecer juntos.

O `.gitignore` mantém dados locais, arquivos pesados, auxiliares de compilação e dependências instaladas fora da inclusão comum. Os 35 arquivos existentes acima de 50.000.000 bytes recebem também entradas explícitas; o Git não dispõe de filtro automático por tamanho. A migração não publica dados nem altera o histórico remoto.

A bibliografia em PDF fica em `docs/references/`, documentos anteriores em `docs/archive/`, auditorias anteriores em `docs/audits/` e pacotes de exportação em `output/exports/`. A remoção de duplicatas não faz parte da reorganização.

## Compilação e preservação

Compilar com `latexmk -cd -bibtexfudge- -outdir=build`, conforme os comandos completos do README. Os novos PDFs e auxiliares ficam no `build/` do respectivo mestre. PDFs anteriores foram preservados para comparação.

`revisar_descarte/` reúne auxiliares antigos, metadados do Finder, histórico da interface R e o link antigo para as saídas. Nada foi excluído. Bases em `_legado/` e logs científicos não são classificados automaticamente como lixo.

O manifesto individual e as cópias de recuperação estão em `docs/audits/reorganizacao_2026-11-12/`. Consultar `mapeamento_de_para.tsv` para converter qualquer caminho anterior.

## Histórico e reconstrução

As antigas rotinas separadas de LISA e regiões foram incorporadas ao atual `R/08_analises_descritivas.R`. Os três scripts climáticos recebidos com os dados permanecem intactos em `data/raw/`, fora da esteira vigente; podem conter caminhos Windows ou referências antigas.

Registrar fonte, período, licença, data de obtenção e checksum de cada entrada antes de uma reprodução integral. Preservar os hashes de `.cas`, `.pop`, `.geo` e `.prm` junto dos resultados SaTScan. A verificação da migração não executa downloads, ETL, modelos ou geração de figuras.
