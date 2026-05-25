# Mortes Evitáveis por Raça

Plataforma modular de monitoramento de mortes evitáveis e desigualdades raciais no Brasil.

## Como configurar o ambiente (Qualquer Máquina)

1.  **Requisitos:** Ter o R (>= 4.1) e o RStudio instalados.
2.  **Clone o Repositório:**
    ```bash
    git clone https://github.com/EvandroStk9/mortes_evitaveis_por_raca.git
    cd mortes_evitaveis_por_raca
    ```
3.  **Instale as Dependências:**
    Abra o RStudio no arquivo `mortes_evitaveis_por_raca.Rproj` e execute:
    ```r
    source("install_deps.R")
    ```
4.  **Organize os Dados:**
    Certifique-se de que os arquivos `.parquet` do projeto de Trânsito estão em:
    `data/raw/transito/sim_do_v_*.parquet`

## Como Executar o Pipeline

O pipeline gerencia automaticamente a ordem de execução e o cache dos dados.

```r
targets::tar_make()
```

## Como Visualizar os Resultados

Para abrir o Dashboard interativo:
```r
shiny::runApp('apps/plataforma_monitoramento')
```

## Estrutura Técnica

-   **Backend:** R + {targets} + DuckDB (Processamento de alta performance).
-   **Armazenamento:** Arquivos Parquet (Compactos e rápidos).
-   **Frontend:** Shiny Dashboard modular.
-   **Documentação:** Quarto (.qmd).
-   **Padrões:** UTF-8 para garantir acentuação correta em Português.
