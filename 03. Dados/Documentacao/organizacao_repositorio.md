# Organizacao para um repositorio GitHub

## Manter no repositorio

- `01. Principal/Projeto Final.tex`, `referencias.bib`, `abnt.cls`, `cvs-id.def`
  e `logoUFF.pdf`.
- `03. Dados/Documentacao/`, incluindo a revisao de calor extremo e a
  formulacao do SaTScan.
- `04. Códigos/01_etl_censo_2022.R` a `05_varredura_satscan.R`.
- `TCC.Rproj`, `README.md` e `.gitignore`.
- Logs de auditoria, macros, tabelas `.tex` e figuras finais necessarias para
  reproduzir o PDF, desde que o tamanho do remoto seja aceitavel.
- Checkpoints derivados pequenos ou intermediarios quando sua origem e hash
  estiverem documentados.

## Manter fora do Git comum

- DBCs do SINAN, NetCDF, ZIPs de chuva e shapefiles brutos: usar armazenamento
  institucional, Git LFS ou um pacote de dados com licenca e checksum.
- `base_final.RDS`, `base_mapas.rds`, `malha_BR_10.RDS` e outros RDS grandes:
  publicar apenas se houver justificativa de licenca e capacidade de LFS.
- Arquivos `.aux`, `.bbl`, `.blg`, `.log`, `.toc` e demais produtos temporarios
  do LaTeX.
- `Projeto_Dengue.html` enquanto nao houver fonte reprodutivel que o gere.
- PDFs de versoes antigas, apresentações, cronogramas e devolutivas que nao
  fazem parte do manuscrito final; preserva-los em um arquivo de deposito, nao
  no caminho principal do pipeline.

## Removido ou consolidado

- `04b_analise_lisa.R` e `04c_fig_mapa_grandes_regioes.R` foram incorporados a
  `04_analises_descritivas.R` para evitar leituras independentes da malha.
- `código-base.R` foi retirado do pipeline ativo por duplicar ETL, mapas e
  SaTScan com caminhos e definicoes divergentes.
- Scripts climaticos antigos em `03. Dados/Originais/` devem ser tratados como
  historico ate serem arquivados com sua fonte e data de execucao.

## Regras de publicacao

1. Nunca publicar chaves, cookies, credenciais ou caminhos pessoais.
2. Registrar fonte, periodo, licenca, checksum e data de download para cada dado
   bruto disponibilizado externamente.
3. Versionar parametros do SaTScan junto com os hashes dos arquivos `.cas`,
   `.pop` e `.geo`.
4. Regerar figuras e tabelas a partir dos scripts, em vez de editar saidas
   manualmente.
