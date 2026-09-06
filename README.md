# Dengue e Epidemiologia Espacial

Trabalho de Conclusao de Curso em Estatistica sobre a distribuicao espacial de
casos provaveis de dengue no Brasil, 2010--2025.

## Estrutura

- `01. Principal/`: manuscrito, classe LaTeX, bibliografia e PDF final.
- `03. Dados/`: dados derivados, documentacao metodologica e entradas locais.
- `04. Codigos/`: pipeline R numerado de ETL, clima, consolidacao, analises e
  SaTScan.
- `05. Saidas/`: figuras, tabelas LaTeX, macros e logs regenerados pelo pipeline.
- `outputs/`: fichamentos bibliograficos e auditorias de desenvolvimento.

Os nomes de diretorio existentes preservam acentuacao para manter compatibilidade
com os arquivos do projeto. Em um novo clone, recomenda-se usar UTF-8.

## Pipeline

Executar a partir da raiz do projeto:

```bash
Rscript "04. Códigos/01_etl_censo_2022.R"
Rscript "04. Códigos/02_extracao_clima_era5.R"
Rscript "04. Códigos/02b_ondas_calor_era5land.R"
Rscript "04. Códigos/03_consolidacao_dataset.R"
Rscript "04. Códigos/04_analises_descritivas.R"
Rscript "04. Códigos/05_varredura_satscan.R"
```

O script 04 incorpora Moran global, LISA e o mapa das Grandes Regioes. O script
05 exige SaTScanBatch acessivel em `$HOME/bin` e preserva o resultado em RDS com
hash dos parametros e das entradas.

## LaTeX

```bash
cd "01. Principal"
pdflatex "Projeto Final.tex"
bibtex "Projeto Final"
pdflatex "Projeto Final.tex"
pdflatex "Projeto Final.tex"
```

## Dados

Os dados brutos do SINAN, NetCDF, chuva e malhas tem tamanho e regras de
distribuicao que nao devem ser presumidos pelo repositorio. Consulte
`03. Dados/Documentacao/organizacao_repositorio.md` antes de publicar dados ou
credenciais em um remoto.

## Estado climatico

Os NetCDF versionados contem temperatura mensal (`t2m`), nao temperatura maxima
diaria. O pipeline registra `temp_C_max` como maxima entre medias mensais e
marca essa escolha nos logs. O script `02b_ondas_calor_era5land.R` exige um
NetCDF diario em `TMAX_DIARIA_NC` e interrompe com mensagem explicita quando a
fonte nao esta disponivel; somente depois disso a covariavel termica pode ser
ativada no SaTScan.
