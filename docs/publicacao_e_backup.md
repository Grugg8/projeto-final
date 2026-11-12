# Publicação no GitHub e cópia física

## O que está no GitHub

O projeto usa o repositório público [Grugg8/projeto-final](https://github.com/Grugg8/projeto-final). Ele contém os fontes ativos em R e LaTeX, metadados de proveniência, figuras utilizadas pela monografia e defesa, tabelas, macros e artefatos atuais de resultados selecionados para inspeção. O `.gitignore` controla quais arquivos locais ficam fora da inclusão comum.

Os dados brutos e processados não acompanham um clone. O GitHub permite revisar o trabalho e compilar os documentos publicados, mas a reprodução das análises exige o pacote de dados separado e os programas descritos no README. Os três scripts históricos recebidos com os dados continuam no pacote local, sem alterações.

Também ficam locais os PDFs compilados, referências em PDF, materiais históricos, exportações para compartilhamento, registros de recuperação, configurações de agentes e arquivos de edição. Nenhum desses arquivos é apagado por estar no `.gitignore`.

## Como obter uma cópia leve

No GitHub, clicar em **Code → Download ZIP**. Copiar esse ZIP para a mídia física. Ele contém a versão publicada, sem o histórico do Git nem os dados locais. Após extrair, abrir `TCC.Rproj` e seguir o README. Para compilar, usar os comandos LaTeX ali descritos.

Para manter também o histórico da versão publicada, instalar o Git e clonar:

```bash
git clone https://github.com/Grugg8/projeto-final.git
```

## Como preservar os dados em mídia física

Há três conjuntos distintos:

| Cópia | Finalidade | Ordem de grandeza medida em 12/11/2026 |
|---|---|---:|
| Versão pública leve | Revisão dos fontes, resultados e compilação dos documentos | Aproximadamente 93 MB de arquivos, antes da compressão |
| Backup científico local | Dados, fontes, documentos e auditorias; sem Git, caches, builds e exportações duplicadas | Aproximadamente 11,1 GB |
| Espelho integral | Tudo, incluindo Git, caches e exportações | Aproximadamente 13,8 GB |

As medidas são tamanhos lógicos de arquivos, não o tamanho final de um ZIP. Para uma cópia completa, reservar pelo menos 16 GB livres e margem adicional para crescimento. Não formatar uma mídia que já contenha arquivos sem preservá-los antes.

Parte dos arquivos do projeto está sob gerenciamento de armazenamento do macOS: 5.807 arquivos, somando cerca de 7,8 GB lógicos, estavam sem conteúdo integral residente na medição. Por isso, o espaço ocupado localmente não representa o volume necessário para um backup offline. Antes de considerar a transferência concluída:

1. Solicitar ao Finder que mantenha os arquivos da pasta disponíveis no dispositivo, conforme a opção oferecida pelo serviço de armazenamento.
2. Aguardar a obtenção dos conteúdos e copiar para a mídia, sem interromper a operação.
3. Conferir quantidades, tamanhos e, para os dados científicos, hashes entre a origem e a cópia.
4. Testar a abertura dos documentos e a leitura dos dados na mídia sem depender de conexão com a nuvem.

Não foi criada uma cópia integral nesta operação, pois não foi indicada uma mídia de destino. Também não foram baixados em massa todos os arquivos apenas para criar um ZIP adicional na máquina.

## Espaço que ainda pode ser avaliado

A exclusão autorizada de 58 auxiliares liberou cerca de 0,6 MB. Os dados científicos permaneceram preservados. As oportunidades maiores exigem decisão separada:

- Cerca de **202 MB** em 117 cópias exportadas tiveram igualdade de SHA-256 confirmada com os originais. Os dois ZIPs de exportação ocupam mais **194 MB**, mas seu conteúdo integral não foi comparado.
- Dezesseis pares de mapas atuais são idênticos por SHA-256, com cerca de **43 MB** por um conjunto de cópias. Há referências históricas aos dois padrões de nome; não os excluir indiscriminadamente.
- `base_final.RDS`, `base_mapas.rds` e `base_contagem.rdata` somam cerca de **917 MB** e não são usados como entradas ou saídas pelos scripts ativos. São candidatos a arquivamento externo, sem prova de que sejam descartáveis.
- A pasta local `.git/` tem cerca de **2,2 GB lógicos**, incluindo referências de recuperação do aplicativo. Ela não integra o ZIP obtido pelo GitHub. Limpar seu histórico exige auditoria própria; não executar remoção de referências ou limpeza agressiva como etapa automática.

Nenhuma dessas exclusões adicionais foi executada. Guardar um backup validado antes de autorizar qualquer redução de dados ou registros de recuperação.

## Atualizações futuras

Editar os fontes e executar as verificações pertinentes. Conferir a lista de arquivos antes de adicioná-los ao Git, pois o `.gitignore` não impõe um limite automático de tamanho. Não incluir credenciais, dados brutos, backups pessoais ou arquivos acima de 50 MB na versão comum do repositório. A publicação inicial desta organização preserva o histórico remoto e não utiliza envio forçado.
