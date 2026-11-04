//+------------------------------------------------------------------+
//|                                         GerenciamentoMaster.mq5  |
//|                             Desenvolvido para MetaTrader 5 (MQL5)|
//|                                                                  |
//| Gerenciamento Master - Gestao de Risco & Execucao Agil           |
//+------------------------------------------------------------------+
#property copyright "@giovannipaganinitrading"
#property link      "https://www.mql5.com"
#property description "Gerenciamento Master (@giovannipaganinitrading) - Risco, Parciais, Adicoes e Fibo R:R Automatica."

#include <Trade\Trade.mqh>

//--- Enums
enum ENUM_RISK_MODE
{
    RISK_FIXED_USD = 0, // Risco Fixo em Moeda ($ USD)
    RISK_PERCENT   = 1  // Risco em Porcentagem (%)
};

enum ENUM_CANDLE_TIMER_POS
{
    TIMER_POS_TOP_RIGHT    = 0, // Canto Superior Direito (Recomendado - Fixo)
    TIMER_POS_BOTTOM_RIGHT = 1, // Canto Inferior Direito
    TIMER_POS_TOP_LEFT     = 2, // Canto Superior Esquerdo
    TIMER_POS_BOTTOM_LEFT  = 3, // Canto Inferior Esquerdo
    TIMER_POS_FOLLOW_PRICE = 4  // Junto ao Preco
};

//--- Parametros de Entrada
input group "=== Configuracoes de Risco ==="
input ENUM_RISK_MODE InpDefaultRiskMode = RISK_FIXED_USD; // Modo de Risco Inicial
input double         InpRiskCash        = 10.0;           // Risco Fixo ($)
input double         InpRiskPercent     = 1.0;            // Risco em % (quando ativo)
input double         InpRiskStepCash    = 5.0;            // Passo de ajuste de $ (+ / -)
input double         InpRiskStepPercent = 0.25;           // Passo de ajuste de % (+ / -)

input group "=== Atalhos Padrao (Customizaveis na Engrenagem) ==="
input string         InpKeyEntry        = "E";            // Tecla: Marcar Entrada
input string         InpKeyStop         = "S";            // Tecla: Marcar Stop Loss
input string         InpKeyMode         = "T";            // Tecla: Alternar Mercado/Pendente
input string         InpKeyHide         = "H";            // Tecla: Ocultar Linhas
input string         InpKeyMin          = "M";            // Tecla: Minimizar/Maximizar Painel
input string         InpKeyExec         = "ESPACO";       // Tecla: Executar Ordem
input string         InpKeyPartial      = "P";            // Tecla: Parcial Rapida em Hedge

input group "=== Configuracoes de Parcial e Adicao ==="
input string         InpKeyAdd          = "A";            // Tecla: Adicao de Posicao
input double         InpDefaultPartialPercent = 30.0;     // Porcentagem Padrao de Parcial (%)
input double         InpDefaultAddPercent     = 50.0;     // Porcentagem Padrao de Adicao (Max 50%)

input group "=== Fracionamento e Divisao de Ordens ==="
input bool           InpEnableOrderSplitting  = true;      // Ativar Fracionamento Automatico de Ordens?
input double         InpMaxVolumePerOrder     = 0.0;       // Max Volume por Ordem (0 = Auto por Ativo)
input double         InpMaxVolStockDefault    = 500.0;     // Limite Padrao p/ Acoes (quando Auto)
input double         InpMaxVolIndexDefault    = 100.0;     // Limite Padrao p/ Indices (quando Auto)
input string         InpCustomSymbolLimits    = "";        // Limites Extras por Ativo (Ex: PETR4=500;WIN*=100)

input group "=== Relogio de Candles (Candle Timer) ==="
input bool                  InpEnableCandleTimer    = true;                    // Ativar Relogio de Candles?
input ENUM_CANDLE_TIMER_POS InpCandleTimerPos       = TIMER_POS_FOLLOW_PRICE;  // Posicao do Relogio (Acompanhar a Barra / Preco)
input color                 InpCandleTimerColor     = C'15,23,42';             // Cor do Relogio (Dark Slate / Preto)
input int                   InpCandleTimerSize      = 9;                       // Tamanho da Fonte do Relogio (B-Clock: 9)
input bool                  InpCandleTimerShowSpread= false;                   // Exibir Spread junto ao Relogio?

input group "=== Fibonacci de Risco:Retorno Automatica ==="
input bool           InpAutoFibo        = true;           // Tracar Fibonacci de R:R ao Abrir Ordem?
input bool           InpFiboRayRight    = false;          // Estender Niveis para a Direita (Ray Right)?
input bool           InpShowFiboPrice   = false;          // Exibir Preco junto aos Niveis da Fibo?

input group "=== Configuracoes da Ordem ==="
input bool           InpDefaultPending  = false;          // Comecar em modo Pendente?
input ulong          InpMagicNumber     = 998877;         // Magic Number
input ulong          InpSlippage        = 15;             // Slippage Tolerado (pontos)
input string         InpOrderComment    = "GMaster";      // Comentario da Ordem

input group "=== Posicao e Cores ==="
input int            InpPanelScale      = 86;            // Tamanho do painel aberto (40 a 150%)
input int            InpMinimizedScale  = 67;            // Tamanho da barra minimizada (60 a 150%)
input bool           InpAutoFitPanel    = true;           // Ajustar automaticamente ao tamanho do grafico
input int            InpPanelX          = 12;             // Posicao X inicial (abaixo do nome do ativo)
input int            InpPanelY          = 48;             // Posicao Y inicial (abaixo do nome do ativo)
input bool           InpStartMinimized  = true;           // Começar com o painel minimizado
input color          InpColorEntry      = C'37,99,235';   // Cor Linha de Entrada (Azul)
input color          InpColorStop       = C'220,38,38';   // Cor Linha Stop Loss (Vermelho)

input group "=== Sinalizador de Ajuste de Stop (Barra Forte & Pivo) ==="
input bool           InpEnableStopSignals     = true;       // Ativar Marcacao de Barra Forte e Pivo?
input int            InpStrongBarLookback     = 20;         // Periodo da Media de Tamanho das Barras (Ex: Ultimas 20 barras)
input double         InpStrongBarRatio        = 1.00;       // Proporcao p/ Barra Forte vs Media das 20 Barras (Ex: 1.0 = 100%)
input color          InpColorStrongBar        = C'21,128,61'; // Cor da Seta de Barra Forte (Verde)
input color          InpColorPivot            = C'217,119,6'; // Cor da Seta de Pivo (Laranja/Dourado)

input group "=== Trava de Disciplina Pessoal (Turno Dia + Turno Noite HK) ==="
input int            InpMaxTradesPerSession   = 1;          // Maximo de Trades por Turno (0 = Sem Limite)
input double         InpMaxLossPerSession     = 30.0;       // Loss Maximo no Turno em $ USD (0 = Sem Limite)
input int            InpNightSessionStartHour = 20;         // Hora de Inicio do Turno Noite/HK (Horario Local, Ex: 20h)

//--- Constantes de Prefixos e Cores
#define PREFIX "GM_"
#define LINE_ENTRY (PREFIX + "Line_Entry")
#define LINE_STOP  (PREFIX + "Line_Stop")
#define FIBO_NAME  (PREFIX + "Fibo_RR")
#define CANDLE_TIMER_NAME (PREFIX + "CandleTimer")
#define SIG_PREFIX (PREFIX + "StopSig_")

// Paleta de Cores Clean Minimalista
const color CLR_BG          = C'255,255,255'; // Branco
const color CLR_BG_CARD     = C'248,250,252'; // Slate 50
const color CLR_BORDER      = C'210,218,228'; // Borda Slate 200
const color CLR_TXT_HEADER  = C'15,23,42';    // Quase preto
const color CLR_TXT_BODY    = C'51,65,85';    // Cinza chumbo
const color CLR_TXT_MUTED   = C'100,116,139'; // Cinza medio
const color CLR_TXT_LIGHT   = C'148,163,184'; // Cinza claro
const color CLR_PRIMARY     = C'37,99,235';   // Azul Moderno
const color CLR_BUY         = C'21,128,61';   // Verde Compra
const color CLR_BUY_BG      = C'240,253,244';
const color CLR_SELL        = C'220,38,38';   // Vermelho Venda
const color CLR_SELL_BG     = C'254,242,242';
const color CLR_BTN_DEF_BG  = C'241,245,249'; // Botao inativo
const color CLR_BTN_ACTIVE  = C'30,41,59';    // Botao ativo
const color CLR_HIGHLIGHT   = C'254,243,199'; // Amarelo de atencao
const color CLR_PARTIAL     = C'146,64,14';   // Amber 600 para Parciais
const color CLR_ADD         = C'29,78,216';  // Sky Blue para Adicao de Posicao

//--- Instancia de Negociacao
CTrade trade;

//--- Fator de Escala DPI para Monitores 4K
double g_dpi_scale = 1.0;
double g_ui_scale = 1.0;
double g_system_dpi_scale = 1.0;
double g_open_scale = 1.0;
double g_minimized_scale = 1.0;
int g_resize_start_x = 0, g_resize_start_y = 0;
double g_resize_start_scale = 1.0;

#define PANEL_MIN_W 460
#define PANEL_MIN_H 696
#define PANEL_SETTINGS_H 736
#define PANEL_MINIMIZED_W 320
#define PANEL_MINIMIZED_H 36
#define PANEL_HEADER_H 56

int Scale(int px)
{
    return (int)MathRound(px * g_dpi_scale);
}

//--- Posicao e Dimensoes Dinamicas do Painel
int            g_panel_x           = 12;
int            g_panel_y           = 48;
int            g_min_panel_x       = 10;
int            g_min_panel_y       = 36;
int            g_panel_w           = PANEL_MIN_W;
int            g_panel_h           = PANEL_MIN_H;

bool           g_is_minimized      = true;
bool           g_settings_open     = false;
bool           g_lines_hidden      = false;

// Variaveis de Estado de Arraste e Redimensionamento
int            g_drag_mode         = 0; // 0=None, 1=Move, 2=ResizeDiag, 3=ResizeW, 4=ResizeH
int            g_drag_offset_x     = 0;
int            g_drag_offset_y     = 0;
bool           g_prev_lbutton      = false;

bool           g_is_editing_risk       = false; // Usuário digitando no campo de risco
bool           g_is_editing_partial    = false; // Usuário digitando no campo de parcial
double         g_partial_percent       = 30.0;  // Porcentagem de Parcial (%)
string         g_key_partial_str       = "P";
int            g_key_partial_vk        = 'P';

bool           g_is_editing_add        = false; // Usuário digitando no campo de adição
double         g_add_percent           = 50.0;  // Porcentagem de Adicao (Travada em no max 50%)
string         g_key_add_str           = "A";
int            g_key_add_vk            = 'A';

// Variaveis da Trava de Disciplina (Max Trades / Max Loss por Turno) e Trava por Senha
#define GM_PESSOAL_MARKER       "GM_Pessoal_Active"

bool           g_is_editing_max_trades = false;
bool           g_is_editing_max_loss   = false;
bool           g_is_editing_pwd        = false;
int            g_max_trades_session    = 1;     // Maximo de trades no turno (0 = sem limite)
double         g_max_loss_session      = 30.0;  // Loss maximo no turno em $ USD (0 = sem limite)
int            g_cur_session_trades    = 0;     // Quantidade de trades realizados no turno atual
double         g_cur_session_pnl       = 0.0;   // Resultado financeiro total (fechado + aberto) no turno atual
bool           g_session_loss_locked   = false; // Trava acionada por bater o Loss Maximo no turno
bool           g_session_trades_locked = false; // Trava acionada por atingir o Maximo de Trades no turno
string         g_session_lock_reason   = "";    // Texto do bloqueio
string         g_pwd_hash              = "";    // Hash da senha cadastrada (vazio = ainda nao cadastrou)
bool           g_risk_pwd_locked       = false; // Se true, Risco, Max Trades e Loss Max estao trancados por senha
string         g_typed_pwd             = "";    // Texto temporario digitado no campo de senha
bool           g_chart_scroll_disabled = false; // Trava do gráfico ao passar o mouse ou arrastar o painel

void SetChartScroll(bool enable)
{
    if (g_chart_scroll_disabled == !enable) return;
    g_chart_scroll_disabled = !enable;
    ChartSetInteger(0, CHART_MOUSE_SCROLL, enable);
}

//--- Variaveis Globais de Estado
ENUM_RISK_MODE        g_risk_mode            = RISK_FIXED_USD;
double                g_risk_percent         = 1.0;
double                g_risk_cash            = 10.0;
bool                  g_is_pending           = false;
bool                  g_candle_timer_enabled = true;
ENUM_CANDLE_TIMER_POS g_candle_timer_pos     = TIMER_POS_FOLLOW_PRICE;
int                   g_candle_timer_size    = 9;
bool                  g_chart_shift_enabled  = true;
double                g_chart_shift_size     = 12.7;
double                g_last_config_version  = 0.0;

// Estado de arrasto e posicao customizada do Relogio de Candles (2 cliques e arrastar)
bool           g_timer_is_custom       = false; // Relogio com posicao customizada pelo usuario?
int            g_timer_custom_x        = -1;    // Posicao X na tela
int            g_timer_custom_y        = -1;    // Posicao Y na tela
bool           g_timer_selected        = false; // Relogio selecionado com 2 cliques?
bool           g_timer_dragging        = false; // Relogio sendo arrastado neste momento?
int            g_timer_drag_offset_x   = 0;
int            g_timer_drag_offset_y   = 0;
uint           g_last_timer_click_time = 0;     // Timestamp do ultimo clique para deteccao de duplo clique

// Codigos e Textos dos Atalhos
string         g_key_entry_str     = "E";
int            g_key_entry_vk      = 'E';

string         g_key_stop_str      = "S";
int            g_key_stop_vk       = 'S';

string         g_key_mode_str      = "T";
int            g_key_mode_vk       = 'T';

string         g_key_hide_str      = "H";
int            g_key_hide_vk       = 'H';

string         g_key_min_str       = "M";
int            g_key_min_vk        = 'M';

string         g_key_exec_str      = "ESPACO";
int            g_key_exec_vk       = 32;

// Estado de Escuta de Tecla
int            g_listening_action  = 0;

double         g_entry_price       = 0.0;
double         g_stop_price        = 0.0;
bool           g_has_stop          = false;
bool           g_has_entry         = false;

// Variaveis de Calculo
double         g_calculated_lot    = 0.0;
double         g_calculated_risk_m = 0.0;
double         g_calculated_risk_p = 0.0;
double         g_actual_loss_at_sl = 0.0;
string         g_direction_str     = "AGUARDANDO STOP";
color          g_direction_color   = CLR_TXT_MUTED;
bool           g_can_trade         = false;
string         g_trade_error_msg   = "Aperte o atalho de Stop";

// Posicao do Mouse
int            g_mouse_x           = 0;
int            g_mouse_y           = 0;
datetime       g_mouse_time        = 0;
double         g_mouse_price       = 0.0;

// Declaracoes antecipadas
void CreatePanel();
void UpdatePanel();
void DrawLines();
void Recalculate();
void UpdateMarketEntryPrice();
void ExecuteTrade();
void CleanupObjects();
void CreateFibonacciRR(double entry, double stop);
int  GetLotDigits(double step);
void InitHotkeys();
string GetKeyName(long vk);
void UpdateCandleTimer();
void DeleteCandleTimer();
string GetCandleTimerString();
void SaveAllToGlobals(bool force_minimized = true);
bool LoadAllFromGlobals();
bool SaveDefaultIni();
bool LoadDefaultIni();
bool SaveSecurityVault();
bool LoadSecurityVault();
bool WriteCurrentDefaultMarker();
bool RestoreCurrentDefault();
void BroadcastConfigToAllCharts();
void CommitPendingPanelEdits();
bool IsRiskPasswordLocked();
string HashPassword(string raw_pwd);
void ShowPasswordLockAlert(string field_name);
void HandlePasswordAction();

// Enums e declaracoes antecipadas para fracionamento e gerenciamento unificado
enum ENUM_ASSET_CLASS
{
    ASSET_INDEX,
    ASSET_STOCK,
    ASSET_OTHER
};

ENUM_ASSET_CLASS DetectAssetClass(string symbol);
double ParseCustomLimitForSymbol(string symbol, string config_str);
double GetEffectiveMaxVolumePerOrder(string symbol);
int    SplitVolumeIntoChunks(double total_volume, double max_per_order, double min_lot, double lot_step, int lot_digits, double &chunks[]);
int    GetChunkCount(double total_volume, double max_per_order);
bool   CheckMarginAndLimits(ENUM_ORDER_TYPE order_type, double price, const double &chunks[], int chunk_count, string &error_msg);
void   SaveOperationState(ulong group_id, double init_vol, double sl, double entry_px, bool is_pending, int pending_orders_count = 0);
void   ClearOperationState();
double GetOperationInitialVolume();
void   CancelOperationPendingOrders(string symbol, ulong magic, ulong group_id = 0);
void   ReconcileOrphanPendingOrders();
bool   HasActiveTradeOnSymbol();
bool   AdjustAllTradeStops(double target_price);
ENUM_POSITION_TYPE GetActiveTradeDirection();
double GetActiveTradeEntryPrice();
void   UpdateStopAdjustmentSignals();
void   ClearStopAdjustmentSignals();
bool   HasOpenPositionOnSymbol(datetime &earliest_open_time, ENUM_POSITION_TYPE &pos_dir);
double GetDayAverageBarRange(int ref_shift, int &bars_count_out);
void   DrawStopSignalMarker(string sig_id, datetime bar_time, double price, bool is_buy, bool is_pivot, string label_text, string tooltip_text);
void   EvaluateSessionDiscipline(bool enforce_emergency_close = true);
void   EmergencyCloseAllAccountPositionsAndOrders(string reason);
datetime GetCurrentSessionStartServerTime(bool &is_night_session);


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    int dpi = (int)TerminalInfoInteger(TERMINAL_SCREEN_DPI);
    if (dpi > 0)
    {
        g_dpi_scale = (double)dpi / 96.0;
    }
    if (g_dpi_scale < 1.0) g_dpi_scale = 1.0;
    g_system_dpi_scale = g_dpi_scale;
    g_open_scale = MathMax(0.40, MathMin(1.50, InpPanelScale / 100.0));
    g_minimized_scale = MathMax(0.60, MathMin(1.50, InpMinimizedScale / 100.0));

    g_panel_x = InpPanelX;
    g_panel_y = InpPanelY;
    g_min_panel_x = 10;
    g_min_panel_y = 36;
    g_panel_w = PANEL_MIN_W;
    g_panel_h = PANEL_MIN_H;

    g_risk_mode    = InpDefaultRiskMode;
    g_risk_percent = InpRiskPercent;
    g_risk_cash    = InpRiskCash;
    g_is_pending   = InpDefaultPending;
    g_candle_timer_enabled = InpEnableCandleTimer;
    g_candle_timer_pos     = InpCandleTimerPos;
    g_candle_timer_size    = InpCandleTimerSize;
    g_chart_shift_enabled  = true;
    g_chart_shift_size     = 12.7;
    g_max_trades_session   = MathMax(0, InpMaxTradesPerSession);
    g_max_loss_session     = MathMax(0.0, InpMaxLossPerSession);

    InitHotkeys();
    g_is_minimized = InpStartMinimized;
    RestoreCurrentDefault();

    if (g_chart_shift_enabled)
    {
        ChartSetInteger(0, CHART_SHIFT, true);
        ChartSetDouble(0, CHART_SHIFT_SIZE, g_chart_shift_size);
    }

    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetDeviationInPoints(InpSlippage);

    ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
    ChartSetInteger(0, CHART_QUICK_NAVIGATION, false); // Desativa a barra nativa do MT5 que abre no Espaco

    CleanupObjects();
    WriteCurrentDefaultMarker();

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    g_entry_price = ask;
    g_has_entry   = true;

    // Se houver operacao em andamento ou salva, restaura precos
    double saved_entry = 0.0;
    if (GlobalVariableGet("GM_OP_" + _Symbol + "_Entry", saved_entry) && saved_entry > 0.0)
    {
        g_entry_price = saved_entry;
    }
    else if (HasActiveTradeOnSymbol())
    {
        g_entry_price = GetActiveTradeEntryPrice();
    }

    if (!g_is_pending)
    {
        UpdateMarketEntryPrice();
    }

    double saved_sl = 0.0;
    if (GlobalVariableGet("GM_OP_" + _Symbol + "_SL", saved_sl) && saved_sl > 0.0)
    {
        g_stop_price = saved_sl;
        g_has_stop   = true;
    }

    EvaluateSessionDiscipline(false);
    CreatePanel();
    Recalculate();

    EventSetTimer(1);
    UpdateCandleTimer();
    UpdateStopAdjustmentSignals();

    ChartRedraw(0);
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Inicializacao de Atalhos                                         |
//+------------------------------------------------------------------+
void InitHotkeys()
{
    g_key_entry_str = (InpKeyEntry != "") ? InpKeyEntry : "E";
    g_key_entry_vk  = StringGetCharacter(g_key_entry_str, 0);

    g_key_stop_str  = (InpKeyStop != "") ? InpKeyStop : "S";
    g_key_stop_vk   = StringGetCharacter(g_key_stop_str, 0);

    g_key_mode_str  = (InpKeyMode != "") ? InpKeyMode : "T";
    g_key_mode_vk   = StringGetCharacter(g_key_mode_str, 0);

    g_key_hide_str  = (InpKeyHide != "") ? InpKeyHide : "H";
    g_key_hide_vk   = StringGetCharacter(g_key_hide_str, 0);

    g_key_min_str   = (InpKeyMin != "") ? InpKeyMin : "M";
    g_key_min_vk    = StringGetCharacter(g_key_min_str, 0);

    g_key_partial_str = (InpKeyPartial != "") ? InpKeyPartial : "P";
    g_key_partial_vk  = StringGetCharacter(g_key_partial_str, 0);
    g_partial_percent = InpDefaultPartialPercent;

    g_key_add_str = (InpKeyAdd != "") ? InpKeyAdd : "A";
    g_key_add_vk  = StringGetCharacter(g_key_add_str, 0);
    g_add_percent = MathMin(50.0, MathMax(1.0, InpDefaultAddPercent));

    g_key_exec_str  = InpKeyExec;
    if (g_key_exec_str == "ESPACO" || g_key_exec_str == "SPACE" || g_key_exec_str == " ")
    {
        g_key_exec_vk = 32;
        g_key_exec_str = "ESPACO";
    }
    else
    {
        g_key_exec_vk = StringGetCharacter(g_key_exec_str, 0);
    }
}

//+------------------------------------------------------------------+
//| Retorna o nome amigavel de uma tecla                             |
//+------------------------------------------------------------------+
string GetKeyName(long vk)
{
    if (vk == 32) return "ESPACO";
    if (vk == 13) return "ENTER";
    if (vk == 27) return "ESC";
    if (vk == 9)  return "TAB";
    if (vk >= 'A' && vk <= 'Z') return ShortToString((ushort)vk);
    if (vk >= 'a' && vk <= 'z') return ShortToString((ushort)(vk - 32));
    if (vk >= '0' && vk <= '9') return ShortToString((ushort)vk);
    return ShortToString((ushort)vk);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    EventKillTimer();
    DeleteCandleTimer();
    CleanupObjects();
    ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, false);
    ChartSetInteger(0, CHART_MOUSE_SCROLL, true);
    ChartSetInteger(0, CHART_QUICK_NAVIGATION, true); // Restaura navegacao nativa ao remover
    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    EvaluateSessionDiscipline(true);
    if (!g_is_pending)
    {
        UpdateMarketEntryPrice();
    }
    Recalculate();
    UpdateCandleTimer();
    ReconcileOrphanPendingOrders();
    UpdateStopAdjustmentSignals();
}

//+------------------------------------------------------------------+
//| Expert timer function                                            |
//+------------------------------------------------------------------+
void OnTimer()
{
    // Sincronizacao em tempo real de alteracoes salvas em outro grafico
    double ver = 0;
    if (GlobalVariableGet("GM_ConfigVersion", ver))
    {
        if (ver != g_last_config_version)
        {
            g_last_config_version = ver;
            bool keep_min = g_is_minimized;
            RestoreCurrentDefault();
            EvaluateSessionDiscipline(true);
            CreatePanel();
            Recalculate();
            UpdatePanel();
            DeleteCandleTimer();
            UpdateCandleTimer();
            ChartRedraw(0);
            return;
        }
    }

    EvaluateSessionDiscipline(true);
    UpdateCandleTimer();
    ReconcileOrphanPendingOrders();
    UpdateStopAdjustmentSignals();
    UpdatePanel();
}

//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
    // Captura remocao de ordens pendentes em tempo real sem latencia
    if (trans.type == TRADE_TRANSACTION_ORDER_DELETE || trans.type == TRADE_TRANSACTION_HISTORY_ADD)
    {
        ReconcileOrphanPendingOrders();
    }
}

//+------------------------------------------------------------------+
//| Retorna a direcao da posicao ativa principal no ativo (Buy/Sell) |
//+------------------------------------------------------------------+
ENUM_POSITION_TYPE GetActiveTradeDirection()
{
    int total_positions = PositionsTotal();
    datetime oldest_time = D'2099.12.31';
    ENUM_POSITION_TYPE ptype = POSITION_TYPE_BUY;
    bool found = false;

    for (int i = 0; i < total_positions; i++)
    {
        ulong ticket = PositionGetTicket(i);
        if (ticket > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol)
        {
            long magic = PositionGetInteger(POSITION_MAGIC);
            datetime pos_time = (datetime)PositionGetInteger(POSITION_TIME);

            if (magic == InpMagicNumber)
            {
                return (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            }

            if (pos_time < oldest_time)
            {
                oldest_time = pos_time;
                ptype = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                found = true;
            }
        }
    }

    if (found) return ptype;

    // Fallback por ordens pendentes do EA no ativo
    int total_orders = OrdersTotal();
    for (int i = 0; i < total_orders; i++)
    {
        ulong ticket = OrderGetTicket(i);
        if (ticket > 0 && OrderGetString(ORDER_SYMBOL) == _Symbol)
        {
            long magic = OrderGetInteger(ORDER_MAGIC);
            if (magic == InpMagicNumber || magic == (InpMagicNumber + 1))
            {
                ENUM_ORDER_TYPE otype = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
                if (otype == ORDER_TYPE_BUY_LIMIT || otype == ORDER_TYPE_BUY_STOP)
                    return POSITION_TYPE_BUY;
                if (otype == ORDER_TYPE_SELL_LIMIT || otype == ORDER_TYPE_SELL_STOP)
                    return POSITION_TYPE_SELL;
            }
        }
    }

    // Se nao encontrou pelo magic, verifica se o stop esta acima ou abaixo da cotacao
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    if (g_has_stop && g_stop_price > ask)
        return POSITION_TYPE_SELL;

    return POSITION_TYPE_BUY;
}

//+------------------------------------------------------------------+
//| Retorna o preco de abertura original da operacao ativa           |
//+------------------------------------------------------------------+
double GetActiveTradeEntryPrice()
{
    double saved_entry = 0.0;
    if (GlobalVariableGet("GM_OP_" + _Symbol + "_Entry", saved_entry) && saved_entry > 0.0)
    {
        return saved_entry;
    }

    int total_positions = PositionsTotal();
    datetime oldest_time = D'2099.12.31';
    double open_price = 0.0;

    for (int i = 0; i < total_positions; i++)
    {
        ulong ticket = PositionGetTicket(i);
        if (ticket > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol)
        {
            long magic = PositionGetInteger(POSITION_MAGIC);
            datetime pos_time = (datetime)PositionGetInteger(POSITION_TIME);

            if (magic == InpMagicNumber)
            {
                return PositionGetDouble(POSITION_PRICE_OPEN);
            }

            if (pos_time < oldest_time)
            {
                oldest_time = pos_time;
                open_price = PositionGetDouble(POSITION_PRICE_OPEN);
            }
        }
    }
    return open_price;
}

//+------------------------------------------------------------------+
//| Atualiza o preco de entrada / adicao a mercado                   |
//+------------------------------------------------------------------+
void UpdateMarketEntryPrice()
{
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

    bool in_trade = HasActiveTradeOnSymbol();

    if (in_trade)
    {
        // Durante trade ativo em modo mercado:
        // A adicao a mercado segue a linha do preco atual (Ask para Compra, Bid para Venda)
        ENUM_POSITION_TYPE ptype = GetActiveTradeDirection();
        if (ptype == POSITION_TYPE_BUY)
        {
            g_entry_price = ask;
        }
        else
        {
            g_entry_price = bid;
        }
    }
    else
    {
        if (g_has_stop)
        {
            if (g_stop_price < bid)
            {
                g_entry_price = ask;
            }
            else if (g_stop_price > ask)
            {
                g_entry_price = bid;
            }
            else
            {
                g_entry_price = ask;
            }
        }
        else
        {
            g_entry_price = ask;
        }
    }

    if (ObjectFind(0, LINE_ENTRY) >= 0)
    {
        ObjectSetDouble(0, LINE_ENTRY, OBJPROP_PRICE, g_entry_price);
        string text = in_trade ?
            StringFormat("  ADIÇÃO MERCADO: %.*f", _Digits, g_entry_price) :
            StringFormat("  ENTRADA MERCADO: %.*f", _Digits, g_entry_price);
        ObjectSetString(0, LINE_ENTRY, OBJPROP_TEXT, text);
    }
}

//+------------------------------------------------------------------+
//| Recalculo principal do Lote com OrderCalcProfit                  |
//+------------------------------------------------------------------+
void Recalculate()
{
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    if (balance <= 0) balance = AccountInfoDouble(ACCOUNT_EQUITY);

    if (g_risk_mode == RISK_FIXED_USD)
    {
        g_calculated_risk_m = g_risk_cash;
        g_calculated_risk_p = (balance > 0) ? (g_risk_cash / balance * 100.0) : 0.0;
    }
    else
    {
        g_calculated_risk_m = balance * (g_risk_percent / 100.0);
        g_calculated_risk_p = g_risk_percent;
    }

    if (!g_has_stop || g_stop_price <= 0)
    {
        g_calculated_lot    = 0.0;
        g_actual_loss_at_sl = 0.0;
        g_direction_str     = StringFormat("AGUARDANDO STOP (%s)", g_key_stop_str);
        g_direction_color   = CLR_TXT_MUTED;
        g_can_trade         = false;
        g_trade_error_msg   = StringFormat("Aperte '%s' para marcar Stop", g_key_stop_str);
        UpdatePanel();
        return;
    }

    ENUM_ORDER_TYPE order_type_for_calc;
    if (g_stop_price < g_entry_price)
    {
        order_type_for_calc = ORDER_TYPE_BUY;
        g_direction_str   = "▲ COMPRA (BUY)";
        g_direction_color = CLR_BUY;
    }
    else if (g_stop_price > g_entry_price)
    {
        order_type_for_calc = ORDER_TYPE_SELL;
        g_direction_str   = "▼ VENDA (SELL)";
        g_direction_color = CLR_SELL;
    }
    else
    {
        g_calculated_lot    = 0.0;
        g_actual_loss_at_sl = 0.0;
        g_direction_str     = "PRECO INVALIDO";
        g_direction_color   = CLR_SELL;
        g_can_trade         = false;
        g_trade_error_msg   = "Stop e Entrada iguais";
        UpdatePanel();
        return;
    }

    double loss_price_diff = MathAbs(g_entry_price - g_stop_price);
    int stop_distance_pts = (int)MathRound(loss_price_diff / _Point);

    long stops_level = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    if (stop_distance_pts < stops_level)
    {
        g_calculated_lot  = 0.0;
        g_can_trade       = false;
        g_trade_error_msg = StringFormat("Stop curto (Min: %d pts)", stops_level);
        UpdatePanel();
        return;
    }

    double loss_per_1_lot = 0.0;
    double simulated_profit = 0.0;

    if (OrderCalcProfit(order_type_for_calc, _Symbol, 1.0, g_entry_price, g_stop_price, simulated_profit))
    {
        loss_per_1_lot = MathAbs(simulated_profit);
    }

    if (loss_per_1_lot <= 0.0)
    {
        double contract_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
        if (contract_size <= 0) contract_size = 1.0;
        double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
        if (tick_size <= 0) tick_size = _Point;
        double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE_LOSS);
        if (tick_value <= 0) tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        
        if (tick_value > 0)
            loss_per_1_lot = (loss_price_diff / tick_size) * tick_value;
        else
            loss_per_1_lot = loss_price_diff * contract_size;
    }

    if (loss_per_1_lot <= 0.0)
    {
        g_calculated_lot  = 0.0;
        g_can_trade       = false;
        g_trade_error_msg = "Erro no calculo do ativo";
        UpdatePanel();
        return;
    }

    double raw_lot = g_calculated_risk_m / loss_per_1_lot;

    double min_lot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double max_lot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    if (lot_step <= 0) lot_step = 0.01;

    double normalized_lot = MathFloor(raw_lot / lot_step) * lot_step;

    if (normalized_lot < min_lot)
    {
        g_calculated_lot  = 0.0;
        g_can_trade       = false;
        g_trade_error_msg = StringFormat("Risco baixo (Min: %.2f)", min_lot);
        UpdatePanel();
        return;
    }

    if (!InpEnableOrderSplitting)
    {
        if (normalized_lot > max_lot) normalized_lot = max_lot;
    }
    else
    {
        // Se divisao estiver ativa, respeita o limite acumulado total do ativo na corretora (se houver)
        double vol_limit = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_LIMIT);
        if (vol_limit > 0.0 && normalized_lot > vol_limit)
        {
            normalized_lot = MathFloor(vol_limit / lot_step) * lot_step;
        }
    }

    g_calculated_lot = NormalizeDouble(normalized_lot, GetLotDigits(lot_step));
    g_actual_loss_at_sl = g_calculated_lot * loss_per_1_lot;

    g_can_trade       = true;
    g_trade_error_msg = "";

    UpdatePanel();
}

//+------------------------------------------------------------------+
//| Retorna o numero de casas decimais para o lote                   |
//+------------------------------------------------------------------+
int GetLotDigits(double step)
{
    if (step <= 0.001) return 3;
    if (step <= 0.01)  return 2;
    if (step <= 0.1)   return 1;
    return 0;
}

//+------------------------------------------------------------------+
//| Alinha um preco ao tick_size exato do ativo (evita invalid price)|
//+------------------------------------------------------------------+
double AlignPrice(double price)
{
    double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    if (tick_size <= 0) return NormalizeDouble(price, _Digits);
    return NormalizeDouble(MathRound(price / tick_size) * tick_size, _Digits);
}

//+------------------------------------------------------------------+
//| Detecta a classe do ativo para aplicar limites adequados         |
//+------------------------------------------------------------------+
ENUM_ASSET_CLASS DetectAssetClass(string symbol)
{
    string sym = symbol;
    StringToUpper(sym);

    string path = SymbolInfoString(symbol, SYMBOL_PATH);
    StringToUpper(path);

    // 1. Deteccao por Pasta / Caminho no MT5
    if (StringFind(path, "INDEX") >= 0 || StringFind(path, "INDICE") >= 0 || 
        StringFind(path, "ÍNDICE") >= 0 || StringFind(path, "FUTUR") >= 0)
    {
        return ASSET_INDEX;
    }
    if (StringFind(path, "STOCK") >= 0 || StringFind(path, "SHARE") >= 0 || 
        StringFind(path, "ACAO") >= 0 || StringFind(path, "AÇÃO") >= 0 || 
        StringFind(path, "AÇÕES") >= 0 || StringFind(path, "EQUITY") >= 0 || 
        StringFind(path, "BOVESPA\\VISTA") >= 0)
    {
        return ASSET_STOCK;
    }

    // 2. Deteccao por Nomes Padrao de Indices (B3 e Globais)
    if (StringFind(sym, "WIN") == 0 || StringFind(sym, "IND") == 0 ||
        StringFind(sym, "WDO") == 0 || StringFind(sym, "DOL") == 0 ||
        StringFind(sym, "IBOV") >= 0 || StringFind(sym, "BRA50") >= 0 ||
        StringFind(sym, "US500") >= 0 || StringFind(sym, "SPX") >= 0 ||
        StringFind(sym, "SP500") >= 0 || StringFind(sym, "USTEC") >= 0 ||
        StringFind(sym, "NAS100") >= 0 || StringFind(sym, "US30") >= 0 ||
        StringFind(sym, "DJI") >= 0 || StringFind(sym, "DAX") >= 0 ||
        StringFind(sym, "GER40") >= 0 || StringFind(sym, "UK100") >= 0 ||
        StringFind(sym, "JP225") >= 0 || StringFind(sym, "HK50") >= 0)
    {
        return ASSET_INDEX;
    }

    // 3. Deteccao de Acoes Brasileiras B3: 4 letras + numero final (ex: PETR4, VALE3, BOVA11)
    int len = StringLen(sym);
    if (len >= 5 && len <= 7)
    {
        bool letters_ok = true;
        for (int i = 0; i < 4; i++)
        {
            ushort ch = StringGetCharacter(sym, i);
            if (ch < 'A' || ch > 'Z') { letters_ok = false; break; }
        }
        if (letters_ok)
        {
            ushort last_ch = StringGetCharacter(sym, len - 1);
            if (last_ch >= '0' && last_ch <= '9')
            {
                return ASSET_STOCK;
            }
        }
    }

    return ASSET_OTHER;
}

//+------------------------------------------------------------------+
//| Le limite configurado pelo usuario para o ativo em questao       |
//+------------------------------------------------------------------+
double ParseCustomLimitForSymbol(string symbol, string config_str)
{
    string sym_upper = symbol;
    StringToUpper(sym_upper);

    string rules[];
    int num_rules = StringSplit(config_str, ';', rules);

    for (int i = 0; i < num_rules; i++)
    {
        string rule = rules[i];
        StringTrimLeft(rule);
        StringTrimRight(rule);
        if (rule == "") continue;

        string parts[];
        if (StringSplit(rule, '=', parts) == 2)
        {
            string pat = parts[0];
            StringTrimLeft(pat);
            StringTrimRight(pat);
            StringToUpper(pat);

            string val_str = parts[1];
            StringTrimLeft(val_str);
            StringTrimRight(val_str);

            double limit = StringToDouble(val_str);
            if (limit <= 0.0) continue;

            if (StringFind(pat, "*") >= 0)
            {
                string prefix = StringSubstr(pat, 0, StringFind(pat, "*"));
                if (prefix == "" || StringFind(sym_upper, prefix) == 0)
                {
                    return limit;
                }
            }
            else if (pat == sym_upper)
            {
                return limit;
            }
        }
    }

    return 0.0;
}

//+------------------------------------------------------------------+
//| Determina o limite maximo efetivo de volume por ordem            |
//+------------------------------------------------------------------+
double GetEffectiveMaxVolumePerOrder(string symbol)
{
    double broker_max = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double broker_min = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double broker_step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    if (broker_step <= 0) broker_step = 0.01;
    if (broker_min <= 0) broker_min = broker_step;

    if (!InpEnableOrderSplitting)
    {
        return (broker_max > 0.0) ? broker_max : 100000.0;
    }

    double limit = 0.0;

    // Regra customizada do usuario por ativo
    if (InpCustomSymbolLimits != "")
    {
        limit = ParseCustomLimitForSymbol(symbol, InpCustomSymbolLimits);
    }

    // Parametro direto do usuario
    if (limit <= 0.0 && InpMaxVolumePerOrder > 0.0)
    {
        limit = InpMaxVolumePerOrder;
    }

    // Inferencia por classe de ativo: Acoes 500, Indices 100
    if (limit <= 0.0)
    {
        ENUM_ASSET_CLASS asset_type = DetectAssetClass(symbol);
        if (asset_type == ASSET_INDEX)
        {
            limit = InpMaxVolIndexDefault;
        }
        else if (asset_type == ASSET_STOCK)
        {
            limit = InpMaxVolStockDefault;
        }
        else
        {
            limit = (broker_max > 0.0) ? broker_max : 100.0;
        }
    }

    // Nunca ultrapassa o limite maximo por ordem da corretora
    if (broker_max > 0.0 && limit > broker_max)
    {
        limit = broker_max;
    }

    // Nunca menor que o lote minimo
    if (limit < broker_min)
    {
        limit = broker_min;
    }

    limit = MathFloor(limit / broker_step) * broker_step;
    return limit;
}

//+------------------------------------------------------------------+
//| Retorna o numero de ordens necessarias para o volume             |
//+------------------------------------------------------------------+
int GetChunkCount(double total_volume, double max_per_order)
{
    if (!InpEnableOrderSplitting || total_volume <= 0.0 || max_per_order <= 0.0) return 1;
    if (total_volume <= max_per_order + 1e-7) return 1;
    return (int)MathCeil(NormalizeDouble(total_volume / max_per_order, 6));
}

//+------------------------------------------------------------------+
//| Divide o volume total em parcelas respeitando maximo e passos    |
//+------------------------------------------------------------------+
int SplitVolumeIntoChunks(double total_volume, double max_per_order, double min_lot, double lot_step, int lot_digits, double &chunks[])
{
    ArrayResize(chunks, 0);
    if (total_volume < min_lot || max_per_order < min_lot) return 0;

    if (!InpEnableOrderSplitting || total_volume <= max_per_order + 1e-7)
    {
        ArrayResize(chunks, 1);
        chunks[0] = NormalizeDouble(total_volume, lot_digits);
        return 1;
    }

    int n_chunks = (int)MathCeil(NormalizeDouble(total_volume / max_per_order, 6));
    if (n_chunks <= 1)
    {
        ArrayResize(chunks, 1);
        chunks[0] = NormalizeDouble(total_volume, lot_digits);
        return 1;
    }

    ArrayResize(chunks, n_chunks);
    double accumulated = 0.0;

    for (int i = 0; i < n_chunks - 1; i++)
    {
        chunks[i] = NormalizeDouble(max_per_order, lot_digits);
        accumulated += chunks[i];
    }

    double remainder = NormalizeDouble(total_volume - accumulated, lot_digits);

    if (remainder < min_lot)
    {
        double needed = min_lot - remainder;
        double transfer = MathCeil(NormalizeDouble(needed / lot_step, 6)) * lot_step;
        transfer = NormalizeDouble(transfer, lot_digits);

        if (chunks[n_chunks - 2] - transfer >= min_lot)
        {
            chunks[n_chunks - 2] = NormalizeDouble(chunks[n_chunks - 2] - transfer, lot_digits);
            chunks[n_chunks - 1] = NormalizeDouble(remainder + transfer, lot_digits);
        }
        else
        {
            double combined = chunks[n_chunks - 2] + remainder;
            double half = MathFloor(NormalizeDouble((combined / 2.0) / lot_step, 6)) * lot_step;
            half = NormalizeDouble(half, lot_digits);
            if (half < min_lot) half = min_lot;
            chunks[n_chunks - 2] = half;
            chunks[n_chunks - 1] = NormalizeDouble(combined - half, lot_digits);
        }
    }
    else
    {
        chunks[n_chunks - 1] = remainder;
    }

    // Verificacao e reconciliacao de arredondamento
    double check_sum = 0.0;
    for (int i = 0; i < n_chunks; i++)
    {
        chunks[i] = NormalizeDouble(chunks[i], lot_digits);
        check_sum += chunks[i];
    }
    check_sum = NormalizeDouble(check_sum, lot_digits);

    double diff = NormalizeDouble(total_volume - check_sum, lot_digits);
    if (MathAbs(diff) >= lot_step)
    {
        chunks[0] = NormalizeDouble(chunks[0] + diff, lot_digits);
    }

    return n_chunks;
}

//+------------------------------------------------------------------+
//| Valida limites da corretora: exposicao, ordens e margem          |
//+------------------------------------------------------------------+
bool CheckMarginAndLimits(ENUM_ORDER_TYPE order_type, double price, const double &chunks[], int chunk_count, string &error_msg)
{
    // 1. Limite maximo acumulado no ativo (SYMBOL_VOLUME_LIMIT)
    double vol_limit = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_LIMIT);
    if (vol_limit > 0.0)
    {
        double current_sym_vol = 0.0;
        for (int i = 0; i < PositionsTotal(); i++)
        {
            if (PositionGetTicket(i) > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol)
            {
                current_sym_vol += PositionGetDouble(POSITION_VOLUME);
            }
        }
        for (int i = 0; i < OrdersTotal(); i++)
        {
            if (OrderGetTicket(i) > 0 && OrderGetString(ORDER_SYMBOL) == _Symbol)
            {
                current_sym_vol += OrderGetDouble(ORDER_VOLUME_INITIAL);
            }
        }

        double total_new_vol = 0.0;
        for (int i = 0; i < chunk_count; i++) total_new_vol += chunks[i];

        if (current_sym_vol + total_new_vol > vol_limit + 1e-6)
        {
            error_msg = StringFormat("Limite maximo de exposicao no ativo atingido (Max: %.2f, Atual: %.2f)",
                                     vol_limit, current_sym_vol);
            return false;
        }
    }

    // 2. Limite maximo de ordens pendentes na conta (ACCOUNT_LIMIT_ORDERS)
    if (g_is_pending)
    {
        long max_orders = AccountInfoInteger(ACCOUNT_LIMIT_ORDERS);
        if (max_orders > 0)
        {
            int current_orders = OrdersTotal();
            if (current_orders + chunk_count > max_orders)
            {
                error_msg = StringFormat("Limite de ordens simultaneas excedido (Max: %d, Atuais: %d, Novas: %d)",
                                         max_orders, current_orders, chunk_count);
                return false;
            }
        }
    }

    // 3. Verificacao de Margem Livre
    double free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    double total_margin_req = 0.0;

    for (int i = 0; i < chunk_count; i++)
    {
        double margin_chunk = 0.0;
        if (OrderCalcMargin(order_type, _Symbol, chunks[i], price, margin_chunk))
        {
            total_margin_req += margin_chunk;
        }
    }

    if (total_margin_req > 0.0 && total_margin_req > free_margin)
    {
        error_msg = StringFormat("Margem insuficiente (Necessario: $%.2f, Livre: $%.2f)",
                                 total_margin_req, free_margin);
        return false;
    }

    return true;
}

//+------------------------------------------------------------------+
//| Salva o estado da operacao unificada nas Variaveis Globais       |
//+------------------------------------------------------------------+
void SaveOperationState(ulong group_id, double init_vol, double sl, double entry_px, bool is_pending, int pending_orders_count = 0)
{
    GlobalVariableSet("GM_OP_" + _Symbol + "_ID", (double)group_id);
    GlobalVariableSet("GM_OP_" + _Symbol + "_InitVol", init_vol);
    GlobalVariableSet("GM_OP_" + _Symbol + "_ExecVol", init_vol);
    GlobalVariableSet("GM_OP_" + _Symbol + "_ClosedVol", 0.0);
    GlobalVariableSet("GM_OP_" + _Symbol + "_SL", sl);
    GlobalVariableSet("GM_OP_" + _Symbol + "_Entry", entry_px);
    GlobalVariableSet("GM_OP_" + _Symbol + "_IsPending", is_pending ? 1.0 : 0.0);
    GlobalVariableSet("GM_OP_" + _Symbol + "_HadPos", is_pending ? 0.0 : 1.0);
    GlobalVariableSet("GM_OP_" + _Symbol + "_HadPending", is_pending ? (pending_orders_count > 0 ? (double)pending_orders_count : 1.0) : 0.0);
}

//+------------------------------------------------------------------+
//| Limpa o estado da operacao unificada                             |
//+------------------------------------------------------------------+
void ClearOperationState()
{
    GlobalVariableDel("GM_OP_" + _Symbol + "_ID");
    GlobalVariableDel("GM_OP_" + _Symbol + "_InitVol");
    GlobalVariableDel("GM_OP_" + _Symbol + "_ExecVol");
    GlobalVariableDel("GM_OP_" + _Symbol + "_ClosedVol");
    GlobalVariableDel("GM_OP_" + _Symbol + "_SL");
    GlobalVariableDel("GM_OP_" + _Symbol + "_Entry");
    GlobalVariableDel("GM_OP_" + _Symbol + "_IsPending");
    GlobalVariableDel("GM_OP_" + _Symbol + "_HadPos");
    GlobalVariableDel("GM_OP_" + _Symbol + "_HadPending");
}

//+------------------------------------------------------------------+
//| Cancela ordens pendentes da operacao                             |
//+------------------------------------------------------------------+
void CancelOperationPendingOrders(string symbol, ulong magic, ulong group_id = 0)
{
    int total_orders = OrdersTotal();
    for (int i = total_orders - 1; i >= 0; i--)
    {
        ulong ord_ticket = OrderGetTicket(i);
        if (ord_ticket > 0)
        {
            if (OrderGetString(ORDER_SYMBOL) == symbol && OrderGetInteger(ORDER_MAGIC) == (long)magic)
            {
                string comment = OrderGetString(ORDER_COMMENT);
                if (group_id > 0)
                {
                    string tag = StringFormat("%I64u", group_id);
                    if (StringFind(comment, tag) < 0) continue;
                }
                trade.OrderDelete(ord_ticket);
                PrintFormat("[Gerenciamento Master] Ordem pendente #%I64u cancelada.", ord_ticket);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Reconcilia ordens pendentes e remove Fibo ao remover ordens/trade|
//+------------------------------------------------------------------+
void ReconcileOrphanPendingOrders()
{
    static uint s_orphan_check_time = 0;
    int total_positions = PositionsTotal();
    int active_primary_pos = 0;

    for (int i = 0; i < total_positions; i++)
    {
        ulong ticket = PositionGetTicket(i);
        if (ticket > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol)
        {
            long magic = PositionGetInteger(POSITION_MAGIC);
            string comment = PositionGetString(POSITION_COMMENT);
            if ((magic == InpMagicNumber || magic == (InpMagicNumber + 1)) && StringFind(comment, "Add") < 0)
            {
                active_primary_pos++;
            }
        }
    }

    int total_orders = OrdersTotal();
    int active_pending = 0;
    for (int i = 0; i < total_orders; i++)
    {
        ulong ticket = OrderGetTicket(i);
        if (ticket > 0 && OrderGetString(ORDER_SYMBOL) == _Symbol)
        {
            long magic = OrderGetInteger(ORDER_MAGIC);
            if (magic == InpMagicNumber || magic == (InpMagicNumber + 1))
            {
                active_pending++;
            }
        }
    }

    string var_had_pos = "GM_OP_" + _Symbol + "_HadPos";
    double had_pos = 0.0;
    GlobalVariableGet(var_had_pos, had_pos);

    string var_had_pending = "GM_OP_" + _Symbol + "_HadPending";
    double had_pending = 0.0;
    GlobalVariableGet(var_had_pending, had_pending);

    // Se ha ordens pendentes no mercado, mantem had_pending registrado
    if (active_pending > 0)
    {
        if (had_pending == 0.0)
        {
            had_pending = (double)active_pending;
            GlobalVariableSet(var_had_pending, had_pending);
        }
    }

    if (active_primary_pos > 0)
    {
        s_orphan_check_time = 0; // Reset debounce timer
        if (had_pos == 0.0)
        {
            GlobalVariableSet(var_had_pos, 1.0);
        }
        // As ordens pendentes foram preenchidas no mercado
        if (had_pending > 0.0 && active_pending == 0)
        {
            GlobalVariableSet(var_had_pending, 0.0);
        }
    }
    else
    {
        // Debounce: espera 500ms para confirmar se nao eh apenas o MT5 processando uma ordem (gap de latencia local)
        bool needs_cleanup = false;
        if (had_pos > 0.0) needs_cleanup = true;
        else if (had_pending > 0.0 && (active_pending == 0 || active_pending < (int)had_pending)) needs_cleanup = true;
        else if (ObjectFind(0, FIBO_NAME) >= 0 && active_pending == 0)
        {
            double op_id = 0.0;
            if (GlobalVariableGet("GM_OP_" + _Symbol + "_ID", op_id)) needs_cleanup = true;
        }

        if (needs_cleanup)
        {
            if (s_orphan_check_time == 0)
            {
                s_orphan_check_time = GetTickCount();
                return;
            }
            if (GetTickCount() - s_orphan_check_time < 500)
            {
                return; // Aguardando confirmacao
            }
        }
        
        s_orphan_check_time = 0; // Limpa para a proxima vez

        // 1. Caso tinha posicao aberta e agora foi encerrada (Stop Loss, Take Profit ou Fechamento Manual)
        if (had_pos > 0.0)
        {
            GlobalVariableSet(var_had_pos, 0.0);
            GlobalVariableSet(var_had_pending, 0.0);
            CancelOperationPendingOrders(_Symbol, InpMagicNumber);
            ClearOperationState();
            if (ObjectFind(0, FIBO_NAME) >= 0)
            {
                // Removido: Mantem a Fibo para o usuario poder tirar print do trade encerrado
                // ObjectDelete(0, FIBO_NAME);
            }
            DrawLines();
            ChartRedraw(0);
            PrintFormat("[Gerenciamento Master] Posicao do ativo %s encerrada. Ordens pendentes residuais e Fibo removidas.", _Symbol);
        }
        // 2. Caso tinha ordem pendente no ativo e ela foi removida/cancelada do grafico ou terminal
        else if (had_pending > 0.0)
        {
            // Se todas as ordens pendentes foram removidas, ou se o usuario removeu ordens pendentes
            if (active_pending == 0 || active_pending < (int)had_pending)
            {
                GlobalVariableSet(var_had_pending, 0.0);
                CancelOperationPendingOrders(_Symbol, InpMagicNumber);
                ClearOperationState();
                if (ObjectFind(0, FIBO_NAME) >= 0)
                {
                    ObjectDelete(0, FIBO_NAME);
                }
                DrawLines();
                ChartRedraw(0);
                PrintFormat("[Gerenciamento Master] Ordem pendente do ativo %s removida. Retracao de Fibonacci removida com sucesso.", _Symbol);
            }
        }
        // 3. Fallback de seguranca: se a Fibo de RR do EA existe no grafico mas NAO ha nenhuma posicao e NENHUMA ordem pendente no ativo
        else if (ObjectFind(0, FIBO_NAME) >= 0 && active_pending == 0)
        {
            double op_id = 0.0;
            if (GlobalVariableGet("GM_OP_" + _Symbol + "_ID", op_id))
            {
                // Removido: Mantem a Fibo RR continua ate proxima entrada ou remocao manual
                // ObjectDelete(0, FIBO_NAME);
                ClearOperationState();
                DrawLines();
                ChartRedraw(0);
                PrintFormat("[Gerenciamento Master] Limpeza automatica: Retracao de Fibonacci removida pois nao ha ordens ativas.");
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Obtem o volume inicial agregado da operacao completa             |
//+------------------------------------------------------------------+
double GetOperationInitialVolume()
{
    // 1. Tenta recuperar das Globais do Terminal
    double persisted_vol = 0.0;
    if (GlobalVariableGet("GM_OP_" + _Symbol + "_InitVol", persisted_vol) && persisted_vol > 0.0)
    {
        return persisted_vol;
    }

    // 2. Se nao encontrou, soma os volumes de entrada no historico
    double total_hist_vol = 0.0;
    int total_positions = PositionsTotal();
    for (int i = 0; i < total_positions; i++)
    {
        ulong ticket = PositionGetTicket(i);
        if (ticket > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol)
        {
            long magic = PositionGetInteger(POSITION_MAGIC);
            string comment = PositionGetString(POSITION_COMMENT);
            if (magic == InpMagicNumber && StringFind(comment, "Add") < 0)
            {
                total_hist_vol += GetInitialPositionVolume(ticket);
            }
        }
    }

    if (total_hist_vol > 0.0) return total_hist_vol;

    // 3. Fallback: soma volume atual em aberto das posicoes da operacao
    double total_curr_vol = 0.0;
    for (int i = 0; i < total_positions; i++)
    {
        ulong ticket = PositionGetTicket(i);
        if (ticket > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol)
        {
            long magic = PositionGetInteger(POSITION_MAGIC);
            string comment = PositionGetString(POSITION_COMMENT);
            if (magic == InpMagicNumber && StringFind(comment, "Add") < 0)
            {
                total_curr_vol += PositionGetDouble(POSITION_VOLUME);
            }
        }
    }
    return total_curr_vol;
}

//+------------------------------------------------------------------+
//| Verifica se ha operacao ativa ou pendente do EA no ativo atual   |
//+------------------------------------------------------------------+
bool HasActiveTradeOnSymbol()
{
    int total_positions = PositionsTotal();
    for (int i = 0; i < total_positions; i++)
    {
        ulong ticket = PositionGetTicket(i);
        if (ticket > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol)
        {
            long magic = PositionGetInteger(POSITION_MAGIC);
            if (magic == InpMagicNumber || magic == (InpMagicNumber + 1))
            {
                return true;
            }
        }
    }

    int total_orders = OrdersTotal();
    for (int i = 0; i < total_orders; i++)
    {
        ulong ticket = OrderGetTicket(i);
        if (ticket > 0 && OrderGetString(ORDER_SYMBOL) == _Symbol)
        {
            long magic = OrderGetInteger(ORDER_MAGIC);
            if (magic == InpMagicNumber || magic == (InpMagicNumber + 1))
            {
                return true;
            }
        }
    }

    return false;
}

//+------------------------------------------------------------------+
//| Ajusta em conjunto todos os stops da operacao ativa no ativo     |
//+------------------------------------------------------------------+
bool AdjustAllTradeStops(double target_price)
{
    if (target_price <= 0.0) return false;

    double target_sl = AlignPrice(target_price);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    int stops_level = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    double min_dist = stops_level * _Point;

    int modified_positions = 0;
    int failed_positions = 0;
    int modified_orders = 0;
    int failed_orders = 0;
    bool alert_shown = false;

    // 1. Modifica todas as posicoes ativas da operacao no ativo
    int total_positions = PositionsTotal();
    for (int i = 0; i < total_positions; i++)
    {
        ulong ticket = PositionGetTicket(i);
        if (ticket > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol)
        {
            long magic = PositionGetInteger(POSITION_MAGIC);
            if (magic == InpMagicNumber || magic == (InpMagicNumber + 1))
            {
                ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                double current_tp = PositionGetDouble(POSITION_TP);
                double current_sl = PositionGetDouble(POSITION_SL);

                // Validacao de stop loss em relacao a cotacao atual de saida
                if (pos_type == POSITION_TYPE_BUY)
                {
                    if (target_sl >= (bid - min_dist))
                    {
                        if (!alert_shown)
                        {
                            Alert("Você tentou posicionar o stop muito perto do preço atual, posicione ele com uma distância um pouco maior.");
                            alert_shown = true;
                        }
                        failed_positions++;
                        continue;
                    }
                }
                else if (pos_type == POSITION_TYPE_SELL)
                {
                    if (target_sl <= (ask + min_dist))
                    {
                        if (!alert_shown)
                        {
                            Alert("Você tentou posicionar o stop muito perto do preço atual, posicione ele com uma distância um pouco maior.");
                            alert_shown = true;
                        }
                        failed_positions++;
                        continue;
                    }
                }

                if (MathAbs(current_sl - target_sl) < (_Point / 2.0))
                {
                    modified_positions++;
                    continue;
                }

                trade.SetExpertMagicNumber(magic);
                if (trade.PositionModify(ticket, target_sl, current_tp))
                {
                    modified_positions++;
                    PrintFormat("[Gerenciamento Master] Stop da posicao #%I64u ajustado para %.*f com sucesso!", ticket, _Digits, target_sl);
                }
                else
                {
                    failed_positions++;
                    if (!alert_shown && trade.ResultRetcode() == TRADE_RETCODE_INVALID_STOPS)
                    {
                        Alert("Você tentou posicionar o stop muito perto do preço atual, posicione ele com uma distância um pouco maior.");
                        alert_shown = true;
                    }
                    PrintFormat("[Gerenciamento Master] Erro ao modificar Stop da posicao #%I64u: %s (Retcode: %d)",
                                ticket, trade.ResultRetcodeDescription(), trade.ResultRetcode());
                }
            }
        }
    }

    // 2. Modifica todas as ordens pendentes da operacao no ativo
    int total_orders = OrdersTotal();
    for (int i = 0; i < total_orders; i++)
    {
        ulong ticket = OrderGetTicket(i);
        if (ticket > 0 && OrderGetString(ORDER_SYMBOL) == _Symbol)
        {
            long magic = OrderGetInteger(ORDER_MAGIC);
            if (magic == InpMagicNumber || magic == (InpMagicNumber + 1))
            {
                double price_open = OrderGetDouble(ORDER_PRICE_OPEN);
                double current_tp  = OrderGetDouble(ORDER_TP);
                double current_sl  = OrderGetDouble(ORDER_SL);
                ENUM_ORDER_TYPE_TIME type_time = (ENUM_ORDER_TYPE_TIME)OrderGetInteger(ORDER_TYPE_TIME);
                datetime exp_time = (datetime)OrderGetInteger(ORDER_TIME_EXPIRATION);

                if (MathAbs(current_sl - target_sl) < (_Point / 2.0))
                {
                    modified_orders++;
                    continue;
                }

                trade.SetExpertMagicNumber(magic);
                if (trade.OrderModify(ticket, price_open, target_sl, current_tp, type_time, exp_time))
                {
                    modified_orders++;
                    PrintFormat("[Gerenciamento Master] Stop da ordem pendente #%I64u ajustado para %.*f com sucesso!", ticket, _Digits, target_sl);
                }
                else
                {
                    failed_orders++;
                    if (!alert_shown && trade.ResultRetcode() == TRADE_RETCODE_INVALID_STOPS)
                    {
                        Alert("Você tentou posicionar o stop muito perto do preço atual, posicione ele com uma distância um pouco maior.");
                        alert_shown = true;
                    }
                    PrintFormat("[Gerenciamento Master] Erro ao modificar Stop da ordem pendente #%I64u: %s (Retcode: %d)",
                                ticket, trade.ResultRetcodeDescription(), trade.ResultRetcode());
                }
            }
        }
    }

    int total_updated = modified_positions + modified_orders;
    if (total_updated > 0)
    {
        g_stop_price = target_sl;
        g_has_stop   = true;
        GlobalVariableSet("GM_OP_" + _Symbol + "_SL", target_sl);

        // A Fibonacci RR permanece fixa no ponto inicial da operacao

        // Esconde a linha virtual do EA para exibir apenas os stops nativos do MetaTrader
        ObjectDelete(0, LINE_STOP);

        PlaySound("ok.wav");
        ChartRedraw(0);
        return true;
    }
    else
    {
        PlaySound("timeout.wav");
        return false;
    }
}

//+------------------------------------------------------------------+
//| Dispara a Execucao da Ordem (Com Divisao / Fracionamento Seguro) |
//+------------------------------------------------------------------+
void ExecuteTrade()
{
    EvaluateSessionDiscipline(true);
    if (g_session_loss_locked)
    {
        Alert("[Gerenciamento Master] TRAVA DE LOSS ATINGIDA! Prejuízo do turno ($", DoubleToString(MathAbs(g_cur_session_pnl), 2),
              ") atingiu o limite máximo de $", DoubleToString(g_max_loss_session, 2), ". Operações bloqueadas neste turno!");
        PlaySound("timeout.wav");
        return;
    }
    if (g_session_trades_locked)
    {
        Alert("[Gerenciamento Master] LIMITE DE TRADES ATINGIDO! Você já realizou ", g_cur_session_trades, " de ", g_max_trades_session,
              " trade(s) permitido(s) neste turno. Use [", g_key_add_str, "] apenas para Adição em posição já aberta!");
        PlaySound("timeout.wav");
        return;
    }

    if (!g_has_stop || g_stop_price <= 0)
    {
        Alert("[Gerenciamento Master] Ordem bloqueada: Marque o Stop Loss (tecla '", g_key_stop_str, "')!");
        PlaySound("timeout.wav");
        return;
    }

    Recalculate();
    if (!g_can_trade || g_calculated_lot <= 0)
    {
        Alert("[Gerenciamento Master] Bloqueado: ", g_trade_error_msg);
        PlaySound("timeout.wav");
        return;
    }

    // Se tem limite de Loss por turno e a perda desta entrada + prejuizo ja acumulado estourar o limite, avisa/bloqueia
    if (g_max_loss_session > 0.0)
    {
        double projected_worst_pnl = g_cur_session_pnl - g_actual_loss_at_sl;
        if (projected_worst_pnl < -(g_max_loss_session + 0.50))
        {
            Alert(StringFormat("[Gerenciamento Master] Risco da operação ($%.2f) somado ao resultado do turno ($%.2f) ultrapassa o Loss Máximo de $%.2f! Reduza o risco.",
                               g_actual_loss_at_sl, g_cur_session_pnl, g_max_loss_session));
            PlaySound("timeout.wav");
            return;
        }
    }

    if (!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED))
    {
        Alert("[Gerenciamento Master] Algo Trading desativado no MetaTrader!");
        PlaySound("timeout.wav");
        return;
    }

    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    bool is_buy = (g_stop_price < g_entry_price);

    double min_lot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    if (lot_step <= 0) lot_step = 0.01;
    if (min_lot <= 0) min_lot = lot_step;
    int lot_digits = GetLotDigits(lot_step);

    double effective_max = GetEffectiveMaxVolumePerOrder(_Symbol);

    double chunks[];
    int chunk_count = SplitVolumeIntoChunks(g_calculated_lot, effective_max, min_lot, lot_step, lot_digits, chunks);
    if (chunk_count <= 0)
    {
        Alert("[Gerenciamento Master] Volume invalido para divisao: ", g_calculated_lot);
        PlaySound("timeout.wav");
        return;
    }

    ENUM_ORDER_TYPE order_type_for_check = is_buy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
    double price_for_check = g_is_pending ? g_entry_price : (is_buy ? ask : bid);
    string limit_err = "";
    if (!CheckMarginAndLimits(order_type_for_check, price_for_check, chunks, chunk_count, limit_err))
    {
        Alert("[Gerenciamento Master] Bloqueado pela plataforma: ", limit_err);
        PlaySound("timeout.wav");
        return;
    }

    // Identificador Unico da Operacao Logica (Group ID)
    ulong group_id = (ulong)TimeCurrent() * 1000 + (ulong)(GetTickCount() % 1000);
    string group_comment = StringFormat("%s_%I64u", InpOrderComment, group_id);
    if (StringLen(group_comment) > 31) group_comment = StringSubstr(group_comment, 0, 31);

    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetDeviationInPoints(InpSlippage);

    double executed_vol = 0.0;
    double weighted_price_sum = 0.0;
    int successful_orders = 0;
    string last_error_desc = "";

    for (int i = 0; i < chunk_count; i++)
    {
        double current_chunk = chunks[i];
        if (current_chunk <= 0.0) continue;

        // Verifica margem individual antes do envio de cada ordem
        double margin_req = 0.0;
        if (OrderCalcMargin(order_type_for_check, _Symbol, current_chunk, price_for_check, margin_req))
        {
            if (margin_req > AccountInfoDouble(ACCOUNT_MARGIN_FREE))
            {
                last_error_desc = StringFormat("Margem livre esgotada antes da ordem %d de %d", i + 1, chunk_count);
                PrintFormat("[Gerenciamento Master] %s. Envio interrompido.", last_error_desc);
                break;
            }
        }

        bool order_sent = false;
        double fill_price = 0.0;
        double fill_vol = 0.0;

        if (!g_is_pending)
        {
            if (is_buy)
            {
                ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                order_sent = trade.Buy(current_chunk, _Symbol, ask, g_stop_price, 0.0, group_comment);
                fill_price = trade.ResultPrice();
                if (fill_price <= 0.0) fill_price = ask;
            }
            else
            {
                bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                order_sent = trade.Sell(current_chunk, _Symbol, bid, g_stop_price, 0.0, group_comment);
                fill_price = trade.ResultPrice();
                if (fill_price <= 0.0) fill_price = bid;
            }
        }
        else
        {
            fill_price = g_entry_price;
            if (is_buy)
            {
                if (g_entry_price > ask)
                    order_sent = trade.BuyStop(current_chunk, g_entry_price, _Symbol, g_stop_price, 0.0, ORDER_TIME_GTC, 0, group_comment);
                else
                    order_sent = trade.BuyLimit(current_chunk, g_entry_price, _Symbol, g_stop_price, 0.0, ORDER_TIME_GTC, 0, group_comment);
            }
            else
            {
                if (g_entry_price < bid)
                    order_sent = trade.SellStop(current_chunk, g_entry_price, _Symbol, g_stop_price, 0.0, ORDER_TIME_GTC, 0, group_comment);
                else
                    order_sent = trade.SellLimit(current_chunk, g_entry_price, _Symbol, g_stop_price, 0.0, ORDER_TIME_GTC, 0, group_comment);
            }
        }

        if (order_sent)
        {
            successful_orders++;
            fill_vol = trade.ResultVolume();
            if (fill_vol <= 0.0) fill_vol = current_chunk;

            executed_vol += fill_vol;
            weighted_price_sum += (fill_price * fill_vol);

            PrintFormat("[Gerenciamento Master] Ordem %d/%d enviada! Lote: %.*f, Preco: %.*f, SL: %.*f (Grupo #%I64u)",
                        i + 1, chunk_count, lot_digits, fill_vol, _Digits, fill_price, _Digits, g_stop_price, group_id);
        }
        else
        {
            last_error_desc = trade.ResultRetcodeDescription();
            PrintFormat("[Gerenciamento Master] Falha na ordem %d/%d (Lote: %.*f): %s (Retcode: %d)",
                        i + 1, chunk_count, lot_digits, current_chunk, last_error_desc, trade.ResultRetcode());
            break;
        }
    }

    if (successful_orders > 0)
    {
        double avg_exec_price = (executed_vol > 0.0) ? (weighted_price_sum / executed_vol) : (is_buy ? ask : bid);
        g_entry_price = avg_exec_price;
        g_has_entry   = true;

        CreateFibonacciRR(avg_exec_price, g_stop_price);

        // Salva estado unificado da operacao nas Globais do Terminal para persistencia
        SaveOperationState(group_id, executed_vol, g_stop_price, avg_exec_price, g_is_pending, successful_orders);

        // Esconde a linha virtual de stop do EA (o MT5 exibe os stops nativos), mantendo a linha de entrada/adicao
        ObjectDelete(0, LINE_STOP);
        if (!g_is_pending)
        {
            UpdateMarketEntryPrice();
        }
        DrawLines();
        ChartRedraw(0);

        // Calcula risco assumido no volume executado
        double loss_per_1_lot = 0.0;
        double simulated_profit = 0.0;
        if (OrderCalcProfit(order_type_for_check, _Symbol, 1.0, avg_exec_price, g_stop_price, simulated_profit))
            loss_per_1_lot = MathAbs(simulated_profit);
        if (loss_per_1_lot <= 0.0 && g_calculated_lot > 0.0)
            loss_per_1_lot = g_actual_loss_at_sl / g_calculated_lot;

        double actual_risk = executed_vol * loss_per_1_lot;

        if (successful_orders == chunk_count)
        {
            PrintFormat("[Gerenciamento Master @giovannipaganinitrading] %s SUCESSO! Total: %.*f lotes em %d ordens. Preco Medio: %.*f, SL: %.*f, Risco: $%.2f",
                        (g_is_pending ? "ORDENS PENDENTES" : (is_buy ? "COMPRA" : "VENDA")),
                        lot_digits, executed_vol, chunk_count, _Digits, avg_exec_price, _Digits, g_stop_price, actual_risk);
            PlaySound("ok.wav");
        }
        else
        {
            PrintFormat("[Gerenciamento Master] ENTRADA: Executado %d de %d ordens (%.*f de %.*f lotes). Risco Real: $%.2f. Protecao Stop ativa em %.*f!",
                        successful_orders, chunk_count, lot_digits, executed_vol, lot_digits, g_calculated_lot, actual_risk, _Digits, g_stop_price);
            PlaySound("timeout.wav");
        }
    }
    else
    {
        Alert("[Gerenciamento Master] Nenhuma ordem pode ser executada: ", last_error_desc);
        PlaySound("timeout.wav");
    }
}

//+------------------------------------------------------------------+
//| Traca a Fibonacci de Risco:Retorno Automatica ao Entrar na Ordem |
//+------------------------------------------------------------------+
void CreateFibonacciRR(double entry, double stop)
{
    if (!InpAutoFibo || entry <= 0 || stop <= 0 || entry == stop) return;

    // Horario das ancoras (Ponto 0 na Entrada, Ponto 1 no Stop deslocado no tempo)
    datetime time_entry = iTime(_Symbol, _Period, 0);
    if (time_entry == 0) time_entry = TimeCurrent();
    datetime time_stop = time_entry + PeriodSeconds(_Period) * 15;

    if (ObjectFind(0, FIBO_NAME) >= 0)
    {
        ObjectDelete(0, FIBO_NAME);
    }

    // Cria a Retracao de Fibonacci NATIVA do MetaTrader 5 (OBJ_FIBO)
    // Anchor 0 = Entrada (Nivel 0.0)
    // Anchor 1 = Stop    (Nivel 1.0)
    if (!ObjectCreate(0, FIBO_NAME, OBJ_FIBO, 0, time_entry, entry, time_stop, stop))
    {
        Print("[Gerenciamento Master] Falha ao criar OBJ_FIBO: ", GetLastError());
        return;
    }

    // Estilo 100% nativo do MT5 identico a ferramenta selecionada na barra de ferramentas:
    // - Linha diagonal vermelha solida continua (STYLE_SOLID)
    // - Marcadores/pontos de ajuste selecionados (OBJPROP_SELECTED = true)
    ObjectSetInteger(0, FIBO_NAME, OBJPROP_COLOR, clrRed);
    ObjectSetInteger(0, FIBO_NAME, OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, FIBO_NAME, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, FIBO_NAME, OBJPROP_RAY_RIGHT, InpFiboRayRight);
    ObjectSetInteger(0, FIBO_NAME, OBJPROP_BACK, false);
    ObjectSetInteger(0, FIBO_NAME, OBJPROP_SELECTABLE, true);
    ObjectSetInteger(0, FIBO_NAME, OBJPROP_SELECTED, true);

    // Niveis de Risco:Retorno matematicos nativos da OBJ_FIBO:
    // Ponto 0 = Entrada, Ponto 1 = Stop
    // Nivel 1.0 = entrada (Ponto 0)
    // Nivel 0.0 = stop    (Ponto 1)
    // Nivel 2.0 = 1x1     (1R a favor da operacao: para cima em Compra, para baixo em Venda)
    // Nivel 3.0 = 2x1
    // Nivel 4.0 = 3x1
    // Nivel 5.0 = 4x1
    // Nivel 6.0 = 5x1
    // Nivel 7.0 = 6x1
    int total_levels = 8;
    ObjectSetInteger(0, FIBO_NAME, OBJPROP_LEVELS, total_levels);

    color clr_level = clrBlack;

    struct FiboLevelDef {
        double val;
        string name;
    };
    // Mapeamento nativo MT5 OBJ_FIBO:
    // Anchor 0 (Primeiro ponto) = Entrada -> Nivel 1.0 no MT5
    // Anchor 1 (Segundo ponto)  = Stop    -> Nivel 0.0 no MT5
    // Nivel 2.0 = 1x1 (Alvo projetado a favor da Entrada)
    // Nivel 3.0 = 2x1
    // Nivel 4.0 = 3x1
    // Nivel 5.0 = 4x1
    // Nivel 6.0 = 5x1
    // Nivel 7.0 = 6x1
    FiboLevelDef defs[8] = {
        { 1.0, "entrada" },
        { 0.0, "stop" },
        { 2.0, "1x1" },
        { 3.0, "2x1" },
        { 4.0, "3x1" },
        { 5.0, "4x1" },
        { 6.0, "5x1" },
        { 7.0, "6x1" }
    };

    for (int i = 0; i < total_levels; i++)
    {
        ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, i, defs[i].val);
        string lbl = InpShowFiboPrice ? StringFormat("%s (%%$)", defs[i].name) : defs[i].name;
        ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, i, lbl);
        ObjectSetInteger(0, FIBO_NAME, OBJPROP_LEVELCOLOR, i, clr_level);
        ObjectSetInteger(0, FIBO_NAME, OBJPROP_LEVELSTYLE, i, STYLE_SOLID);
        ObjectSetInteger(0, FIBO_NAME, OBJPROP_LEVELWIDTH, i, 1);
    }

    Print(StringFormat("[Gerenciamento Master] Retracao Nativa MT5 tracada! Entrada: %.*f, Stop: %.*f", _Digits, entry, _Digits, stop));
    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Obtem o Volume Inicial de Abertura da Posicao no Historico       |
//+------------------------------------------------------------------+
double GetInitialPositionVolume(ulong pos_ticket)
{
    ulong pos_id = PositionGetInteger(POSITION_IDENTIFIER);
    if (pos_id == 0) pos_id = pos_ticket;

    // Seleciona o historico referente a esta posicao
    if (HistorySelectByPosition(pos_id))
    {
        double sum_in_vol = 0.0;
        int deals_total = HistoryDealsTotal();
        for (int i = 0; i < deals_total; i++)
        {
            ulong deal_ticket = HistoryDealGetTicket(i);
            if (deal_ticket > 0)
            {
                long entry = HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
                if (entry == DEAL_ENTRY_IN) // Deal inicial de entrada
                {
                    double vol = HistoryDealGetDouble(deal_ticket, DEAL_VOLUME);
                    if (vol > 0.0) sum_in_vol += vol;
                }
            }
        }
        if (sum_in_vol > 0.0) return sum_in_vol;

        // Tenta pelas ordens historicas se nao achou deal
        int orders_total = HistoryOrdersTotal();
        for (int i = 0; i < orders_total; i++)
        {
            ulong ord_ticket = HistoryOrderGetTicket(i);
            if (ord_ticket > 0 && ord_ticket == pos_id)
            {
                double ord_vol = HistoryOrderGetDouble(ord_ticket, ORDER_VOLUME_INITIAL);
                if (ord_vol > 0.0) return ord_vol;
            }
        }
    }

    // Fallback: volume atual
    return PositionGetDouble(POSITION_VOLUME);
}

//+------------------------------------------------------------------+
//| Fechamento parcial seguro compatível com Netting                 |
//+------------------------------------------------------------------+
bool ExecuteSafePartialClose(ulong ticket, double volume_to_close, ulong deviation)
{
    if (!PositionSelectByTicket(ticket)) return false;
    long margin_mode = AccountInfoInteger(ACCOUNT_MARGIN_MODE);
    if (margin_mode == ACCOUNT_MARGIN_MODE_RETAIL_NETTING || margin_mode == ACCOUNT_MARGIN_MODE_EXCHANGE)
    {
        long pos_type = PositionGetInteger(POSITION_TYPE);
        string symbol = PositionGetString(POSITION_SYMBOL);
        double price = 0.0;
        
        trade.SetDeviationInPoints(deviation);
        trade.SetExpertMagicNumber(InpMagicNumber);
        
        if (pos_type == POSITION_TYPE_BUY)
        {
            price = SymbolInfoDouble(symbol, SYMBOL_BID);
            return trade.Sell(volume_to_close, symbol, price, 0, 0, "GMaster_Partial");
        }
        else
        {
            price = SymbolInfoDouble(symbol, SYMBOL_ASK);
            return trade.Buy(volume_to_close, symbol, price, 0, 0, "GMaster_Partial");
        }
    }
    else
    {
        return trade.PositionClosePartial(ticket, volume_to_close, deviation);
    }
}

//+------------------------------------------------------------------+
//| Execucao Instantanea de Parcial Unificada (Hedge & Netting)      |
//+------------------------------------------------------------------+
void ExecutePartialClose()
{
    // Debounce de seguranca contra cliques duplos rapidos
    static uint s_last_partial_tick = 0;
    uint now_tick = GetTickCount();
    if (now_tick - s_last_partial_tick < 400) return;
    s_last_partial_tick = now_tick;

    int total_positions = PositionsTotal();
    if (total_positions <= 0)
    {
        Alert("[Gerenciamento Master] Nenhuma posicao aberta encontrada!");
        return;
    }

    // =====================================================================
    // 1. PRIORIDADE MAXIMA: SE HOUVER UMA ADICAO DE POSICAO, FECHA 100% DELA
    // =====================================================================
    ulong addition_tickets[];
    double addition_vols[];
    int additions_found = 0;

    bool is_netting = (AccountInfoInteger(ACCOUNT_MARGIN_MODE) == ACCOUNT_MARGIN_MODE_RETAIL_NETTING || 
                       AccountInfoInteger(ACCOUNT_MARGIN_MODE) == ACCOUNT_MARGIN_MODE_EXCHANGE);

    if (!is_netting)
    {
        for (int i = 0; i < total_positions; i++)
        {
            ulong ticket = PositionGetTicket(i);
            if (ticket > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol)
            {
                long magic = PositionGetInteger(POSITION_MAGIC);
                string comment = PositionGetString(POSITION_COMMENT);
                if (magic == (InpMagicNumber + 1) || StringFind(comment, "Add") >= 0)
                {
                    ArrayResize(addition_tickets, additions_found + 1);
                    ArrayResize(addition_vols, additions_found + 1);
                    addition_tickets[additions_found] = ticket;
                    addition_vols[additions_found] = PositionGetDouble(POSITION_VOLUME);
                    additions_found++;
                }
            }
        }
    }

    if (additions_found > 0)
    {
        double total_add_closed = 0.0;
        for (int a = 0; a < additions_found; a++)
        {
            if (trade.PositionClose(addition_tickets[a], InpSlippage))
            {
                total_add_closed += addition_vols[a];
                Print(StringFormat("[Gerenciamento Master @giovannipaganinitrading] 1a PARCIAL: ADICAO FECHADA 100%%! Ticket #%I64u (%.2f lotes). Risco adicional zerado com sucesso!",
                                   addition_tickets[a], addition_vols[a]));
            }
            else
            {
                Alert("[Gerenciamento Master] Erro ao fechar adicao de posicao: ", trade.ResultRetcodeDescription());
            }
        }
        if (total_add_closed > 0)
        {
            PlaySound("ok.wav");
        }
        return;
    }

    // =====================================================================
    // 2. COM A ADICAO JA ENCERRADA: EXECUTA A PARCIAL NA OPERACAO PRINCIPAL
    // =====================================================================
    ulong primary_tickets[];
    double primary_vols[];
    int primary_count = 0;
    double total_current_open_vol = 0.0;

    // Busca todas as posicoes que pertencem a operacao principal (Magic == InpMagicNumber)
    for (int i = 0; i < total_positions; i++)
    {
        ulong ticket = PositionGetTicket(i);
        if (ticket > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol)
        {
            long magic = PositionGetInteger(POSITION_MAGIC);
            string comment = PositionGetString(POSITION_COMMENT);
            if (magic == InpMagicNumber && StringFind(comment, "Add") < 0)
            {
                double p_vol = PositionGetDouble(POSITION_VOLUME);
                if (p_vol > 0.0)
                {
                    ArrayResize(primary_tickets, primary_count + 1);
                    ArrayResize(primary_vols, primary_count + 1);
                    primary_tickets[primary_count] = ticket;
                    primary_vols[primary_count] = p_vol;
                    total_current_open_vol += p_vol;
                    primary_count++;
                }
            }
        }
    }

    // Fallback: se nao encontrou pelo Magic mas ha posicoes no simbolo, pega as posicoes do ativo
    if (primary_count == 0)
    {
        for (int i = 0; i < total_positions; i++)
        {
            ulong ticket = PositionGetTicket(i);
            if (ticket > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol)
            {
                double p_vol = PositionGetDouble(POSITION_VOLUME);
                if (p_vol > 0.0)
                {
                    ArrayResize(primary_tickets, primary_count + 1);
                    ArrayResize(primary_vols, primary_count + 1);
                    primary_tickets[primary_count] = ticket;
                    primary_vols[primary_count] = p_vol;
                    total_current_open_vol += p_vol;
                    primary_count++;
                }
            }
        }
    }

    if (primary_count == 0 || total_current_open_vol <= 0.0)
    {
        PrintFormat("[Gerenciamento Master] Nenhuma posicao aberta no ativo %s!", _Symbol);
        PlaySound("timeout.wav");
        return;
    }

    // Regras de volume da corretora
    double min_lot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    if (lot_step <= 0) lot_step = 0.01;
    if (min_lot <= 0) min_lot = lot_step;
    int lot_digits = GetLotDigits(lot_step);

    total_current_open_vol = NormalizeDouble(total_current_open_vol, lot_digits);

    // Obtem o volume INICIAL AGREGADO da operacao completa
    double initial_total_vol = GetOperationInitialVolume();
    if (initial_total_vol < total_current_open_vol) initial_total_vol = total_current_open_vol;

    // Calcula lote baseado no volume INICIAL da operacao agregada
    double raw_lot = initial_total_vol * (g_partial_percent / 100.0);
    double target_close_lot = MathRound(raw_lot / lot_step) * lot_step;
    target_close_lot = NormalizeDouble(target_close_lot, lot_digits);

    if (target_close_lot < min_lot) target_close_lot = min_lot;

    // Se o que resta na operacao for menor ou igual a parcial calculada, fecha o restante (Saida Final)
    bool is_final_exit = (target_close_lot >= total_current_open_vol);
    if (is_final_exit)
    {
        target_close_lot = total_current_open_vol;
    }

    // =====================================================================
    // 3. EXECUCAO: FECHAMENTO TOTAL OU DISTRIBUICAO DE PARCIAL ENTRE AS ORDENS
    // =====================================================================
    double actual_closed_total = 0.0;

    if (is_final_exit)
    {
        // Encerramento total de todas as posicoes da operacao
        for (int k = 0; k < primary_count; k++)
        {
            if (trade.PositionClose(primary_tickets[k], InpSlippage))
            {
                actual_closed_total += primary_vols[k];
            }
            else
            {
                PrintFormat("[Gerenciamento Master] Erro ao fechar posicao #%I64u: %s",
                            primary_tickets[k], trade.ResultRetcodeDescription());
            }
        }

        // Cancela quaisquer ordens pendentes residuais para evitar reabertura indesejada
        CancelOperationPendingOrders(_Symbol, InpMagicNumber);
        ClearOperationState();

        PrintFormat("[Gerenciamento Master @giovannipaganinitrading] SAIDA FINAL CONCLUIDA! Operacao encerrada totalmente (%.*f lotes fechados). Saldo residual zerado.",
                    lot_digits, actual_closed_total);
        PlaySound("ok.wav");
        return;
    }

    // Distribuicao de fechamento parcial entre as posicoes que compoem a operacao
    double remaining_to_close = target_close_lot;

    for (int k = 0; k < primary_count && remaining_to_close > 0.0; k++)
    {
        // Re-consulta o volume real atual da posicao
        if (!PositionSelectByTicket(primary_tickets[k])) continue;
        double current_p_vol = PositionGetDouble(POSITION_VOLUME);
        if (current_p_vol <= 0.0) continue;

        current_p_vol = NormalizeDouble(current_p_vol, lot_digits);

        if (current_p_vol <= remaining_to_close)
        {
            // Fecha 100% desta posicao
            if (trade.PositionClose(primary_tickets[k], InpSlippage))
            {
                actual_closed_total += current_p_vol;
                remaining_to_close = NormalizeDouble(remaining_to_close - current_p_vol, lot_digits);
                PrintFormat("[Gerenciamento Master] Posicao #%I64u (%.*f lotes) fechada integralmente na parcial.",
                            primary_tickets[k], lot_digits, current_p_vol);
            }
            else
            {
                PrintFormat("[Gerenciamento Master] Erro ao fechar posicao #%I64u: %s",
                            primary_tickets[k], trade.ResultRetcodeDescription());
            }
        }
        else
        {
            // Fecha uma fracao desta posicao
            double close_chunk = MathFloor(remaining_to_close / lot_step) * lot_step;
            close_chunk = NormalizeDouble(close_chunk, lot_digits);

            // Protecao de regras MT5: saldo restante nao pode ficar entre 0 e min_lot
            double rem_after = NormalizeDouble(current_p_vol - close_chunk, lot_digits);
            if (rem_after > 0.0 && rem_after < min_lot)
            {
                if (current_p_vol - min_lot >= min_lot)
                {
                    close_chunk = NormalizeDouble(current_p_vol - min_lot, lot_digits);
                }
                else
                {
                    close_chunk = current_p_vol; // Fecha tudo para nao violar o lote minimo
                }
            }

            if (close_chunk >= current_p_vol)
            {
                if (trade.PositionClose(primary_tickets[k], InpSlippage))
                {
                    actual_closed_total += current_p_vol;
                    remaining_to_close = NormalizeDouble(remaining_to_close - current_p_vol, lot_digits);
                    if (remaining_to_close < 0.0) remaining_to_close = 0.0;
                }
            }
            else if (close_chunk >= min_lot)
            {
                if (ExecuteSafePartialClose(primary_tickets[k], close_chunk, InpSlippage))
                {
                    actual_closed_total += close_chunk;
                    remaining_to_close = NormalizeDouble(remaining_to_close - close_chunk, lot_digits);
                    PrintFormat("[Gerenciamento Master] Posicao #%I64u: fechamento parcial de %.*f lotes (restam %.*f).",
                                primary_tickets[k], lot_digits, close_chunk, lot_digits, rem_after);
                }
                else
                {
                    PrintFormat("[Gerenciamento Master] Erro no PositionClosePartial da posicao #%I64u: %s",
                                primary_tickets[k], trade.ResultRetcodeDescription());
                }
            }
        }
    }

    // Atualiza rastreamento global persistente
    double prev_closed = 0.0;
    GlobalVariableGet("GM_OP_" + _Symbol + "_ClosedVol", prev_closed);
    GlobalVariableSet("GM_OP_" + _Symbol + "_ClosedVol", prev_closed + actual_closed_total);

    double rem_open = NormalizeDouble(total_current_open_vol - actual_closed_total, lot_digits);
    if (rem_open < 0.0) rem_open = 0.0;

    PrintFormat("[Gerenciamento Master @giovannipaganinitrading] PARCIAL UNIFICADA SUCESSO! Fechado %.*f lotes (%.0f%% de %.*f inicial). Restam: %.*f lotes em aberto.",
                lot_digits, actual_closed_total, g_partial_percent, lot_digits, initial_total_vol, lot_digits, rem_open);
    PlaySound("ok.wav");
}

//+------------------------------------------------------------------+
//| Execucao de Adicao de Posicao (Scale-In / Maximo 50%)            |
//+------------------------------------------------------------------+
void ExecutePositionAddition()
{
    EvaluateSessionDiscipline(true);
    if (g_session_loss_locked)
    {
        Alert("[Gerenciamento Master] TRAVA DE LOSS ATINGIDA! Adição bloqueada neste turno.");
        PlaySound("timeout.wav");
        return;
    }

    int total_positions = PositionsTotal();
    if (total_positions <= 0)
    {
        Alert("[Gerenciamento Master] Nenhuma posicao aberta para adicionar! A primeira entrada deve ser feita via [Espaco].");
        return;
    }

    ulong primary_ticket = 0;
    double pos_volume = 0.0;
    ENUM_POSITION_TYPE pos_type = POSITION_TYPE_BUY;
    double primary_sl = 0.0;

    // Busca a ordem principal para sincronizar perfeitamente o Stop Loss
    datetime oldest_time = D'2099.12.31';
    for (int i = 0; i < total_positions; i++)
    {
        ulong ticket = PositionGetTicket(i);
        if (ticket > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol)
        {
            long magic = PositionGetInteger(POSITION_MAGIC);
            datetime pos_time = (datetime)PositionGetInteger(POSITION_TIME);

            if (magic == InpMagicNumber)
            {
                primary_ticket = ticket;
                pos_volume = PositionGetDouble(POSITION_VOLUME);
                pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                primary_sl = PositionGetDouble(POSITION_SL);
                break;
            }

            if (pos_time < oldest_time)
            {
                oldest_time = pos_time;
                primary_ticket = ticket;
                pos_volume = PositionGetDouble(POSITION_VOLUME);
                pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                primary_sl = PositionGetDouble(POSITION_SL);
            }
        }
    }

    if (primary_ticket == 0 || pos_volume <= 0)
    {
        Alert(StringFormat("[Gerenciamento Master] Nenhuma posicao aberta no ativo %s para adicionar!", _Symbol));
        return;
    }

    // Trava estrita de seguranca de no maximo 50%
    double clamped_pct = MathMin(50.0, MathMax(1.0, g_add_percent));

    // Volume original de abertura da operacao principal (agregado)
    double initial_vol = GetOperationInitialVolume();
    if (initial_vol <= 0.0) initial_vol = pos_volume;

    // Regras de lote da corretora
    double min_lot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    if (lot_step <= 0) lot_step = 0.01;
    if (min_lot <= 0) min_lot = lot_step;

    int lot_digits = GetLotDigits(lot_step);

    // Calcula lote de adicao (sempre com base no volume inicial e limitado a 50%)
    double raw_lot = initial_vol * (clamped_pct / 100.0);
    double add_lot = MathRound(raw_lot / lot_step) * lot_step;
    add_lot = NormalizeDouble(add_lot, lot_digits);

    if (add_lot < min_lot) add_lot = min_lot;

    // =====================================================================
    // SINCRONIZACAO AUTOMATICA DO STOP LOSS:
    // O Stop da adicao eh OBRIGATORIAMENTE igual ao Stop da ordem principal!
    // =====================================================================
    double sl_to_use = primary_sl;
    if (sl_to_use <= 0.0 && g_has_stop && g_stop_price > 0)
    {
        sl_to_use = g_stop_price;
    }

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

    double effective_max = GetEffectiveMaxVolumePerOrder(_Symbol);
    double add_chunks[];
    int add_chunk_count = SplitVolumeIntoChunks(add_lot, effective_max, min_lot, lot_step, lot_digits, add_chunks);
    if (add_chunk_count <= 0)
    {
        Alert("[Gerenciamento Master] Volume invalido para adicao: ", add_lot);
        return;
    }

    // Tag especial para a adicao (Magic = InpMagicNumber + 1 e Comentario GMaster_Add)
    trade.SetExpertMagicNumber(InpMagicNumber + 1);

    // MODO MERCADO (IMEDIATO)
    if (!g_is_pending)
    {
        int add_success = 0;
        double executed_add = 0.0;
        for (int c = 0; c < add_chunk_count; c++)
        {
            double cur_add_chunk = add_chunks[c];
            if (cur_add_chunk <= 0.0) continue;

            if (pos_type == POSITION_TYPE_BUY)
            {
                ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                if (trade.Buy(cur_add_chunk, _Symbol, ask, sl_to_use, 0.0, "GMaster_Add"))
                {
                    add_success++;
                    executed_add += cur_add_chunk;
                }
                else
                {
                    Alert("[Gerenciamento Master] Erro na adicao a mercado: ", trade.ResultRetcodeDescription());
                    break;
                }
            }
            else // SELL
            {
                bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                if (trade.Sell(cur_add_chunk, _Symbol, bid, sl_to_use, 0.0, "GMaster_Add"))
                {
                    add_success++;
                    executed_add += cur_add_chunk;
                }
                else
                {
                    Alert("[Gerenciamento Master] Erro na adicao a mercado: ", trade.ResultRetcodeDescription());
                    break;
                }
            }
        }

        if (add_success > 0)
        {
            Print(StringFormat("[Gerenciamento Master @giovannipaganinitrading] ADICAO executada! Lote: %.*f (%.0f%% de %.*f inicial em %d ordens), SL Sincronizado: %.*f",
                               lot_digits, executed_add, clamped_pct, lot_digits, initial_vol, add_success, _Digits, sl_to_use));
            PlaySound("ok.wav");
            UpdateMarketEntryPrice();
            DrawLines();
            ChartRedraw(0);
        }
    }
    // MODO PENDENTE
    else
    {
        if (!g_has_entry || g_entry_price <= 0)
        {
            trade.SetExpertMagicNumber(InpMagicNumber);
            Alert("[Gerenciamento Master] Posicione a linha de Entrada com 'E' para adicionar como ordem pendente!");
            return;
        }

        int add_success = 0;
        for (int c = 0; c < add_chunk_count; c++)
        {
            double cur_add_chunk = add_chunks[c];
            if (cur_add_chunk <= 0.0) continue;

            if (pos_type == POSITION_TYPE_BUY)
            {
                if (g_entry_price < ask)
                {
                    if (trade.BuyLimit(cur_add_chunk, g_entry_price, _Symbol, sl_to_use, 0.0, ORDER_TIME_GTC, 0, "GMaster_Add"))
                        add_success++;
                    else
                    {
                        Alert("[Gerenciamento Master] Erro no Buy Limit de adicao: ", trade.ResultRetcodeDescription());
                        break;
                    }
                }
                else
                {
                    if (trade.BuyStop(cur_add_chunk, g_entry_price, _Symbol, sl_to_use, 0.0, ORDER_TIME_GTC, 0, "GMaster_Add"))
                        add_success++;
                    else
                    {
                        Alert("[Gerenciamento Master] Erro no Buy Stop de adicao: ", trade.ResultRetcodeDescription());
                        break;
                    }
                }
            }
            else // SELL
            {
                if (g_entry_price > bid)
                {
                    if (trade.SellLimit(cur_add_chunk, g_entry_price, _Symbol, sl_to_use, 0.0, ORDER_TIME_GTC, 0, "GMaster_Add"))
                        add_success++;
                    else
                    {
                        Alert("[Gerenciamento Master] Erro no Sell Limit de adicao: ", trade.ResultRetcodeDescription());
                        break;
                    }
                }
                else
                {
                    if (trade.SellStop(cur_add_chunk, g_entry_price, _Symbol, sl_to_use, 0.0, ORDER_TIME_GTC, 0, "GMaster_Add"))
                        add_success++;
                    else
                    {
                        Alert("[Gerenciamento Master] Erro no Sell Stop de adicao: ", trade.ResultRetcodeDescription());
                        break;
                    }
                }
            }
        }

        if (add_success > 0)
        {
            Print(StringFormat("[Gerenciamento Master] ADICAO PENDENTE colocada! Total: %.*f em %d ordens, SL: %.*f",
                               lot_digits, add_lot, add_success, _Digits, sl_to_use));
            PlaySound("ok.wav");
        }
    }

    // Restaura o Magic Number padrao
    trade.SetExpertMagicNumber(InpMagicNumber);
}

//+------------------------------------------------------------------+
//| Tratamento de Eventos no Grafico                                 |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{

    // Evento disparado quando qualquer gráfico salva novas configurações padrão (Salvar Default ou Sincronizacao)
    if (id == CHARTEVENT_CUSTOM + 8888 || (id >= CHARTEVENT_CUSTOM && sparam == "RELOAD_DEFAULT"))
    {
        double ver = 0;
        if (GlobalVariableGet("GM_ConfigVersion", ver))
            g_last_config_version = ver;

        g_timer_selected = false;
        g_timer_dragging = false;
        g_timer_is_custom = false;
        g_timer_custom_x = -1;
        g_timer_custom_y = -1;
        RestoreCurrentDefault();
        EvaluateSessionDiscipline(true);
        CreatePanel();
        Recalculate();
        UpdatePanel();
        DeleteCandleTimer();
        UpdateCandleTimer();
        ChartRedraw(0);
        return;
    }

    // Refit when tiled charts or the terminal window change size.
    if (id == CHARTEVENT_CHART_CHANGE)
    {
        if (g_drag_mode == 0) { RepositionPanel(); }
        UpdateCandleTimer();
        ChartRedraw(0);
        return;
    }

    if (id == CHARTEVENT_MOUSE_MOVE)
    {
        g_mouse_x = (int)lparam;
        g_mouse_y = (int)dparam;
        int window = 0;
        ChartXYToTimePrice(0, g_mouse_x, g_mouse_y, window, g_mouse_time, g_mouse_price);
        bool lbutton = (((int)StringToInteger(sparam) & 1) != 0);

        // Verificacao do Relogio de Candles para arrasto
        int tx = -1000, ty = -1000, tw = 80, th = 24;
        bool over_timer = false;
        if (g_candle_timer_enabled && ObjectFind(0, CANDLE_TIMER_NAME) >= 0)
        {
            tx = (int)ObjectGetInteger(0, CANDLE_TIMER_NAME, OBJPROP_XDISTANCE);
            ty = (int)ObjectGetInteger(0, CANDLE_TIMER_NAME, OBJPROP_YDISTANCE);
            tw = (int)ObjectGetInteger(0, CANDLE_TIMER_NAME, OBJPROP_XSIZE);
            th = (int)ObjectGetInteger(0, CANDLE_TIMER_NAME, OBJPROP_YSIZE);
            if (tw <= 0) tw = 80;
            if (th <= 0) th = 24;
            over_timer = (g_mouse_x >= tx - 8 && g_mouse_x <= tx + tw + 8 &&
                          g_mouse_y >= ty - 8 && g_mouse_y <= ty + th + 8);
        }

        // Se o usuario selecionou nativamente no MT5 com duplo clique
        if (ObjectGetInteger(0, CANDLE_TIMER_NAME, OBJPROP_SELECTED) != 0 && !g_timer_selected)
        {
            g_timer_selected = true;
        }

        // Se soltou o botao do mouse enquanto arrastava o relogio
        if (!lbutton && g_timer_dragging)
        {
            g_timer_dragging = false;
            g_timer_custom_x = (int)ObjectGetInteger(0, CANDLE_TIMER_NAME, OBJPROP_XDISTANCE);
            g_timer_custom_y = (int)ObjectGetInteger(0, CANDLE_TIMER_NAME, OBJPROP_YDISTANCE);
            g_timer_is_custom = true;
            SetChartScroll(true);
        }

        // Se o relogio estiver selecionado
        if (g_timer_selected)
        {
            if (lbutton && !g_prev_lbutton && over_timer)
            {
                g_timer_dragging = true;
                g_timer_drag_offset_x = g_mouse_x - tx;
                g_timer_drag_offset_y = g_mouse_y - ty;
            }
            else if (lbutton && g_timer_dragging)
            {
                g_timer_custom_x = MathMax(2, g_mouse_x - g_timer_drag_offset_x);
                g_timer_custom_y = MathMax(2, g_mouse_y - g_timer_drag_offset_y);
                g_timer_is_custom = true;

                ObjectSetInteger(0, CANDLE_TIMER_NAME, OBJPROP_CORNER, CORNER_LEFT_UPPER);
                ObjectSetInteger(0, CANDLE_TIMER_NAME, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
                ObjectSetInteger(0, CANDLE_TIMER_NAME, OBJPROP_XDISTANCE, g_timer_custom_x);
                ObjectSetInteger(0, CANDLE_TIMER_NAME, OBJPROP_YDISTANCE, g_timer_custom_y);
                SetChartScroll(false);
                ChartRedraw(0);
                g_prev_lbutton = lbutton;
                return;
            }
        }

        int cur_x = g_is_minimized ? g_min_panel_x : g_panel_x;
        int cur_y = g_is_minimized ? g_min_panel_y : g_panel_y;
        int px = Scale(cur_x), py = Scale(cur_y);
        int logical_w = g_is_minimized ? PANEL_MINIMIZED_W : g_panel_w;
        int logical_h = PanelBaseHeight();
        int pw = Scale(logical_w), ph = Scale(logical_h);
        int grip = MathMax(5, Scale(g_is_minimized ? 8 : 16));
        bool over = (g_mouse_x >= px && g_mouse_x <= px + pw &&
                     g_mouse_y >= py && g_mouse_y <= py + ph);
        SetChartScroll(!(over || g_drag_mode > 0 || over_timer || g_timer_dragging));
        if (!lbutton)
        {
            g_drag_mode = 0;
            g_prev_lbutton = false;
            return;
        }
        if (!g_prev_lbutton && over)
        {
            if (g_mouse_x >= px + pw - grip && g_mouse_y >= py + ph - grip)
                g_drag_mode = 2;
            else if (g_mouse_x >= px + pw - MathMax(3, Scale(4)))
                g_drag_mode = 3;
            else if (g_mouse_y >= py + ph - MathMax(3, Scale(4)))
                g_drag_mode = 4;
            else if (g_mouse_x < px + pw - Scale(g_is_minimized ? 76 : 110) &&
                     g_mouse_y <= py + Scale(g_is_minimized ? PANEL_MINIMIZED_H : PANEL_HEADER_H))
            {
                g_drag_mode = 1;
                g_drag_offset_x = g_mouse_x - px;
                g_drag_offset_y = g_mouse_y - py;
            }
            g_resize_start_x = g_mouse_x;
            g_resize_start_y = g_mouse_y;
            g_resize_start_scale = g_ui_scale;
        }
        else if (g_prev_lbutton && g_drag_mode > 0)
        {
            if (g_drag_mode == 1)
            {
                if (g_is_minimized)
                {
                    g_min_panel_x = MathMax(1, (int)MathRound((g_mouse_x - g_drag_offset_x) / g_dpi_scale));
                    g_min_panel_y = MathMax(1, (int)MathRound((g_mouse_y - g_drag_offset_y) / g_dpi_scale));
                }
                else
                {
                    g_panel_x = MathMax(1, (int)MathRound((g_mouse_x - g_drag_offset_x) / g_dpi_scale));
                    g_panel_y = MathMax(1, (int)MathRound((g_mouse_y - g_drag_offset_y) / g_dpi_scale));
                }
            }
            else
            {
                // Resize the entire interface, including fonts and controls.
                double dx = (g_mouse_x - g_resize_start_x) / (g_system_dpi_scale * logical_w);
                double dy = (g_mouse_y - g_resize_start_y) / (g_system_dpi_scale * logical_h);
                double delta = (g_drag_mode == 3) ? dx : ((g_drag_mode == 4) ? dy :
                               ((MathAbs(dx) >= MathAbs(dy)) ? dx : dy));
                double size = g_resize_start_scale + delta;
                if (g_is_minimized) g_minimized_scale = MathMax(0.60, MathMin(1.50, size));
                else g_open_scale = MathMax(0.40, MathMin(1.50, size));
            }
            RepositionPanel();
            ChartRedraw(0);
        }
        g_prev_lbutton = lbutton;
        return;
    }

    // 2. Atalhos de Teclado
    if (id == CHARTEVENT_KEYDOWN)
    {
        if (g_is_editing_risk || g_is_editing_partial || g_is_editing_add || g_is_editing_max_trades || g_is_editing_max_loss || g_is_editing_pwd) return; // Nao dispara atalhos enquanto usuario digita no campo de edicao
        if (g_listening_action > 0)
        {
            string new_key = GetKeyName(lparam);
            int new_vk = (int)lparam;

            if (g_listening_action == 1)      { g_key_entry_str = new_key; g_key_entry_vk = new_vk; }
            else if (g_listening_action == 2) { g_key_stop_str  = new_key; g_key_stop_vk  = new_vk; }
            else if (g_listening_action == 3) { g_key_mode_str  = new_key; g_key_mode_vk  = new_vk; }
            else if (g_listening_action == 4) { g_key_hide_str  = new_key; g_key_hide_vk  = new_vk; }
            else if (g_listening_action == 5) { g_key_min_str   = new_key; g_key_min_vk   = new_vk; }
            else if (g_listening_action == 6) { g_key_exec_str  = new_key; g_key_exec_vk  = new_vk; }
            else if (g_listening_action == 7) { g_key_partial_str = new_key; g_key_partial_vk = new_vk; }
            else if (g_listening_action == 8) { g_key_add_str     = new_key; g_key_add_vk     = new_vk; }

            g_listening_action = 0;
            CreatePanel();
            Recalculate();
            ChartRedraw(0);
            return;
        }

        long key_upper = lparam;
        if (key_upper >= 'a' && key_upper <= 'z') key_upper -= 32;

        long entry_upper = g_key_entry_vk;
        if (entry_upper >= 'a' && entry_upper <= 'z') entry_upper -= 32;

        long stop_upper = g_key_stop_vk;
        if (stop_upper >= 'a' && stop_upper <= 'z') stop_upper -= 32;

        long mode_upper = g_key_mode_vk;
        if (mode_upper >= 'a' && mode_upper <= 'z') mode_upper -= 32;

        long hide_upper = g_key_hide_vk;
        if (hide_upper >= 'a' && hide_upper <= 'z') hide_upper -= 32;

        long min_upper = g_key_min_vk;
        if (min_upper >= 'a' && min_upper <= 'z') min_upper -= 32;

        if (key_upper == entry_upper)
        {
            // Se houver trade em andamento, o usuario pode usar o E para definir a entrada de uma Adicao Pendente

            if (g_mouse_price > 0)
            {
                g_entry_price = AlignPrice(g_mouse_price);
                g_has_entry   = true;
                g_is_pending  = true;
                DrawLines();
                Recalculate();
                ChartRedraw(0);
            }
        }
        else if (key_upper == stop_upper)
        {
            if (g_mouse_price > 0)
            {
                bool has_position = false;
                for (int i = 0; i < PositionsTotal(); i++)
                {
                    ulong ticket = PositionGetTicket(i);
                    if (ticket > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol)
                    {
                        long magic = PositionGetInteger(POSITION_MAGIC);
                        if (magic == InpMagicNumber || magic == (InpMagicNumber + 1))
                        {
                            has_position = true;
                            break;
                        }
                    }
                }

                if (has_position)
                {
                    // Ajusta em conjunto todos os stops da operacao em andamento no ativo
                    AdjustAllTradeStops(g_mouse_price);
                }
                else
                {
                    g_stop_price = AlignPrice(g_mouse_price);
                    g_has_stop   = true;
                    if (!g_is_pending) UpdateMarketEntryPrice();
                    DrawLines();
                    Recalculate();
                    ChartRedraw(0);
                }
            }
        }
        else if (key_upper == mode_upper)
        {
            g_is_pending = !g_is_pending;
            if (!g_is_pending)
            {
                UpdateMarketEntryPrice();
            }
            DrawLines();
            Recalculate();
            
            // Se voltou para modo mercado com trade aberto, garante a Fibo original na entrada real da operacao
            if (!g_is_pending && HasActiveTradeOnSymbol() && g_has_stop)
            {
                double op_entry = GetActiveTradeEntryPrice();
                if (op_entry > 0.0)
                {
                    CreateFibonacciRR(op_entry, g_stop_price);
                }
            }
            
            ChartRedraw(0);
        }
        else if (key_upper == hide_upper)
        {
            g_lines_hidden = !g_lines_hidden;
            DrawLines();
            UpdatePanel();
            ChartRedraw(0);
        }
        else if (key_upper == min_upper)
        {
            g_is_minimized = !g_is_minimized;
            if (g_is_minimized)
            {
                g_min_panel_x = 10;
                g_min_panel_y = 36;
            }
            CreatePanel();
            UpdatePanel();
            ChartRedraw(0);
        }
        else if (lparam == g_key_exec_vk || key_upper == g_key_exec_vk)
        {
            ExecuteTrade();
        }
        else if (key_upper == g_key_partial_vk || lparam == g_key_partial_vk)
        {
            ExecutePartialClose();
        }
        else if (key_upper == g_key_add_vk || lparam == g_key_add_vk)
        {
            ExecutePositionAddition();
        }
        else if (key_upper == 'F')
        {
            if (HasActiveTradeOnSymbol())
            {
                double op_entry = GetActiveTradeEntryPrice();
                if (op_entry > 0.0 && g_has_stop)
                {
                    CreateFibonacciRR(op_entry, g_stop_price);
                }
            }
            else if (g_has_entry && g_has_stop)
            {
                CreateFibonacciRR(g_entry_price, g_stop_price);
            }
        }
        return;
    }

    // 3. Arrastar Linhas e Objetos
    if (id == CHARTEVENT_OBJECT_DRAG)
    {
        if (sparam == LINE_STOP)
        {
            g_stop_price = AlignPrice(ObjectGetDouble(0, LINE_STOP, OBJPROP_PRICE));
            g_has_stop   = true;
            if (!g_is_pending) UpdateMarketEntryPrice();
            Recalculate();
            ChartRedraw(0);
        }
        else if (sparam == LINE_ENTRY)
        {
            // Se houver trade aberto e o usuario arrastar a entrada, entra em modo de adicao pendente automaticamente
            g_entry_price = AlignPrice(ObjectGetDouble(0, LINE_ENTRY, OBJPROP_PRICE));
            g_has_entry   = true;
            g_is_pending  = true;
            Recalculate();
            ChartRedraw(0);
        }
        else if (sparam == CANDLE_TIMER_NAME)
        {
            g_timer_is_custom = true;
            g_timer_custom_x = (int)ObjectGetInteger(0, CANDLE_TIMER_NAME, OBJPROP_XDISTANCE);
            g_timer_custom_y = (int)ObjectGetInteger(0, CANDLE_TIMER_NAME, OBJPROP_YDISTANCE);
            ChartRedraw(0);
        }
        return;
    }

    // 4. Cliques no Grafico (Deteccao de duplo clique e desselecao do relogio)
    if (id == CHARTEVENT_CLICK)
    {
        int cx = (int)lparam;
        int cy = (int)dparam;
        int tx = (int)ObjectGetInteger(0, CANDLE_TIMER_NAME, OBJPROP_XDISTANCE);
        int ty = (int)ObjectGetInteger(0, CANDLE_TIMER_NAME, OBJPROP_YDISTANCE);
        int tw = (int)ObjectGetInteger(0, CANDLE_TIMER_NAME, OBJPROP_XSIZE);
        int th = (int)ObjectGetInteger(0, CANDLE_TIMER_NAME, OBJPROP_YSIZE);
        if (tw <= 0) tw = 90;
        if (th <= 0) th = 25;

        bool over_clk = (cx >= tx - 10 && cx <= tx + tw + 10 && cy >= ty - 10 && cy <= ty + th + 10);
        if (over_clk)
        {
            uint now = GetTickCount();
            if (now - g_last_timer_click_time < 450)
            {
                if (TerminalInfoInteger(TERMINAL_KEYSTATE_SHIFT) < 0)
                {
                    g_timer_is_custom = false;
                    g_timer_custom_x = -1;
                    g_timer_custom_y = -1;
                    g_timer_selected = false;
                    g_timer_dragging = false;
                    Alert("[Gerenciamento Master] Relogio de candles redefinido para a posicao padrao.");
                    UpdateCandleTimer();
                    ChartRedraw(0);
                    return;
                }

                g_timer_selected = !g_timer_selected;
                ObjectSetInteger(0, CANDLE_TIMER_NAME, OBJPROP_SELECTED, g_timer_selected);
                if (g_timer_selected)
                {
                    g_timer_custom_x = tx;
                    g_timer_custom_y = ty;
                    g_timer_is_custom = true;
                    g_timer_dragging = true;
                    g_timer_drag_offset_x = cx - tx;
                    g_timer_drag_offset_y = cy - ty;
                    PlaySound("tick.wav");
                }
                else
                {
                    g_timer_dragging = false;
                }
                UpdateCandleTimer();
                ChartRedraw(0);
            }
            g_last_timer_click_time = now;
            return;
        }
        else
        {
            if (g_timer_selected)
            {
                g_timer_selected = false;
                g_timer_dragging = false;
                ObjectSetInteger(0, CANDLE_TIMER_NAME, OBJPROP_SELECTED, false);
                UpdateCandleTimer();
                ChartRedraw(0);
            }
        }
    }

    // 5. Cliques em Botoes
    if (id == CHARTEVENT_OBJECT_CLICK)
    {
        // Clique em Seta / Marcacao de Barra Forte ou Pivo -> Ajusta o Stop da operacao para o nivel sugerido
        if (StringFind(sparam, SIG_PREFIX) == 0)
        {
            double target_sl = ObjectGetDouble(0, sparam, OBJPROP_PRICE);
            if (target_sl > 0.0)
            {
                AdjustAllTradeStops(target_sl);
            }
            return;
        }

        // Duplo clique direto no objeto do Relogio de Candles
        if (sparam == CANDLE_TIMER_NAME)
        {
            uint now = GetTickCount();
            if (now - g_last_timer_click_time < 450)
            {
                if (TerminalInfoInteger(TERMINAL_KEYSTATE_SHIFT) < 0)
                {
                    g_timer_is_custom = false;
                    g_timer_custom_x = -1;
                    g_timer_custom_y = -1;
                    g_timer_selected = false;
                    g_timer_dragging = false;
                    Alert("[Gerenciamento Master] Relogio de candles redefinido para a posicao padrao.");
                    UpdateCandleTimer();
                    ChartRedraw(0);
                    return;
                }

                g_timer_selected = !g_timer_selected;
                ObjectSetInteger(0, CANDLE_TIMER_NAME, OBJPROP_SELECTED, g_timer_selected);
                if (g_timer_selected)
                {
                    int cur_x = (int)ObjectGetInteger(0, CANDLE_TIMER_NAME, OBJPROP_XDISTANCE);
                    int cur_y = (int)ObjectGetInteger(0, CANDLE_TIMER_NAME, OBJPROP_YDISTANCE);
                    g_timer_custom_x = cur_x;
                    g_timer_custom_y = cur_y;
                    g_timer_is_custom = true;
                    g_timer_dragging = true;
                    g_timer_drag_offset_x = g_mouse_x - cur_x;
                    g_timer_drag_offset_y = g_mouse_y - cur_y;
                    PlaySound("tick.wav");
                }
                else
                {
                    g_timer_dragging = false;
                }
                UpdateCandleTimer();
                ChartRedraw(0);
            }
            g_last_timer_click_time = now;
            return;
        }


        // Minimizar / Maximizar
        if (sparam == PREFIX + "Btn_Min")
        {
            g_is_minimized = !g_is_minimized;
            if (g_is_minimized)
            {
                g_min_panel_x = 10;
                g_min_panel_y = 36;
            }
            CreatePanel();
            UpdatePanel();
            ChartRedraw(0);
            return;
        }

        // Engrenagem
        if (sparam == PREFIX + "Btn_Gear")
        {
            CommitPendingPanelEdits();
            g_settings_open = !g_settings_open;
            g_listening_action = 0;
            if (g_is_minimized) g_is_minimized = false;
            CreatePanel();
            UpdatePanel();
            ChartRedraw(0);
            return;
        }

        // Botoes dentro da Engrenagem
        if (g_settings_open)
        {
            if      (sparam == PREFIX + "Btn_SetKey_Entry") { g_listening_action = 1; CreatePanel(); ChartRedraw(0); }
            else if (sparam == PREFIX + "Btn_SetKey_Stop")  { g_listening_action = 2; CreatePanel(); ChartRedraw(0); }
            else if (sparam == PREFIX + "Btn_SetKey_Mode")  { g_listening_action = 3; CreatePanel(); ChartRedraw(0); }
            else if (sparam == PREFIX + "Btn_SetKey_Hide")  { g_listening_action = 4; CreatePanel(); ChartRedraw(0); }
            else if (sparam == PREFIX + "Btn_SetKey_Min")   { g_listening_action = 5; CreatePanel(); ChartRedraw(0); }
            else if (sparam == PREFIX + "Btn_SetKey_Exec")  { g_listening_action = 6; CreatePanel(); ChartRedraw(0); }
            else if (sparam == PREFIX + "Btn_SetKey_Partial") { g_listening_action = 7; CreatePanel(); ChartRedraw(0); }
            else if (sparam == PREFIX + "Btn_SetKey_Add")     { g_listening_action = 8; CreatePanel(); ChartRedraw(0); }
            else if (sparam == PREFIX + "Btn_ToggleCandleTimer")
            {
                g_candle_timer_enabled = !g_candle_timer_enabled;
                if (!g_candle_timer_enabled)
                    DeleteCandleTimer();
                else
                    UpdateCandleTimer();
                CreatePanel();
                ChartRedraw(0);
            }
            else if (sparam == PREFIX + "Btn_SaveDefault")
            {
                ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                SaveCurrentDefault();
            }
            else if (sparam == PREFIX + "Btn_SettingsBack")
            {
                g_settings_open = false;
                g_listening_action = 0;
                CreatePanel();
                Recalculate();
                ChartRedraw(0);
            }
            return;
        }

        // Botoes da Tela Principal
        if (sparam == PREFIX + "Btn_Execute")
        {
            ExecuteTrade();
        }
        else if (sparam == PREFIX + "Btn_ExecPartial")
        {
            ExecutePartialClose();
        }
        else if (sparam == PREFIX + "Edit_Partial")
        {
            g_is_editing_partial = true;
            return;
        }
        else if (sparam == PREFIX + "Btn_ExecAdd")
        {
            ExecutePositionAddition();
        }
        else if (sparam == PREFIX + "Edit_Add")
        {
            g_is_editing_add = true;
            return;
        }
        else if (sparam == PREFIX + "Btn_ModeMarket")
        {
            g_is_pending = false;
            UpdateMarketEntryPrice();
            DrawLines();
            Recalculate();
            ChartRedraw(0);
        }
        else if (sparam == PREFIX + "Btn_ModePending")
        {
            g_is_pending = true;
            DrawLines();
            Recalculate();
            ChartRedraw(0);
        }
        else if (sparam == PREFIX + "Edit_Risk")
        {
            if (IsRiskPasswordLocked())
            {
                ShowPasswordLockAlert("Risco da Operação");
                return;
            }
            g_is_editing_risk = true;
            return;
        }
        else if (sparam == PREFIX + "Btn_RiskModeCash")
        {
            if (IsRiskPasswordLocked())
            {
                ShowPasswordLockAlert("Modo de Risco ($/%)");
                return;
            }
            g_is_editing_risk = false; g_is_editing_partial = false; g_is_editing_add = false;
            g_risk_mode = RISK_FIXED_USD;
            BroadcastConfigToAllCharts();
            Recalculate();
            UpdatePanel();
            ChartRedraw(0);
        }
        else if (sparam == PREFIX + "Btn_RiskModePerc")
        {
            if (IsRiskPasswordLocked())
            {
                ShowPasswordLockAlert("Modo de Risco ($/%)");
                return;
            }
            g_is_editing_risk = false; g_is_editing_partial = false; g_is_editing_add = false;
            g_risk_mode = RISK_PERCENT;
            BroadcastConfigToAllCharts();
            Recalculate();
            UpdatePanel();
            ChartRedraw(0);
        }
        else if (sparam == PREFIX + "Btn_RiskMinus")
        {
            if (IsRiskPasswordLocked())
            {
                ShowPasswordLockAlert("Risco da Operação");
                return;
            }
            g_is_editing_risk = false; g_is_editing_partial = false; g_is_editing_add = false;
            if (g_risk_mode == RISK_PERCENT)
                g_risk_percent = NormalizeDouble(MathMax(0.01, g_risk_percent - InpRiskStepPercent), 2);
            else
                g_risk_cash = NormalizeDouble(MathMax(0.10, g_risk_cash - InpRiskStepCash), 2);
            BroadcastConfigToAllCharts();
            Recalculate();
            UpdatePanel();
            ChartRedraw(0);
        }
        else if (sparam == PREFIX + "Btn_RiskPlus")
        {
            if (IsRiskPasswordLocked())
            {
                ShowPasswordLockAlert("Risco da Operação");
                return;
            }
            g_is_editing_risk = false; g_is_editing_partial = false; g_is_editing_add = false;
            if (g_risk_mode == RISK_PERCENT)
                g_risk_percent = NormalizeDouble(MathMin(100.0, g_risk_percent + InpRiskStepPercent), 2);
            else
                g_risk_cash = NormalizeDouble(g_risk_cash + InpRiskStepCash, 2);
            BroadcastConfigToAllCharts();
            Recalculate();
            UpdatePanel();
            ChartRedraw(0);
        }
        else if (sparam == PREFIX + "Edit_MaxTrades")
        {
            if (IsRiskPasswordLocked())
            {
                ShowPasswordLockAlert("Máximo de Trades");
                return;
            }
            g_is_editing_max_trades = true;
            return;
        }
        else if (sparam == PREFIX + "Edit_MaxLoss")
        {
            if (IsRiskPasswordLocked())
            {
                ShowPasswordLockAlert("Loss Máximo ($)");
                return;
            }
            g_is_editing_max_loss = true;
            return;
        }
        else if (sparam == PREFIX + "Edit_Pwd")
        {
            g_is_editing_pwd = true;
            string cur_t = ObjectGetString(0, PREFIX + "Edit_Pwd", OBJPROP_TEXT);
            if (cur_t == "Nova senha" || cur_t == "Senha" || cur_t == "Nova (opcional)" || StringFind(cur_t, "•") >= 0)
            {
                ObjectSetString(0, PREFIX + "Edit_Pwd", OBJPROP_TEXT, "");
                ChartRedraw(0);
            }
            return;
        }
        else if (sparam == PREFIX + "Btn_PwdLock")
        {
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
            HandlePasswordAction();
            return;
        }
        else
        {
            g_is_editing_risk = false; g_is_editing_partial = false; g_is_editing_add = false;
            g_is_editing_max_trades = false; g_is_editing_max_loss = false; g_is_editing_pwd = false;
        }
    }

    // 5. Finalizacao da Edicao de Risco / Disciplina / Senha (Enter ou Clique fora)
    if (id == CHARTEVENT_OBJECT_ENDEDIT)
    {
        if (sparam == PREFIX + "Edit_Risk")
        {
            g_is_editing_risk = false; g_is_editing_partial = false; g_is_editing_add = false;
            if (IsRiskPasswordLocked())
            {
                UpdatePanel();
                ChartRedraw(0);
                ShowPasswordLockAlert("Risco da Operação");
                return;
            }
            string txt = ObjectGetString(0, PREFIX + "Edit_Risk", OBJPROP_TEXT);
            StringReplace(txt, ",", "."); // Permite tanto virgula (12,25) quanto ponto (12.25)

            // Extrai somente digitos numericos e ponto decimal
            string clean_txt = "";
            bool has_dot = false;
            for (int i = 0; i < StringLen(txt); i++)
            {
                ushort ch = StringGetCharacter(txt, i);
                if (ch >= '0' && ch <= '9')
                {
                    clean_txt += ShortToString(ch);
                }
                else if (ch == '.' && !has_dot)
                {
                    clean_txt += ".";
                    has_dot = true;
                }
            }

            double val = StringToDouble(clean_txt);
            if (val > 0.0)
            {
                if (g_risk_mode == RISK_FIXED_USD)
                    g_risk_cash = NormalizeDouble(val, 2);
                else
                    g_risk_percent = NormalizeDouble(val, 2);
                BroadcastConfigToAllCharts();
            }
            Recalculate();
            UpdatePanel();
            ChartRedraw(0);
        }
        else if (sparam == PREFIX + "Edit_Partial")
        {
            g_is_editing_partial = false;
            string txt = ObjectGetString(0, PREFIX + "Edit_Partial", OBJPROP_TEXT);
            StringReplace(txt, ",", ".");
            string clean_txt = "";
            bool has_dot = false;
            for (int i = 0; i < StringLen(txt); i++)
            {
                ushort ch = StringGetCharacter(txt, i);
                if (ch >= '0' && ch <= '9') clean_txt += ShortToString(ch);
                else if (ch == '.' && !has_dot) { clean_txt += "."; has_dot = true; }
            }
            double val = StringToDouble(clean_txt);
            if (val > 0.0 && val <= 100.0)
            {
                g_partial_percent = NormalizeDouble(val, 1);
                BroadcastConfigToAllCharts();
            }
            UpdatePanel();
            ChartRedraw(0);
        }
        else if (sparam == PREFIX + "Edit_Add")
        {
            g_is_editing_add = false;
            string txt = ObjectGetString(0, PREFIX + "Edit_Add", OBJPROP_TEXT);
            StringReplace(txt, ",", ".");
            string clean_txt = "";
            bool has_dot = false;
            for (int i = 0; i < StringLen(txt); i++)
            {
                ushort ch = StringGetCharacter(txt, i);
                if (ch >= '0' && ch <= '9') clean_txt += ShortToString(ch);
                else if (ch == '.' && !has_dot) { clean_txt += "."; has_dot = true; }
            }
            double val = StringToDouble(clean_txt);
            if (val > 0.0)
            {
                // TRAVA ESTREITA DE NO MAXIMO 50%
                g_add_percent = MathMin(50.0, MathMax(1.0, NormalizeDouble(val, 1)));
                BroadcastConfigToAllCharts();
            }
            UpdatePanel();
            ChartRedraw(0);
        }
        else if (sparam == PREFIX + "Edit_MaxTrades")
        {
            g_is_editing_max_trades = false;
            if (IsRiskPasswordLocked())
            {
                UpdatePanel();
                ChartRedraw(0);
                ShowPasswordLockAlert("Máximo de Trades");
                return;
            }
            string txt = ObjectGetString(0, PREFIX + "Edit_MaxTrades", OBJPROP_TEXT);
            string clean_txt = "";
            for (int i = 0; i < StringLen(txt); i++)
            {
                ushort ch = StringGetCharacter(txt, i);
                if (ch >= '0' && ch <= '9') clean_txt += ShortToString(ch);
            }
            if (clean_txt != "")
            {
                int val = (int)StringToInteger(clean_txt);
                g_max_trades_session = MathMax(0, MathMin(99, val));
                EvaluateSessionDiscipline(false);
                BroadcastConfigToAllCharts();
            }
            UpdatePanel();
            ChartRedraw(0);
        }
        else if (sparam == PREFIX + "Edit_MaxLoss")
        {
            g_is_editing_max_loss = false;
            if (IsRiskPasswordLocked())
            {
                UpdatePanel();
                ChartRedraw(0);
                ShowPasswordLockAlert("Loss Máximo ($)");
                return;
            }
            string txt = ObjectGetString(0, PREFIX + "Edit_MaxLoss", OBJPROP_TEXT);
            StringReplace(txt, ",", ".");
            string clean_txt = "";
            bool has_dot = false;
            for (int i = 0; i < StringLen(txt); i++)
            {
                ushort ch = StringGetCharacter(txt, i);
                if (ch >= '0' && ch <= '9') clean_txt += ShortToString(ch);
                else if (ch == '.' && !has_dot) { clean_txt += "."; has_dot = true; }
            }
            if (clean_txt != "")
            {
                double val = StringToDouble(clean_txt);
                g_max_loss_session = MathMax(0.0, NormalizeDouble(val, 2));
                EvaluateSessionDiscipline(true);
                BroadcastConfigToAllCharts();
            }
            UpdatePanel();
            ChartRedraw(0);
        }
        else if (sparam == PREFIX + "Edit_Pwd")
        {
            g_is_editing_pwd = false;
            string txt = ObjectGetString(0, PREFIX + "Edit_Pwd", OBJPROP_TEXT);
            StringTrimLeft(txt);
            StringTrimRight(txt);
            if (txt != "" && txt != "Nova senha" && txt != "Senha" && txt != "Nova (opcional)" && StringFind(txt, "•") < 0)
            {
                g_typed_pwd = txt;
                // Mascara o texto digitado com bolinhas ate clicar no botao ou ja executa
                ObjectSetString(0, PREFIX + "Edit_Pwd", OBJPROP_TEXT, "••••••");
                ChartRedraw(0);
            }
        }
        return;
    }
}

//+------------------------------------------------------------------+
//| Desenha as Linhas de Entrada e Stop Loss no Grafico              |
//+------------------------------------------------------------------+
void DrawLines()
{
    if (g_lines_hidden)
    {
        ObjectDelete(0, LINE_ENTRY);
        ObjectDelete(0, LINE_STOP);
        ObjectDelete(0, FIBO_NAME);
        return;
    }

    bool in_trade = HasActiveTradeOnSymbol();

    if (g_has_entry && g_entry_price > 0)
    {
        if (ObjectFind(0, LINE_ENTRY) < 0)
        {
            ObjectCreate(0, LINE_ENTRY, OBJ_HLINE, 0, 0, g_entry_price);
            ObjectSetInteger(0, LINE_ENTRY, OBJPROP_COLOR, InpColorEntry);
            ObjectSetInteger(0, LINE_ENTRY, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, LINE_ENTRY, OBJPROP_WIDTH, 2);
            ObjectSetInteger(0, LINE_ENTRY, OBJPROP_SELECTABLE, g_is_pending);
            ObjectSetInteger(0, LINE_ENTRY, OBJPROP_SELECTED, false);
        }
        else
        {
            ObjectSetDouble(0, LINE_ENTRY, OBJPROP_PRICE, g_entry_price);
            ObjectSetInteger(0, LINE_ENTRY, OBJPROP_SELECTABLE, g_is_pending);
        }

        // As linhas ficam SEMPRE em segundo plano (por baixo do painel)
        ObjectSetInteger(0, LINE_ENTRY, OBJPROP_BACK, true);
        ObjectSetInteger(0, LINE_ENTRY, OBJPROP_ZORDER, 0);

        string entry_label = in_trade ? 
            (g_is_pending ? 
                StringFormat("  ADIÇÃO PENDENTE: %.*f", _Digits, g_entry_price) : 
                StringFormat("  ADIÇÃO MERCADO: %.*f", _Digits, g_entry_price)) :
            (g_is_pending ? 
                StringFormat("  ENTRADA PENDENTE: %.*f", _Digits, g_entry_price) : 
                StringFormat("  ENTRADA MERCADO: %.*f", _Digits, g_entry_price));
        ObjectSetString(0, LINE_ENTRY, OBJPROP_TEXT, entry_label);
    }

    // Se houver trade em andamento, oculta o stop virtual do EA (o MT5 exibe os stops nativos do terminal)
    if (in_trade)
    {
        ObjectDelete(0, LINE_STOP);
    }
    else if (g_has_stop && g_stop_price > 0)
    {
        if (ObjectFind(0, LINE_STOP) < 0)
        {
            ObjectCreate(0, LINE_STOP, OBJ_HLINE, 0, 0, g_stop_price);
            ObjectSetInteger(0, LINE_STOP, OBJPROP_COLOR, InpColorStop);
            ObjectSetInteger(0, LINE_STOP, OBJPROP_STYLE, STYLE_DASH);
            ObjectSetInteger(0, LINE_STOP, OBJPROP_WIDTH, 2);
            ObjectSetInteger(0, LINE_STOP, OBJPROP_SELECTABLE, true);
            ObjectSetInteger(0, LINE_STOP, OBJPROP_SELECTED, false);
        }
        else
        {
            ObjectSetDouble(0, LINE_STOP, OBJPROP_PRICE, g_stop_price);
        }

        // As linhas ficam SEMPRE em segundo plano (por baixo do painel)
        ObjectSetInteger(0, LINE_STOP, OBJPROP_BACK, true);
        ObjectSetInteger(0, LINE_STOP, OBJPROP_ZORDER, 0);

        string sl_label = StringFormat("  STOP LOSS: %.*f (Perda: $%.2f)", 
                                       _Digits, g_stop_price, g_actual_loss_at_sl);
        ObjectSetString(0, LINE_STOP, OBJPROP_TEXT, sl_label);
    }
    else
    {
        ObjectDelete(0, LINE_STOP);
    }
}

//+------------------------------------------------------------------+
//| Criacao de Retangulo Auxiliar com Escala                         |
//+------------------------------------------------------------------+
void CreateRect(string name, int x, int y, int w, int h, color bg_col, color border_col)
{
    if (ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, Scale(x));
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, Scale(y));
    ObjectSetInteger(0, name, OBJPROP_XSIZE, Scale(w));
    ObjectSetInteger(0, name, OBJPROP_YSIZE, Scale(h));
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg_col);
    ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, name, OBJPROP_COLOR, border_col);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    ObjectSetInteger(0, name, OBJPROP_ZORDER, 50);
}

//+------------------------------------------------------------------+
//| Criacao de Label Auxiliar com Escala                             |
//+------------------------------------------------------------------+
void CreateLabel(string name, int x, int y, string text, color col, int font_size = 9, bool bold = false)
{
    if (ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, Scale(x));
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, Scale(y));
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_COLOR, col);
    ObjectSetString(0, name, OBJPROP_FONT, bold ? "Segoe UI Semibold" : "Segoe UI");
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, MathMax(1, (int)MathRound(font_size * g_ui_scale)));
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    ObjectSetInteger(0, name, OBJPROP_ZORDER, 60);
}

//+------------------------------------------------------------------+
//| Criacao de Botao Auxiliar com Escala                             |
//+------------------------------------------------------------------+
void CreateButton(string name, int x, int y, int w, int h, string text, color bg_col, color text_col, int font_size = 9, bool bold = false)
{
    if (ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, Scale(x));
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, Scale(y));
    ObjectSetInteger(0, name, OBJPROP_XSIZE, Scale(w));
    ObjectSetInteger(0, name, OBJPROP_YSIZE, Scale(h));
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg_col);
    ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, CLR_BORDER);
    ObjectSetInteger(0, name, OBJPROP_COLOR, text_col);
    ObjectSetString(0, name, OBJPROP_FONT, bold ? "Segoe UI Semibold" : "Segoe UI");
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, MathMax(1, (int)MathRound(font_size * g_ui_scale)));
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    ObjectSetInteger(0, name, OBJPROP_ZORDER, 60);
}

//+------------------------------------------------------------------+
//| Criacao de Campo Editavel (Input) Auxiliar com Escala            |
//+------------------------------------------------------------------+
void CreateEdit(string name, int x, int y, int w, int h, string text, color bg_col, color text_col, color border_col, int font_size = 10, bool bold = true)
{
    if (ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_EDIT, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, Scale(x));
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, Scale(y));
    ObjectSetInteger(0, name, OBJPROP_XSIZE, Scale(w));
    ObjectSetInteger(0, name, OBJPROP_YSIZE, Scale(h));
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg_col);
    ObjectSetInteger(0, name, OBJPROP_COLOR, text_col);
    ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, border_col);
    ObjectSetString(0, name, OBJPROP_FONT, bold ? "Segoe UI Semibold" : "Segoe UI");
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, MathMax(1, (int)MathRound(font_size * g_ui_scale)));
    ObjectSetInteger(0, name, OBJPROP_ALIGN, ALIGN_CENTER);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_READONLY, false);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    ObjectSetInteger(0, name, OBJPROP_ZORDER, 60);
}

//+------------------------------------------------------------------+
//| Atualizacao Direta de Posicao e Tamanho (Sem Deletar / Sem Piscar)|
//+------------------------------------------------------------------+
void SetObjPos(string name, int x, int y)
{
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, Scale(x));
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, Scale(y));
}

void SetObjSize(string name, int w, int h)
{
    ObjectSetInteger(0, name, OBJPROP_XSIZE, Scale(w));
    ObjectSetInteger(0, name, OBJPROP_YSIZE, Scale(h));
}

void SetObjRect(string name, int x, int y, int w, int h)
{
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, Scale(x));
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, Scale(y));
    ObjectSetInteger(0, name, OBJPROP_XSIZE, Scale(w));
    ObjectSetInteger(0, name, OBJPROP_YSIZE, Scale(h));
}


// The shortcut screen retains enough height for all eight rows.
int PanelBaseHeight()
{
    if (g_is_minimized) return PANEL_MINIMIZED_H;
    return g_settings_open ? PANEL_SETTINGS_H : g_panel_h;
}

// Independent preferred sizes; automatic fitting does not overwrite them.
void ApplyPanelScale()
{
    int base_w = g_is_minimized ? PANEL_MINIMIZED_W : g_panel_w;
    int base_h = PanelBaseHeight();
    double size = g_is_minimized ? g_minimized_scale : g_open_scale;
    int chart_w = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0);
    int chart_h = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);
    if (InpAutoFitPanel && chart_w > 20 && chart_h > 20)
    {
        double fit_w = (chart_w - 12.0) / (g_system_dpi_scale * base_w);
        double fit_h = (chart_h - 12.0) / (g_system_dpi_scale * base_h);
        size = MathMin(size, MathMin(fit_w, fit_h));
    }
    g_ui_scale = MathMax(0.10, size);
    g_dpi_scale = g_system_dpi_scale * g_ui_scale;

    int cur_x = g_is_minimized ? g_min_panel_x : g_panel_x;
    int cur_y = g_is_minimized ? g_min_panel_y : g_panel_y;
    int pixel_x = Scale(cur_x), pixel_y = Scale(cur_y);
    if (chart_w > 20) pixel_x = MathMax(4, MathMin(pixel_x, chart_w - Scale(base_w) - 4));
    if (chart_h > 20) pixel_y = MathMax(4, MathMin(pixel_y, chart_h - Scale(base_h) - 4));
    if (g_is_minimized)
    {
        g_min_panel_x = (int)MathRound(pixel_x / g_dpi_scale);
        g_min_panel_y = (int)MathRound(pixel_y / g_dpi_scale);
    }
    else
    {
        g_panel_x = (int)MathRound(pixel_x / g_dpi_scale);
        g_panel_y = (int)MathRound(pixel_y / g_dpi_scale);
    }
}

// One shared layout keeps creation, dragging and resizing in sync.
void PanelRect(bool create, string id, int x, int y, int w, int h, color bg, color border)
{
    if (create) CreateRect(PREFIX + id, x, y, w, h, bg, border);
    else SetObjRect(PREFIX + id, x, y, w, h);
}

void PanelLabel(bool create, string id, int x, int y, string text, color col, int size = 12, bool bold = false)
{
    if (create) CreateLabel(PREFIX + id, x, y, text, col, size, bold);
    else SetObjPos(PREFIX + id, x, y);
    ObjectSetInteger(0, PREFIX + id, OBJPROP_FONTSIZE, MathMax(1, (int)MathRound(size * g_ui_scale)));
}

void PanelButton(bool create, string id, int x, int y, int w, int h, string text, color bg, color col, int size = 13)
{
    if (create) CreateButton(PREFIX + id, x, y, w, h, text, bg, col, size, true);
    else SetObjRect(PREFIX + id, x, y, w, h);
    ObjectSetInteger(0, PREFIX + id, OBJPROP_FONTSIZE, MathMax(1, (int)MathRound(size * g_ui_scale)));
}

void PanelEdit(bool create, string id, int x, int y, int w, int h, string text, int size = 16)
{
    if (create) CreateEdit(PREFIX + id, x, y, w, h, text, CLR_BG, CLR_TXT_HEADER, CLR_BORDER, size, true);
    else SetObjRect(PREFIX + id, x, y, w, h);
    ObjectSetInteger(0, PREFIX + id, OBJPROP_FONTSIZE, MathMax(1, (int)MathRound(size * g_ui_scale)));
}

string DisplayNumber(double value, int digits = 2)
{
    string text = DoubleToString(value, digits);
    StringReplace(text, ".", ",");
    return text;
}

// Uses the risk already calculated for the rounded lot, not the requested cash limit.
string LotRiskSummary()
{
    bool valid = g_has_stop && g_can_trade && g_calculated_lot > 0 &&
                 MathIsValidNumber(g_actual_loss_at_sl) && g_actual_loss_at_sl >= 0;
    string volume = DisplayNumber(valid ? g_calculated_lot : 0.0) + " lotes";
    if (!valid) return volume + " (risco --)";

    if (InpEnableOrderSplitting && g_calculated_lot > 0.0)
    {
        double eff_max = GetEffectiveMaxVolumePerOrder(_Symbol);
        int chunks_cnt = GetChunkCount(g_calculated_lot, eff_max);
        if (chunks_cnt > 1)
        {
            volume += StringFormat(" [%d ords]", chunks_cnt);
        }
    }

    string currency = AccountInfoString(ACCOUNT_CURRENCY);
    string unit = (currency == "USD" || currency == "") ? "$" : currency + " ";
    return volume + " (" + unit + DisplayNumber(g_actual_loss_at_sl) + ")";
}

void SetSummaryText(string id, string text, int available_width, int base_size)
{
    string name = PREFIX + id;
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetString(0, name, OBJPROP_TOOLTIP, text + " | Risco calculado da entrada até o stop");
    int font_size = MathMax(1, (int)MathRound(base_size * g_ui_scale));
    uint width = 0, height = 0;
    while (font_size > 1)
    {
        if (!TextSetFont("Segoe UI Semibold", -10 * font_size)) break;
        if (!TextGetSize(text, width, height) || (int)width <= Scale(available_width)) break;
        font_size--;
    }
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_size);
}

void LayoutPanel(bool create)
{
    int x = g_is_minimized ? g_min_panel_x : g_panel_x;
    int y = g_is_minimized ? g_min_panel_y : g_panel_y;
    int w = g_is_minimized ? PANEL_MINIMIZED_W : g_panel_w;
    int h = PanelBaseHeight();
    int left = x + 18, inner = w - 36;
    PanelRect(create, "Bg", x, y, w, h, CLR_BG, CLR_BORDER);
    PanelRect(create, "TopBar", x, y, w, 3, CLR_PRIMARY, CLR_PRIMARY);
    if (g_is_minimized)
    {
        PanelLabel(create, "HeaderTitle", x + 10, y + 9, "GM | 0,00 lotes (risco --)", CLR_TXT_HEADER, 11, true);
        PanelButton(create, "Btn_Min", x + w - 68, y + 5, 26, 26, "+", CLR_BTN_DEF_BG, CLR_TXT_HEADER, 12);
        PanelButton(create, "Btn_Gear", x + w - 36, y + 5, 26, 26, "⚙", CLR_BTN_DEF_BG, CLR_TXT_HEADER, 11);
        PanelRect(create, "CornerGrip", x + w - 8, y + h - 5, 8, 5, CLR_TXT_MUTED, CLR_TXT_MUTED);
        if (create)
        {
            ObjectSetString(0, PREFIX + "Btn_Min", OBJPROP_TOOLTIP, "Ampliar [" + g_key_min_str + "]");
            ObjectSetString(0, PREFIX + "Btn_Gear", OBJPROP_TOOLTIP, "Configurar atalhos");
            ObjectSetString(0, PREFIX + "CornerGrip", OBJPROP_TOOLTIP, "Arraste para diminuir ou aumentar a barra");
        }
        return;
    }
    string title = g_settings_open ? "Configurar atalhos" : "Gerenciamento Master";
    PanelLabel(create, "HeaderTitle", left, y + 17, title, CLR_TXT_HEADER, 15, true);
    PanelButton(create, "Btn_Min", x + w - 104, y + 8, 40, 40, "−", CLR_BTN_DEF_BG, CLR_TXT_HEADER, 17);
    PanelButton(create, "Btn_Gear", x + w - 56, y + 8, 40, 40, g_settings_open ? "←" : "⚙", CLR_BTN_DEF_BG, CLR_TXT_HEADER, 17);
    if (create)
    {
        ObjectSetString(0, PREFIX + "Btn_Min", OBJPROP_TOOLTIP, "Minimizar [" + g_key_min_str + "]");
        ObjectSetString(0, PREFIX + "Btn_Gear", OBJPROP_TOOLTIP, g_settings_open ? "Voltar ao painel" : "Configurar atalhos do teclado");
    }

    if (g_settings_open)
    {
        PanelLabel(create, "Lbl_SetDesc", left, y + 76, "Clique na tecla que deseja alterar.", CLR_TXT_BODY, 12);
        PanelLabel(create, "Lbl_SetDesc2", left, y + 100, "Depois, pressione a nova tecla no teclado.", CLR_TXT_MUTED, 11);
        string ids[] = {"Entry", "Stop", "Mode", "Hide", "Min", "Exec", "Partial", "Add"};
        string labels[] = {"Marcar entrada", "Marcar stop", "Mercado / pendente", "Ocultar linhas", "Minimizar painel", "Executar ordem", "Realizar parcial", "Adicionar à posição"};
        string keys[8];
        keys[0] = g_key_entry_str; keys[1] = g_key_stop_str;
        keys[2] = g_key_mode_str; keys[3] = g_key_hide_str;
        keys[4] = g_key_min_str; keys[5] = g_key_exec_str;
        keys[6] = g_key_partial_str; keys[7] = g_key_add_str;
        for (int i = 0; i < 8; i++)
        {
            int sy = y + 130 + i * 48;
            bool listening = (g_listening_action == i + 1);
            PanelLabel(create, "Lbl_SK_" + ids[i], left, sy + 11, labels[i], CLR_TXT_BODY, 12);
            PanelButton(create, "Btn_SetKey_" + ids[i], left + 222, sy, inner - 222, 40,
                        listening ? "Pressione..." : "[" + keys[i] + "]",
                        listening ? CLR_HIGHLIGHT : CLR_BTN_DEF_BG, CLR_TXT_HEADER, 13);
        }
        int sy_ct = y + 130 + 8 * 48 + 6;
        PanelRect(create, "DivSet", left, sy_ct - 4, inner, 1, CLR_BORDER, CLR_BORDER);
        PanelLabel(create, "Lbl_SK_CandleTimer", left, sy_ct + 11, "Relógio de Candles", CLR_TXT_BODY, 12);
        PanelButton(create, "Btn_ToggleCandleTimer", left + 222, sy_ct, inner - 222, 40,
                    g_candle_timer_enabled ? "ATIVADO" : "DESATIVADO",
                    g_candle_timer_enabled ? CLR_BUY_BG : CLR_BTN_DEF_BG,
                    g_candle_timer_enabled ? CLR_BUY : CLR_TXT_MUTED, 13);
        if (create)
            ObjectSetString(0, PREFIX + "Btn_ToggleCandleTimer", OBJPROP_TOOLTIP, "Clique para ligar ou desligar o Relógio de Candles no gráfico");

        PanelButton(create, "Btn_SaveDefault", left, sy_ct + 54, inner, 42, "Salvar Default", CLR_PRIMARY, clrWhite, 13);
        PanelButton(create, "Btn_SettingsBack", left, sy_ct + 104, inner, 42, "Concluir e voltar", CLR_BTN_DEF_BG, CLR_TXT_HEADER, 13);
        if (create)
        {
            ObjectSetString(0, PREFIX + "Btn_SaveDefault", OBJPROP_TOOLTIP, "Salva as configurações atuais como padrão para novos gráficos");
            ObjectSetString(0, PREFIX + "Btn_SettingsBack", OBJPROP_TOOLTIP, "Voltar ao painel principal");
        }
        PanelLabel(create, "Lbl_Brand", left, y + h - 26, "@giovannipaganinitrading", CLR_TXT_MUTED, 10);
    }
    else
    {
        int half = (inner - 8) / 2;
        PanelButton(create, "Btn_ModeMarket", left, y + 60, half, 40, "Mercado", CLR_BTN_ACTIVE, clrWhite);
        PanelButton(create, "Btn_ModePending", left + half + 8, y + 60, inner - half - 8, 40, "Pendente", CLR_BTN_DEF_BG, CLR_TXT_BODY);
        PanelButton(create, "Btn_RiskModeCash", left, y + 112, half, 40, "Valor em US$", CLR_BTN_ACTIVE, clrWhite);
        PanelButton(create, "Btn_RiskModePerc", left + half + 8, y + 112, inner - half - 8, 40, "% do saldo", CLR_BTN_DEF_BG, CLR_TXT_BODY);
        PanelButton(create, "Btn_RiskMinus", left, y + 162, 48, 48, "−", CLR_BTN_DEF_BG, CLR_TXT_HEADER, 20);
        PanelEdit(create, "Edit_Risk", left + 58, y + 162, inner - 116, 48, DisplayNumber(g_risk_mode == RISK_FIXED_USD ? g_risk_cash : g_risk_percent), 20);
        PanelButton(create, "Btn_RiskPlus", left + inner - 48, y + 162, 48, 48, "+", CLR_BTN_DEF_BG, CLR_TXT_HEADER, 20);
        PanelRect(create, "Div1", left, y + 222, inner, 1, CLR_BORDER, CLR_BORDER);

        PanelRect(create, "DirBadgeBg", left, y + 234, inner, 36, CLR_HIGHLIGHT, CLR_PARTIAL);
        PanelLabel(create, "Lbl_Direction", left + 12, y + 241, "Aguardando definição do stop", CLR_PARTIAL, 12, true);

        PanelRect(create, "LotCardBg", left, y + 282, inner, 54, CLR_BG_CARD, CLR_BORDER);
        PanelLabel(create, "Lbl_LotCardTag", left + 12, y + 286, "Volume e risco no stop", CLR_TXT_BODY, 10);
        PanelLabel(create, "Lbl_LotVal", left + 12, y + 305, "0,00 lotes (risco --)", CLR_PRIMARY, 16, true);
        if (create) ObjectSetInteger(0, PREFIX + "Lbl_LotVal", OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
        PanelButton(create, "Btn_Execute", left, y + 348, inner, 44, "Aguardando stop", CLR_BTN_DEF_BG, CLR_TXT_MUTED, 13);
        PanelRect(create, "Div2", left, y + 404, inner, 1, CLR_BORDER, CLR_BORDER);

        PanelEdit(create, "Edit_Partial", left, y + 416, 88, 44, DisplayNumber(g_partial_percent, 1) + "%", 16);
        PanelButton(create, "Btn_ExecPartial", left + 98, y + 416, inner - 98, 44, "Realizar parcial", C'255,247,237', CLR_PARTIAL, 13);
        PanelEdit(create, "Edit_Add", left, y + 468, 88, 44, DisplayNumber(g_add_percent, 1) + "%", 16);
        PanelButton(create, "Btn_ExecAdd", left + 98, y + 468, inner - 98, 44, "Adicionar à posição", C'239,246,255', CLR_ADD, 13);

        // Secao de Disciplina Pessoal: Max Trades & Loss Maximo Diario ($ USD)
        PanelRect(create, "Div3", left, y + 522, inner, 1, CLR_BORDER, CLR_BORDER);
        PanelLabel(create, "Lbl_MaxTrades", left, y + 541, "Máx Trades:", CLR_TXT_BODY, 11, true);
        PanelEdit(create, "Edit_MaxTrades", left + 98, y + 532, 76, 38, IntegerToString(g_max_trades_session), 14);
        PanelLabel(create, "Lbl_MaxLoss", left + 188, y + 541, "Loss Máx ($):", CLR_TXT_BODY, 11, true);
        PanelEdit(create, "Edit_MaxLoss", left + 298, y + 532, inner - 298, 38, DisplayNumber(g_max_loss_session, 2), 14);

        PanelRect(create, "DiscBadgeBg", left, y + 578, inner, 34, CLR_BG_CARD, CLR_BORDER);
        PanelLabel(create, "Lbl_DiscStatus", left + 10, y + 585, "Turno Dia: 0/1 trade | Resultado: $0,00", CLR_TXT_BODY, 11, true);

        // Linha de Senha do Risco / Limites (Persiste mesmo tirando e colocando o EA)
        PanelLabel(create, "Lbl_Pwd", left, y + 629, "Senha:", CLR_TXT_BODY, 11, true);
        PanelEdit(create, "Edit_Pwd", left + 62, y + 620, 148, 36, (g_pwd_hash == "") ? "Nova senha" : "Senha", 12);
        PanelButton(create, "Btn_PwdLock", left + 218, y + 620, inner - 218, 36,
                    (g_pwd_hash == "") ? "🔒 Cadastrar Senha" : (g_risk_pwd_locked ? "🔑 Destravar Risco" : "🔒 Salvar e Travar"),
                    CLR_BTN_ACTIVE, clrWhite, 11);

        PanelLabel(create, "Lbl_Brand", left, y + h - 26, "@giovannipaganinitrading", CLR_TXT_MUTED, 10);
        if (create)
        {
            ObjectSetInteger(0, PREFIX + "Btn_ExecPartial", OBJPROP_BORDER_COLOR, CLR_PARTIAL);
            ObjectSetInteger(0, PREFIX + "Btn_ExecAdd", OBJPROP_BORDER_COLOR, CLR_ADD);
            ObjectSetString(0, PREFIX + "Edit_Risk", OBJPROP_TOOLTIP, "Digite o risco desejado e pressione Enter.");
            ObjectSetString(0, PREFIX + "Edit_Partial", OBJPROP_TOOLTIP, "Percentual da parcial. Confirme com Enter.");
            ObjectSetString(0, PREFIX + "Edit_Add", OBJPROP_TOOLTIP, "Percentual de adição, limitado a 50%. Confirme com Enter.");
            ObjectSetString(0, PREFIX + "Edit_MaxTrades", OBJPROP_TOOLTIP, "Máximo de trades permitidos no turno (0 = sem limite). Confirme com Enter.");
            ObjectSetString(0, PREFIX + "Edit_MaxLoss", OBJPROP_TOOLTIP, "Loss máximo em $ USD no turno (0 = sem limite). Se atingir, zera e trava o turno!");
            ObjectSetString(0, PREFIX + "Edit_Pwd", OBJPROP_TOOLTIP, "Digite a senha para cadastrar (1ª vez) ou para destravar a edição de Risco e Limites.");
            ObjectSetString(0, PREFIX + "Btn_PwdLock", OBJPROP_TOOLTIP, "Clique para cadastrar a senha, destravar a edição ou salvar e travar novamente.");
            ObjectSetString(0, PREFIX + "Btn_ModeMarket", OBJPROP_TOOLTIP, "Alternar modo [" + g_key_mode_str + "]");
            ObjectSetString(0, PREFIX + "Btn_ModePending", OBJPROP_TOOLTIP, "Alternar modo [" + g_key_mode_str + "]");
        }
    }
    PanelRect(create, "CornerGrip", x + w - 16, y + h - 16, 16, 16, CLR_BTN_DEF_BG, CLR_BORDER);
    if (create) ObjectSetString(0, PREFIX + "CornerGrip", OBJPROP_TOOLTIP, "Arraste para diminuir ou aumentar todo o painel");
    PanelLabel(create, "CornerIcon", x + w - 14, y + h - 18, "◢", CLR_TXT_MUTED, 9, true);
    PanelRect(create, "EdgeRight", x + w - 3, y + PANEL_HEADER_H, 3, h - PANEL_HEADER_H - 16, CLR_BORDER, CLR_BORDER);
    PanelRect(create, "EdgeBottom", left, y + h - 3, inner, 3, CLR_BORDER, CLR_BORDER);
}

void RepositionPanel()
{
    ApplyPanelScale();
    LayoutPanel(false);
    UpdatePanel();
}

void CreatePanel()
{
    ApplyPanelScale();
    CleanupPanelObjects();
    LayoutPanel(true);
    UpdatePanel();
}

void UpdatePanel()
{
    bool is_locked = (g_session_loss_locked || g_session_trades_locked);
    color top_bar_col = g_session_loss_locked ? CLR_SELL : (g_session_trades_locked ? CLR_PARTIAL : CLR_PRIMARY);
    ObjectSetInteger(0, PREFIX + "TopBar", OBJPROP_BGCOLOR, top_bar_col);
    ObjectSetInteger(0, PREFIX + "TopBar", OBJPROP_COLOR, top_bar_col);

    if (g_is_minimized)
    {
        string title = "GM";
        if (g_candle_timer_enabled)
        {
            string t_str = GetCandleTimerString();
            if (t_str != "") title += " [" + t_str + "]";
        }
        if (g_session_loss_locked)
        {
            title += " | ⛔ TRAVADO LOSS ($" + DisplayNumber(MathAbs(g_cur_session_pnl)) + ")";
            ObjectSetInteger(0, PREFIX + "HeaderTitle", OBJPROP_COLOR, CLR_SELL);
        }
        else if (g_session_trades_locked)
        {
            title += StringFormat(" | 🔒 %d/%d TRADE FEITO", g_cur_session_trades, g_max_trades_session);
            ObjectSetInteger(0, PREFIX + "HeaderTitle", OBJPROP_COLOR, CLR_PARTIAL);
        }
        else
        {
            title += " | " + LotRiskSummary();
            ObjectSetInteger(0, PREFIX + "HeaderTitle", OBJPROP_COLOR, CLR_TXT_HEADER);
        }
        SetSummaryText("HeaderTitle", title, PANEL_MINIMIZED_W - 86, 11);
        return;
    }
    if (g_settings_open) return;

    ObjectSetInteger(0, PREFIX + "Btn_ModeMarket", OBJPROP_BGCOLOR, g_is_pending ? CLR_BTN_DEF_BG : CLR_BTN_ACTIVE);
    ObjectSetInteger(0, PREFIX + "Btn_ModeMarket", OBJPROP_COLOR, g_is_pending ? CLR_TXT_BODY : clrWhite);
    ObjectSetInteger(0, PREFIX + "Btn_ModePending", OBJPROP_BGCOLOR, g_is_pending ? CLR_BTN_ACTIVE : CLR_BTN_DEF_BG);
    ObjectSetInteger(0, PREFIX + "Btn_ModePending", OBJPROP_COLOR, g_is_pending ? clrWhite : CLR_TXT_BODY);

    bool cash = (g_risk_mode == RISK_FIXED_USD);
    bool pwd_locked = IsRiskPasswordLocked();

    ObjectSetInteger(0, PREFIX + "Btn_RiskModeCash", OBJPROP_BGCOLOR, cash ? CLR_BTN_ACTIVE : CLR_BTN_DEF_BG);
    ObjectSetInteger(0, PREFIX + "Btn_RiskModeCash", OBJPROP_COLOR, cash ? clrWhite : CLR_TXT_BODY);
    ObjectSetInteger(0, PREFIX + "Btn_RiskModePerc", OBJPROP_BGCOLOR, cash ? CLR_BTN_DEF_BG : CLR_BTN_ACTIVE);
    ObjectSetInteger(0, PREFIX + "Btn_RiskModePerc", OBJPROP_COLOR, cash ? CLR_TXT_BODY : clrWhite);
    ObjectSetInteger(0, PREFIX + "Btn_RiskMinus", OBJPROP_COLOR, pwd_locked ? CLR_TXT_MUTED : CLR_TXT_HEADER);
    ObjectSetInteger(0, PREFIX + "Btn_RiskPlus", OBJPROP_COLOR, pwd_locked ? CLR_TXT_MUTED : CLR_TXT_HEADER);

    ObjectSetInteger(0, PREFIX + "Edit_Risk", OBJPROP_READONLY, pwd_locked);
    ObjectSetInteger(0, PREFIX + "Edit_Risk", OBJPROP_BGCOLOR, pwd_locked ? CLR_BG_CARD : CLR_BG);
    if (!g_is_editing_risk)
    {
        string risk_str = DisplayNumber(cash ? g_risk_cash : g_risk_percent);
        ObjectSetString(0, PREFIX + "Edit_Risk", OBJPROP_TEXT, pwd_locked ? ("🔒 " + risk_str) : risk_str);
    }

    string status = "Aguardando definição do stop";
    color status_color = CLR_PARTIAL, status_bg = CLR_HIGHLIGHT;
    if (g_session_loss_locked)
    {
        status = StringFormat("⛔ LOSS MÁX ATINGIDO (-$%s)", DisplayNumber(MathAbs(g_cur_session_pnl)));
        status_color = CLR_SELL;
        status_bg = CLR_SELL_BG;
    }
    else if (g_session_trades_locked)
    {
        status = StringFormat("🔒 LIMITE %d/%d TRADE ATINGIDO", g_cur_session_trades, g_max_trades_session);
        status_color = CLR_PARTIAL;
        status_bg = CLR_HIGHLIGHT;
    }
    else if (g_has_stop)
    {
        status = g_direction_str;
        status_color = g_direction_color;
        status_bg = (g_direction_color == CLR_BUY) ? CLR_BUY_BG : CLR_SELL_BG;
        if (!g_can_trade) { status = g_trade_error_msg; status_color = CLR_SELL; status_bg = CLR_SELL_BG; }
    }
    ObjectSetString(0, PREFIX + "Lbl_Direction", OBJPROP_TEXT, status);
    ObjectSetString(0, PREFIX + "Lbl_Direction", OBJPROP_TOOLTIP, status);
    ObjectSetInteger(0, PREFIX + "Lbl_Direction", OBJPROP_COLOR, status_color);
    ObjectSetInteger(0, PREFIX + "DirBadgeBg", OBJPROP_BGCOLOR, status_bg);
    ObjectSetInteger(0, PREFIX + "DirBadgeBg", OBJPROP_COLOR, status_color);
    SetSummaryText("Lbl_LotVal", LotRiskSummary(), g_panel_w - 60, 16);

    string execute_text = "Aguardando stop [" + g_key_stop_str + "]";
    color execute_bg = CLR_BTN_DEF_BG, execute_color = CLR_TXT_BODY;
    if (g_session_loss_locked)
    {
        execute_text = "⛔ Bloqueado: Loss Máximo no Turno";
        execute_bg = CLR_SELL_BG; execute_color = CLR_SELL;
    }
    else if (g_session_trades_locked)
    {
        execute_text = StringFormat("🔒 Bloqueado: %d/%d Trade Realizado", g_cur_session_trades, g_max_trades_session);
        execute_bg = CLR_HIGHLIGHT; execute_color = CLR_PARTIAL;
    }
    else if (g_has_stop && !g_can_trade)
    {
        execute_text = "Revise o stop e o risco";
        execute_bg = CLR_SELL_BG; execute_color = CLR_SELL;
    }
    else if (g_has_stop && g_can_trade)
    {
        double eff_max = GetEffectiveMaxVolumePerOrder(_Symbol);
        int chunks_cnt = GetChunkCount(g_calculated_lot, eff_max);
        if (InpEnableOrderSplitting && chunks_cnt > 1)
        {
            execute_text = (g_is_pending ? "Criar ordens pendentes" : "Abrir a mercado") +
                           StringFormat(" (%d ords) [", chunks_cnt) + g_key_exec_str + "]";
        }
        else
        {
            execute_text = (g_is_pending ? "Criar ordem pendente" : "Abrir a mercado") + " [" + g_key_exec_str + "]";
        }
        execute_bg = (g_direction_color == CLR_BUY) ? CLR_BUY : CLR_SELL;
        execute_color = clrWhite;
    }
    ObjectSetString(0, PREFIX + "Btn_Execute", OBJPROP_TEXT, execute_text);
    ObjectSetInteger(0, PREFIX + "Btn_Execute", OBJPROP_BGCOLOR, execute_bg);
    ObjectSetInteger(0, PREFIX + "Btn_Execute", OBJPROP_COLOR, execute_color);
    string exec_tooltip = g_trade_error_msg;
    if (is_locked)
        exec_tooltip = g_session_lock_reason;
    else if (g_can_trade)
    {
        double eff_max = GetEffectiveMaxVolumePerOrder(_Symbol);
        int chunks_cnt = GetChunkCount(g_calculated_lot, eff_max);
        if (InpEnableOrderSplitting && chunks_cnt > 1)
            exec_tooltip = StringFormat("Executar entrada dividida em %d ordens (Risco total: $%.2f) [%s]", chunks_cnt, g_actual_loss_at_sl, g_key_exec_str);
        else
            exec_tooltip = "Executar ordem [" + g_key_exec_str + "]";
    }
    ObjectSetString(0, PREFIX + "Btn_Execute", OBJPROP_TOOLTIP, exec_tooltip);

    ObjectSetString(0, PREFIX + "Btn_ExecPartial", OBJPROP_TEXT, "Realizar parcial [" + g_key_partial_str + "]");
    ObjectSetString(0, PREFIX + "Btn_ExecAdd", OBJPROP_TEXT, "Adicionar à posição [" + g_key_add_str + "]");
    if (!g_is_editing_partial)
        ObjectSetString(0, PREFIX + "Edit_Partial", OBJPROP_TEXT, DisplayNumber(g_partial_percent, 1) + "%");
    if (!g_is_editing_add)
        ObjectSetString(0, PREFIX + "Edit_Add", OBJPROP_TEXT, DisplayNumber(g_add_percent, 1) + "%");

    ObjectSetInteger(0, PREFIX + "Edit_MaxTrades", OBJPROP_READONLY, pwd_locked);
    ObjectSetInteger(0, PREFIX + "Edit_MaxTrades", OBJPROP_BGCOLOR, pwd_locked ? CLR_BG_CARD : CLR_BG);
    if (!g_is_editing_max_trades)
    {
        string mt_str = IntegerToString(g_max_trades_session);
        ObjectSetString(0, PREFIX + "Edit_MaxTrades", OBJPROP_TEXT, pwd_locked ? ("🔒 " + mt_str) : mt_str);
    }

    ObjectSetInteger(0, PREFIX + "Edit_MaxLoss", OBJPROP_READONLY, pwd_locked);
    ObjectSetInteger(0, PREFIX + "Edit_MaxLoss", OBJPROP_BGCOLOR, pwd_locked ? CLR_BG_CARD : CLR_BG);
    if (!g_is_editing_max_loss)
    {
        string ml_str = DisplayNumber(g_max_loss_session, 2);
        ObjectSetString(0, PREFIX + "Edit_MaxLoss", OBJPROP_TEXT, pwd_locked ? ("🔒 " + ml_str) : ml_str);
    }

    // Atualiza linha da Senha
    if (!g_is_editing_pwd)
    {
        if (g_typed_pwd != "")
            ObjectSetString(0, PREFIX + "Edit_Pwd", OBJPROP_TEXT, "••••••");
        else if (g_pwd_hash == "")
            ObjectSetString(0, PREFIX + "Edit_Pwd", OBJPROP_TEXT, "Nova senha");
        else if (pwd_locked)
            ObjectSetString(0, PREFIX + "Edit_Pwd", OBJPROP_TEXT, "Senha");
        else
            ObjectSetString(0, PREFIX + "Edit_Pwd", OBJPROP_TEXT, "Nova (opcional)");
    }

    if (g_pwd_hash == "")
    {
        ObjectSetString(0, PREFIX + "Btn_PwdLock", OBJPROP_TEXT, "🔒 Cadastrar e Travar");
        ObjectSetInteger(0, PREFIX + "Btn_PwdLock", OBJPROP_BGCOLOR, CLR_PRIMARY);
        ObjectSetInteger(0, PREFIX + "Btn_PwdLock", OBJPROP_COLOR, clrWhite);
    }
    else if (pwd_locked)
    {
        ObjectSetString(0, PREFIX + "Btn_PwdLock", OBJPROP_TEXT, "🔑 Destravar Risco");
        ObjectSetInteger(0, PREFIX + "Btn_PwdLock", OBJPROP_BGCOLOR, CLR_BTN_ACTIVE);
        ObjectSetInteger(0, PREFIX + "Btn_PwdLock", OBJPROP_COLOR, clrWhite);
    }
    else
    {
        ObjectSetString(0, PREFIX + "Btn_PwdLock", OBJPROP_TEXT, "🔒 Salvar e Travar");
        ObjectSetInteger(0, PREFIX + "Btn_PwdLock", OBJPROP_BGCOLOR, CLR_BUY);
        ObjectSetInteger(0, PREFIX + "Btn_PwdLock", OBJPROP_COLOR, clrWhite);
    }

    bool is_night = false;
    GetCurrentSessionStartServerTime(is_night);
    string sess_name = is_night ? "Noite/HK" : "Dia";
    string trades_str = (g_max_trades_session > 0) ? StringFormat("%d/%d", g_cur_session_trades, g_max_trades_session) : StringFormat("%d", g_cur_session_trades);
    string pnl_sign = (g_cur_session_pnl >= 0.0) ? "+$" : "-$";
    string disc_txt = StringFormat("Turno %s: %s trades | PnL: %s%s", sess_name, trades_str, pnl_sign, DisplayNumber(MathAbs(g_cur_session_pnl), 2));
    if (g_max_loss_session > 0.0)
        disc_txt += StringFormat(" (Lim: -$%s)", DisplayNumber(g_max_loss_session, 0));

    color disc_col = CLR_TXT_BODY;
    color disc_bg  = CLR_BG_CARD;
    color disc_brd = CLR_BORDER;
    if (g_session_loss_locked)
    {
        disc_col = CLR_SELL; disc_bg = CLR_SELL_BG; disc_brd = CLR_SELL;
    }
    else if (g_session_trades_locked)
    {
        disc_col = CLR_PARTIAL; disc_bg = CLR_HIGHLIGHT; disc_brd = CLR_PARTIAL;
    }
    else if (g_cur_session_pnl > 0.01)
    {
        disc_col = CLR_BUY;
    }
    else if (g_cur_session_pnl < -0.01)
    {
        disc_col = CLR_SELL;
    }

    SetSummaryText("Lbl_DiscStatus", disc_txt, g_panel_w - 56, 10);
    ObjectSetInteger(0, PREFIX + "Lbl_DiscStatus", OBJPROP_COLOR, disc_col);
    ObjectSetInteger(0, PREFIX + "DiscBadgeBg", OBJPROP_BGCOLOR, disc_bg);
    ObjectSetInteger(0, PREFIX + "DiscBadgeBg", OBJPROP_COLOR, disc_brd);
}

void CleanupPanelObjects()
{
    // Deleta apenas os componentes visuais do painel, preservando Linhas e Fibo
    ObjectsDeleteAll(0, PREFIX + "Bg");
    ObjectsDeleteAll(0, PREFIX + "TopBar");
    ObjectsDeleteAll(0, PREFIX + "Header");
    ObjectsDeleteAll(0, PREFIX + "Btn_");
    ObjectsDeleteAll(0, PREFIX + "Lbl_");
    ObjectsDeleteAll(0, PREFIX + "Edit_");
    ObjectsDeleteAll(0, PREFIX + "DirBadge");
    ObjectsDeleteAll(0, PREFIX + "Div");
    ObjectsDeleteAll(0, PREFIX + "LotCard");
    ObjectsDeleteAll(0, PREFIX + "DiscBadge");
    ObjectsDeleteAll(0, PREFIX + "Corner");
    ObjectsDeleteAll(0, PREFIX + "Edge");
}

//+------------------------------------------------------------------+
//| Relogio de Candles (Candle Timer)                                |
//+------------------------------------------------------------------+
void DeleteCandleTimer()
{
    g_timer_selected = false;
    g_timer_dragging = false;
    if (ObjectFind(0, CANDLE_TIMER_NAME) >= 0)
    {
        ObjectDelete(0, CANDLE_TIMER_NAME);
    }
}

string GetCandleTimerString()
{
    datetime bar_time = iTime(_Symbol, _Period, 0);
    if (bar_time <= 0) return "";

    int period_sec = PeriodSeconds(_Period);
    if (period_sec <= 0) return "";

    // Usa TimeCurrent() + relogio monotonico (GetTickCount64) em vez de TimeTradeServer(),
    // pois TimeTradeServer() depende do relogio local do Windows do usuario (se o PC do aluno
    // estiver adiantado ou atrasado em segundos, o relogio de candles abria em 1:30 ou 2:53 no M2).
    static datetime s_last_srv_time = 0;
    static ulong    s_sec_start_ms  = 0;
    static long     s_last_tick_msc = 0;
    static bool     s_has_live_sync = false;

    datetime srv_time = TimeCurrent();
    datetime sym_time = (datetime)SymbolInfoInteger(_Symbol, SYMBOL_TIME);
    if (sym_time > srv_time) srv_time = sym_time;

    ulong now_ms = GetTickCount64();

    if (srv_time > 0)
    {
        ulong sub_sec_ms = 0;
        long  tick_msc   = 0;
        MqlTick last_tick;
        if (SymbolInfoTick(_Symbol, last_tick) && last_tick.time_msc > 0)
        {
            tick_msc = last_tick.time_msc;
            if (last_tick.time >= srv_time)
            {
                srv_time   = last_tick.time;
                sub_sec_ms = (ulong)(last_tick.time_msc % 1000);
            }
        }

        if (s_last_srv_time == 0)
        {
            s_last_srv_time = srv_time;
            s_sec_start_ms  = (now_ms > sub_sec_ms) ? (now_ms - sub_sec_ms) : 0;
            s_last_tick_msc = tick_msc;
            s_has_live_sync = false;
        }
        else if (srv_time != s_last_srv_time || (tick_msc > 0 && tick_msc != s_last_tick_msc))
        {
            s_last_srv_time = srv_time;
            s_sec_start_ms  = (now_ms > sub_sec_ms) ? (now_ms - sub_sec_ms) : 0;
            if (tick_msc > 0) s_last_tick_msc = tick_msc;
            s_has_live_sync = true;
        }
    }

    datetime cur_time = srv_time;
    if (s_has_live_sync && s_last_srv_time > 0 && now_ms >= s_sec_start_ms)
    {
        ulong elapsed_ms = now_ms - s_sec_start_ms;
        if (elapsed_ms < 60000)
            cur_time = s_last_srv_time + (datetime)(elapsed_ms / 1000);
    }

    if (cur_time <= 0) cur_time = TimeCurrent();

    long rem_sec = (long)((bar_time + period_sec) - cur_time);
    if (rem_sec < 0) rem_sec = 0;
    if (rem_sec > period_sec) rem_sec = period_sec;

    int days  = (int)(rem_sec / 86400);
    long rem_in_day = rem_sec % 86400;
    int hours = (int)(rem_in_day / 3600);
    int mins  = (int)((rem_in_day % 3600) / 60);
    int secs  = (int)(rem_in_day % 60);

    if (days > 0)
        return StringFormat("%dd %d:%02d:%02d", days, hours, mins, secs);
    if (hours > 0)
        return StringFormat("%d:%02d:%02d", hours, mins, secs);
    return StringFormat("%d:%02d", mins, secs);
}

void UpdateCandleTimer()
{
    if (!g_candle_timer_enabled)
    {
        DeleteCandleTimer();
        return;
    }

    string timer_str = GetCandleTimerString();
    if (timer_str == "") return;

    if (InpCandleTimerShowSpread)
    {
        long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
        timer_str += StringFormat(" [Sp: %d]", (int)spread);
    }

    if (ObjectFind(0, CANDLE_TIMER_NAME) >= 0)
    {
        if (ObjectGetInteger(0, CANDLE_TIMER_NAME, OBJPROP_TYPE) != OBJ_LABEL)
        {
            ObjectDelete(0, CANDLE_TIMER_NAME);
        }
    }

    if (ObjectFind(0, CANDLE_TIMER_NAME) < 0)
    {
        ObjectCreate(0, CANDLE_TIMER_NAME, OBJ_LABEL, 0, 0, 0);
        ObjectSetString(0, CANDLE_TIMER_NAME, OBJPROP_FONT, "Segoe UI Semibold");
        ObjectSetInteger(0, CANDLE_TIMER_NAME, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, CANDLE_TIMER_NAME, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
        ObjectSetInteger(0, CANDLE_TIMER_NAME, OBJPROP_SELECTABLE, true);
        ObjectSetInteger(0, CANDLE_TIMER_NAME, OBJPROP_SELECTED, false);
        ObjectSetInteger(0, CANDLE_TIMER_NAME, OBJPROP_HIDDEN, false);
    }

    // Calcula coordenadas na tela (X, Y)
    int x_dist = 0, y_dist = 0;

    if (g_timer_is_custom && g_timer_custom_x >= 0 && g_timer_custom_y >= 0)
    {
        x_dist = g_timer_custom_x;
        y_dist = g_timer_custom_y;
    }
    else if (g_candle_timer_pos == TIMER_POS_FOLLOW_PRICE)
    {
        datetime bar_time = iTime(_Symbol, _Period, 0);
        double close_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        if (close_price <= 0) close_price = iClose(_Symbol, _Period, 0);

        if (!ChartGetInteger(0, CHART_SHIFT))
        {
            ChartSetInteger(0, CHART_SHIFT, true);
        }
        if (g_chart_shift_size > 0 && MathAbs(ChartGetDouble(0, CHART_SHIFT_SIZE) - g_chart_shift_size) > 0.5)
        {
            ChartSetDouble(0, CHART_SHIFT_SIZE, g_chart_shift_size);
        }

        int x_bar = 0, y_bar = 0;
        bool xy_ok = (bar_time > 0 && ChartTimePriceToXY(0, 0, bar_time, close_price, x_bar, y_bar));
        if (!xy_ok && bar_time > 0)
        {
            double open_0 = iOpen(_Symbol, _Period, 0);
            if (open_0 > 0) xy_ok = ChartTimePriceToXY(0, 0, bar_time, open_0, x_bar, y_bar);
        }

        if (xy_ok)
        {
            int bar_spacing = 8;
            datetime prev_time = iTime(_Symbol, _Period, 1);
            int x_prev = 0, y_prev = 0;
            if (prev_time > 0 && ChartTimePriceToXY(0, 0, prev_time, close_price, x_prev, y_prev))
            {
                int diff = x_bar - x_prev;
                if (diff > 0 && diff < 80) bar_spacing = diff;
            }
            else
            {
                long scale = ChartGetInteger(0, CHART_SCALE);
                bar_spacing = (int)(1 << scale);
                if (bar_spacing < 4) bar_spacing = 4;
            }

            x_dist = x_bar + bar_spacing + 4;
            y_dist = y_bar - 7;
        }
        else
        {
            int chart_w = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
            x_dist = MathMax(20, chart_w - 110);
            y_dist = 35;
        }

        int chart_w = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
        int chart_h = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
        if (chart_w > 80 && x_dist > chart_w - 45)
            x_dist = chart_w - 45;
        if (x_dist < 10) x_dist = 10;
        if (y_dist < 20) y_dist = 20;
        if (chart_h > 50 && y_dist > chart_h - 25) y_dist = chart_h - 25;
    }
    else
    {
        int chart_w = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
        int chart_h = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);

        if (g_candle_timer_pos == TIMER_POS_TOP_RIGHT)
        {
            x_dist = MathMax(20, chart_w - 110);
            y_dist = 35;
        }
        else if (g_candle_timer_pos == TIMER_POS_BOTTOM_RIGHT)
        {
            x_dist = MathMax(20, chart_w - 110);
            y_dist = MathMax(20, chart_h - 45);
        }
        else if (g_candle_timer_pos == TIMER_POS_TOP_LEFT)
        {
            x_dist = 60;
            y_dist = 60;
        }
        else if (g_candle_timer_pos == TIMER_POS_BOTTOM_LEFT)
        {
            x_dist = 50;
            y_dist = MathMax(20, chart_h - 45);
        }
    }

    if (!g_timer_dragging)
    {
        ObjectSetInteger(0, CANDLE_TIMER_NAME, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, CANDLE_TIMER_NAME, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
        ObjectSetInteger(0, CANDLE_TIMER_NAME, OBJPROP_XDISTANCE, x_dist);
        ObjectSetInteger(0, CANDLE_TIMER_NAME, OBJPROP_YDISTANCE, y_dist);
    }

    color text_color = InpCandleTimerColor;
    if (g_timer_selected)
    {
        text_color = clrDodgerBlue;
    }
    else
    {
        color bg = (color)ChartGetInteger(0, CHART_COLOR_BACKGROUND);
        int r = (int)(bg & 0xFF);
        int g = (int)((bg >> 8) & 0xFF);
        int b = (int)((bg >> 16) & 0xFF);
        double luminance = 0.299 * r + 0.587 * g + 0.114 * b;
        if (luminance < 100 && text_color == C'15,23,42')
        {
            text_color = clrWhite;
        }
    }

    ObjectSetInteger(0, CANDLE_TIMER_NAME, OBJPROP_COLOR, text_color);
    ObjectSetInteger(0, CANDLE_TIMER_NAME, OBJPROP_FONTSIZE, g_candle_timer_size);
    ObjectSetString(0, CANDLE_TIMER_NAME, OBJPROP_TEXT, timer_str);
    ObjectSetInteger(0, CANDLE_TIMER_NAME, OBJPROP_SELECTABLE, true);
    ObjectSetInteger(0, CANDLE_TIMER_NAME, OBJPROP_SELECTED, g_timer_selected);
    ObjectSetInteger(0, CANDLE_TIMER_NAME, OBJPROP_HIDDEN, false);
    ObjectSetString(0, CANDLE_TIMER_NAME, OBJPROP_TOOLTIP, "Duplo clique para selecionar e arrastar para onde quiser na tela! (Shift + Duplo clique redefine)");
}

//+------------------------------------------------------------------+
//| Limpa todas as marcacoes visuais de Barra Forte e Pivo           |
//+------------------------------------------------------------------+
void ClearStopAdjustmentSignals()
{
    ObjectsDeleteAll(0, SIG_PREFIX);
}

//+------------------------------------------------------------------+
//| Verifica se ha posicao aberta no ativo e retorna tempo/direcao   |
//+------------------------------------------------------------------+
bool HasOpenPositionOnSymbol(datetime &earliest_open_time, ENUM_POSITION_TYPE &pos_dir)
{
    int total_positions = PositionsTotal();
    earliest_open_time = D'2099.12.31';
    pos_dir = POSITION_TYPE_BUY;
    bool found_magic = false;
    bool found_any   = false;

    for (int i = 0; i < total_positions; i++)
    {
        ulong ticket = PositionGetTicket(i);
        if (ticket > 0 && PositionGetString(POSITION_SYMBOL) == _Symbol)
        {
            long magic = PositionGetInteger(POSITION_MAGIC);
            datetime ptime = (datetime)PositionGetInteger(POSITION_TIME);
            ENUM_POSITION_TYPE ptype = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

            if (magic == InpMagicNumber || magic == (InpMagicNumber + 1))
            {
                if (!found_magic || ptime < earliest_open_time)
                {
                    earliest_open_time = ptime;
                    pos_dir = ptype;
                }
                found_magic = true;
            }
            else if (!found_magic)
            {
                if (!found_any || ptime < earliest_open_time)
                {
                    earliest_open_time = ptime;
                    pos_dir = ptype;
                }
                found_any = true;
            }
        }
    }

    return (found_magic || found_any);
}

//+------------------------------------------------------------------+
//| Calcula a media do tamanho total (High-Low) das ultimas N barras |
//| a partir da abertura do dia/pregao (sem pegar barras de ontem)   |
//+------------------------------------------------------------------+
double GetDayAverageBarRange(int ref_shift, int &bars_count_out)
{
    bars_count_out = 0;
    datetime ref_time = iTime(_Symbol, _Period, ref_shift);
    if (ref_time <= 0) return 0.0;

    MqlDateTime dt_ref;
    TimeToStruct(ref_time, dt_ref);
    dt_ref.hour = 0;
    dt_ref.min  = 0;
    dt_ref.sec  = 0;
    datetime day_start = StructToTime(dt_ref);

    int lookback = MathMax(1, InpStrongBarLookback);
    double sum_range = 0.0;
    int count = 0;

    // Soma ate as ultimas N barras (ex: 20) anteriores, parando na abertura do dia atual
    for (int b = ref_shift + 1; b <= ref_shift + lookback; b++)
    {
        datetime bt = iTime(_Symbol, _Period, b);
        if (bt <= 0 || bt < day_start) break; // Nao pega barras do dia anterior

        double hi = iHigh(_Symbol, _Period, b);
        double lo = iLow(_Symbol, _Period, b);
        if (hi > 0 && lo > 0 && hi >= lo)
        {
            sum_range += (hi - lo);
            count++;
        }
    }

    // Se for a primeira barra da abertura do dia, inclui a propria barra como referencia
    if (count == 0)
    {
        double hi = iHigh(_Symbol, _Period, ref_shift);
        double lo = iLow(_Symbol, _Period, ref_shift);
        if (hi > 0 && lo > 0 && hi >= lo)
        {
            sum_range = (hi - lo);
            count = 1;
        }
    }

    bars_count_out = count;
    if (count <= 0) return 0.0;
    return (sum_range / count);
}

//+------------------------------------------------------------------+
//| Calcula a media do corpo (|Close-Open|) das ultimas N barras     |
//| a partir da abertura do dia/pregao (sem pegar barras de ontem)   |
//+------------------------------------------------------------------+
double GetLastBarsAverageBody(int ref_shift)
{
    datetime ref_time = iTime(_Symbol, _Period, ref_shift);
    if (ref_time <= 0) return 0.0;

    MqlDateTime dt_ref;
    TimeToStruct(ref_time, dt_ref);
    dt_ref.hour = 0;
    dt_ref.min  = 0;
    dt_ref.sec  = 0;
    datetime day_start = StructToTime(dt_ref);

    int lookback = MathMax(1, InpStrongBarLookback);
    double sum_body = 0.0;
    int count = 0;

    for (int b = ref_shift + 1; b <= ref_shift + lookback; b++)
    {
        datetime bt = iTime(_Symbol, _Period, b);
        if (bt <= 0 || bt < day_start) break; // Nao pega barras do dia anterior

        double op = iOpen(_Symbol, _Period, b);
        double cl = iClose(_Symbol, _Period, b);
        if (op > 0 && cl > 0)
        {
            sum_body += MathAbs(cl - op);
            count++;
        }
    }
    if (count <= 0) return 0.0;
    return (sum_body / count);
}

//+------------------------------------------------------------------+
//| Desenha Seta e Texto de Nivel de Stop no Grafico                 |
//+------------------------------------------------------------------+
void DrawStopSignalMarker(string sig_id, datetime bar_time, double price, bool is_buy, bool is_pivot, string label_text, string tooltip_text)
{
    string arrow_name = SIG_PREFIX + "Arr_" + sig_id;
    string text_name  = SIG_PREFIX + "Txt_" + sig_id;
    color  col        = is_pivot ? InpColorPivot : InpColorStrongBar;

    // 1. Seta na barra (abaixo da minima na compra, acima da maxima na venda)
    if (ObjectFind(0, arrow_name) < 0)
    {
        ObjectCreate(0, arrow_name, OBJ_ARROW, 0, bar_time, price);
        ObjectSetInteger(0, arrow_name, OBJPROP_ARROWCODE, is_buy ? 233 : 234); // Seta solida para cima (233) ou para baixo (234)
        ObjectSetInteger(0, arrow_name, OBJPROP_ANCHOR, is_buy ? ANCHOR_TOP : ANCHOR_BOTTOM);
        ObjectSetInteger(0, arrow_name, OBJPROP_COLOR, col);
        ObjectSetInteger(0, arrow_name, OBJPROP_WIDTH, 2);
        ObjectSetInteger(0, arrow_name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, arrow_name, OBJPROP_BACK, false);
        ObjectSetInteger(0, arrow_name, OBJPROP_ZORDER, 40);
        ObjectSetString(0, arrow_name, OBJPROP_TOOLTIP, tooltip_text + " (Clique para mover o Stop para cá)");
    }
    else
    {
        ObjectSetDouble(0, arrow_name, OBJPROP_PRICE, price);
        ObjectSetInteger(0, arrow_name, OBJPROP_TIME, bar_time);
    }

    // 2. Rótulo com tipo (BARRA FORTE / PIVÔ) e preço sugerido do stop
    if (ObjectFind(0, text_name) < 0)
    {
        ObjectCreate(0, text_name, OBJ_TEXT, 0, bar_time, price);
        ObjectSetString(0, text_name, OBJPROP_TEXT, "   " + label_text);
        ObjectSetString(0, text_name, OBJPROP_FONT, "Segoe UI Semibold");
        ObjectSetInteger(0, text_name, OBJPROP_FONTSIZE, 8);
        ObjectSetInteger(0, text_name, OBJPROP_COLOR, col);
        ObjectSetInteger(0, text_name, OBJPROP_ANCHOR, is_buy ? ANCHOR_UPPER : ANCHOR_LOWER);
        ObjectSetInteger(0, text_name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, text_name, OBJPROP_BACK, false);
        ObjectSetInteger(0, text_name, OBJPROP_ZORDER, 40);
        ObjectSetString(0, text_name, OBJPROP_TOOLTIP, tooltip_text + " (Clique para mover o Stop para cá)");
    }
}

//+------------------------------------------------------------------+
//| Monitora e marca Barras Fortes fechadas e Pivos a favor do trade |
//+------------------------------------------------------------------+
void UpdateStopAdjustmentSignals()
{
    if (!InpEnableStopSignals || g_lines_hidden)
    {
        ClearStopAdjustmentSignals();
        return;
    }

    datetime pos_open_time = 0;
    ENUM_POSITION_TYPE pos_dir = POSITION_TYPE_BUY;

    // So exibe avisos quando houver operacao aberta no ativo
    if (!HasOpenPositionOnSymbol(pos_open_time, pos_dir))
    {
        ClearStopAdjustmentSignals();
        return;
    }

    bool is_buy = (pos_dir == POSITION_TYPE_BUY);
    int entry_bar = iBarShift(_Symbol, _Period, pos_open_time, false);
    if (entry_bar < 1) return; // Ainda na mesma barra de abertura sem barras fechadas posteriores

    // Limita varredura a no maximo 150 barras para performance
    if (entry_bar > 150) entry_bar = 150;

    for (int k = entry_bar; k >= 1; k--)
    {
        datetime bt   = iTime(_Symbol, _Period, k);
        double   open = iOpen(_Symbol, _Period, k);
        double   close= iClose(_Symbol, _Period, k);
        double   hi   = iHigh(_Symbol, _Period, k);
        double   lo   = iLow(_Symbol, _Period, k);
        double   bar_range = hi - lo;
        double   bar_body  = MathAbs(close - open);

        if (bt <= 0 || bar_range <= 0) continue;

        // =================================================================
        // 1. DETECCAO DE BARRA FORTE FECHADA A FAVOR DA OPERACAO
        // Compara o Tamanho Total (High - Low) ou Corpo Cheio da barra com
        // a media das ultimas 20 barras (InpStrongBarLookback)
        // =================================================================
        bool is_favorable_bar = is_buy ? (close > open) : (close < open);
        if (is_favorable_bar)
        {
            int n_bars = 0;
            double avg_range = GetDayAverageBarRange(k, n_bars);
            double avg_body  = GetLastBarsAverageBody(k);
            double body_pct  = (bar_range > 0) ? (bar_body / bar_range) : 0.0;

            // Eh Barra Forte se:
            // (a) O tamanho total (High-Low) >= Proporcao * Media de tamanho das ultimas 20 barras, OU
            // (b) Eh uma barra de corpo cheio (>= 65% de corpo) e seu corpo eh maior que a media de corpo das ultimas 20 barras
            bool strong_by_range = (avg_range > 0.0 && bar_range >= (avg_range * InpStrongBarRatio));
            bool strong_by_body  = (avg_body > 0.0 && body_pct >= 0.65 && bar_body >= (avg_body * InpStrongBarRatio));

            if (strong_by_range || strong_by_body)
            {
                double stop_lvl = AlignPrice(is_buy ? (lo - _Point) : (hi + _Point));
                double pct_of_avg = (avg_range > 0.0) ? ((bar_range / avg_range) * 100.0) : 100.0;
                string sig_id = "SB_" + IntegerToString((long)bt);
                string lbl = StringFormat("★ BARRA FORTE (%.*f)", _Digits, stop_lvl);
                string tip = StringFormat("Barra Forte Fechada (%.0f%% da média das últimas %d barras)\nTam. Barra: %.1f pts | Média %d Barras: %.1f pts\nStop sugerido: %.*f",
                                          pct_of_avg, n_bars, bar_range / _Point, n_bars, avg_range / _Point, _Digits, stop_lvl);

                DrawStopSignalMarker(sig_id, bt, stop_lvl, is_buy, false, lbl, tip);
            }
        }

        // =================================================================
        // 2. DETECCAO DE PIVO CONFIRMADO (Rompimento deixando Fundo + Alto / Topo + Baixo)
        // Na Compra: Barra k+1 fez um fundo (minima menor ou igual a k+2 e k)
        // e a barra k rompeu a maxima de k+1, confirmando o pivo!
        // =================================================================
        double hi_prev1 = iHigh(_Symbol, _Period, k + 1);
        double lo_prev1 = iLow(_Symbol, _Period, k + 1);
        double hi_prev2 = iHigh(_Symbol, _Period, k + 2);
        double lo_prev2 = iLow(_Symbol, _Period, k + 2);
        datetime bt_prev1 = iTime(_Symbol, _Period, k + 1);

        if (hi_prev1 > 0 && lo_prev1 > 0 && hi_prev2 > 0 && lo_prev2 > 0)
        {
            if (is_buy)
            {
                // Fundo em k+1 ou k+2 e rompimento da maxima anterior pela barra k
                bool broke_prev_high = (hi > hi_prev1 && close > hi_prev1 - (bar_range * 0.35));
                bool swing_low_formed = (lo_prev1 <= lo_prev2 && lo > lo_prev1);
                if (broke_prev_high && swing_low_formed)
                {
                    double pivot_low = lo_prev1;
                    double stop_lvl  = AlignPrice(pivot_low - _Point);
                    string sig_id    = "PV_" + IntegerToString((long)bt_prev1);
                    string lbl       = StringFormat("▲ PIVÔ STOP (%.*f)", _Digits, stop_lvl);
                    string tip       = StringFormat("Pivô de Alta Confirmado (Rompeu máxima anterior deixando fundo em %.*f)\nStop sugerido: %.*f",
                                                    _Digits, pivot_low, _Digits, stop_lvl);

                    DrawStopSignalMarker(sig_id, bt_prev1, stop_lvl, true, true, lbl, tip);
                }
            }
            else
            {
                // Topo em k+1 e perda da minima anterior pela barra k
                bool broke_prev_low   = (lo < lo_prev1 && close < lo_prev1 + (bar_range * 0.35));
                bool swing_high_formed = (hi_prev1 >= hi_prev2 && hi < hi_prev1);
                if (broke_prev_low && swing_high_formed)
                {
                    double pivot_high = hi_prev1;
                    double stop_lvl   = AlignPrice(pivot_high + _Point);
                    string sig_id     = "PV_" + IntegerToString((long)bt_prev1);
                    string lbl        = StringFormat("▼ PIVÔ STOP (%.*f)", _Digits, stop_lvl);
                    string tip        = StringFormat("Pivô de Baixa Confirmado (Perdeu mínima anterior deixando topo em %.*f)\nStop sugerido: %.*f",
                                                     _Digits, pivot_high, _Digits, stop_lvl);

                    DrawStopSignalMarker(sig_id, bt_prev1, stop_lvl, false, true, lbl, tip);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Calcula o inicio do Turno Atual (Dia vs Noite/HK) no horario do  |
//| servidor do MT5, baseado na hora local configurada (Ex: 20h)     |
//+------------------------------------------------------------------+
datetime GetCurrentSessionStartServerTime(bool &is_night_session)
{
    datetime srv_now = TimeTradeServer();
    if (srv_now <= 0) srv_now = TimeCurrent();
    datetime loc_now = TimeLocal();
    if (loc_now <= 0) loc_now = srv_now;

    long offset_sec = (long)(srv_now - loc_now);
    int night_hr = MathMax(18, MathMin(23, InpNightSessionStartHour));
    int day_hr   = 6; // 06:00 da manha encerra o turno da madrugada/HK e inicia o turno do Dia

    MqlDateTime dt_loc;
    TimeToStruct(loc_now, dt_loc);

    datetime session_start_loc = 0;
    if (dt_loc.hour >= night_hr)
    {
        is_night_session = true;
        dt_loc.hour = night_hr;
        dt_loc.min  = 0;
        dt_loc.sec  = 0;
        session_start_loc = StructToTime(dt_loc);
    }
    else if (dt_loc.hour < day_hr)
    {
        is_night_session = true;
        dt_loc.hour = night_hr;
        dt_loc.min  = 0;
        dt_loc.sec  = 0;
        session_start_loc = StructToTime(dt_loc) - 86400; // Comecou ontem as 20h/21h
    }
    else
    {
        is_night_session = false;
        dt_loc.hour = day_hr;
        dt_loc.min  = 0;
        dt_loc.sec  = 0;
        session_start_loc = StructToTime(dt_loc);
    }

    return (datetime)(session_start_loc + offset_sec);
}

//+------------------------------------------------------------------+
//| Zera imediatamente todas as posicoes e ordens pendentes da conta |
//| ao atingir o Loss Maximo do turno                                |
//+------------------------------------------------------------------+
void EmergencyCloseAllAccountPositionsAndOrders(string reason)
{
    int closed_cnt = 0;
    int total_pos = PositionsTotal();
    for (int i = total_pos - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (ticket > 0)
        {
            long magic = PositionGetInteger(POSITION_MAGIC);
            trade.SetExpertMagicNumber(magic);
            if (trade.PositionClose(ticket, InpSlippage))
            {
                closed_cnt++;
            }
        }
    }

    int total_ord = OrdersTotal();
    for (int i = total_ord - 1; i >= 0; i--)
    {
        ulong ord_ticket = OrderGetTicket(i);
        if (ord_ticket > 0)
        {
            trade.OrderDelete(ord_ticket);
        }
    }

    trade.SetExpertMagicNumber(InpMagicNumber);
    ClearOperationState();
    DrawLines();
    ChartRedraw(0);

    Alert("[Gerenciamento Master] ⛔ STOP DIÁRIO ACIONADO! ", reason, " Todas as posições e ordens foram encerradas e novas operações estão travadas neste turno!");
    PlaySound("timeout.wav");
}

//+------------------------------------------------------------------+
//| Avalia Quantidade de Trades Logicos e Resultado Financeiro ($PnL)|
//| no Turno Atual (Dia ou Noite/HK) em toda a conta                 |
//+------------------------------------------------------------------+
void EvaluateSessionDiscipline(bool enforce_emergency_close = true)
{
    bool is_night = false;
    datetime sess_start_srv = GetCurrentSessionStartServerTime(is_night);
    datetime srv_now = TimeTradeServer();
    if (srv_now <= 0) srv_now = TimeCurrent();

    // Chave unica da sessao atual para persistir trava de Loss mesmo apos zerar
    string sess_lock_key = "GM_LOCK_LOSS_" + IntegerToString((long)sess_start_srv);

    double closed_pnl = 0.0;
    string op_keys[];
    int op_count = 0;

    if (HistorySelect(sess_start_srv, srv_now + 3600))
    {
        int total_deals = HistoryDealsTotal();
        for (int i = 0; i < total_deals; i++)
        {
            ulong deal_ticket = HistoryDealGetTicket(i);
            if (deal_ticket == 0) continue;

            long entry_type = HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
            long deal_type  = HistoryDealGetInteger(deal_ticket, DEAL_TYPE);
            if (deal_type != DEAL_TYPE_BUY && deal_type != DEAL_TYPE_SELL) continue;

            // Soma PnL realizado no turno (Lucro + Swap + Comissao + Taxas)
            if (entry_type == DEAL_ENTRY_OUT || entry_type == DEAL_ENTRY_INOUT || entry_type == DEAL_ENTRY_OUT_BY)
            {
                closed_pnl += HistoryDealGetDouble(deal_ticket, DEAL_PROFIT)
                            + HistoryDealGetDouble(deal_ticket, DEAL_SWAP)
                            + HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION)
                            + HistoryDealGetDouble(deal_ticket, DEAL_FEE);
            }
            else if (entry_type == DEAL_ENTRY_IN)
            {
                // Comissao cobrada na entrada
                closed_pnl += HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION)
                            + HistoryDealGetDouble(deal_ticket, DEAL_FEE);

                // Contagem de Trades Logicos (ignora Adicoes de Posicao e agrupa ordens fracionadas!)
                long d_magic = HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
                string d_comment = HistoryDealGetString(deal_ticket, DEAL_COMMENT);
                string d_symbol  = HistoryDealGetString(deal_ticket, DEAL_SYMBOL);
                datetime d_time  = (datetime)HistoryDealGetInteger(deal_ticket, DEAL_TIME);

                // Adicoes na mesma operacao aberta NAO contam como um novo trade!
                if (d_magic == (long)(InpMagicNumber + 1) || StringFind(d_comment, "Add") >= 0)
                    continue;

                // Extrai identificador do grupo se for ordem fracionada do GMaster (Ex: GMaster_123456)
                string group_key = "";
                int underscore_pos = StringFind(d_comment, "_");
                if (StringFind(d_comment, InpOrderComment) == 0 && underscore_pos > 0)
                {
                    group_key = d_symbol + "_" + StringSubstr(d_comment, underscore_pos + 1);
                }
                else
                {
                    // Agrupa ordens abertas no mesmo ativo dentro da mesma janela de 10 segundos
                    group_key = d_symbol + "_T" + IntegerToString((long)(d_time / 10));
                }

                bool already_counted = false;
                for (int k = 0; k < op_count; k++)
                {
                    if (op_keys[k] == group_key)
                    {
                        already_counted = true;
                        break;
                    }
                }
                if (!already_counted)
                {
                    ArrayResize(op_keys, op_count + 1);
                    op_keys[op_count] = group_key;
                    op_count++;
                }
            }
        }
    }

    // Soma resultado flutuante das posicoes abertas na conta inteira
    double floating_pnl = 0.0;
    int total_pos = PositionsTotal();
    for (int i = 0; i < total_pos; i++)
    {
        ulong ticket = PositionGetTicket(i);
        if (ticket > 0)
        {
            floating_pnl += PositionGetDouble(POSITION_PROFIT)
                          + PositionGetDouble(POSITION_SWAP);
        }
    }

    // Verifica se tambem ha alguma ordem pendente primaria na conta (para contar como tentativa ativa)
    int pending_primary_groups = 0;
    if (op_count == 0 && total_pos == 0)
    {
        for (int i = 0; i < OrdersTotal(); i++)
        {
            ulong ord_ticket = OrderGetTicket(i);
            if (ord_ticket > 0)
            {
                long omagic = OrderGetInteger(ORDER_MAGIC);
                string ocomment = OrderGetString(ORDER_COMMENT);
                if (omagic != (long)(InpMagicNumber + 1) && StringFind(ocomment, "Add") < 0)
                {
                    pending_primary_groups = 1;
                    break;
                }
            }
        }
    }

    g_cur_session_trades = op_count + pending_primary_groups;
    g_cur_session_pnl    = closed_pnl + floating_pnl;

    // 1. Verifica Trava de Loss Maximo no Turno ($ USD)
    bool was_loss_locked = false;
    double lock_val = 0.0;
    if (GlobalVariableGet(sess_lock_key, lock_val) && lock_val > 0.0)
        was_loss_locked = true;

    if (g_max_loss_session > 0.0 && g_cur_session_pnl <= -(g_max_loss_session - 0.001))
    {
        g_session_loss_locked = true;
        GlobalVariableSet(sess_lock_key, 1.0);
        g_session_lock_reason = StringFormat("Trava de Loss Máximo atingida no turno (-$%.2f / Limite: -$%.2f). Operações bloqueadas!",
                                             MathAbs(g_cur_session_pnl), g_max_loss_session);

        // Se houver posicoes ou ordens abertas e o preuizo total bateu o limite (ex: -$30), zera tudo na hora!
        if (enforce_emergency_close && (PositionsTotal() > 0 || OrdersTotal() > 0))
        {
            EmergencyCloseAllAccountPositionsAndOrders(StringFormat("Prejuízo do turno atingiu -$%.2f (Limite: -$%.2f).",
                                                                    MathAbs(g_cur_session_pnl), g_max_loss_session));
        }
    }
    else if (was_loss_locked && g_max_loss_session > 0.0)
    {
        g_session_loss_locked = true;
        g_session_lock_reason = StringFormat("Turno travado por atingir o Loss Máximo de -$%.2f.", g_max_loss_session);
    }
    else
    {
        g_session_loss_locked = false;
    }

    // 2. Verifica Trava de Quantidade Maxima de Trades no Turno
    // Importante: Mesmo quando atingir 1/1 trade, Adicao (tecla A) e Parcial (tecla P) continuam liberadas enquanto a posicao estiver aberta!
    if (g_max_trades_session > 0 && g_cur_session_trades >= g_max_trades_session)
    {
        g_session_trades_locked = true;
        if (!g_session_loss_locked)
        {
            g_session_lock_reason = StringFormat("Limite de %d/%d trade(s) no turno atingido! Novas entradas bloqueadas (Adição [%s] e Parcial [%s] continuam liberadas na posição aberta).",
                                                 g_cur_session_trades, g_max_trades_session, g_key_add_str, g_key_partial_str);
        }
    }
    else
    {
        g_session_trades_locked = false;
        if (!g_session_loss_locked)
            g_session_lock_reason = "";
    }
}

bool IsRiskPasswordLocked()
{
    return (g_pwd_hash != "" && g_risk_pwd_locked);
}

string HashPassword(string raw_pwd)
{
    StringTrimLeft(raw_pwd);
    StringTrimRight(raw_pwd);
    if (raw_pwd == "") return "";

    ulong h1 = 14695981039346656037ULL;
    ulong h2 = 1099511628211ULL;
    int len = StringLen(raw_pwd);
    for (int i = 0; i < len; i++)
    {
        ushort ch = StringGetCharacter(raw_pwd, i);
        h1 ^= (ulong)(ch + (i * 131));
        h1 *= 1099511628211ULL;
        h2 ^= (ulong)(ch * 65599 + i);
        h2 = (h2 << 13) | (h2 >> 51);
    }
    return StringFormat("%08X%08X%08X%08X",
                        (uint)((h1 >> 32) & 0xFFFFFFFF),
                        (uint)(h1 & 0xFFFFFFFF),
                        (uint)((h2 >> 32) & 0xFFFFFFFF),
                        (uint)(h2 & 0xFFFFFFFF));
}

void ShowPasswordLockAlert(string field_name)
{
    Alert(StringFormat("🔒 [%s BLOQUEADO POR SENHA]\nDigite sua senha no campo 'Senha' do painel e clique em 'Destravar Risco' para alterar.", field_name));
}

void CommitPendingPanelEdits()
{
    if (IsRiskPasswordLocked()) return;

    if (ObjectFind(0, PREFIX + "Edit_Risk") >= 0)
    {
        string txt = ObjectGetString(0, PREFIX + "Edit_Risk", OBJPROP_TEXT);
        StringReplace(txt, "🔒", "");
        StringReplace(txt, " ", "");
        StringReplace(txt, ",", ".");
        if (txt != "")
        {
            double val = StringToDouble(txt);
            if (val > 0.0)
            {
                if (g_risk_mode == RISK_FIXED_USD) g_risk_cash = val;
                else g_risk_percent = val;
            }
        }
    }
    if (ObjectFind(0, PREFIX + "Edit_MaxTrades") >= 0)
    {
        string txt = ObjectGetString(0, PREFIX + "Edit_MaxTrades", OBJPROP_TEXT);
        StringReplace(txt, "🔒", "");
        StringTrimLeft(txt);
        StringTrimRight(txt);
        if (txt != "" && txt != "Ilim" && txt != "ILIM" && txt != "ilim")
        {
            int val = (int)StringToInteger(txt);
            if (val >= 0) g_max_trades_session = val;
        }
    }
    if (ObjectFind(0, PREFIX + "Edit_MaxLoss") >= 0)
    {
        string txt = ObjectGetString(0, PREFIX + "Edit_MaxLoss", OBJPROP_TEXT);
        StringReplace(txt, "🔒", "");
        StringReplace(txt, ",", ".");
        StringTrimLeft(txt);
        StringTrimRight(txt);
        if (txt != "" && txt != "Ilim" && txt != "ILIM" && txt != "ilim")
        {
            double val = StringToDouble(txt);
            if (val >= 0.0) g_max_loss_session = val;
        }
    }
}

void HandlePasswordAction()
{
    string pwd = g_typed_pwd;
    StringTrimLeft(pwd);
    StringTrimRight(pwd);

    if (pwd == "" && ObjectFind(0, PREFIX + "Edit_Pwd") >= 0)
    {
        string raw_box = ObjectGetString(0, PREFIX + "Edit_Pwd", OBJPROP_TEXT);
        StringTrimLeft(raw_box);
        StringTrimRight(raw_box);
        if (raw_box != "" && raw_box != "••••••")
            pwd = raw_box;
    }

    // 1. Nenhuma senha cadastrada ainda -> Cadastrar senha e travar
    if (g_pwd_hash == "")
    {
        CommitPendingPanelEdits();
        if (pwd == "")
        {
            Alert("⚠️ Digite uma senha no campo 'Senha' ao lado antes de clicar em 'Cadastrar e Travar'.");
            return;
        }
        g_pwd_hash = HashPassword(pwd);
        g_risk_pwd_locked = true;
        g_typed_pwd = "";
        g_is_editing_pwd = false;

        SaveSecurityVault();
        EvaluateSessionDiscipline(true);
        Recalculate();
        UpdatePanel();
        BroadcastConfigToAllCharts();
        Alert("🔒 Senha cadastrada com sucesso! Risco, Max Trades e Loss Max ($) estao travados em todos os graficos.");
        return;
    }

    // 2. Senha ja cadastrada e painel TRAVADO -> Tentar destravar
    if (g_risk_pwd_locked)
    {
        if (pwd == "")
        {
            Alert("🔑 Digite sua senha no campo 'Senha' ao lado e clique em 'Destravar Risco'.");
            return;
        }
        if (HashPassword(pwd) == g_pwd_hash)
        {
            g_risk_pwd_locked = false;
            g_typed_pwd = "";
            g_is_editing_pwd = false;

            SaveSecurityVault();
            UpdatePanel();
            BroadcastConfigToAllCharts();
            Alert("🔓 Risco e Limites Diarios destravados! Faca os ajustes desejados e depois clique em 'Salvar e Travar'.");
        }
        else
        {
            g_typed_pwd = "";
            g_is_editing_pwd = false;
            ObjectSetString(0, PREFIX + "Edit_Pwd", OBJPROP_TEXT, "");
            ChartRedraw(0);
            Alert("❌ Senha incorreta! O Risco e os limites diarios permanecem bloqueados.");
        }
        return;
    }

    // 3. Senha ja cadastrada e painel DESTRAVADO -> Salvar e Travar novamente (permite trocar a senha se digitou uma nova)
    CommitPendingPanelEdits();
    if (pwd != "")
    {
        g_pwd_hash = HashPassword(pwd);
    }
    g_risk_pwd_locked = true;
    g_typed_pwd = "";
    g_is_editing_pwd = false;

    SaveSecurityVault();
    EvaluateSessionDiscipline(true);
    Recalculate();
    UpdatePanel();
    BroadcastConfigToAllCharts();
    Alert("🔒 Novos parametros de Risco e Disciplina salvos e travados em todos os graficos!");
}

bool SaveSecurityVault()
{
    int handle = FileOpen("GerenciamentoMaster_Security.dat", FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
    if (handle == INVALID_HANDLE) return false;

    FileWriteString(handle, StringFormat("PwdHash=%s\r\n", g_pwd_hash));
    FileWriteString(handle, StringFormat("RiskPwdLocked=%d\r\n", g_risk_pwd_locked ? 1 : 0));
    FileWriteString(handle, StringFormat("LockedRiskMode=%d\r\n", (int)g_risk_mode));
    FileWriteString(handle, StringFormat("LockedRiskCash=%.2f\r\n", g_risk_cash));
    FileWriteString(handle, StringFormat("LockedRiskPercent=%.2f\r\n", g_risk_percent));
    FileWriteString(handle, StringFormat("LockedMaxTrades=%d\r\n", g_max_trades_session));
    FileWriteString(handle, StringFormat("LockedMaxLoss=%.2f\r\n", g_max_loss_session));

    FileClose(handle);
    return true;
}

bool LoadSecurityVault()
{
    if (!FileIsExist("GerenciamentoMaster_Security.dat", FILE_COMMON)) return false;
    int handle = FileOpen("GerenciamentoMaster_Security.dat", FILE_READ|FILE_TXT|FILE_ANSI|FILE_COMMON);
    if (handle == INVALID_HANDLE) return false;

    string loaded_hash = "";
    bool   loaded_locked = true;
    ENUM_RISK_MODE loaded_mode = g_risk_mode;
    double loaded_cash = g_risk_cash;
    double loaded_perc = g_risk_percent;
    int    loaded_max_trades = g_max_trades_session;
    double loaded_max_loss = g_max_loss_session;

    while (!FileIsEnding(handle))
    {
        string line = FileReadString(handle);
        StringTrimLeft(line);
        StringTrimRight(line);
        if (line == "" || StringSubstr(line, 0, 1) == "#") continue;

        int eq = StringFind(line, "=");
        if (eq <= 0) continue;

        string key = StringSubstr(line, 0, eq);
        string val = StringSubstr(line, eq + 1);
        StringTrimLeft(key); StringTrimRight(key);
        StringTrimLeft(val); StringTrimRight(val);

        if      (key == "PwdHash")           loaded_hash = val;
        else if (key == "RiskPwdLocked")     loaded_locked = (StringToInteger(val) != 0);
        else if (key == "LockedRiskMode")    loaded_mode = (StringToInteger(val) == 1) ? RISK_PERCENT : RISK_FIXED_USD;
        else if (key == "LockedRiskCash")    loaded_cash = MathMax(0.0, StringToDouble(val));
        else if (key == "LockedRiskPercent") loaded_perc = MathMax(0.0, StringToDouble(val));
        else if (key == "LockedMaxTrades")   loaded_max_trades = MathMax(0, (int)StringToInteger(val));
        else if (key == "LockedMaxLoss")     loaded_max_loss = MathMax(0.0, StringToDouble(val));
    }
    FileClose(handle);

    if (loaded_hash != "")
    {
        g_pwd_hash = loaded_hash;
        g_risk_pwd_locked = loaded_locked;
        // Sempre impoe os valores do cofre se houver senha cadastrada, impedindo bypass via F7 ou remocao do EA
        g_risk_mode = loaded_mode;
        g_risk_cash = loaded_cash;
        g_risk_percent = loaded_perc;
        g_max_trades_session = loaded_max_trades;
        g_max_loss_session = loaded_max_loss;
        return true;
    }
    return false;
}

void BroadcastConfigToAllCharts()
{
    if (MQLInfoInteger(MQL_TESTER)) return;

    SaveSecurityVault();
    SaveAllToGlobals(false);
    SaveDefaultIni();
    WriteCurrentDefaultMarker();

    long current_id = ChartID();
    long chart_id = ChartFirst();
    while (chart_id >= 0)
    {
        if (chart_id != current_id)
        {
            if (ObjectFind(chart_id, GM_PESSOAL_MARKER) >= 0 || ObjectFind(chart_id, "GM_Bg") >= 0)
            {
                EventChartCustom(chart_id, 8888, 0, 0.0, "RELOAD_DEFAULT");
                ChartRedraw(chart_id);
            }
        }
        chart_id = ChartNext(chart_id);
    }
}

void CleanupObjects()
{
    // Deleta tudo ao desanexar o Expert do grafico
    ObjectsDeleteAll(0, PREFIX);
    ObjectDelete(0, "GMCurrentDefault88");
    ObjectDelete(0, GM_PESSOAL_MARKER);
}
//+------------------------------------------------------------------+

// BEGIN CURRENT CHART DEFAULT
#define GM_CURRENT_MARKER "GMCurrentDefault88"
string CurrentDefaultState()
{
    // Only settings are copied. Entry/stop prices and calculated lots are per symbol.
    return "88|0" + "|" +
        DoubleToString(g_open_scale, 4) + "|" + DoubleToString(g_minimized_scale, 4) + "|" +
        IntegerToString((int)g_is_minimized) + "|" + IntegerToString((int)g_risk_mode) + "|" +
        DoubleToString(g_risk_cash, 2) + "|" + DoubleToString(g_risk_percent, 2) + "|" +
        DoubleToString(g_partial_percent, 1) + "|" + DoubleToString(g_add_percent, 1) + "|" +
        IntegerToString(g_key_entry_vk) + "|" + IntegerToString(g_key_stop_vk) + "|" +
        IntegerToString(g_key_mode_vk) + "|" + IntegerToString(g_key_hide_vk) + "|" +
        IntegerToString(g_key_min_vk) + "|" + IntegerToString(g_key_exec_vk) + "|" +
        IntegerToString(g_key_partial_vk) + "|" + IntegerToString(g_key_add_vk) + "|" +
        DoubleToString(Scale(g_panel_x) / g_system_dpi_scale, 2) + "|" +
        DoubleToString(Scale(g_panel_y) / g_system_dpi_scale, 2) + "|" + IntegerToString((int)g_lines_hidden) + "|" + IntegerToString((int)g_is_pending) + "|" +
        IntegerToString((int)g_candle_timer_enabled) + "|" +
        IntegerToString((int)g_timer_is_custom) + "|" +
        IntegerToString(g_timer_custom_x) + "|" +
        IntegerToString(g_timer_custom_y) + "|" +
        IntegerToString(g_min_panel_x) + "|" +
        IntegerToString(g_min_panel_y) + "|" +
        IntegerToString((int)g_candle_timer_pos) + "|" +
        IntegerToString(g_candle_timer_size) + "|" +
        IntegerToString((int)g_chart_shift_enabled) + "|" +
        DoubleToString(g_chart_shift_size, 2) + "|" +
        IntegerToString(g_max_trades_session) + "|" +
        DoubleToString(g_max_loss_session, 2) + "|" +
        g_pwd_hash + "|" +
        IntegerToString(g_risk_pwd_locked ? 1 : 0);
}

bool WriteCurrentDefaultMarker()
{
    if (ObjectFind(0, GM_PESSOAL_MARKER) < 0)
        ObjectCreate(0, GM_PESSOAL_MARKER, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, GM_PESSOAL_MARKER, OBJPROP_XDISTANCE, -10000);
    ObjectSetInteger(0, GM_PESSOAL_MARKER, OBJPROP_YDISTANCE, -10000);
    ObjectSetInteger(0, GM_PESSOAL_MARKER, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, GM_PESSOAL_MARKER, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, GM_PESSOAL_MARKER, OBJPROP_COLOR, clrNONE);

    if (ObjectFind(0, GM_CURRENT_MARKER) < 0 &&
        !ObjectCreate(0, GM_CURRENT_MARKER, OBJ_LABEL, 0, 0, 0)) return false;
    ObjectSetInteger(0, GM_CURRENT_MARKER, OBJPROP_XDISTANCE, -10000);
    ObjectSetInteger(0, GM_CURRENT_MARKER, OBJPROP_YDISTANCE, -10000);
    ObjectSetInteger(0, GM_CURRENT_MARKER, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, GM_CURRENT_MARKER, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, GM_CURRENT_MARKER, OBJPROP_COLOR, clrNONE);
    return ObjectSetString(0, GM_CURRENT_MARKER, OBJPROP_TEXT, CurrentDefaultState());
}

bool SaveDefaultIni()
{
    int handle = FileOpen("GerenciamentoMaster_Default.ini", FILE_WRITE|FILE_TXT|FILE_ANSI);
    if (handle == INVALID_HANDLE) return false;

    FileWriteString(handle, StringFormat("RiskMode=%d\r\n", (int)g_risk_mode));
    FileWriteString(handle, StringFormat("RiskCash=%.2f\r\n", g_risk_cash));
    FileWriteString(handle, StringFormat("RiskPercent=%.2f\r\n", g_risk_percent));
    FileWriteString(handle, StringFormat("PartialPercent=%.1f\r\n", g_partial_percent));
    FileWriteString(handle, StringFormat("AddPercent=%.1f\r\n", g_add_percent));
    FileWriteString(handle, StringFormat("KeyEntry=%d\r\n", g_key_entry_vk));
    FileWriteString(handle, StringFormat("KeyStop=%d\r\n", g_key_stop_vk));
    FileWriteString(handle, StringFormat("KeyMode=%d\r\n", g_key_mode_vk));
    FileWriteString(handle, StringFormat("KeyHide=%d\r\n", g_key_hide_vk));
    FileWriteString(handle, StringFormat("KeyMin=%d\r\n", g_key_min_vk));
    FileWriteString(handle, StringFormat("KeyExec=%d\r\n", g_key_exec_vk));
    FileWriteString(handle, StringFormat("KeyPartial=%d\r\n", g_key_partial_vk));
    FileWriteString(handle, StringFormat("KeyAdd=%d\r\n", g_key_add_vk));
    FileWriteString(handle, StringFormat("OpenScale=%.4f\r\n", g_open_scale));
    FileWriteString(handle, StringFormat("MinScale=%.4f\r\n", g_minimized_scale));
    FileWriteString(handle, StringFormat("IsMinimized=%d\r\n", (int)g_is_minimized));
    FileWriteString(handle, StringFormat("IsPending=%d\r\n", (int)g_is_pending));
    FileWriteString(handle, StringFormat("MinPanelX=%d\r\n", g_min_panel_x));
    FileWriteString(handle, StringFormat("MinPanelY=%d\r\n", g_min_panel_y));
    FileWriteString(handle, StringFormat("PanelX=%d\r\n", g_panel_x));
    FileWriteString(handle, StringFormat("PanelY=%d\r\n", g_panel_y));
    FileWriteString(handle, StringFormat("LinesHidden=%d\r\n", (int)g_lines_hidden));
    FileWriteString(handle, StringFormat("CandleTimerEnabled=%d\r\n", (int)g_candle_timer_enabled));
    FileWriteString(handle, StringFormat("TimerIsCustom=%d\r\n", (int)g_timer_is_custom));
    FileWriteString(handle, StringFormat("TimerCustomX=%d\r\n", g_timer_custom_x));
    FileWriteString(handle, StringFormat("TimerCustomY=%d\r\n", g_timer_custom_y));
    FileWriteString(handle, StringFormat("CandleTimerPos=%d\r\n", (int)g_candle_timer_pos));
    FileWriteString(handle, StringFormat("CandleTimerSize=%d\r\n", g_candle_timer_size));
    FileWriteString(handle, StringFormat("ChartShiftEnabled=%d\r\n", (int)g_chart_shift_enabled));
    FileWriteString(handle, StringFormat("ChartShiftSize=%.2f\r\n", g_chart_shift_size));
    FileWriteString(handle, StringFormat("MaxTradesSession=%d\r\n", g_max_trades_session));
    FileWriteString(handle, StringFormat("MaxLossSession=%.2f\r\n", g_max_loss_session));
    FileWriteString(handle, StringFormat("PwdHash=%s\r\n", g_pwd_hash));
    FileWriteString(handle, StringFormat("RiskPwdLocked=%d\r\n", g_risk_pwd_locked ? 1 : 0));

    FileClose(handle);
    return true;
}

bool LoadDefaultIni()
{
    if (!FileIsExist("GerenciamentoMaster_Default.ini")) return false;
    int handle = FileOpen("GerenciamentoMaster_Default.ini", FILE_READ|FILE_TXT|FILE_ANSI);
    if (handle == INVALID_HANDLE) return false;

    while (!FileIsEnding(handle))
    {
        string line = FileReadString(handle);
        StringTrimLeft(line);
        StringTrimRight(line);
        if (line == "" || StringSubstr(line, 0, 1) == "#" || StringSubstr(line, 0, 1) == ";") continue;

        int eq = StringFind(line, "=");
        if (eq <= 0) continue;

        string key = StringSubstr(line, 0, eq);
        string val = StringSubstr(line, eq + 1);
        StringTrimLeft(key); StringTrimRight(key);
        StringTrimLeft(val); StringTrimRight(val);

        if      (key == "RiskMode")           g_risk_mode = (StringToInteger(val) == 1) ? RISK_PERCENT : RISK_FIXED_USD;
        else if (key == "RiskCash")           g_risk_cash = MathMax(0.0, StringToDouble(val));
        else if (key == "RiskPercent")        g_risk_percent = MathMax(0.0, StringToDouble(val));
        else if (key == "PartialPercent")     g_partial_percent = MathMax(0.1, MathMin(100.0, StringToDouble(val)));
        else if (key == "AddPercent")         g_add_percent = MathMax(1.0, MathMin(50.0, StringToDouble(val)));
        else if (key == "KeyEntry")         { g_key_entry_vk = (int)StringToInteger(val); g_key_entry_str = GetKeyName(g_key_entry_vk); }
        else if (key == "KeyStop")          { g_key_stop_vk  = (int)StringToInteger(val); g_key_stop_str  = GetKeyName(g_key_stop_vk); }
        else if (key == "KeyMode")          { g_key_mode_vk  = (int)StringToInteger(val); g_key_mode_str  = GetKeyName(g_key_mode_vk); }
        else if (key == "KeyHide")          { g_key_hide_vk  = (int)StringToInteger(val); g_key_hide_str  = GetKeyName(g_key_hide_vk); }
        else if (key == "KeyMin")           { g_key_min_vk   = (int)StringToInteger(val); g_key_min_str   = GetKeyName(g_key_min_vk); }
        else if (key == "KeyExec")          { g_key_exec_vk  = (int)StringToInteger(val); g_key_exec_str  = GetKeyName(g_key_exec_vk); }
        else if (key == "KeyPartial")       { g_key_partial_vk = (int)StringToInteger(val); g_key_partial_str = GetKeyName(g_key_partial_vk); }
        else if (key == "KeyAdd")           { g_key_add_vk   = (int)StringToInteger(val); g_key_add_str   = GetKeyName(g_key_add_vk); }
        else if (key == "OpenScale")          g_open_scale = MathMax(0.40, MathMin(1.50, StringToDouble(val)));
        else if (key == "MinScale")           g_minimized_scale = MathMax(0.60, MathMin(1.50, StringToDouble(val)));
        else if (key == "IsMinimized")        g_is_minimized = (StringToInteger(val) != 0);
        else if (key == "IsPending")          g_is_pending = (StringToInteger(val) != 0);
        else if (key == "MinPanelX")          g_min_panel_x = MathMax(0, (int)StringToInteger(val));
        else if (key == "MinPanelY")          g_min_panel_y = MathMax(0, (int)StringToInteger(val));
        else if (key == "PanelX")             g_panel_x = MathMax(0, (int)StringToInteger(val));
        else if (key == "PanelY")             g_panel_y = MathMax(0, (int)StringToInteger(val));
        else if (key == "LinesHidden")        g_lines_hidden = (StringToInteger(val) != 0);
        else if (key == "CandleTimerEnabled") g_candle_timer_enabled = (StringToInteger(val) != 0);
        else if (key == "TimerIsCustom")      g_timer_is_custom = (StringToInteger(val) != 0);
        else if (key == "TimerCustomX")       g_timer_custom_x  = (int)StringToInteger(val);
        else if (key == "TimerCustomY")       g_timer_custom_y  = (int)StringToInteger(val);
        else if (key == "CandleTimerPos")     g_candle_timer_pos = (ENUM_CANDLE_TIMER_POS)StringToInteger(val);
        else if (key == "CandleTimerSize")    g_candle_timer_size = (int)StringToInteger(val);
        else if (key == "ChartShiftEnabled")  g_chart_shift_enabled = (StringToInteger(val) != 0);
        else if (key == "ChartShiftSize")     g_chart_shift_size = StringToDouble(val);
        else if (key == "MaxTradesSession")   g_max_trades_session = MathMax(0, (int)StringToInteger(val));
        else if (key == "MaxLossSession")     g_max_loss_session = MathMax(0.0, StringToDouble(val));
        else if (key == "PwdHash" && val != "") g_pwd_hash = val;
        else if (key == "RiskPwdLocked")      g_risk_pwd_locked = (StringToInteger(val) != 0);
    }

    FileClose(handle);
    return true;
}

//+------------------------------------------------------------------+
//| Salva todas as configuracoes nas Variaveis Globais do Terminal   |
//+------------------------------------------------------------------+
void SaveAllToGlobals(bool force_minimized = true)
{
    double ver = 0;
    if (!GlobalVariableGet("GM_ConfigVersion", ver)) ver = 1.0;
    else ver += 1.0;
    g_last_config_version = ver;

    // Atualiza a versao global para notificar todos os outros graficos
    GlobalVariableSet("GM_ConfigVersion", ver);

    GlobalVariableSet("GM_RiskMode", (double)g_risk_mode);
    GlobalVariableSet("GM_RiskCash", g_risk_cash);
    GlobalVariableSet("GM_RiskPercent", g_risk_percent);
    GlobalVariableSet("GM_PartialPercent", g_partial_percent);
    GlobalVariableSet("GM_AddPercent", g_add_percent);
    GlobalVariableSet("GM_OpenScale", g_open_scale);
    GlobalVariableSet("GM_MinimizedScale", g_minimized_scale);
    if (force_minimized)
        GlobalVariableSet("GM_IsMinimized", 1.0); // Padrao salvo sempre abre minimizado
    GlobalVariableSet("GM_MinPanelX", (double)g_min_panel_x);
    GlobalVariableSet("GM_MinPanelY", (double)g_min_panel_y);
    GlobalVariableSet("GM_CandleTimer", g_candle_timer_enabled ? 1.0 : 0.0);
    GlobalVariableSet("GM_TimerIsCustom", 0.0);
    GlobalVariableSet("GM_TimerCustomX", -1.0);
    GlobalVariableSet("GM_TimerCustomY", -1.0);
    GlobalVariableSet("GM_CandleTimerPos", (double)g_candle_timer_pos);
    GlobalVariableSet("GM_CandleTimerSize", (double)g_candle_timer_size);
    GlobalVariableSet("GM_ChartShiftEnabled", g_chart_shift_enabled ? 1.0 : 0.0);
    GlobalVariableSet("GM_ChartShiftSize", g_chart_shift_size);
    GlobalVariableSet("GM_LinesHidden", g_lines_hidden ? 1.0 : 0.0);
    GlobalVariableSet("GM_IsPending", g_is_pending ? 1.0 : 0.0);
    GlobalVariableSet("GM_KeyEntry", (double)g_key_entry_vk);
    GlobalVariableSet("GM_KeyStop", (double)g_key_stop_vk);
    GlobalVariableSet("GM_KeyMode", (double)g_key_mode_vk);
    GlobalVariableSet("GM_KeyHide", (double)g_key_hide_vk);
    GlobalVariableSet("GM_KeyMin", (double)g_key_min_vk);
    GlobalVariableSet("GM_KeyExec", (double)g_key_exec_vk);
    GlobalVariableSet("GM_KeyPartial", (double)g_key_partial_vk);
    GlobalVariableSet("GM_KeyAdd", (double)g_key_add_vk);
    GlobalVariableSet("GM_PanelX", (double)g_panel_x);
    GlobalVariableSet("GM_PanelY", (double)g_panel_y);
    GlobalVariableSet("GM_MaxTradesSession", (double)g_max_trades_session);
    GlobalVariableSet("GM_MaxLossSession", g_max_loss_session);
    GlobalVariableSet("GM_RiskPwdLocked", g_risk_pwd_locked ? 1.0 : 0.0);
}

//+------------------------------------------------------------------+
//| Carrega todas as configuracoes das Variaveis Globais do Terminal |
//+------------------------------------------------------------------+
bool LoadAllFromGlobals()
{
    double val = 0;
    if (!GlobalVariableGet("GM_ConfigVersion", val)) return false;
    g_last_config_version = val;

    if (GlobalVariableGet("GM_RiskMode", val))       g_risk_mode = ((int)val == 1) ? RISK_PERCENT : RISK_FIXED_USD;
    if (GlobalVariableGet("GM_RiskCash", val))       g_risk_cash = val;
    if (GlobalVariableGet("GM_RiskPercent", val))    g_risk_percent = val;
    if (GlobalVariableGet("GM_PartialPercent", val)) g_partial_percent = val;
    if (GlobalVariableGet("GM_AddPercent", val))     g_add_percent = val;
    if (GlobalVariableGet("GM_OpenScale", val))      g_open_scale = val;
    if (GlobalVariableGet("GM_MinimizedScale", val)) g_minimized_scale = val;
    if (GlobalVariableGet("GM_IsMinimized", val))    g_is_minimized = (val != 0.0);
    if (GlobalVariableGet("GM_MinPanelX", val))      g_min_panel_x = (int)val;
    if (GlobalVariableGet("GM_MinPanelY", val))      g_min_panel_y = (int)val;
    if (GlobalVariableGet("GM_CandleTimer", val))    g_candle_timer_enabled = (val != 0.0);
    if (GlobalVariableGet("GM_TimerIsCustom", val))  g_timer_is_custom = (val != 0.0);
    if (GlobalVariableGet("GM_TimerCustomX", val))   g_timer_custom_x  = (int)val;
    if (GlobalVariableGet("GM_TimerCustomY", val))   g_timer_custom_y  = (int)val;
    if (GlobalVariableGet("GM_CandleTimerPos", val))    g_candle_timer_pos = (ENUM_CANDLE_TIMER_POS)(int)val;
    if (GlobalVariableGet("GM_CandleTimerSize", val))   g_candle_timer_size = (int)val;
    if (GlobalVariableGet("GM_ChartShiftEnabled", val)) g_chart_shift_enabled = (val != 0.0);
    if (GlobalVariableGet("GM_ChartShiftSize", val))    g_chart_shift_size = val;
    if (GlobalVariableGet("GM_LinesHidden", val))    g_lines_hidden = (val != 0.0);
    if (GlobalVariableGet("GM_IsPending", val))      g_is_pending = (val != 0.0);
    if (GlobalVariableGet("GM_KeyEntry", val))       { g_key_entry_vk = (int)val; g_key_entry_str = GetKeyName(g_key_entry_vk); }
    if (GlobalVariableGet("GM_KeyStop", val))        { g_key_stop_vk = (int)val; g_key_stop_str = GetKeyName(g_key_stop_vk); }
    if (GlobalVariableGet("GM_KeyMode", val))        { g_key_mode_vk = (int)val; g_key_mode_str = GetKeyName(g_key_mode_vk); }
    if (GlobalVariableGet("GM_KeyHide", val))        { g_key_hide_vk = (int)val; g_key_hide_str = GetKeyName(g_key_hide_vk); }
    if (GlobalVariableGet("GM_KeyMin", val))         { g_key_min_vk = (int)val; g_key_min_str = GetKeyName(g_key_min_vk); }
    if (GlobalVariableGet("GM_KeyExec", val))        { g_key_exec_vk = (int)val; g_key_exec_str = GetKeyName(g_key_exec_vk); }
    if (GlobalVariableGet("GM_KeyPartial", val))     { g_key_partial_vk = (int)val; g_key_partial_str = GetKeyName(g_key_partial_vk); }
    if (GlobalVariableGet("GM_KeyAdd", val))         { g_key_add_vk = (int)val; g_key_add_str = GetKeyName(g_key_add_vk); }
    if (GlobalVariableGet("GM_PanelX", val))         g_panel_x = (int)val;
    if (GlobalVariableGet("GM_PanelY", val))         g_panel_y = (int)val;
    if (GlobalVariableGet("GM_MaxTradesSession", val)) g_max_trades_session = MathMax(0, (int)val);
    if (GlobalVariableGet("GM_MaxLossSession", val))   g_max_loss_session = MathMax(0.0, val);
    if (GlobalVariableGet("GM_RiskPwdLocked", val))    g_risk_pwd_locked = (val != 0.0);

    if (g_chart_shift_enabled)
    {
        ChartSetInteger(0, CHART_SHIFT, true);
        ChartSetDouble(0, CHART_SHIFT_SIZE, g_chart_shift_size);
    }
    return true;
}

bool RestoreCurrentDefault()
{
    bool restored = false;

    // 1. Carrega primeiro o INI compartilhado (inclui hash de senha e configuracoes salvas)
    if (LoadDefaultIni())
        restored = true;

    // 2. Carrega das variaveis globais do terminal MT5 (sincronizacao instantanea entre graficos)
    if (LoadAllFromGlobals())
        restored = true;

    // 3. Fallback: marcador de objeto local do grafico
    if (!restored && ObjectFind(0, GM_CURRENT_MARKER) >= 0)
    {
        string parts[];
        int count = StringSplit(ObjectGetString(0, GM_CURRENT_MARKER, OBJPROP_TEXT), '|', parts);
        if ((count >= 22) && parts[0] == "88")
        {
            if (_UninitReason != REASON_PARAMETERS)
            {
                g_open_scale = MathMax(0.40, MathMin(1.50, StringToDouble(parts[2])));
                g_minimized_scale = MathMax(0.60, MathMin(1.50, StringToDouble(parts[3])));
                g_is_minimized = (StringToInteger(parts[4]) != 0);
                g_risk_mode = (StringToInteger(parts[5]) == 1) ? RISK_PERCENT : RISK_FIXED_USD;
                g_risk_cash = MathMax(0.0, StringToDouble(parts[6]));
                g_risk_percent = MathMax(0.0, StringToDouble(parts[7]));
                g_partial_percent = MathMax(0.1, MathMin(100.0, StringToDouble(parts[8])));
                g_add_percent = MathMax(1.0, MathMin(50.0, StringToDouble(parts[9])));
                g_key_entry_vk = (int)StringToInteger(parts[10]); g_key_entry_str = GetKeyName(g_key_entry_vk);
                g_key_stop_vk = (int)StringToInteger(parts[11]); g_key_stop_str = GetKeyName(g_key_stop_vk);
                g_key_mode_vk = (int)StringToInteger(parts[12]); g_key_mode_str = GetKeyName(g_key_mode_vk);
                g_key_hide_vk = (int)StringToInteger(parts[13]); g_key_hide_str = GetKeyName(g_key_hide_vk);
                g_key_min_vk = (int)StringToInteger(parts[14]); g_key_min_str = GetKeyName(g_key_min_vk);
                g_key_exec_vk = (int)StringToInteger(parts[15]); g_key_exec_str = GetKeyName(g_key_exec_vk);
                g_key_partial_vk = (int)StringToInteger(parts[16]); g_key_partial_str = GetKeyName(g_key_partial_vk);
                g_key_add_vk = (int)StringToInteger(parts[17]); g_key_add_str = GetKeyName(g_key_add_vk);
                g_panel_x = MathMax(0, (int)MathRound(StringToDouble(parts[18])));
                g_panel_y = MathMax(0, (int)MathRound(StringToDouble(parts[19])));
                g_lines_hidden = (StringToInteger(parts[20]) != 0);
                g_is_pending = (StringToInteger(parts[21]) != 0);
                if (count >= 23) g_candle_timer_enabled = (StringToInteger(parts[22]) != 0);
                if (count >= 26)
                {
                    g_timer_is_custom = (StringToInteger(parts[23]) != 0);
                    g_timer_custom_x  = (int)StringToInteger(parts[24]);
                    g_timer_custom_y  = (int)StringToInteger(parts[25]);
                }
                if (count >= 28)
                {
                    g_min_panel_x = (int)StringToInteger(parts[26]);
                    g_min_panel_y = (int)StringToInteger(parts[27]);
                }
                if (count >= 30)
                {
                    g_candle_timer_pos = (ENUM_CANDLE_TIMER_POS)StringToInteger(parts[28]);
                    g_candle_timer_size = (int)StringToInteger(parts[29]);
                }
                if (count >= 32)
                {
                    g_chart_shift_enabled = (StringToInteger(parts[30]) != 0);
                    g_chart_shift_size = StringToDouble(parts[31]);
                }
                if (count >= 34)
                {
                    g_max_trades_session = MathMax(0, (int)StringToInteger(parts[32]));
                    g_max_loss_session   = MathMax(0.0, StringToDouble(parts[33]));
                }
                if (count >= 36)
                {
                    if (parts[34] != "") g_pwd_hash = parts[34];
                    g_risk_pwd_locked = (StringToInteger(parts[35]) != 0);
                }
            }
            restored = true;
        }
    }

    // 4. Sempre aplica o Cofre de Seguranca (FILE_COMMON) por cima:
    //    Mesmo se tirar e recolocar o EA ou tentar alterar no F7, a senha e os limites travados prevalecem!
    if (LoadSecurityVault())
        restored = true;

    if (g_chart_shift_enabled)
    {
        ChartSetInteger(0, CHART_SHIFT, true);
        ChartSetDouble(0, CHART_SHIFT_SIZE, g_chart_shift_size);
    }

    return restored;
}

bool SaveCurrentDefault()
{
    if (MQLInfoInteger(MQL_TESTER)) return false;
    ResetLastError();

    // Garante que qualquer valor digitado nos campos abertos seja capturado (se destravado)
    CommitPendingPanelEdits();

    // Se ja existe senha cadastrada, ao Salvar Default tambem garante que o cofre seja atualizado e travado
    if (g_pwd_hash != "")
        g_risk_pwd_locked = true;

    // 1. Forca o estado minimizado no grafico atual antes de salvar (posicionado abaixo do nome do ativo X=10, Y=36)
    g_settings_open = false;
    g_is_minimized = true;
    g_min_panel_x = 10;
    g_min_panel_y = 36;

    // 2. Ajusta o triangulo de distanciamento do grafico (Chart Shift) conforme a imagem (~12.7%)
    g_chart_shift_enabled = true;
    g_chart_shift_size = 12.7;
    ChartSetInteger(0, CHART_SHIFT, true);
    ChartSetDouble(0, CHART_SHIFT_SIZE, g_chart_shift_size);

    // 3. Configura o Relogio de Candles para acompanhar a barra estilo B-Clock, tamanho menor
    g_candle_timer_pos = TIMER_POS_FOLLOW_PRICE;
    g_candle_timer_size = 9;
    g_timer_is_custom = false; // Reseta arrasto manual para seguir a barra
    g_timer_custom_x = -1;
    g_timer_custom_y = -1;
    g_timer_selected = false;
    g_timer_dragging = false;

    // 4. Grava no Cofre de Seguranca (FILE_COMMON), nas Variaveis Globais e no INI antes de salvar o template
    SaveSecurityVault();
    SaveAllToGlobals(true);
    SaveDefaultIni();
    WriteCurrentDefaultMarker();

    EvaluateSessionDiscipline(true);
    CreatePanel();
    UpdatePanel();
    DeleteCandleTimer();
    UpdateCandleTimer();
    ChartRedraw(0);

    // 5. Salva template default.tpl para novos graficos abertos (salvo ja minimizado e com shift configurado)
    ResetLastError();
    ChartSaveTemplate(0, "default.tpl");

    // 6. Atualiza e notifica instantaneamente todos os outros graficos abertos
    long current_id = ChartID();
    long chart_id = ChartFirst();
    int count_updated = 0;

    while (chart_id >= 0)
    {
        if (chart_id != current_id)
        {
            // Verifica se o grafico ja tem especificamente o Gerenciamento Master Pessoal rodando
            if (ObjectFind(chart_id, GM_PESSOAL_MARKER) >= 0)
            {
                // Aplica diretamente o Chart Shift em cada grafico aberto
                ChartSetInteger(chart_id, CHART_SHIFT, true);
                ChartSetDouble(chart_id, CHART_SHIFT_SIZE, g_chart_shift_size);

                // Dispara evento customizado para o grafico recarregar Risco, Max Trades, Loss Max e Senha na hora
                EventChartCustom(chart_id, 8888, 0, 0.0, "RELOAD_DEFAULT");
                ChartRedraw(chart_id);
            }
            else
            {
                // O grafico nao tem o Pessoal (ou estava com a versao antiga/alunos): aplica default.tpl para migrar e sincronizar tudo!
                ChartApplyTemplate(chart_id, "default.tpl");
            }
            count_updated++;
        }
        chart_id = ChartNext(chart_id);
    }

    // 7. Log no terminal
    PrintFormat("[Gerenciamento Master Pessoal] Padrao e bloqueios sincronizados com sucesso em %d graficos (default.tpl e Cofre atualizados).", count_updated);
    return true;
}
// END CURRENT CHART DEFAULT
