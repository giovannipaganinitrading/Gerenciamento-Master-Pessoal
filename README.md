# Gerenciamento Master Pessoal (MQL5 / MetaTrader 5)

Expert Advisor completo de **Gestão de Risco, Execução Rápida por Atalhos, Disciplina Operacional com Cofre de Senha e Sinalizador de Barra Forte & Pivô** para MetaTrader 5 (MQL5).

---

## 🚀 Principais Funcionalidades

### 1. Cálculo Automático de Lote & Execução por Atalhos
- **Risco Fixo (`$ USD`) ou Percentual (`%` do Saldo):** Calcula automaticamente o volume exato da operação com base na distância entre a **Linha de Entrada (Azul)** e a **Linha de Stop Loss (Vermelha)**.
- **Modo Mercado ou Ordem Pendente (`Buy/Sell Limit` e `Buy/Sell Stop`):** Alternância instantânea pela tecla `T` ou botão no painel.
- **Fracionamento Automático de Ordens (Order Splitting):** Divide automaticamente lotes grandes em múltiplos envios caso o volume calculado ultrapasse o limite por ordem do ativo (ex.: Ações, Índices/WIN, Forex/CFDs) e gerencia todas as frações como uma única operação unificada.
- **Parcial Rápida (`P`) e Adição de Posição (`A`):**
  - Executa parciais com 1 clique/tecla mesmo em contas **Hedge** ou **Netting**.
  - Permite adicionar lote à operação aberta (limitado a até 50% do volume inicial) **somente quando o Stop Loss já estiver protegido no Break-Even (0x0) ou no lucro**.

### 2. 🔒 Trava de Disciplina Diária (Turnos Dia + Noite/HK) & Cofre por Senha
- **Controle por Turno:**
  - **Turno Dia:** `00:00` até `19:59` (horário local).
  - **Turno Noite (HK):** a partir das `20:00` (configurável em `InpNightSessionStartHour`).
- **Máximo de Trades por Turno (`Máx Trades`):**
  - Conta como **1 trade** a operação completa (incluindo entradas fracionadas e adições na mesma posição aberta).
  - Se atingir o limite de trades do turno, bloqueia novas aberturas (mas mantém liberadas adições a favor da posição já aberta e com stop protegido).
- **Loss Máximo por Turno (`Loss Máx $`):**
  - Monitora em tempo real a soma do **resultado fechado no turno + lucro/prejuízo flutuante aberto**.
  - Caso a perda atinja ou ultrapasse o limite estipulado (ex.: `-30.00 USD`), o EA **zera todas as posições abertas a mercado, cancela ordens pendentes e trava novas operações** até a virada do próximo turno.
- **Cofre de Senha Anti-Sabotagem (`FILE_COMMON`):**
  - Permite cadastrar uma senha diretamente no painel (`🔒 Cadastrar e Travar`).
  - Trava a edição de **Risco (`$`/`%`)**, **Máx Trades** e **Loss Máx ($)** com hash criptografado salvo em `GerenciamentoMaster_Security.dat` (`FILE_COMMON`).
  - **Imune a remoção do EA ou alteração via `F7`:** Mesmo se remover e recolocar o EA no gráfico, reiniciar o MT5 ou tentar alterar os inputs no `F7`, o Cofre prevalece e mantém os limites travados até que a senha correta seja digitada em `🔑 Destravar Risco`.

### 3. ★ Sinalizador Visual de Ajuste Manual de Stop (Barra Forte & Pivô)
- **Nunca move o Stop sozinho:** O EA apenas marca visualmente no gráfico os pontos técnicos para você ajustar manualmente clicando no marcador ou pressionando a tecla `S`.
- **`★ BARRA FORTE` (Estrela Verde):**
  - Compara a barra recém-fechada a favor da posição contra a **média das últimas 20 barras a partir da abertura do dia atual (`00:00`)**, sem misturar barras do dia anterior.
  - Exibe o marcador na mínima (Compra) ou máxima (Venda) da barra de ignição/força.
- **`▲/▼ PIVÔ STOP` (Seta Laranja/Dourada):**
  - Identifica fundos mais altos (em Compra) ou topos mais baixos (em Venda) confirmados a favor do trade.

### 4. 🔄 Sincronização Multi-Gráfico Instantânea
- Qualquer ajuste de **Risco**, **Limites Diários**, **Senha** ou **Atalhos** sincroniza instantaneamente entre todos os gráficos abertos no MT5 via `EventChartCustom`, Variáveis Globais do Terminal e `GerenciamentoMaster_Default.ini`.
- O botão **Salvar Default** (menu da engrenagem `⚙`) salva o template `default.tpl` já com o painel minimizado no canto superior esquerdo, **Chart Shift** ajustado e **Relógio de Candles (B-Clock)** acompanhando o preço.

---

## ⌨️ Atalhos Padrão (Customizáveis no Menu `⚙`)

| Tecla | Função |
| :---: | :--- |
| **`E`** | Posicionar linha de **Entrada** na altura atual do mouse |
| **`S`** | Posicionar linha de **Stop Loss** na altura do mouse (ou mover o Stop da posição aberta) |
| **`T`** | Alternar entre ordem a **Mercado** e **Pendente** |
| **`H`** | Ocultar / Mostrar linhas no gráfico |
| **`M`** | Minimizar / Maximizar painel |
| **`ESPAÇO`** | Executar Ordem de Compra/Venda |
| **`P`** | Executar **Parcial** rápida da posição aberta |
| **`A`** | Executar **Adição** na posição aberta (requer Stop >= 0x0) |

---

## 🛠️ Estrutura de Arquivos & Como Compilar

- [`Gerenciamento Master Pessoal.mq5`](./Gerenciamento%20Master%20Pessoal.mq5) — Código-fonte completo em MQL5 (arquivo único, sem dependências externas além da biblioteca padrão `<Trade\Trade.mqh>`).
- [`Gerenciamento Master Pessoal.ex5`](./Gerenciamento%20Master%20Pessoal.ex5) — Binário compilado pronto para uso no MetaTrader 5.

### Instalação no MetaTrader 5:
1. No MT5, clique em **Arquivo -> Abrir Pasta de Dados** (`Ctrl+Shift+D`).
2. Navegue até `MQL5/Experts/`.
3. Copie o arquivo `Gerenciamento Master Pessoal.mq5` (e/ou `Gerenciamento Master Pessoal.ex5`) para dentro da pasta.
4. Para editar ou recompilar no **MetaEditor** (`F4`), abra o `.mq5` e pressione `F7` (**Compile**).
5. No MT5, ative **Negociação Algorítmica (Algo Trading)** e arraste o EA para o gráfico.
