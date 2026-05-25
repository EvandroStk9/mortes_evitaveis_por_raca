# Mortes Evitveis por Raa

Plataforma modular de monitoramento de mortes evitveis e desigualdades raciais no Brasil.

## Estrutura do Repositrio

- `core/`: Funes compartilhadas, configuraes globais e metadados base.
- `data/`: Data Lakehouse local baseado em Parquet.
    - `raw/`: Dados brutos (imutveis).
    - `staging/`: Dados limpos e padronizados.
    - `gold/`: Produtos analticos finais.
- `modules/`: Módulos temáticos (COVID, Trnsito, Homicdios, etc).
- `apps/`: Dashboards Shiny para visualizao pblica.
- `docs/`: Documentao metodolgica (Quarto).
- `tests/`: Bateria de testes de integridade e qualidade de dados.

## Como Executar

Este projeto utiliza o framework `{targets}` para gerenciar o pipeline de dados.

1. Abra o projeto no RStudio.
2. Certifique-se de que as dependncias esto instaladas (ver `core/setup.R`).
3. No console do R, execute:
   ```r
   targets::tar_make()
   ```

## Princpios de Engenharia de Dados

1. **Reprodutibilidade:** Todo o processamento  codificado e versionado.
2. **Modularidade:** Novos temas podem ser adicionados sem quebrar os existentes.
3. **Escalabilidade:** Uso de Parquet e DuckDB para lidar com grandes volumes de dados (SIM).
4. **Governança:** Metadados claros e validao de dados em todas as etapas.
