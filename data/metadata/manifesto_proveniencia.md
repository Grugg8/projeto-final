# Manifesto de Proveniência

Manifesto mínimo para reconstrução do estudo. Valores não registrados nos artefatos atuais permanecem explicitamente pendentes; não devem ser inferidos.

| Componente | Fonte/arquivo | Cobertura | Estado |
|---|---|---|---|
| Casos | DATASUS/SINAN, arquivos DBC | 2010--2025 | Data de extração de 2025 não preservada; registrar antes de nova execução |
| Malha | `data/raw/malhas/malha_BR_10.RDS` | referência municipal 2010 | Versionada; registrar SHA-256 no próximo release |
| População | entradas IBGE/TCU usadas por `05_consolidacao_dataset.R` | 2010--2025 | Registrar arquivo, tabela, data e SHA-256 |
| Temperatura diária | CDS ERA5-Land, `era5land_t2m_YYYY.nc` | 2010--2025 | Script usa 00/06/12/18 UTC; registrar requisições, cobertura e SHA-256 |
| Temperatura/umidade | CDS ERA5 | 2010--2025 | Registrar variável, nível, requisição e SHA-256 |
| Precipitação | Brazilian Unified Rainfall Dataset / UNIPLU-BR | 2010--2025 | Registrar versão, DOI, arquivos e SHA-256 |
| Socioespacial | IBGE Censo 2022/SIDRA | 2022 | Registrar tabelas SIDRA, data e extração |
| Varredura | SaTScan v10.3.2 via `rsatscan` | painel agregado | Preservar `.cas`, `.pop`, `.geo`, `.prm`, saída nativa e RDS |

## Regras de reconstrução

1. Não versionar credenciais. O download ERA5-Land requer `CDS_EMAIL` no ambiente.
2. Calcular SHA-256 de cada entrada antes do ETL e gravar os hashes no log do run.
3. Registrar versão do R, pacotes (`renv.lock` ou equivalente) e executável SaTScan.
4. Registrar data/hora de download e data de corte dos DBCs, especialmente 2025.
5. Manter separados dados brutos e derivados durante a reconstrução do pipeline.

## Artefatos canônicos atuais

- Manuscrito: `tex/Projeto Final.tex`
- Modelo reportado no apêndice: `output/tables/tabela_clusters_satscan_puro.tex`
- Macros canônicas: `output/macros/macros_satscan_puro.tex`
- Parâmetros: `output/models/params/satscan_params_puro.prm`

Os resultados térmicos persistidos são tratados como análise comparativa histórica até que a cadeia de origem seja congelada e rerodada.
