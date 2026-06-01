# Download de Séries do BCB - Resumo

Data: 2026-06-01
Data de Referência: 2026-06-01

## Resumo Executivo
- **Total de Séries**: 5
- **Sucesso**: 5
- **Falhas**: 0

## Séries Baixadas com Sucesso

### 1. IPCA mensal (SGS 433)
- Status: ✓ Sucesso
- Registros: 58
- Período: 2021-07-01 a 2026-04-01
- Arquivo: output/dados/ipca.csv
- Notas: Série mensal, baixada via rbcb::get_series()

### 2. Câmbio R$/US$ (SGS 1)
- Status: ✓ Sucesso
- Registros: 1.254
- Período: 2021-06-02 a 2026-05-29
- Arquivo: output/dados/cambio.csv
- Notas: Série diária, requer parâmetros de data. Baixada via API BCB com RCurl

### 3. Selic meta (SGS 432)
- Status: ✓ Sucesso
- Registros: 1.826
- Período: 2021-06-02 a 2026-06-01
- Arquivo: output/dados/selic.csv
- Notas: Série diária, requer parâmetros de data. Baixada via API BCB com RCurl

### 4. IBC-Br original (SGS 24363)
- Status: ✓ Sucesso
- Registros: 57
- Período: 2021-07-01 a 2026-03-01
- Arquivo: output/dados/ibc_original.csv
- Notas: Série mensal, baixada via rbcb::get_series()

### 5. IBC-Br com ajuste sazonal (SGS 24364)
- Status: ✓ Sucesso
- Registros: 57
- Período: 2021-07-01 a 2026-03-01
- Arquivo: output/dados/ibc_sa.csv
- Notas: Série mensal, baixada via rbcb::get_series()

## Observações Técnicas

### Problema Inicial com Séries Diárias
As séries de câmbio (SGS 1) e Selic (SGS 432) retornavam erro 406 do servidor BCB quando consultadas sem parâmetros de data. A solução foi:
1. Consultar a API diretamente via RCurl (em vez de rbcb::get_series())
2. Incluir parâmetros dataInicial e dataFinal no formato dd/mm/aaaa
3. Respeitar a limitação de 10 anos de janela de consulta para séries diárias

### Schema dos Arquivos CSV
Todos os arquivos seguem o schema:
- Coluna 1: `data` (formato ISO YYYY-MM-DD)
- Coluna 2: `valor` (numérico)

## Próximas Etapas
Os dados estão prontos para cálculo de variações (mensal, anual, 12 meses) conforme a política de convenção:
- var_mes: usar série SA (IBC-Br com ajuste sazonal)
- var_ano e var_12m: usar série original (IBC-Br sem ajuste)
