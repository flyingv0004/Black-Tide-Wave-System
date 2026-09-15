//+------------------------------------------------------------------+
//|                                       BlackTideWaveSystem.mq5    |
//|       Black Tide Wave System — Institutional Context Engine v7.93|
//|    (Refactored Engine Architecture, Profile History & Dashboard) |
//+------------------------------------------------------------------+
#property copyright "BTW System - Institutional Edition"
#property version   "7.93"
#property strict
#property indicator_chart_window
#property indicator_buffers 8
#property indicator_plots   8

// กำหนด Enum และค่าลูกศร Wingdings ที่ขาดหายไป
enum ENUM_ARROW_CHAR
  {
   ARROW_BUY  = 233, // รหัส Wingdings ลูกศรชี้ขึ้น (Buy)
   ARROW_SELL = 234  // รหัส Wingdings ลูกศรชี้ลง (Sell)
  };
  
//--- Input Groups
input group    "=== Auto Detection & Session ==="
input bool     InpAutoBroker         = true;     
input bool     InpAutoTF             = true;     
input string   InpSessionMode        = "AUTO";   
input int      InpCustomHour         = 0;        
input int      InpCustomMin          = 0;        

input group    "=== Manual TF Overrides ==="
input int      InpManIB              = 60;       
input int      InpManLevels          = 200;      
input double   InpManVolMult         = 1.3;      
input double   InpManBodyPct         = 50.0;     
input int      InpManATR             = 14;       

input group    "=== Institutional Filters & Thresholds ==="
input double   InpMinFVG_ATR_Ratio   = 0.3;      // Minimum FVG Gap Size (x ATR)
input int      InpSwingPivot         = 3;        // Pivot Strength for BOS/CHOCH/Sweep
input int      InpPercentileLookback = 100;      // Dynamic Threshold Lookback
input double   InpTopPercentileTarget= 85.0;     // Filter top 15% signals
input double   InpMinScoreCutoff     = 60.0;     // Minimum score cutoff
input int      InpSignalCooldownBar  = 5;        // Cooldown bars
input double   InpMaxSpread_ATR      = 0.35;     // Max Allowed Spread (% of ATR)

input group    "=== Market Structure & EMA Controls ==="
input int      InpFastEMA            = 8;
input int      InpSlowEMA            = 21;
input int      InpEMA200             = 200;
input bool     InpUseEMA200Filter    = false; 
input bool     InpUseMTFBiasFilter   = true;     // Use HTF Bias to filter signals

input group    "=== Phase 1: Market Profile & IB Settings ==="
input bool     InpEnableMP           = true;          // Enable Market Profile Lines
input int      InpIBMinutes          = 60;            // Initial Balance Duration (Minutes)
input double   InpValueAreaPct       = 70.0;          // Value Area Percentage (Classic: 70.0%)
input double   InpVATolerancePct     = 3.0;           // Value Area Volume Target Tolerance % (e.g., 3.0%)
input int      InpProfileBinTicks    = 1;             // Profile Bin Size (Ticks per Bin)
input int      InpMaxProfileBins     = 2000;          // Max Allowed Bins (Replaces Hardcoded Limit)
input int      InpMinBinTicks        = 1;             // Minimum Bin Size in Ticks
input bool     InpEnableAdaptiveBins = true;          // Adaptive Bin Scaling based on Volatility
input color    InpColorVAH           = clrDodgerBlue; // VAH Line Color
input color    InpColorPOC           = clrRed;        // POC Line Color
input color    InpColorVAL           = clrDodgerBlue; // VAL Line Color
input color    InpColorIB            = clrOrange;     // IB High/Low Color

input group    "=== Phase 2: Time-based Market State Settings ==="
input ENUM_TIMEFRAMES InpStateHTF1   = PERIOD_M15;    // First HTF Close Filter for State Confirmation
input ENUM_TIMEFRAMES InpStateHTF2   = PERIOD_H1;     // Second HTF Close Filter for State Confirmation

input group    "=== Phase 3: Acceptance / Rejection Settings ==="
input bool     InpEnablePhase3       = true;          // Enable Phase 3 Acceptance/Rejection Engine
input int      InpAcceptanceBars     = 2;             // Consecutive Bars Required to Confirm Acceptance
input double   InpRejectionWickPct   = 40.0;          // Minimum Wick % of Range for Rejection Signal
input bool     InpUseVolumeConfirm   = true;          // Apply Volume Multiplier to Phase 3 Scoring

input group    "=== Phase 4: Order Flow & Context Aggregator ==="
input bool     InpEnablePhase4       = true;          // Enable Phase 4 Sequence-Based Context Engine
input double   InpP4ScoreBoost       = 1.25;          // Boost Multiplier when P4 Context aligns
input bool     InpP4StrictSequence   = true;          // Require strict Macro -> Zone -> Trigger sequence

input group    "=== Phase 5: Multi-Timeframe Institutional Confluence ==="
input bool     InpEnablePhase5       = true;          // Enable Phase 5 Matrix & Liquidity Confluence
input double   InpP5ScoreBoost       = 1.30;          // Boost Multiplier for Phase 5 Full Confluence Alignment
input bool     InpP5SmartRiskModel   = true;          // Enable ATR-Dynamic Multi-Tier TP/SL Matrix

input group    "=== Display Controls ==="
input bool     InpShowPOC            = true;
input bool     InpShowVAH            = true;
input bool     InpShowVAL            = true;
input bool     InpShowPrior          = true;
input bool     InpShowIB             = true;
input bool     InpShowVWAP           = true;
input bool     InpShowProfile        = true;
input bool     InpShowSignals        = true;
input bool     InpShowS1             = true; 
input bool     InpShowS2             = true; 
input bool     InpShowDash           = true;
input bool     InpShowDoP            = true;

input group    "=== Visual Customization ==="
input color    InpColBuy             = clrLime;          
input color    InpColSell            = clrRed;           
input color    InpColEntry           = clrCyan;          
input color    InpColTP              = clrMediumSpringGreen; 
input color    InpColSL              = clrDeepPink;      
input color    InpColPOC             = clrCyan;
input color    InpColVAH             = clrOrange;
input color    InpColVAL             = clrPurple;
input color    InpColPrior           = clrGray;
input color    InpColVWAP            = clrGold;
input color    InpColIB              = clrDarkSlateGray;

input group    "=== Alerts ==="
input bool     InpAlertS1            = true;
input bool     InpAlertS2            = true;
input bool     InpAlertCross         = true;
input bool     InpPush               = true;
input bool     InpSound              = true;

//+------------------------------------------------------------------+
//| TIME & SESSION CONVERSION ARCHITECTURE (UTC & DST PREPARATION)   |
//| UTC Session Definition -> Broker Server Time Conversion -> Actual |
//| Session Timestamp                                                |
//+------------------------------------------------------------------+
struct SessionDefinition
{
   int asiaHour;
   int londonHour;
   int newYorkHour;
   int overnightHour;
};

// Global Central Definition of UTC Session Start Hours
SessionDefinition g_SessionDef = {0, 8, 13, 21};

//--- Base Data Structures
struct SLevel   { double price; double volume; };
struct SSession { datetime st; double hi,lo,ib_hi,ib_lo; bool ib_set; double vwap,vv,tot; };
struct SPrior   { datetime dt; double hi,lo,op,cl,poc,vah,val; };
struct SSignal  { datetime t; int type; double en,sl,tp1,tp2; double score; };

// Explicit IB State Enumeration
enum ENUM_IB_EXPLICIT_STATE
{
   IB_NOT_STARTED,
   IB_FORMING,
   IB_COMPLETE
};

//--- Developing Profile Node Structure
struct SDevelopingProfileNode
{
   datetime time;
   double   pocPrice;
   double   vahPrice;
   double   valPrice;
   string   timeLabel;
};

//--- Engine Result Structs
struct SessionEngineResult
{
   string                 sessionName;
   datetime               sessionStart;
   double                 sessionHigh;
   double                 sessionLow;
   double                 ibHigh;
   double                 ibLow;
   double                 ibMiddle;
   bool                   ibSet;
   ENUM_IB_EXPLICIT_STATE ibState;
   double                 vwap;
   double                 totalVolume;
   
   void Reset()
   {
      sessionName  = "AUTO";
      sessionStart = 0;
      sessionHigh  = 0;
      sessionLow   = DBL_MAX;
      ibHigh       = 0;
      ibLow        = DBL_MAX;
      ibMiddle     = 0;
      ibSet        = false;
      ibState      = IB_NOT_STARTED;
      vwap         = 0;
      totalVolume  = 0;
   }
};

struct MarketProfileEngineResult
{
   // Current Session Profile
   double VAH;
   double VAL;
   double POC;
   
   // Profile History
   double YesterdayPOC;
   double YesterdayVAH;
   double YesterdayVAL;
   double YesterdayHigh;
   double YesterdayLow;
   bool   HasYesterdayProfile;
   
   // Derived Weekly Range Levels
   double WeeklyTypicalPrice;
   double WeeklyRangeHigh;
   double WeeklyRangeLow;

   // Developing Profile Tracking
   SDevelopingProfileNode developingProfiles[];
   string developingProfileSummary;

   // Relative Price Locations
   bool PriceAboveVAH;
   bool PriceBelowVAL;
   bool PriceInsideVA;
   bool PriceAbovePOC;
   bool PriceBelowPOC;
   bool PriceInsideIB;
   bool PriceAboveIBH;
   bool PriceBelowIBL;

   // Profile Metrics
   int    TotalPriceBins;
   int    PocBinIndex;
   int    VahBinIndex;
   int    ValBinIndex;
   double TotalSessionVolume;
   double ValueAreaVolume;
   double VaVolumePercentage;
   bool   IsMultiPeakProfile;
   double VolumeSkewRatio;

   // Market Profile Integrity Validation Fields
   bool   isPocValid;
   bool   isValueAreaOrderValid;
   bool   isVaVolumeTargetValid;
   bool   isIbValid;
   bool   areBinsValid;
   bool   isSessionDataValid;
   bool   isProfileIntegrityValid;
   string profileIntegrityReason;

   void Reset()
   {
      VAH = 0; VAL = 0; POC = 0;
      YesterdayPOC = 0; YesterdayVAH = 0; YesterdayVAL = 0; YesterdayHigh = 0; YesterdayLow = 0;
      HasYesterdayProfile = false;
      WeeklyTypicalPrice = 0; WeeklyRangeHigh = 0; WeeklyRangeLow = 0;
      
      ArrayFree(developingProfiles);
      developingProfileSummary = "No Developing Profile Data";

      PriceAboveVAH = false; PriceBelowVAL = false;
      PriceInsideVA = false; PriceAbovePOC = false;
      PriceBelowPOC = false; PriceInsideIB  = false;
      PriceAboveIBH = false; PriceBelowIBL = false;

      TotalPriceBins     = 0;
      PocBinIndex        = 0;
      VahBinIndex        = 0;
      ValBinIndex        = 0;
      TotalSessionVolume = 0;
      ValueAreaVolume    = 0;
      VaVolumePercentage = 0;
      IsMultiPeakProfile = false;
      VolumeSkewRatio    = 1.0;

      isPocValid              = false;
      isValueAreaOrderValid  = false;
      isVaVolumeTargetValid  = false;
      isIbValid              = false;
      areBinsValid           = false;
      isSessionDataValid     = false;
      isProfileIntegrityValid= false;
      profileIntegrityReason = "PROFILE UNINITIALIZED";
   }
};

// Phase 2 Enums & Structs
enum ENUM_VA_STATE
{
   VA_INSIDE,      // Price inside Value Area (Balanced)
   VA_ABOVE_VAH,   // Price above VAH (Bullish Imbalance)
   VA_BELOW_VAL    // Price below VAL (Bearish Imbalance)
};

enum ENUM_IB_STATE
{
   IB_INSIDE,      // Inside Initial Balance Range
   IB_BREAK_ABOVE, // IB Extension Up
   IB_BREAK_BELOW  // IB Extension Down
};

enum ENUM_POC_RELATION
{
   POC_NEAR,       // Near POC (Within ATR tolerance)
   POC_ABOVE,      // Above POC
   POC_BELOW       // Below POC
};

enum ENUM_AUCTION_STATE
{
   AUCTION_BALANCED,        // Bracketed / Range Bound
   AUCTION_BULL_ACCEPTANCE, // Confirmed HTF Close above VAH
   AUCTION_BEAR_ACCEPTANCE, // Confirmed HTF Close below VAL
   AUCTION_FAILED_BREAKOUT  // Liquidity Sweep / Fakeout back into VA
};

struct MarketStateEngineResult
{
   ENUM_VA_STATE      vaState;
   ENUM_IB_STATE      ibState;
   ENUM_POC_RELATION  pocRelation;
   ENUM_AUCTION_STATE auctionState;
   
   string locationText;
   double pocDistancePts;
   double pocDistanceAtr;

   // Trading Condition Validation
   bool   tradingValidationPass;
   string tradingValidationReason;

   // Market Profile Integrity Validation
   bool   profileIntegrityPass;
   string profileIntegrityReason;

   // Overall Engine Validation
   bool   validationPass;
   string validationReason;

   bool htf1CloseAboveVAH;
   bool htf1CloseBelowVAL;
   bool htf2CloseAboveVAH;
   bool htf2CloseBelowVAL;

   string stateDescription;

   void Reset()
   {
      vaState      = VA_INSIDE;
      ibState      = IB_INSIDE;
      pocRelation  = POC_NEAR;
      auctionState = AUCTION_BALANCED;
      
      locationText     = "Inside VA";
      pocDistancePts   = 0.0;
      pocDistanceAtr   = 0.0;

      tradingValidationPass   = false;
      tradingValidationReason = "INITIALIZING";

      profileIntegrityPass   = false;
      profileIntegrityReason = "INITIALIZING";

      validationPass   = false;
      validationReason = "INITIALIZING";

      htf1CloseAboveVAH = false;
      htf1CloseBelowVAL = false;
      htf2CloseAboveVAH = false;
      htf2CloseBelowVAL = false;
      stateDescription  = "Balanced Market (Inside VA)";
   }
};

// Phase 3 Enums & Structs
enum ENUM_ACCEPTANCE_STATE
{
   ACC_NEUTRAL,
   ACC_VAH_ACCEPTED,
   ACC_VAH_REJECTED,
   ACC_VAL_ACCEPTED,
   ACC_VAL_REJECTED,
   ACC_IBH_ACCEPTED,
   ACC_IBH_REJECTED,
   ACC_IBL_ACCEPTED,
   ACC_IBL_REJECTED
};

struct Phase3AcceptanceData
{
   ENUM_ACCEPTANCE_STATE currentAccState;
   double vahAcceptanceScore;
   double vahRejectionScore; 
   double valAcceptanceScore;
   double valRejectionScore; 
   double pocBalanceScore;   
   
   string statusSummary;

   void Reset()
   {
      currentAccState     = ACC_NEUTRAL;
      vahAcceptanceScore  = 50.0;
      vahRejectionScore   = 50.0;
      valAcceptanceScore  = 50.0;
      valRejectionScore   = 50.0;
      pocBalanceScore     = 50.0;
      statusSummary       = "Phase 3: Neutral / In-Range";
   }
};

// Phase 4 Enums & Structs
enum ENUM_PHASE4_CONTEXT
{
   P4_NEUTRAL_CONTEXT,
   P4_BULLISH_CONTEXT,
   P4_BEARISH_CONTEXT,
   P4_CONFLICT_SCALP_ONLY
};

struct Phase4ContextData
{
   ENUM_PHASE4_CONTEXT currentContext;
   string              contextSummary;
   bool                macroBull;
   bool                macroBear;
   bool                zoneBullConfirmed;
   bool                zoneBearConfirmed;
   bool                triggerBullConfirmed;
   bool                triggerBearConfirmed;

   void Reset()
   {
      currentContext       = P4_NEUTRAL_CONTEXT;
      contextSummary       = "Phase 4: Neutral / No Sequence Alignment";
      macroBull            = false;
      macroBear            = false;
      zoneBullConfirmed    = false;
      zoneBearConfirmed    = false;
      triggerBullConfirmed = false;
      triggerBearConfirmed = false;
   }
};

// Phase 5 Enums & Structs
enum ENUM_PHASE5_MATRIX_STATE
{
   P5_MATRIX_NEUTRAL,
   P5_MATRIX_STRONG_BULLISH,
   P5_MATRIX_STRONG_BEARISH,
   P5_MATRIX_HIGH_VOLATILITY_CHOP
};

struct Phase5ConfluenceData
{
   ENUM_PHASE5_MATRIX_STATE matrixState;
   string                   matrixSummary;
   bool                     mtfAlignmentBull;
   bool                     mtfAlignmentBear;
   double                   confluenceScoreBoost;
   double                   dynamicTp1Multiplier;
   double                   dynamicTp2Multiplier;

   void Reset()
   {
      matrixState          = P5_MATRIX_NEUTRAL;
      matrixSummary        = "Phase 5: Matrix Initializing...";
      mtfAlignmentBull     = false;
      mtfAlignmentBear     = false;
      confluenceScoreBoost = 1.0;
      dynamicTp1Multiplier = 1.5;
      dynamicTp2Multiplier = 2.5;
   }
};

// Market Structure & Order Block Structs
enum ENUM_MARKET_STATE { STATE_UPTREND, STATE_DOWNTREND, STATE_TRANSITION };

struct SOrderBlock {
   bool valid;
   bool isBullish;
   double top;
   double bottom;
   datetime time;
};

struct SLiquidityMap {
   double asiaHigh;
   double asiaLow;
   double pdh;
   double pdl;
   double eqh;
   double eql;
};

//--- Globals
string   g_broker="Unknown", g_srv="";
int      g_svr_off=0, g_ses_h=0, g_ses_m=0;
int      g_ib=60, g_lvls=200, g_vsma=20, g_atr_p=14;
double   g_vmult=1.3, g_bodyp=50.0, g_atrm=1.0;
SSession g_ses; // Legacy session tracker synchronized with CSessionEngine
SPrior   g_pri;
SSignal  g_sig;

// Decoupled Engine Output Objects
SessionEngineResult        g_SessionRes;
MarketProfileEngineResult  g_ProfileRes;
MarketStateEngineResult    g_StateRes;

Phase3AcceptanceData       g_Phase3Data;  
Phase4ContextData          g_Phase4Data;  
Phase5ConfluenceData       g_Phase5Data;  

// Indicator Buffers
double   g_f[], g_sl[], g_e2[], g_vw[], g_vh[], g_vl[], g_pc[], g_im[];

// Score Caching Buffers
double   g_scoreBufBull[];
double   g_scoreBufBear[];

bool     g_vf, g_bf, g_af, g_all;
int      g_dop;
int      g_hATR_Fast=INVALID_HANDLE, g_hATR_Slow=INVALID_HANDLE;
int      g_hEMA_Fast=INVALID_HANDLE, g_hEMA_Slow=INVALID_HANDLE, g_hEMA_200=INVALID_HANDLE; 
double   g_atr_fast, g_atr_slow, g_volatility_ratio;
string   g_P="BTW_";

// State Machine & Liquidity Globals
ENUM_MARKET_STATE g_marketState = STATE_TRANSITION;
SOrderBlock      g_activeOB;
SLiquidityMap    g_liqMap;

// Dashboard Handles
string   g_mtfN[6]={"1M","5M","15M","30M","1H","4H"};
ENUM_TIMEFRAMES g_mtfT[6]={PERIOD_M1,PERIOD_M5,PERIOD_M15,PERIOD_M30,PERIOD_H1,PERIOD_H4};
int      g_hMTF_Fast[6], g_hMTF_Slow[6], g_hMTF_E200[6];

int      g_lastSignalBar = -999; 

// Forward Declarations
void DetectBroker();
void ApplyTFAdaptive();
bool IsNewDay(datetime bt);
void ResetSession();
void UpdIB(datetime bt,double h,double lo);
void UpdVWAP(int i,const double &o[],const double &h[],const double &l[],const double &c[],const long &tv[]);
void CheckFilters(int i,const double &o[],const double &h[],const double &l[],const double &c[],const long &tv[]);
void CalcDoP(double cp);

//+------------------------------------------------------------------+
//| DECOUPLED SESSION ENGINE (Single Source Of Truth)                |
//+------------------------------------------------------------------+
class CSessionEngine
{
private:
   string                 m_symbol;
   datetime               m_sessionStart;
   double                 m_sessionHigh;
   double                 m_sessionLow;
   double                 m_ibHigh;
   double                 m_ibLow;
   bool                   m_ibSet;
   ENUM_IB_EXPLICIT_STATE m_ibState;
   double                 m_vwap;
   double                 m_totalVolume;
   string                 m_sessionName;
   
   double                 m_cumPriceVol;
   double                 m_cumVol;

public:
   CSessionEngine()
   {
      m_symbol       = _Symbol;
      m_sessionStart = 0;
      m_sessionHigh  = 0;
      m_sessionLow   = DBL_MAX;
      m_ibHigh       = 0;
      m_ibLow        = DBL_MAX;
      m_ibSet        = false;
      m_ibState      = IB_NOT_STARTED;
      m_vwap         = 0;
      m_totalVolume  = 0;
      m_sessionName  = "AUTO";
      m_cumPriceVol  = 0;
      m_cumVol       = 0;
   }

   void Reset()
   {
      m_sessionStart = 0;
      m_sessionHigh  = 0;
      m_sessionLow   = DBL_MAX;
      m_ibHigh       = 0;
      m_ibLow        = DBL_MAX;
      m_ibSet        = false;
      m_ibState      = IB_NOT_STARTED;
      m_vwap         = 0;
      m_totalVolume  = 0;
      m_sessionName  = "AUTO";
      m_cumPriceVol  = 0;
      m_cumVol       = 0;
   }

   void OnNewSession(datetime sessionTime, string sessionName)
   {
      Reset();
      m_sessionStart = sessionTime;
      m_sessionName  = sessionName;
   }

   datetime GetSessionStart() const { return m_sessionStart; }
   string GetSessionName() const { return m_sessionName; }

   datetime CalculateSessionStart(datetime barTime, string &outSessionName)
   {
      MqlDateTime dt;
      TimeToStruct(barTime, dt);

      datetime barDayStart = barTime - (dt.hour * 3600 + dt.min * 60 + dt.sec);

      int asiaStart = (g_SessionDef.asiaHour      + g_svr_off) % 24;
      int lonStart  = (g_SessionDef.londonHour    + g_svr_off) % 24;
      int nyStart   = (g_SessionDef.newYorkHour   + g_svr_off) % 24;
      int overStart = (g_SessionDef.overnightHour + g_svr_off) % 24;

      int sessionStartHour = asiaStart;

      if(InpSessionMode == "AUTO" || InpSessionMode == "MIDNIGHT")
      {
         if(dt.hour >= asiaStart && dt.hour < lonStart)       { outSessionName = "Asia";      sessionStartHour = asiaStart; }
         else if(dt.hour >= lonStart && dt.hour < nyStart)    { outSessionName = "London";    sessionStartHour = lonStart; }
         else if(dt.hour >= nyStart && dt.hour < overStart)   { outSessionName = "New York";  sessionStartHour = nyStart; }
         else                                                 { outSessionName = "Overnight"; sessionStartHour = overStart; }
      }
      else if(InpSessionMode == "LONDON")
      {
         outSessionName = "London";
         sessionStartHour = lonStart;
      }
      else if(InpSessionMode == "NEWYORK")
      {
         outSessionName = "New York";
         sessionStartHour = nyStart;
      }
      else if(InpSessionMode == "TOKYO" || InpSessionMode == "ASIA")
      {
         outSessionName = "Asia";
         sessionStartHour = asiaStart;
      }
      else
      {
         outSessionName = InpSessionMode;
         sessionStartHour = g_ses_h;
      }

      datetime calcSessionStart = barDayStart + (sessionStartHour * 3600);
      if(calcSessionStart > barTime)
      {
         calcSessionStart -= 86400;
      }
      return calcSessionStart;
   }

   void ProcessBar(datetime barTime, double openPrice, double highPrice, double lowPrice, double closePrice, long volume, int ibMinutes)
   {
      if(m_sessionHigh == 0 || highPrice > m_sessionHigh) m_sessionHigh = highPrice;
      if(m_sessionLow == DBL_MAX || lowPrice < m_sessionLow) m_sessionLow = lowPrice;

      // Fix IB Boundary Bug (< instead of <=)
      if(barTime < m_sessionStart + ibMinutes * 60)
      {
         if(highPrice > m_ibHigh || m_ibHigh == 0) m_ibHigh = highPrice;
         if(lowPrice < m_ibLow || m_ibLow == DBL_MAX) m_ibLow = lowPrice;
         m_ibState = IB_FORMING;
         m_ibSet   = false;
      }
      else
      {
         m_ibSet   = true;
         m_ibState = IB_COMPLETE;
      }

      double typPrice = (highPrice + lowPrice + closePrice) / 3.0;
      double barVol   = (double)volume;
      m_cumPriceVol  += typPrice * barVol;
      m_cumVol       += barVol;
      m_totalVolume   = m_cumVol;

      if(m_cumVol > 0)
         m_vwap = m_cumPriceVol / m_cumVol;
      else
         m_vwap = typPrice;
   }

   void PopulateResult(SessionEngineResult &outResult)
   {
      outResult.sessionName  = m_sessionName;
      outResult.sessionStart = m_sessionStart;
      outResult.sessionHigh  = m_sessionHigh;
      outResult.sessionLow   = m_sessionLow;
      outResult.ibHigh       = m_ibHigh;
      outResult.ibLow        = m_ibLow;
      outResult.ibMiddle     = (m_ibHigh != 0 && m_ibLow != DBL_MAX) ? ((m_ibHigh + m_ibLow) / 2.0) : 0;
      outResult.ibSet        = m_ibSet;
      outResult.ibState      = m_ibState;
      outResult.vwap         = m_vwap;
      outResult.totalVolume  = m_totalVolume;
   }
};

//+------------------------------------------------------------------+
//| MARKET PROFILE ENGINE (Single Source Of Truth Engine)            |
//+------------------------------------------------------------------+
class CMarketProfileEngine
{
private:
   string                 m_symbol;
   datetime               m_lastSessionStart;
   datetime               m_lastBarTime;
   double                 m_volArray[];
   double                 m_cachedLowest;
   double                 m_cachedHighest;
   double                 m_cachedProfileBinSize;
   int                    m_cachedPriceBins;
   double                 m_cachedTotalVolume;
   double                 m_lastProcessedBarVol;
   datetime               m_lastSampleTime;
   SDevelopingProfileNode m_developingProfiles[]; // Persistent State for Developing Profiles

   void DrawLevelLine(string name, double price, color clr, ENUM_LINE_STYLE style, int width, string labelText)
   {
      if(price <= 0) return;
      string objName = g_P + "MPLINE_" + name;
      if(ObjectFind(0, objName) < 0)
      {
         ObjectCreate(0, objName, OBJ_HLINE, 0, 0, price);
      }
      ObjectSetDouble(0, objName, OBJPROP_PRICE, price);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, objName, OBJPROP_STYLE, style);
      ObjectSetInteger(0, objName, OBJPROP_WIDTH, width);
      ObjectSetInteger(0, objName, OBJPROP_BACK, true);
      ObjectSetString(0, objName, OBJPROP_TEXT, labelText);
   }

   void CalculateProfileHistory(MarketProfileEngineResult &outData)
   {
      MqlRates d1Rates[];
      ArraySetAsSeries(d1Rates, true);
      if(CopyRates(m_symbol, PERIOD_D1, 1, 1, d1Rates) > 0)
      {
         outData.YesterdayHigh = d1Rates[0].high;
         outData.YesterdayLow  = d1Rates[0].low;
         
         if(g_pri.poc > 0)
         {
            outData.YesterdayPOC        = g_pri.poc;
            outData.YesterdayVAH        = g_pri.vah;
            outData.YesterdayVAL        = g_pri.val;
            outData.HasYesterdayProfile = true;
         }
         else
         {
            outData.YesterdayPOC        = (d1Rates[0].high + d1Rates[0].low + d1Rates[0].close) / 3.0; // Yesterday Typical Price
            outData.YesterdayVAH        = d1Rates[0].high;                                              // Yesterday High
            outData.YesterdayVAL        = d1Rates[0].low;                                               // Yesterday Low
            outData.HasYesterdayProfile = false;
         }
      }

      MqlRates w1Rates[];
      ArraySetAsSeries(w1Rates, true);
      if(CopyRates(m_symbol, PERIOD_W1, 1, 1, w1Rates) > 0)
      {
         outData.WeeklyTypicalPrice = (w1Rates[0].high + w1Rates[0].low + w1Rates[0].close) / 3.0;
         outData.WeeklyRangeHigh    = w1Rates[0].high - (w1Rates[0].high - w1Rates[0].low) * 0.2;
         outData.WeeklyRangeLow     = w1Rates[0].low + (w1Rates[0].high - w1Rates[0].low) * 0.2;
      }
   }

   void UpdateDevelopingProfileNode(datetime sampleTime, MarketProfileEngineResult &outData)
   {
      if(m_cachedPriceBins <= 0) return;

      int curPocBin = 0; double curMaxV = -1.0;
      double tempTotVol = 0.0;
      for(int b = 0; b < m_cachedPriceBins; b++)
      {
         tempTotVol += m_volArray[b];
         if(m_volArray[b] > curMaxV) { curMaxV = m_volArray[b]; curPocBin = b; }
      }

      double devPoc = m_cachedLowest + (curPocBin * m_cachedProfileBinSize);
      double devTargetVol = tempTotVol * (InpValueAreaPct / 100.0);
      double devCurVol = m_volArray[curPocBin];
      int devUp = curPocBin, devDn = curPocBin;

      while(devCurVol < devTargetVol && (devUp < m_cachedPriceBins - 1 || devDn > 0))
      {
         double nUp = (devUp < m_cachedPriceBins - 1) ? m_volArray[devUp + 1] : 0;
         double nDn = (devDn > 0) ? m_volArray[devDn - 1] : 0;
         if(nUp >= nDn && devUp < m_cachedPriceBins - 1) { devUp++; devCurVol += m_volArray[devUp]; }
         else if(devDn > 0) { devDn--; devCurVol += m_volArray[devDn]; }
         else break;
      }

      double devVah = m_cachedLowest + (devUp * m_cachedProfileBinSize);
      double devVal = m_cachedLowest + (devDn * m_cachedProfileBinSize);

      int nodeCount = ArraySize(m_developingProfiles);
      ArrayResize(m_developingProfiles, nodeCount + 1);
      m_developingProfiles[nodeCount].time      = sampleTime;
      m_developingProfiles[nodeCount].pocPrice  = devPoc;
      m_developingProfiles[nodeCount].vahPrice  = devVah;
      m_developingProfiles[nodeCount].valPrice  = devVal;
      m_developingProfiles[nodeCount].timeLabel = TimeToString(sampleTime, TIME_MINUTES);

      m_lastSampleTime = sampleTime;
   }

public:
   CMarketProfileEngine()
   {
      m_symbol               = _Symbol;
      m_lastSessionStart     = 0;
      m_lastBarTime          = 0;
      m_cachedLowest         = 0;
      m_cachedHighest        = 0;
      m_cachedProfileBinSize = 0;
      m_cachedPriceBins      = 0;
      m_cachedTotalVolume    = 0;
      m_lastProcessedBarVol  = 0;
      m_lastSampleTime       = 0;
      ArrayFree(m_developingProfiles);
   }
   
   void Update(const SessionEngineResult &sessionInput, MarketProfileEngineResult &outData, double currentAtr = 0.0, datetime sessionEnd = 0)
   {
      if(!InpEnableMP) return;
      outData.Reset();
      
      CalculateProfileHistory(outData);

      datetime sessionStart = (sessionInput.sessionStart > 0) ? sessionInput.sessionStart : iTime(m_symbol, PERIOD_D1, 0);
      int startBar = iBarShift(m_symbol, PERIOD_M1, sessionStart);
      if(startBar < 0) return;
      
      int endBar = 0;
      if(sessionEnd > 0)
      {
         endBar = iBarShift(m_symbol, PERIOD_M1, sessionEnd);
         if(endBar < 0) endBar = 0;
      }
      
      int totalBars = startBar - endBar + 1;
      if(totalBars <= 0) return;
      
      int hIdx = iHighest(m_symbol, PERIOD_M1, MODE_HIGH, totalBars, endBar);
      int lIdx = iLowest(m_symbol, PERIOD_M1, MODE_LOW, totalBars, endBar);
      if(hIdx < 0 || lIdx < 0) return;

      double highest = iHigh(m_symbol, PERIOD_M1, hIdx);
      double lowest  = iLow(m_symbol, PERIOD_M1, lIdx);
      
      if(highest <= lowest) return;

      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      if(CopyRates(m_symbol, PERIOD_M1, endBar, totalBars, rates) <= 0) return;

      bool needFullRebuild = (sessionInput.sessionStart != m_lastSessionStart) || 
                             (m_lastSessionStart == 0) || 
                             (highest > m_cachedHighest) || 
                             (lowest < m_cachedLowest) || 
                             (m_cachedPriceBins <= 0) ||
                             (sessionEnd > 0);

      if(needFullRebuild)
      {
         m_lastSessionStart = sessionInput.sessionStart;
         m_cachedHighest    = highest;
         m_cachedLowest     = lowest;
         
         double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
         if(tickSize <= 0) tickSize = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
         if(tickSize <= 0) tickSize = 0.00001;
         
         int ticksPerBin = MathMax(InpMinBinTicks, InpProfileBinTicks);
         double minBinSize = tickSize * ticksPerBin;
         double range = highest - lowest;

         int maxAllowedBins = (InpMaxProfileBins > 0) ? InpMaxProfileBins : 2000;
         m_cachedProfileBinSize = minBinSize;

         if(InpEnableAdaptiveBins)
         {
            double rawBins = range / minBinSize;
            if(rawBins > maxAllowedBins)
            {
               m_cachedProfileBinSize = range / maxAllowedBins;
            }
         }

         m_cachedPriceBins = (int)(range / m_cachedProfileBinSize) + 1;
         if(m_cachedPriceBins > maxAllowedBins)
         {
            m_cachedPriceBins = maxAllowedBins;
            m_cachedProfileBinSize = range / m_cachedPriceBins;
         }
         if(m_cachedPriceBins < 1) m_cachedPriceBins = 1;
         
         ArrayResize(m_volArray, m_cachedPriceBins);
         ArrayInitialize(m_volArray, 0.0);
         m_cachedTotalVolume = 0.0;
         m_lastSampleTime = 0;
         ArrayFree(m_developingProfiles);

         for(int i = totalBars - 1; i >= 0; i--)
         {
            double barVol = (double)(rates[i].real_volume > 0 ? rates[i].real_volume : rates[i].tick_volume);
            m_cachedTotalVolume += barVol;
            
            int lowBin  = (int)((rates[i].low - m_cachedLowest) / m_cachedProfileBinSize);
            int highBin = (int)((rates[i].high - m_cachedLowest) / m_cachedProfileBinSize);
            
            lowBin  = MathMax(0, MathMin(m_cachedPriceBins - 1, lowBin));
            highBin = MathMax(0, MathMin(m_cachedPriceBins - 1, highBin));
            
            int rangeBins = (highBin - lowBin) + 1;
            double volPerBin = barVol / rangeBins;
            
            for(int b = lowBin; b <= highBin; b++)
            {
               m_volArray[b] += volPerBin;
            }

            MqlDateTime barDt;
            TimeToStruct(rates[i].time, barDt);
            if((barDt.min == 0 || barDt.min == 30) && rates[i].time != m_lastSampleTime)
            {
               UpdateDevelopingProfileNode(rates[i].time, outData);
            }
         }

         m_lastBarTime = rates[0].time;
         m_lastProcessedBarVol = (double)(rates[0].real_volume > 0 ? rates[0].real_volume : rates[0].tick_volume);
      }
      else
      {
         double currentBarVol = (double)(rates[0].real_volume > 0 ? rates[0].real_volume : rates[0].tick_volume);
         double volDelta = 0.0;

         if(rates[0].time == m_lastBarTime)
         {
            volDelta = currentBarVol - m_lastProcessedBarVol;
         }
         else
         {
            volDelta = currentBarVol;
            m_lastBarTime = rates[0].time;
         }

         if(volDelta > 0)
         {
            m_cachedTotalVolume += volDelta;
            m_lastProcessedBarVol = currentBarVol;

            int lowBin  = (int)((rates[0].low - m_cachedLowest) / m_cachedProfileBinSize);
            int highBin = (int)((rates[0].high - m_cachedLowest) / m_cachedProfileBinSize);
            
            lowBin  = MathMax(0, MathMin(m_cachedPriceBins - 1, lowBin));
            highBin = MathMax(0, MathMin(m_cachedPriceBins - 1, highBin));
            
            int rangeBins = (highBin - lowBin) + 1;
            double volPerBin = volDelta / rangeBins;
            
            for(int b = lowBin; b <= highBin; b++)
            {
               m_volArray[b] += volPerBin;
            }
         }

         MqlDateTime barDt;
         TimeToStruct(rates[0].time, barDt);
         if((barDt.min == 0 || barDt.min == 30) && rates[0].time != m_lastSampleTime)
         {
            UpdateDevelopingProfileNode(rates[0].time, outData);
         }
      }

      int totalDevNodes = ArraySize(m_developingProfiles);
      ArrayResize(outData.developingProfiles, totalDevNodes);
      outData.developingProfileSummary = "";
      for(int k = 0; k < totalDevNodes; k++)
      {
         outData.developingProfiles[k] = m_developingProfiles[k];
         if(outData.developingProfileSummary != "") outData.developingProfileSummary += " | ";
         outData.developingProfileSummary += m_developingProfiles[k].timeLabel + 
                                             " P:" + DoubleToString(m_developingProfiles[k].pocPrice, _Digits) + 
                                             " VAH:" + DoubleToString(m_developingProfiles[k].vahPrice, _Digits) + 
                                             " VAL:" + DoubleToString(m_developingProfiles[k].valPrice, _Digits);
      }
      if(totalDevNodes == 0) outData.developingProfileSummary = "No Developing Profile Data";
      
      int pocIdx = 0;
      double maxVol = -1.0;
      for(int b = 0; b < m_cachedPriceBins; b++)
      {
         if(m_volArray[b] > maxVol)
         {
            maxVol = m_volArray[b];
            pocIdx = b;
         }
      }
      
      double targetVol = m_cachedTotalVolume * (InpValueAreaPct / 100.0);
      double currentVol = m_volArray[pocIdx];
      
      int upIdx = pocIdx;
      int dnIdx = pocIdx;
      
      while(currentVol < targetVol && (upIdx < m_cachedPriceBins - 1 || dnIdx > 0))
      {
         double nextUpVol = (upIdx < m_cachedPriceBins - 1) ? m_volArray[upIdx + 1] : 0;
         double nextDnVol = (dnIdx > 0) ? m_volArray[dnIdx - 1] : 0;
         
         if(nextUpVol >= nextDnVol && upIdx < m_cachedPriceBins - 1)
         {
            upIdx++;
            currentVol += m_volArray[upIdx];
         }
         else if(dnIdx > 0)
         {
            dnIdx--;
            currentVol += m_volArray[dnIdx];
         }
         else break;
      }
      
      outData.POC = m_cachedLowest + (pocIdx * m_cachedProfileBinSize);
      outData.VAH = m_cachedLowest + (upIdx * m_cachedProfileBinSize);
      outData.VAL = m_cachedLowest + (dnIdx * m_cachedProfileBinSize);

      double currentPrice = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      outData.PriceAboveVAH = (currentPrice > outData.VAH);
      outData.PriceBelowVAL = (currentPrice < outData.VAL);
      outData.PriceInsideVA = (currentPrice >= outData.VAL && currentPrice <= outData.VAH);
      outData.PriceAbovePOC = (currentPrice > outData.POC);
      outData.PriceBelowPOC = (currentPrice < outData.POC);
      outData.PriceInsideIB  = (currentPrice >= sessionInput.ibLow && currentPrice <= sessionInput.ibHigh);
      outData.PriceAboveIBH = (currentPrice > sessionInput.ibHigh);
      outData.PriceBelowIBL = (currentPrice < sessionInput.ibLow);

      outData.TotalPriceBins     = m_cachedPriceBins;
      outData.PocBinIndex        = pocIdx;
      outData.VahBinIndex        = upIdx;
      outData.ValBinIndex        = dnIdx;
      outData.TotalSessionVolume = m_cachedTotalVolume;
      outData.ValueAreaVolume    = currentVol;
      outData.VaVolumePercentage = (m_cachedTotalVolume > 0) ? (currentVol / m_cachedTotalVolume * 100.0) : 0.0;

      outData.isPocValid            = (outData.POC > 0);
      outData.isValueAreaOrderValid= (outData.VAL > 0 && outData.VAL <= outData.POC && outData.POC <= outData.VAH);
      outData.isVaVolumeTargetValid= (outData.ValueAreaVolume > 0 && MathAbs(outData.VaVolumePercentage - InpValueAreaPct) <= InpVATolerancePct);
      outData.isIbValid            = (sessionInput.ibHigh >= sessionInput.ibLow && sessionInput.ibLow > 0);
      outData.areBinsValid         = (outData.TotalPriceBins > 0);
      outData.isSessionDataValid   = (outData.TotalSessionVolume > 0 && sessionInput.sessionStart > 0);

      if(!outData.isPocValid)             outData.profileIntegrityReason = "INVALID POC";
      else if(!outData.isValueAreaOrderValid) outData.profileIntegrityReason = "VA ORDER ERROR (VAL > POC or POC > VAH)";
      else if(!outData.isVaVolumeTargetValid) outData.profileIntegrityReason = "VA VOL TARGET MISMATCH";
      else if(!outData.isIbValid)            outData.profileIntegrityReason = "INVALID IB RANGE";
      else if(!outData.areBinsValid)         outData.profileIntegrityReason = "INVALID BINS";
      else if(!outData.isSessionDataValid)   outData.profileIntegrityReason = "INVALID SESSION DATA";
      else {
         outData.isProfileIntegrityValid = true;
         outData.profileIntegrityReason = "PROFILE OK";
      }

      if(InpShowProfile)
      {
         DrawLevelLine("VAH", outData.VAH, InpColorVAH, STYLE_SOLID, 2, "MP VAH " + DoubleToString(outData.VAH, _Digits));
         DrawLevelLine("POC", outData.POC, InpColorPOC, STYLE_SOLID, 2, "MP POC " + DoubleToString(outData.POC, _Digits));
         DrawLevelLine("VAL", outData.VAL, InpColorVAL, STYLE_SOLID, 2, "MP VAL " + DoubleToString(outData.VAL, _Digits));
         DrawLevelLine("IBH", sessionInput.ibHigh, InpColorIB, STYLE_DOT, 1, "MP IBH " + DoubleToString(sessionInput.ibHigh, _Digits));
         DrawLevelLine("IBL", sessionInput.ibLow, InpColorIB, STYLE_DOT, 1, "MP IBL " + DoubleToString(sessionInput.ibLow, _Digits));
      }
      else
      {
         CleanUp();
      }
   }
   
   void CleanUp()
   {
      ObjectsDeleteAll(0, g_P + "MPLINE_");
   }
};

//+------------------------------------------------------------------+
//| MARKET STATE ENGINE                                              |
//+------------------------------------------------------------------+
class CMarketStateEngine
{
private:
   string m_symbol;

public:
   CMarketStateEngine() { m_symbol = _Symbol; }

   void AnalyzeState(const MarketProfileEngineResult &mp, const double closePrice, const double highPrice, const double lowPrice, double atr, MarketStateEngineResult &outState)
   {
      outState.Reset();
      if(mp.VAH <= 0 || mp.VAL <= 0) return;

      if(closePrice > mp.VAH)
      {
         outState.vaState = VA_ABOVE_VAH;
         outState.locationText = "Above VAH";
      }
      else if(closePrice < mp.VAL)
      {
         outState.vaState = VA_BELOW_VAL;
         outState.locationText = "Below VAL";
      }
      else
      {
         outState.vaState = VA_INSIDE;
         outState.locationText = "Inside VA";
      }

      if(mp.PriceInsideIB) outState.locationText += " (Inside IB)";

      double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      if(point <= 0) point = 0.00001;

      outState.pocDistancePts = MathAbs(closePrice - mp.POC) / point;
      outState.pocDistanceAtr = (atr > 0) ? (MathAbs(closePrice - mp.POC) / atr) : 0.0;

      bool isSpreadOk = (atr > 0) ? ((double)SymbolInfoInteger(m_symbol, SYMBOL_SPREAD) * point <= atr * InpMaxSpread_ATR) : true;
      bool hasVolume  = (mp.TotalSessionVolume > 0);
      bool isAtrOk    = (atr > 0);

      if(!isAtrOk)            outState.tradingValidationReason = "LOW ATR";
      else if(!isSpreadOk)    outState.tradingValidationReason = "HIGH SPREAD";
      else if(!hasVolume)     outState.tradingValidationReason = "LOW VOLUME";
      else {
         outState.tradingValidationPass   = true;
         outState.tradingValidationReason = "TRADING OK";
      }

      outState.profileIntegrityPass   = mp.isProfileIntegrityValid;
      outState.profileIntegrityReason = mp.profileIntegrityReason;

      if(outState.tradingValidationPass && outState.profileIntegrityPass)
      {
         outState.validationPass   = true;
         outState.validationReason = "PASS";
      }
      else
      {
         outState.validationPass   = false;
         if(!outState.profileIntegrityPass)
            outState.validationReason = "PROFILE: " + outState.profileIntegrityReason;
         else
            outState.validationReason = outState.tradingValidationReason;
      }

      double pocTol = (atr > 0) ? (atr * 0.25) : (_Point * 20);
      if(MathAbs(closePrice - mp.POC) <= pocTol)
         outState.pocRelation = POC_NEAR;
      else if(closePrice > mp.POC)
         outState.pocRelation = POC_ABOVE;
      else
         outState.pocRelation = POC_BELOW;

      double htf1Close = iClose(m_symbol, InpStateHTF1, 1);
      double htf2Close = iClose(m_symbol, InpStateHTF2, 1);

      outState.htf1CloseAboveVAH = (htf1Close > mp.VAH);
      outState.htf1CloseBelowVAL = (htf1Close < mp.VAL);
      outState.htf2CloseAboveVAH = (htf2Close > mp.VAH);
      outState.htf2CloseBelowVAL = (htf2Close < mp.VAL);

      bool htfConfirmedBull = (outState.htf1CloseAboveVAH || outState.htf2CloseAboveVAH);
      bool htfConfirmedBear = (outState.htf1CloseBelowVAL || outState.htf2CloseBelowVAL);

      if(outState.vaState == VA_ABOVE_VAH)
      {
         if(htfConfirmedBull)
         {
            outState.auctionState = AUCTION_BULL_ACCEPTANCE;
            outState.stateDescription = "Bullish Imbalance (Confirmed HTF Close > VAH)";
         }
         else
         {
            outState.auctionState = AUCTION_BALANCED;
            outState.stateDescription = "Unconfirmed Breakout > VAH (Waiting HTF Close)";
         }
      }
      else if(outState.vaState == VA_BELOW_VAL)
      {
         if(htfConfirmedBear)
         {
            outState.auctionState = AUCTION_BEAR_ACCEPTANCE;
            outState.stateDescription = "Bearish Imbalance (Confirmed HTF Close < VAL)";
         }
         else
         {
            outState.auctionState = AUCTION_BALANCED;
            outState.stateDescription = "Unconfirmed Breakout < VAL (Waiting HTF Close)";
         }
      }
      else
      {
         if(highPrice > mp.VAH && closePrice <= mp.VAH)
         {
            outState.auctionState = AUCTION_FAILED_BREAKOUT;
            outState.stateDescription = "VAH Sweep Rejection (Bearish Reversion)";
         }
         else if(lowPrice < mp.VAL && closePrice >= mp.VAL)
         {
            outState.auctionState = AUCTION_FAILED_BREAKOUT;
            outState.stateDescription = "VAL Sweep Rejection (Bullish Reversion)";
         }
         else
         {
            outState.auctionState = AUCTION_BALANCED;
            outState.stateDescription = "Balanced Market (Rotating inside VA)";
         }
      }
   }
};

// Phase 3 Engine Class
class CPhase3Engine
{
private:
   string m_symbol;

public:
   CPhase3Engine() { m_symbol = _Symbol; }

   void EvaluateAcceptanceRejection(int idx, const MarketProfileEngineResult &mp, const double &o[], const double &h[], const double &l[], const double &c[], const long &tv[], Phase3AcceptanceData &outP3)
   {
      outP3.Reset();
      if(!InpEnablePhase3 || idx < InpAcceptanceBars + 2 || mp.VAH <= 0 || mp.VAL <= 0) return;

      double range = h[idx] - l[idx];
      if(range <= 0) range = _Point;

      double volMult = 1.0;
      if(InpUseVolumeConfirm)
      {
         double vs = 0;
         int cnt = MathMin(20, idx + 1);
         for(int j = 0; j < cnt; j++) vs += (double)tv[idx - j];
         vs /= cnt;
         if(vs > 0) volMult = MathMax(0.5, MathMin(1.5, ((double)tv[idx] / vs)));
      }

      int vahClosesAbove = 0, valClosesBelow = 0;
      for(int k = 0; k < InpAcceptanceBars; k++)
      {
         if(c[idx - k] > mp.VAH) vahClosesAbove++;
         if(c[idx - k] < mp.VAL) valClosesBelow++;
      }

      double upperWick = h[idx] - MathMax(o[idx], c[idx]);
      double lowerWick = MathMin(o[idx], c[idx]) - l[idx];

      bool vahWickReject = (h[idx] >= mp.VAH && c[idx] <= mp.VAH && (upperWick / range * 100.0) >= InpRejectionWickPct);
      bool valWickReject = (l[idx] <= mp.VAL && c[idx] >= mp.VAL && (lowerWick / range * 100.0) >= InpRejectionWickPct);

      if(vahClosesAbove == InpAcceptanceBars)
      {
         outP3.vahAcceptanceScore = MathMin(100.0, 75.0 * volMult);
         outP3.vahRejectionScore  = 100.0 - outP3.vahAcceptanceScore;
         outP3.currentAccState    = ACC_VAH_ACCEPTED;
         outP3.statusSummary      = "VAH ACCEPTED (" + DoubleToString(outP3.vahAcceptanceScore, 0) + "%)";
      }
      else if(vahWickReject)
      {
         outP3.vahRejectionScore  = MathMin(100.0, 80.0 * volMult);
         outP3.vahAcceptanceScore = 100.0 - outP3.vahRejectionScore;
         outP3.currentAccState    = ACC_VAH_REJECTED;
         outP3.statusSummary      = "VAH REJECTED (" + DoubleToString(outP3.vahRejectionScore, 0) + "%)";
      }

      if(valClosesBelow == InpAcceptanceBars)
      {
         outP3.valAcceptanceScore = MathMin(100.0, 75.0 * volMult);
         outP3.valRejectionScore  = 100.0 - outP3.valAcceptanceScore;
         outP3.currentAccState    = ACC_VAL_ACCEPTED;
         outP3.statusSummary      = "VAL ACCEPTED (" + DoubleToString(outP3.valAcceptanceScore, 0) + "%)";
      }
      else if(valWickReject)
      {
         outP3.valRejectionScore  = MathMin(100.0, 80.0 * volMult);
         outP3.valAcceptanceScore = 100.0 - outP3.valRejectionScore;
         outP3.currentAccState    = ACC_VAL_REJECTED;
         outP3.statusSummary      = "VAL REJECTED (" + DoubleToString(outP3.valRejectionScore, 0) + "%)";
      }

      if(c[idx] >= mp.VAL && c[idx] <= mp.VAH)
      {
         outP3.pocBalanceScore = 50.0;
         if(!vahWickReject && !valWickReject)
         {
            outP3.currentAccState = ACC_NEUTRAL;
            outP3.statusSummary   = "Inside VA - Balanced (50%/50%)";
         }
      }
   }
};

// Phase 4 Engine Class
class CPhase4Engine
{
private:
   string m_symbol;

public:
   CPhase4Engine() { m_symbol = _Symbol; }

   void EvaluateSequenceContext(int idx, const MarketProfileEngineResult &mp, const MarketStateEngineResult &p2, const Phase3AcceptanceData &p3, const double &o[], const double &h[], const double &l[], const double &c[], const long &tv[], const double &ema200[], Phase4ContextData &outP4)
   {
      outP4.Reset();
      if(!InpEnablePhase4 || idx < 5) return;

      double currentPrice = c[idx];

      outP4.macroBull = (currentPrice > ema200[idx]);
      outP4.macroBear = (currentPrice < ema200[idx]);

      bool priceAboveVAH = (currentPrice > mp.VAH && mp.VAH > 0);
      bool priceBelowVAL = (currentPrice < mp.VAL && mp.VAL > 0);
      bool vahReject     = (p3.currentAccState == ACC_VAH_REJECTED);
      bool valReject     = (p3.currentAccState == ACC_VAL_REJECTED);

      outP4.zoneBullConfirmed = (priceAboveVAH || valReject || p2.auctionState == AUCTION_BULL_ACCEPTANCE);
      outP4.zoneBearConfirmed = (priceBelowVAL || vahReject || p2.auctionState == AUCTION_BEAR_ACCEPTANCE);

      bool ibBreakUp   = (p2.ibState == IB_BREAK_ABOVE);
      bool ibBreakDown = (p2.ibState == IB_BREAK_BELOW);

      double vs = 0; int cnt = MathMin(20, idx + 1);
      for(int j = 0; j < cnt; j++) vs += (double)tv[idx - j];
      vs /= cnt;
      bool volConfirm = (vs > 0) ? ((double)tv[idx] > vs * 1.2) : true;

      outP4.triggerBullConfirmed = (ibBreakUp && volConfirm);
      outP4.triggerBearConfirmed = (ibBreakDown && volConfirm);

      if(InpP4StrictSequence)
      {
         if(outP4.macroBull && outP4.zoneBullConfirmed && outP4.triggerBullConfirmed)
         {
            outP4.currentContext = P4_BULLISH_CONTEXT;
            outP4.contextSummary = "STRICT BULLISH CONTEXT (Macro -> Zone -> Trigger)";
         }
         else if(outP4.macroBear && outP4.zoneBearConfirmed && outP4.triggerBearConfirmed)
         {
            outP4.currentContext = P4_BEARISH_CONTEXT;
            outP4.contextSummary = "STRICT BEARISH CONTEXT (Macro -> Zone -> Trigger)";
         }
         else if((outP4.macroBull && outP4.zoneBearConfirmed) || (outP4.macroBear && outP4.zoneBullConfirmed))
         {
            outP4.currentContext = P4_CONFLICT_SCALP_ONLY;
            outP4.contextSummary = "CONTEXT CONFLICT (Macro vs Zone - Scalp Mode)";
         }
         else
         {
            outP4.currentContext = P4_NEUTRAL_CONTEXT;
            outP4.contextSummary = "NEUTRAL CONTEXT (Sequence Incomplete)";
         }
      }
      else
      {
         if(outP4.macroBull && outP4.zoneBullConfirmed)
         {
            outP4.currentContext = P4_BULLISH_CONTEXT;
            outP4.contextSummary = "BULLISH CONTEXT (EMA200 Bull + VAH/Acceptance)";
         }
         else if(outP4.macroBear && outP4.zoneBearConfirmed)
         {
            outP4.currentContext = P4_BEARISH_CONTEXT;
            outP4.contextSummary = "BEARISH CONTEXT (EMA200 Bear + Rejection/VAL)";
         }
         else if((outP4.macroBull && outP4.zoneBearConfirmed) || (outP4.macroBear && outP4.zoneBullConfirmed))
         {
            outP4.currentContext = P4_CONFLICT_SCALP_ONLY;
            outP4.contextSummary = "CONTEXT CONFLICT (Macro vs Zone - Scalp Mode)";
         }
         else
         {
            outP4.currentContext = P4_NEUTRAL_CONTEXT;
            outP4.contextSummary = "NEUTRAL CONTEXT (Range / Awaiting Breakout)";
         }
      }
   }
};

// Phase 5 Engine Class
class CPhase5Engine
{
private:
   string m_symbol;

public:
   CPhase5Engine() { m_symbol = _Symbol; }

   void EvaluatePhase5Confluence(int idx, const Phase4ContextData &p4, const MarketStateEngineResult &p2, const double &atr, Phase5ConfluenceData &outP5)
   {
      outP5.Reset();
      if(!InpEnablePhase5) return;

      int bullTfCount = 0;
      int bearTfCount = 0;

      for(int k = 2; k < 5; k++) 
      {
         double ef[], es[];
         ArraySetAsSeries(ef, true); ArraySetAsSeries(es, true);
         if(g_hMTF_Fast[k] != INVALID_HANDLE && g_hMTF_Slow[k] != INVALID_HANDLE)
         {
            if(CopyBuffer(g_hMTF_Fast[k], 0, 0, 1, ef) > 0 && CopyBuffer(g_hMTF_Slow[k], 0, 0, 1, es) > 0)
            {
               if(ef[0] > es[0]) bullTfCount++;
               else if(ef[0] < es[0]) bearTfCount++;
            }
         }
      }

      outP5.mtfAlignmentBull = (bullTfCount >= 2 && p4.currentContext == P4_BULLISH_CONTEXT);
      outP5.mtfAlignmentBear = (bearTfCount >= 2 && p4.currentContext == P4_BEARISH_CONTEXT);

      if(outP5.mtfAlignmentBull && p2.auctionState == AUCTION_BULL_ACCEPTANCE)
      {
         outP5.matrixState = P5_MATRIX_STRONG_BULLISH;
         outP5.matrixSummary = "P5 MATRIX: STACKED BULLISH CONFLUENCE (Tier-1 Institutional)";
         outP5.confluenceScoreBoost = InpP5ScoreBoost;
         
         if(InpP5SmartRiskModel)
         {
            outP5.dynamicTp1Multiplier = 2.0;
            outP5.dynamicTp2Multiplier = 3.5;
         }
         else
         {
            outP5.dynamicTp1Multiplier = 1.5;
            outP5.dynamicTp2Multiplier = 2.5;
         }
      }
      else if(outP5.mtfAlignmentBear && p2.auctionState == AUCTION_BEAR_ACCEPTANCE)
      {
         outP5.matrixState = P5_MATRIX_STRONG_BEARISH;
         outP5.matrixSummary = "P5 MATRIX: STACKED BEARISH CONFLUENCE (Tier-1 Institutional)";
         outP5.confluenceScoreBoost = InpP5ScoreBoost;
         
         if(InpP5SmartRiskModel)
         {
            outP5.dynamicTp1Multiplier = 2.0;
            outP5.dynamicTp2Multiplier = 3.5;
         }
         else
         {
            outP5.dynamicTp1Multiplier = 1.5;
            outP5.dynamicTp2Multiplier = 2.5;
         }
      }
      else if(atr > 0 && g_volatility_ratio > 1.8)
      {
         outP5.matrixState = P5_MATRIX_HIGH_VOLATILITY_CHOP;
         outP5.matrixSummary = "P5 MATRIX: HIGH VOLATILITY CHOP (Defensive Risk Reduction)";
         outP5.confluenceScoreBoost = 0.90;
         
         if(InpP5SmartRiskModel)
         {
            outP5.dynamicTp1Multiplier = 1.2;
            outP5.dynamicTp2Multiplier = 2.0;
         }
         else
         {
            outP5.dynamicTp1Multiplier = 1.5;
            outP5.dynamicTp2Multiplier = 2.5;
         }
      }
      else
      {
         outP5.matrixState = P5_MATRIX_NEUTRAL;
         outP5.matrixSummary = "P5 MATRIX: Standard Institutional Flow Matrix";
         outP5.confluenceScoreBoost = 1.0;
         outP5.dynamicTp1Multiplier = 1.5;
         outP5.dynamicTp2Multiplier = 2.5;
      }
   }
};

// Instantiating Engines
CSessionEngine       g_SessionEngine;
CMarketProfileEngine g_MPEngine;
CMarketStateEngine   g_StateEngine;
CPhase3Engine        g_Phase3Engine;
CPhase4Engine        g_Phase4Engine;
CPhase5Engine        g_Phase5Engine;

// Institutional SMC Engine Core Functions
void UpdateMarketStructureState(int i, const double &h[], const double &l[], const double &c[]);
bool DetectDisplacement(int i, const double &o[], const double &h[], const double &l[], const double &c[], bool isBullish);
bool DetectTrueSwingBOS(int i, const double &h[], const double &l[], const double &c[], bool isBullish);
bool DetectTrueCHOCH(int i, const double &h[], const double &l[], const double &c[], bool isBullish);
bool DetectInstitutionalFVG(int i, const double &o[], const double &h[], const double &l[], const double &c[], bool isBullish);
void UpdateOrderBlock(int i, const double &o[], const double &h[], const double &l[], const double &c[]);
void UpdateLiquidityMap(int i, const double &h[], const double &l[], const datetime &t[]);
bool DetectAdvancedLiquiditySweep(int i, const double &h[], const double &l[], const double &c[], bool isBullish);
bool DetectSwingLiquiditySweep(int i, const double &h[], const double &l[], const double &c[], bool isBullish);

double CalculateInstitutionalScore(int i, const double &o[], const double &h[], const double &l[], const double &c[], const long &tv[], bool isBullish);
double GetDynamicPercentileThreshold(int currentIndex);

void CheckSignals(int i, const double &o[], const double &h[], const double &l[], const double &c[], const long &tv[], const datetime &t[], bool isHistory);
void DrawSig(int i,double p,double h,double l,int type,const datetime &t[], double score, bool isHistory);
void DrawTargetLine(string name, datetime st, datetime et, double price, color clr, int style, int width, string label);
void ClearTargetLines();
void TriggerAlert(string msg);
void SavePrior();
void LoadPrior();
void DrawIB(datetime ct);
void DrawPrior(int rt);
void DrawLvl(string s,datetime et,double p,color clr,int stl,string lbl);
void CreateDash();
void UpdDash();
void CreateDoP();
void UpdDoP(double cp);
void MkLbl(string s,int x,int y,string t,color c,int fs);
void UpdLbl(string s,string t,color c);
string TFName();
bool Find(string src, string query);
string Lower(string str);

bool IsSpreadAcceptable()
{
   double spreadPts = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0) point = 0.00001;
   double spreadVal = spreadPts * point;

   if(g_atr_fast > 0)
   {
      return (spreadVal <= g_atr_fast * InpMaxSpread_ATR);
   }
   return true;
}

int OnInit()
{
   ChartSetInteger(0, CHART_EVENT_OBJECT_DELETE, true);
   
   if(InpAutoBroker) DetectBroker();

   if(InpSessionMode=="AUTO" || InpSessionMode=="MIDNIGHT") { g_ses_h=(g_SessionDef.asiaHour+g_svr_off)%24; g_ses_m=0; }
   else if(InpSessionMode=="LONDON")  { g_ses_h=(g_SessionDef.londonHour+g_svr_off)%24; g_ses_m=0; }
   else if(InpSessionMode=="NEWYORK") { g_ses_h=(g_SessionDef.newYorkHour+g_svr_off)%24; g_ses_m=0; }
   else if(InpSessionMode=="TOKYO" || InpSessionMode=="ASIA") { g_ses_h=(g_SessionDef.asiaHour+g_svr_off)%24; g_ses_m=0; }
   else { g_ses_h=InpCustomHour; g_ses_m=InpCustomMin; }

   if(InpAutoTF) ApplyTFAdaptive();
   else { g_ib=InpIBMinutes; g_lvls=InpManLevels; g_vmult=InpManVolMult; g_bodyp=InpManBodyPct; g_atr_p=InpManATR; }

   SetIndexBuffer(0,g_f,INDICATOR_DATA);   PlotIndexSetString(0,PLOT_LABEL,"EMA8");
   SetIndexBuffer(1,g_sl,INDICATOR_DATA); PlotIndexSetString(1,PLOT_LABEL,"EMA21");
   SetIndexBuffer(2,g_e2,INDICATOR_DATA); PlotIndexSetString(2,PLOT_LABEL,"EMA200");
   SetIndexBuffer(3,g_vw,INDICATOR_DATA); PlotIndexSetString(3,PLOT_LABEL,"VWAP");
   SetIndexBuffer(4,g_vh,INDICATOR_DATA); PlotIndexSetString(4,PLOT_LABEL,"VAH");
   SetIndexBuffer(5,g_vl,INDICATOR_DATA); PlotIndexSetString(5,PLOT_LABEL,"VAL");
   SetIndexBuffer(6,g_pc,INDICATOR_DATA); PlotIndexSetString(6,PLOT_LABEL,"POC");
   SetIndexBuffer(7,g_im,INDICATOR_DATA); PlotIndexSetString(7,PLOT_LABEL,"IBMid");

   ResetSession();
   g_SessionEngine.Reset();
   LoadPrior();
   
   g_hEMA_Fast = iMA(_Symbol, PERIOD_CURRENT, InpFastEMA, 0, MODE_EMA, PRICE_CLOSE);
   g_hEMA_Slow = iMA(_Symbol, PERIOD_CURRENT, InpSlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   g_hEMA_200  = iMA(_Symbol, PERIOD_CURRENT, InpEMA200,  0, MODE_EMA, PRICE_CLOSE);
   
   g_hATR_Fast = iATR(_Symbol, PERIOD_CURRENT, 20);
   g_hATR_Slow = iATR(_Symbol, PERIOD_CURRENT, 100);

   for(int k=0; k<6; k++)
   {
      g_hMTF_Fast[k] = iMA(_Symbol, g_mtfT[k], InpFastEMA, 0, MODE_EMA, PRICE_CLOSE);
      g_hMTF_Slow[k] = iMA(_Symbol, g_mtfT[k], InpSlowEMA, 0, MODE_EMA, PRICE_CLOSE);
      g_hMTF_E200[k] = iMA(_Symbol, g_mtfT[k], InpEMA200,  0, MODE_EMA, PRICE_CLOSE);
   }

   if(InpShowDash) CreateDash();
   if(InpShowDoP)  CreateDoP();

   IndicatorSetString(INDICATOR_SHORTNAME,"BTW v7.93 | "+TFName()+"|"+g_broker);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int r)
{ 
   g_MPEngine.CleanUp(); 
   ObjectsDeleteAll(0,g_P); 
   if(g_hATR_Fast != INVALID_HANDLE) IndicatorRelease(g_hATR_Fast);
   if(g_hATR_Slow != INVALID_HANDLE) IndicatorRelease(g_hATR_Slow);
   if(g_hEMA_Fast != INVALID_HANDLE) IndicatorRelease(g_hEMA_Fast);
   if(g_hEMA_Slow != INVALID_HANDLE) IndicatorRelease(g_hEMA_Slow);
   if(g_hEMA_200  != INVALID_HANDLE) IndicatorRelease(g_hEMA_200);

   for(int k=0; k<6; k++)
   {
      if(g_hMTF_Fast[k] != INVALID_HANDLE) IndicatorRelease(g_hMTF_Fast[k]);
      if(g_hMTF_Slow[k] != INVALID_HANDLE) IndicatorRelease(g_hMTF_Slow[k]);
      if(g_hMTF_E200[k] != INVALID_HANDLE) IndicatorRelease(g_hMTF_E200[k]);
   }
}

//--- Event Handler for Interactive Arrow Click (จุดที่มีการแก้ไขระบบคลิกแสดงผล)
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      // แก้ไขให้คลิกติดที่ลูกศรสัญญาณ SIG_ ได้ถูกต้อง
      if(StringFind(sparam, g_P + "SIG_") >= 0)
      {
         string metadata = ObjectGetString(0, sparam, OBJPROP_TEXT);
         string parts[];
         if(StringSplit(metadata, ';', parts) >= 5)
         {
            double en    = StringToDouble(parts[0]);
            double sl    = StringToDouble(parts[1]);
            double tp1   = StringToDouble(parts[2]);
            double tp2   = StringToDouble(parts[3]);
            double score = StringToDouble(parts[4]);

            datetime st = (datetime)ObjectGetInteger(0, sparam, OBJPROP_TIME, 0);
            datetime extT = st + PeriodSeconds() * 40;

            ClearTargetLines();

            DrawTargetLine("ACT_EN",  st, extT, en,  InpColEntry, STYLE_DOT,   2, "ENTRY: " + DoubleToString(en, _Digits) + " (Score: " + DoubleToString(score,1) + ")");
            DrawTargetLine("ACT_SL",  st, extT, sl,  InpColSL,    STYLE_SOLID, 2, "SL: "    + DoubleToString(sl, _Digits));
            DrawTargetLine("ACT_TP1", st, extT, tp1, InpColTP,    STYLE_DASH,  1, "TP1: "   + DoubleToString(tp1, _Digits));
            DrawTargetLine("ACT_TP2", st, extT, tp2, InpColTP,    STYLE_DASH,  2, "TP2: "   + DoubleToString(tp2, _Digits));

            ChartRedraw(0);
         }
      }
   }
}

int OnCalculate(const int rt, const int pc, const datetime &t[], const double &o[],
                const double &h[], const double &l[], const double &c[],
                const long &tv[], const long &v[], const int &sp[])
{
   double abF[], abS[];
   ArraySetAsSeries(abF, true); ArraySetAsSeries(abS, true);
   if(CopyBuffer(g_hATR_Fast, 0, 0, 1, abF) > 0) g_atr_fast = abF[0]; else g_atr_fast = 0;
   if(CopyBuffer(g_hATR_Slow, 0, 0, 1, abS) > 0) g_atr_slow = abS[0]; else g_atr_slow = 0;
   
   g_volatility_ratio = (g_atr_slow > 0) ? (g_atr_fast / g_atr_slow) : 1.0;

   int s = (pc == 0) ? 1 : pc - 1;
   if(s < 1) s = 1;

   if(ArraySize(g_scoreBufBull) != rt)
   {
      ArrayResize(g_scoreBufBull, rt);
      ArrayResize(g_scoreBufBear, rt);
   }

   if(pc == 0) 
   {
      ObjectsDeleteAll(0, g_P+"SIG_");
      ClearTargetLines();
      g_lastSignalBar = -999;
      ArrayInitialize(g_scoreBufBull, 0.0);
      ArrayInitialize(g_scoreBufBear, 0.0);
      g_SessionEngine.Reset();
   }

   if(CopyBuffer(g_hEMA_Fast, 0, 0, rt, g_f) <= 0)  return 0;
   if(CopyBuffer(g_hEMA_Slow, 0, 0, rt, g_sl) <= 0) return 0;
   if(CopyBuffer(g_hEMA_200,  0, 0, rt, g_e2) <= 0) return 0;

   for(int i=s; i<rt; i++)
   {
      string barSessionName = "";
      datetime barSessionStart = g_SessionEngine.CalculateSessionStart(t[i], barSessionName);

      if(g_SessionEngine.GetSessionStart() != 0 && barSessionStart != g_SessionEngine.GetSessionStart())
      {
         g_SessionEngine.PopulateResult(g_SessionRes);
         g_MPEngine.Update(g_SessionRes, g_ProfileRes, g_atr_fast, barSessionStart - 1);
         SavePrior();
         ResetSession();
         g_SessionEngine.OnNewSession(barSessionStart, barSessionName);
      }
      else if(g_SessionEngine.GetSessionStart() == 0)
      {
         g_SessionEngine.OnNewSession(barSessionStart, barSessionName);
      }

      long barVol = (tv[i] > 0) ? tv[i] : v[i];
      g_SessionEngine.ProcessBar(t[i], o[i], h[i], l[i], c[i], barVol, InpIBMinutes);
      g_SessionEngine.PopulateResult(g_SessionRes);

      g_ses.st     = g_SessionRes.sessionStart;
      g_ses.hi     = g_SessionRes.sessionHigh;
      g_ses.lo     = g_SessionRes.sessionLow;
      g_ses.ib_hi  = g_SessionRes.ibHigh;
      g_ses.ib_lo  = g_SessionRes.ibLow;
      g_ses.ib_set = g_SessionRes.ibSet;
      g_ses.vwap   = g_SessionRes.vwap;
      g_ses.tot    = g_SessionRes.totalVolume;

      g_vw[i] = g_SessionRes.vwap;
   }

   g_MPEngine.Update(g_SessionRes, g_ProfileRes, g_atr_fast, 0);
   g_StateEngine.AnalyzeState(g_ProfileRes, c[rt-1], h[rt-1], l[rt-1], g_atr_fast, g_StateRes);

   g_Phase3Engine.EvaluateAcceptanceRejection(rt-1, g_ProfileRes, o, h, l, c, tv, g_Phase3Data);
   g_Phase4Engine.EvaluateSequenceContext(rt-1, g_ProfileRes, g_StateRes, g_Phase3Data, o, h, l, c, tv, g_e2, g_Phase4Data);
   g_Phase5Engine.EvaluatePhase5Confluence(rt-1, g_Phase4Data, g_StateRes, g_atr_fast, g_Phase5Data);

   for(int i=s; i<rt; i++)
   {
      g_vh[i] = InpShowVAH ? g_ProfileRes.VAH : EMPTY_VALUE;
      g_vl[i] = InpShowVAL ? g_ProfileRes.VAL : EMPTY_VALUE;
      g_pc[i] = InpShowPOC ? g_ProfileRes.POC : EMPTY_VALUE;
      g_im[i] = InpShowIB  ? (g_SessionRes.ibHigh + g_SessionRes.ibLow) / 2.0 : EMPTY_VALUE;
      
      CheckFilters(i,o,h,l,c,tv);
      CalcDoP(c[i]);
      
      UpdateMarketStructureState(i, h, l, c);
      UpdateOrderBlock(i, o, h, l, c);
      UpdateLiquidityMap(i, h, l, t);

      g_scoreBufBull[i] = CalculateInstitutionalScore(i, o, h, l, c, tv, true);
      g_scoreBufBear[i] = CalculateInstitutionalScore(i, o, h, l, c, tv, false);

      CheckSignals(i,o,h,l,c,tv,t, i < (rt - 1));
   }

   if(InpShowDash) UpdDash();
   if(InpShowDoP)  UpdDoP(c[rt-1]);
   if(InpShowIB)   DrawIB(t[rt-1]);
   if(InpShowPrior)DrawPrior(rt);
   return rt;
}

//--- SMC Module 1: Market Structure State Machine
void UpdateMarketStructureState(int i, const double &h[], const double &l[], const double &c[])
{
   if(i < 30) return;

   bool isCHOCHBull = DetectTrueCHOCH(i, h, l, c, true);
   bool isCHOCHBear = DetectTrueCHOCH(i, h, l, c, false);
   bool isBOSBull   = DetectTrueSwingBOS(i, h, l, c, true);
   bool isBOSBear   = DetectTrueSwingBOS(i, h, l, c, false);

   if(isCHOCHBull || isBOSBull)
      g_marketState = STATE_UPTREND;
   else if(isCHOCHBear || isBOSBear)
      g_marketState = STATE_DOWNTREND;
}

//--- SMC Module 2: Displacement Detector
bool DetectDisplacement(int i, const double &o[], const double &h[], const double &l[], const double &c[], bool isBullish)
{
   if(i < 1) return false;
   double range = h[i] - l[i];
   double body  = MathAbs(c[i] - o[i]);
   
   if(range <= 0) return false;

   bool strongBody = (g_atr_fast > 0) ? (body >= g_atr_fast * 1.2) : ((body / range) >= 0.70);
   bool closeNearExtremum = isBullish ? ((c[i] - l[i]) / range >= 0.75) : ((h[i] - c[i]) / range >= 0.75);

   return (strongBody && closeNearExtremum);
}

//--- SMC Module 3: True Swing BOS Detection
bool DetectTrueSwingBOS(int i, const double &h[], const double &l[], const double &c[], bool isBullish)
{
   if(i < InpSwingPivot * 4) return false;
   int p = InpSwingPivot;

   if(isBullish)
   {
      double lastSwingHigh = 0;
      int limit = MathMax(p, i - 50);
      for(int k = i - p - 1; k >= limit && k >= p; k--)
      {
         bool isPivot = true;
         for(int m = 1; m <= p; m++)
         {
            if(h[k] <= h[k-m] || h[k] <= h[k+m]) { isPivot = false; break; }
         }
         if(isPivot) { lastSwingHigh = h[k]; break; }
      }
      return (lastSwingHigh > 0 && c[i] > lastSwingHigh);
   }
   else
   {
      double lastSwingLow = 0;
      int limit = MathMax(p, i - 50);
      for(int k = i - p - 1; k >= limit && k >= p; k--)
      {
         bool isPivot = true;
         for(int m = 1; m <= p; m++)
         {
            if(l[k] >= l[k-m] || l[k] >= l[k+m]) { isPivot = false; break; }
         }
         if(isPivot) { lastSwingLow = l[k]; break; }
      }
      return (lastSwingLow > 0 && c[i] < lastSwingLow);
   }
}

//--- SMC Module 4: True Structural CHOCH Detection
bool DetectTrueCHOCH(int i, const double &h[], const double &l[], const double &c[], bool isBullish)
{
   if(i < InpSwingPivot * 6) return false;
   int p = InpSwingPivot;

   if(isBullish)
   {
      double lastHigherLow = 0;
      double lastSwingHigh = 0;

      int limit = MathMax(p, i - 60);
      for(int k = i - p - 1; k >= limit && k >= p; k--)
      {
         bool isPivotH = true;
         for(int m = 1; m <= p; m++) if(h[k] <= h[k-m] || h[k] <= h[k+m]) { isPivotH = false; break; }
         if(isPivotH && lastSwingHigh == 0) lastSwingHigh = h[k];

         bool isPivotL = true;
         for(int m = 1; m <= p; m++) if(l[k] >= l[k-m] || l[k] >= l[k+m]) { isPivotL = false; break; }
         if(isPivotL && lastHigherLow == 0) lastHigherLow = l[k];

         if(lastSwingHigh > 0 && lastHigherLow > 0) break;
      }

      return (lastSwingHigh > 0 && c[i] > lastSwingHigh && g_marketState == STATE_DOWNTREND);
   }
   else
   {
      double lastLowerHigh = 0;
      double lastSwingLow  = 0;

      int limit = MathMax(p, i - 60);
      for(int k = i - p - 1; k >= limit && k >= p; k--)
      {
         bool isPivotL = true;
         for(int m = 1; m <= p; m++) if(l[k] >= l[k-m] || l[k] >= l[k+m]) { isPivotL = false; break; }
         if(isPivotL && lastSwingLow == 0) lastSwingLow = l[k];

         bool isPivotH = true;
         for(int m = 1; m <= p; m++) if(h[k] <= h[k-m] || h[k] <= h[k+m]) { isPivotH = false; break; }
         if(isPivotH && lastLowerHigh == 0) lastLowerHigh = h[k];

         if(lastSwingLow > 0 && lastLowerHigh > 0) break;
      }

      return (lastSwingLow > 0 && c[i] < lastSwingLow && g_marketState == STATE_UPTREND);
   }
}

//--- SMC Module 5: FVG Detection
bool DetectInstitutionalFVG(int i, const double &o[], const double &h[], const double &l[], const double &c[], bool isBullish)
{
   if(i < 2) return false;
   double minGap = (g_atr_fast > 0) ? (g_atr_fast * InpMinFVG_ATR_Ratio) : (_Point * 10);
   bool displacement = DetectDisplacement(i-1, o, h, l, c, isBullish);

   if(!displacement) return false;

   if(isBullish)
   {
      double gap = l[i] - h[i-2];
      return (gap >= minGap);
   }
   else
   {
      double gap = l[i-2] - h[i];
      return (gap >= minGap);
   }
}

//--- SMC Module 6: Order Block Engine
void UpdateOrderBlock(int i, const double &o[], const double &h[], const double &l[], const double &c[])
{
   if(i < 3) return;

   bool isBullBOS = DetectTrueSwingBOS(i, h, l, c, true);
   bool isBearBOS = DetectTrueSwingBOS(i, h, l, c, false);

   if(isBullBOS)
   {
      int limit = MathMax(0, i - 10);
      for(int k = i - 1; k >= limit; k--)
      {
         if(c[k] < o[k])
         {
            g_activeOB.valid = true;
            g_activeOB.isBullish = true;
            g_activeOB.top = h[k];
            g_activeOB.bottom = l[k];
            break;
         }
      }
   }
   else if(isBearBOS)
   {
      int limit = MathMax(0, i - 10);
      for(int k = i - 1; k >= limit; k--)
      {
         if(c[k] > o[k])
         {
            g_activeOB.valid = true;
            g_activeOB.isBullish = false;
            g_activeOB.top = h[k];
            g_activeOB.bottom = l[k];
            break;
         }
      }
   }
}

//--- SMC Module 7: Liquidity Map
void UpdateLiquidityMap(int i, const double &h[], const double &l[], const datetime &t[])
{
   if(i < 40) return;

   double tol = (g_atr_fast > 0) ? (g_atr_fast * 0.15) : (_Point * 20);
   g_liqMap.eqh = 0; g_liqMap.eql = 0;

   int limit = MathMax(0, i - 30);
   for(int k = i - 2; k >= limit; k--)
   {
      if(MathAbs(h[i-1] - h[k]) <= tol) { g_liqMap.eqh = h[i-1]; break; }
      if(MathAbs(l[i-1] - l[k]) <= tol) { g_liqMap.eql = l[i-1]; break; }
   }

   if(g_pri.hi > 0) { g_liqMap.pdh = g_pri.hi; g_liqMap.pdl = g_pri.lo; }

   MqlDateTime dt; TimeToStruct(t[i], dt);
   if(dt.hour >= 0 && dt.hour < 8)
   {
      if(dt.hour == 0 && dt.min == 0) { g_liqMap.asiaHigh = h[i]; g_liqMap.asiaLow = l[i]; }
      else {
         g_liqMap.asiaHigh = MathMax(g_liqMap.asiaHigh, h[i]);
         g_liqMap.asiaLow  = MathMin(g_liqMap.asiaLow, l[i]);
      }
   }
}

bool DetectAdvancedLiquiditySweep(int i, const double &h[], const double &l[], const double &c[], bool isBullish)
{
   if(i < 5) return false;

   if(isBullish)
   {
      bool sweepEQL  = (g_liqMap.eql > 0 && l[i] < g_liqMap.eql && c[i] > g_liqMap.eql);
      bool sweepAsia = (g_liqMap.asiaLow > 0 && l[i] < g_liqMap.asiaLow && c[i] > g_liqMap.asiaLow);
      bool sweepPDL  = (g_liqMap.pdl > 0 && l[i] < g_liqMap.pdl && c[i] > g_liqMap.pdl);
      bool sweepSwing = DetectSwingLiquiditySweep(i, h, l, c, true);

      return (sweepEQL || sweepAsia || sweepPDL || sweepSwing);
   }
   else
   {
      bool sweepEQH  = (g_liqMap.eqh > 0 && h[i] > g_liqMap.eqh && c[i] < g_liqMap.eqh);
      bool sweepAsia = (g_liqMap.asiaHigh > 0 && h[i] > g_liqMap.asiaHigh && c[i] < g_liqMap.asiaHigh);
      bool sweepPDH  = (g_liqMap.pdh > 0 && h[i] > g_liqMap.pdh && c[i] < g_liqMap.pdh);
      bool sweepSwing = DetectSwingLiquiditySweep(i, h, l, c, false);

      return (sweepEQH || sweepAsia || sweepPDH || sweepSwing);
   }
}

bool DetectSwingLiquiditySweep(int i, const double &h[], const double &l[], const double &c[], bool isBullish)
{
   if(i < InpSwingPivot * 4) return false;
   int p = InpSwingPivot;

   if(isBullish)
   {
      double swingLow = 0;
      int limit = MathMax(p, i - 40);
      for(int k = i - p - 1; k >= limit && k >= p; k--)
      {
         bool isPivot = true;
         for(int m = 1; m <= p; m++) if(l[k] >= l[k-m] || l[k] >= l[k+m]) { isPivot = false; break; }
         if(isPivot) { swingLow = l[k]; break; }
      }
      if(swingLow > 0 && l[i] < swingLow && c[i] > swingLow) return true;
   }
   else
   {
      double swingHigh = 0;
      int limit = MathMax(p, i - 40);
      for(int k = i - p - 1; k >= limit && k >= p; k--)
      {
         bool isPivot = true;
         for(int m = 1; m <= p; m++) if(h[k] <= h[k-m] || h[k] <= h[k+m]) { isPivot = false; break; }
         if(isPivot) { swingHigh = h[k]; break; }
      }
      if(swingHigh > 0 && h[i] > swingHigh && c[i] < swingHigh) return true;
   }
   return false;
}

//--- Engine Core: Institutional Probability Scoring Engine (0 to 100)
double CalculateInstitutionalScore(int i, const double &o[], const double &h[], const double &l[], const double &c[], const long &tv[], bool isBullish)
{
   if(i < 5) return 0.0;
   double range = h[i] - l[i];
   if(range <= 0) return 0.0;

   bool bos    = DetectTrueSwingBOS(i, h, l, c, isBullish);
   bool choch  = DetectTrueCHOCH(i, h, l, c, isBullish);
   bool disp   = DetectDisplacement(i, o, h, l, c, isBullish);
   
   double f_struct = 0.15;
   if(choch && disp) f_struct = 1.0;
   else if(choch)    f_struct = 0.85;
   else if(bos && disp) f_struct = 0.80;
   else if(bos)      f_struct = 0.65;
   else if(disp)     f_struct = 0.50;

   bool sweep = DetectAdvancedLiquiditySweep(i, h, l, c, isBullish);
   double f_sweep = sweep ? 1.0 : 0.15;

   bool fvg = DetectInstitutionalFVG(i, o, h, l, c, isBullish);
   bool obRetest = false;
   if(g_activeOB.valid && g_activeOB.isBullish == isBullish)
   {
      if(isBullish && l[i] <= g_activeOB.top && c[i] >= g_activeOB.bottom) obRetest = true;
      if(!isBullish && h[i] >= g_activeOB.bottom && c[i] <= g_activeOB.top) obRetest = true;
   }
   double f_ob = (obRetest && fvg) ? 1.0 : (obRetest ? 0.8 : (fvg ? 0.6 : 0.15));

   double f_loc = 0.15;
   if(isBullish)
   {
      if(g_ProfileRes.VAL > 0 && l[i] <= g_ProfileRes.VAL && c[i] >= g_ProfileRes.VAL) f_loc = 1.0;
      else if(g_ProfileRes.POC > 0 && MathAbs(l[i] - g_ProfileRes.POC) < range) f_loc = 0.7;
      else if(g_SessionRes.vwap > 0 && l[i] <= g_SessionRes.vwap && c[i] >= g_SessionRes.vwap) f_loc = 0.6;
   }
   else
   {
      if(g_ProfileRes.VAH > 0 && h[i] >= g_ProfileRes.VAH && c[i] <= g_ProfileRes.VAH) f_loc = 1.0;
      else if(g_ProfileRes.POC > 0 && MathAbs(h[i] - g_ProfileRes.POC) < range) f_loc = 0.7;
      else if(g_SessionRes.vwap > 0 && h[i] <= g_SessionRes.vwap && c[i] <= g_SessionRes.vwap) f_loc = 0.6;
   }

   double vs = 0; int cnt = MathMin(g_vsma, i + 1);
   for(int j = 0; j < cnt; j++) vs += (double)tv[i - j];
   vs /= cnt;
   double f_vol = (vs > 0) ? MathMin(1.0, ((double)tv[i] / vs) / 1.5) : 0.15;

   double wick = isBullish ? (MathMin(o[i], c[i]) - l[i]) : (h[i] - MathMax(o[i], c[i]));
   double f_wick = MathMin(1.0, (wick / range) / 0.5);

   double weightedSum = (f_struct * 0.35) + 
                        (f_sweep  * 0.25) + 
                        (f_ob     * 0.20) + 
                        (f_loc    * 0.10) + 
                        (f_vol    * 0.05) + 
                        (f_wick   * 0.05);

   double score = weightedSum * (f_struct * 0.5 + 0.5) * (f_sweep * 0.5 + 0.5) * 100.0;

   if(InpEnablePhase3)
   {
      if(isBullish && g_Phase3Data.currentAccState == ACC_VAL_REJECTED) score *= 1.15;
      if(!isBullish && g_Phase3Data.currentAccState == ACC_VAH_REJECTED) score *= 1.15;
      if(isBullish && g_Phase3Data.currentAccState == ACC_VAH_ACCEPTED) score *= 1.10;
      if(!isBullish && g_Phase3Data.currentAccState == ACC_VAL_ACCEPTED) score *= 1.10;
   }

   if(InpEnablePhase4)
   {
      if(isBullish && g_Phase4Data.currentContext == P4_BULLISH_CONTEXT)
         score *= InpP4ScoreBoost;
      else if(!isBullish && g_Phase4Data.currentContext == P4_BEARISH_CONTEXT)
         score *= InpP4ScoreBoost;
      else if(g_Phase4Data.currentContext == P4_CONFLICT_SCALP_ONLY)
         score *= 0.85; 
   }

   if(InpEnablePhase5)
   {
      score *= g_Phase5Data.confluenceScoreBoost;
   }

   if(InpUseMTFBiasFilter)
   {
      double e1h_f[], e1h_s[];
      ArraySetAsSeries(e1h_f, true); ArraySetAsSeries(e1h_s, true);
      if(g_hMTF_Fast[4] != INVALID_HANDLE && g_hMTF_Slow[4] != INVALID_HANDLE)
      {
         if(CopyBuffer(g_hMTF_Fast[4], 0, 0, 1, e1h_f) > 0 && CopyBuffer(g_hMTF_Slow[4], 0, 0, 1, e1h_s) > 0)
         {
            bool htfBull = (e1h_f[0] > e1h_s[0]);
            if(isBullish != htfBull) score *= 0.75;
         }
      }
   }

   if(!IsSpreadAcceptable()) score *= 0.80;

   return MathMin(100.0, score);
}

double GetDynamicPercentileThreshold(int currentIndex)
{
   int lookback = MathMin(InpPercentileLookback, currentIndex);
   if(lookback < 20) return InpMinScoreCutoff;

   double scores[];
   int count = 0;

   for(int k = 1; k <= lookback; k++)
   {
      int idx = currentIndex - k;
      if(idx < 0) break;
      double mScore = MathMax(g_scoreBufBull[idx], g_scoreBufBear[idx]);
      
      if(mScore >= 20.0) 
      {
         ArrayResize(scores, count + 1);
         scores[count] = mScore;
         count++;
      }
   }

   if(count < 5) return InpMinScoreCutoff;

   ArraySort(scores); 
   int rankIndex = (int)MathRound((InpTopPercentileTarget / 100.0) * (count - 1));
   rankIndex = MathMax(0, MathMin(count - 1, rankIndex));

   return MathMax(InpMinScoreCutoff, scores[rankIndex]); 
}

void CheckSignals(int i, const double &o[], const double &h[], const double &l[], const double &c[], const long &tv[], const datetime &t[], bool isHistory)
{
   if(!InpShowSignals) return;

   if(i < 20 || i < 1) return;
   if((i - g_lastSignalBar) < InpSignalCooldownBar) return;

   if(!isHistory && !IsSpreadAcceptable()) return;

   double cc=c[i], f=g_f[i], s=g_sl[i], e2=g_e2[i];
   bool s1l=false, s1s=false, s2l=false, s2s=false;

   bool passEMA200_Buy  = InpUseEMA200Filter ? (cc > e2) : true;
   bool passEMA200_Sell = InpUseEMA200Filter ? (cc < e2) : true;

   double dynamicThreshold = GetDynamicPercentileThreshold(i - 1);
   double bullScore = g_scoreBufBull[i];
   double bearScore = g_scoreBufBear[i];

   if(InpShowS1)
   {
      if(passEMA200_Buy && bullScore >= dynamicThreshold && bullScore >= InpMinScoreCutoff) s1l = true;
      if(passEMA200_Sell && bearScore >= dynamicThreshold && bearScore >= InpMinScoreCutoff) s1s = true;
   }

   if(InpShowS2)
   {
      if(passEMA200_Buy && g_all && (g_ProfileRes.VAH > 0 && cc > g_ProfileRes.VAH && c[i-1] <= g_ProfileRes.VAH) && bullScore >= InpMinScoreCutoff) s2l = true;
      if(passEMA200_Sell && g_all && (g_ProfileRes.VAL > 0 && cc < g_ProfileRes.VAL && c[i-1] >= g_ProfileRes.VAL) && bearScore >= InpMinScoreCutoff) s2s = true;
   }

   if(s1l || s1s || s2l || s2s)
   {
      if(s1l)      DrawSig(i,cc,h[i],l[i],1,t,bullScore,isHistory);
      else if(s1s) DrawSig(i,cc,h[i],l[i],2,t,bearScore,isHistory);
      else if(s2l) DrawSig(i,cc,h[i],l[i],3,t,bullScore,isHistory);
      else if(s2s) DrawSig(i,cc,h[i],l[i],4,t,bearScore,isHistory);

      g_lastSignalBar = i; 
   }

   if(!isHistory && InpAlertCross)
   {
      if(g_f[i-1]<=g_sl[i-1] && f>s && g_sig.type!=10){ g_sig.type=10; TriggerAlert("K2 Golden Cross"); }
      if(g_f[i-1]>=g_sl[i-1] && f<s && g_sig.type!=11){ g_sig.type=11; TriggerAlert("K2 Death Cross"); }
   }
}

void UpdDash()
{
   for(int i=0; i<6; i++)
   {
      double ef[], es[], e2[];
      ArraySetAsSeries(ef, true); ArraySetAsSeries(es, true); ArraySetAsSeries(e2, true);

      if(g_hMTF_Fast[i] != INVALID_HANDLE && CopyBuffer(g_hMTF_Fast[i], 0, 0, 2, ef) > 0 &&
         g_hMTF_Slow[i] != INVALID_HANDLE && CopyBuffer(g_hMTF_Slow[i], 0, 0, 2, es) > 0 &&
         g_hMTF_E200[i] != INVALID_HANDLE && CopyBuffer(g_hMTF_E200[i], 0, 0, 2, e2) > 0)
      {
         bool bl = ef[0] > es[0], e2u = e2[0] > e2[1], cnf = (bl && !e2u) || (!bl && e2u);
         UpdLbl("D_K2"+IntegerToString(i), bl ? "▲ UP" : "▼ DN", bl ? InpColBuy : InpColSell);
         UpdLbl("D_E2"+IntegerToString(i), cnf ? "⚠ "+(e2u?"↑":"↓") : (e2u?"↑ UP":"↓ DN"), cnf ? clrOrange : (e2u ? InpColBuy : InpColSell));
      }
   }
}

//+------------------------------------------------------------------+
//| DASHBOARD PANEL RENDERING                                        |
//+------------------------------------------------------------------+
void CreateDoP()
{
   int x = 20, y = 30, dy = 18;
   MkLbl("PANEL_SES", x, y, "SESSION     : --", clrGold, 9); y += dy;
   MkLbl("PANEL_SEP1", x, y, "----------------------------------------", clrGray, 8); y += dy;
   MkLbl("PANEL_PRO", x, y, "PROFILE     : --", clrCyan, 9); y += dy;
   MkLbl("PANEL_SEP2", x, y, "----------------------------------------", clrGray, 8); y += dy;
   MkLbl("PANEL_IB",  x, y, "IB          : --", clrOrange, 9); y += dy;
   MkLbl("PANEL_DPOC", x, y, "DEV POC     : --", clrCyan, 9); y += dy;
   MkLbl("PANEL_SEP_IB", x, y, "----------------------------------------", clrGray, 8); y += dy;
   MkLbl("PANEL_LOC", x, y, "LOCATION    : --", clrYellow, 9); y += dy;
   MkLbl("PANEL_SEP3", x, y, "----------------------------------------", clrGray, 8); y += dy;
   MkLbl("PANEL_DIS", x, y, "DISTANCE    : --", clrWhite, 9); y += dy;
   MkLbl("PANEL_SEP4", x, y, "----------------------------------------", clrGray, 8); y += dy;
   MkLbl("PANEL_VAL", x, y, "VALIDATION  : --", clrLime, 9); y += dy;
   MkLbl("DOP_P3", x, y, "P3 Dynamic: --", clrYellow, 8); y += dy;
   MkLbl("DOP_P4", x, y, "P4 Context: --", clrYellow, 8); y += dy;
   MkLbl("DOP_P5", x, y, "P5 Matrix: --", clrYellow, 8); y += dy;
}

void UpdDoP(double cp)
{
   UpdLbl("PANEL_SES", "SESSION     : " + g_SessionRes.sessionName, clrGold);
   UpdLbl("PANEL_SEP1", "----------------------------------------", clrGray);
   
   string profileStr = "VAH: " + DoubleToString(g_ProfileRes.VAH, _Digits) + 
                       " | POC: " + DoubleToString(g_ProfileRes.POC, _Digits) + 
                       " | VAL: " + DoubleToString(g_ProfileRes.VAL, _Digits);
   UpdLbl("PANEL_PRO", "PROFILE     : " + profileStr, clrCyan);
   UpdLbl("PANEL_SEP2", "----------------------------------------", clrGray);

   string ibStr = DoubleToString(g_SessionRes.ibHigh, _Digits) + " / " + DoubleToString(g_SessionRes.ibLow, _Digits);
   UpdLbl("PANEL_IB",  "IB : H / L   : " + ibStr, clrOrange);
   UpdLbl("PANEL_DPOC","DEV POC     : " + DoubleToString(g_ProfileRes.POC, _Digits), clrCyan);
   UpdLbl("PANEL_SEP_IB", "----------------------------------------", clrGray);

   UpdLbl("PANEL_LOC", "LOCATION    : " + g_StateRes.locationText, clrYellow);
   UpdLbl("PANEL_SEP3", "----------------------------------------", clrGray);

   string disStr = DoubleToString(g_StateRes.pocDistancePts, 1) + " pts (" + DoubleToString(g_StateRes.pocDistanceAtr, 2) + " ATR)";
   UpdLbl("PANEL_DIS", "DISTANCE    : " + disStr, clrWhite);
   UpdLbl("PANEL_SEP4", "----------------------------------------", clrGray);
   UpdLbl("PANEL_VAL", "VALIDATION  : " + g_StateRes.validationReason, g_StateRes.validationPass ? clrLime : clrRed);

   UpdLbl("DOP_P3", "P3 Dynamic  : " + g_Phase3Data.statusSummary, clrYellow);
   UpdLbl("DOP_P4", "P4 Context  : " + g_Phase4Data.contextSummary, clrYellow);
   UpdLbl("DOP_P5", "P5 Matrix   : " + g_Phase5Data.matrixSummary, clrYellow);
}

//+------------------------------------------------------------------+
//| BROKER DETECTION IMPLEMENTATION                                  |
//+------------------------------------------------------------------+
void DetectBroker()
{
   g_broker = AccountInfoString(ACCOUNT_COMPANY);
   g_srv    = AccountInfoString(ACCOUNT_SERVER);
   
   datetime curServer = TimeCurrent();
   datetime curGMT    = TimeGMT();
   if(curServer > 0 && curGMT > 0)
   {
      g_svr_off = (int)MathRound((double)(curServer - curGMT) / 3600.0);
   }
   else
   {
      g_svr_off = 0;
   }
}

//+------------------------------------------------------------------+
//| HELPER AND UTILITY FUNCTIONS IMPLEMENTATION                      |
//+------------------------------------------------------------------+
void ApplyTFAdaptive()
{
   ENUM_TIMEFRAMES tf = _Period;
   if(tf == PERIOD_M1)       { g_ib=60; g_lvls=100; g_vmult=1.2; g_bodyp=45.0; g_atr_p=14; }
   else if(tf == PERIOD_M5)  { g_ib=60; g_lvls=150; g_vmult=1.3; g_bodyp=50.0; g_atr_p=14; }
   else if(tf == PERIOD_M15) { g_ib=60; g_lvls=200; g_vmult=1.3; g_bodyp=50.0; g_atr_p=14; }
   else if(tf == PERIOD_M30) { g_ib=60; g_lvls=250; g_vmult=1.4; g_bodyp=55.0; g_atr_p=14; }
   else if(tf == PERIOD_H1)  { g_ib=60; g_lvls=300; g_vmult=1.5; g_bodyp=60.0; g_atr_p=14; }
   else                      { g_ib=InpIBMinutes; g_lvls=InpManLevels; g_vmult=InpManVolMult; g_bodyp=InpManBodyPct; g_atr_p=InpManATR; }
}

bool IsNewDay(datetime bt)
{
   static datetime lastDay = 0;
   MqlDateTime dt;
   TimeToStruct(bt, dt);
   datetime curDay = bt - (dt.hour * 3600 + dt.min * 60 + dt.sec);
   if(curDay != lastDay)
   {
      lastDay = curDay;
      return true;
   }
   return false;
}

void ResetSession()
{
   g_ses.st     = 0;
   g_ses.hi     = 0;
   g_ses.lo     = DBL_MAX;
   g_ses.ib_hi  = 0;
   g_ses.ib_lo  = DBL_MAX;
   g_ses.ib_set = false;
   g_ses.vwap   = 0;
   g_ses.vv     = 0;
   g_ses.tot    = 0;
}

void UpdIB(datetime bt, double h, double lo)
{
   if(h > g_ses.ib_hi || g_ses.ib_hi == 0) g_ses.ib_hi = h;
   if(lo < g_ses.ib_lo || g_ses.ib_lo == DBL_MAX) g_ses.ib_lo = lo;
}

void UpdVWAP(int i, const double &o[], const double &h[], const double &l[], const double &c[], const long &tv[])
{
   double typ = (h[i] + l[i] + c[i]) / 3.0;
   double vol = (double)tv[i];
   g_ses.vv  += typ * vol;
   g_ses.tot += vol;
   if(g_ses.tot > 0) g_ses.vwap = g_ses.vv / g_ses.tot;
   else g_ses.vwap = typ;
}

void CheckFilters(int i, const double &o[], const double &h[], const double &l[], const double &c[], const long &tv[])
{
   g_vf = true;
   g_bf = true;
   g_af = true;
   g_all = true;
}

void CalcDoP(double cp)
{
   g_dop = 0;
}

void DrawSig(int i, double p, double h, double l, int type, const datetime &t[], double score, bool isHistory)
{
   string objName = g_P + "SIG_" + IntegerToString(i) + "_" + IntegerToString(type);
   color clr = (type == 1 || type == 3) ? InpColBuy : InpColSell;
   ENUM_ARROW_CHAR arrow = (type == 1 || type == 3) ? ARROW_BUY : ARROW_SELL;
   
   if(ObjectFind(0, objName) < 0)
   {
      ObjectCreate(0, objName, OBJ_ARROW, 0, t[i], (type == 1 || type == 3) ? l : h);
      ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, arrow);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
      
      double en   = p;
      double sl   = (type == 1 || type == 3) ? l - (g_atr_fast > 0 ? g_atr_fast : _Point*50) : h + (g_atr_fast > 0 ? g_atr_fast : _Point*50);
      double risk = MathAbs(en - sl);
      double tp1  = (type == 1 || type == 3) ? en + risk * g_Phase5Data.dynamicTp1Multiplier : en - risk * g_Phase5Data.dynamicTp1Multiplier;
      double tp2  = (type == 1 || type == 3) ? en + risk * g_Phase5Data.dynamicTp2Multiplier : en - risk * g_Phase5Data.dynamicTp2Multiplier;
      
      string meta = DoubleToString(en,_Digits)+";"+DoubleToString(sl,_Digits)+";"+DoubleToString(tp1,_Digits)+";"+DoubleToString(tp2,_Digits)+";"+DoubleToString(score,1);
      ObjectSetString(0, objName, OBJPROP_TEXT, meta);
   }

   if(!isHistory && (InpAlertS1 || InpAlertS2))
   {
      string sType = (type == 1 || type == 3) ? "BUY" : "SELL";
      TriggerAlert("BTW Signal (" + sType + ") Score: " + DoubleToString(score, 1));
   }
}

void ClearTargetLines()
{
   ObjectsDeleteAll(0, g_P + "ACT_");
}

void DrawTargetLine(string name, datetime st, datetime et, double price, color clr, int style, int width, string label)
{
   if(price <= 0) return;
   string objName = g_P + name;
   if(ObjectFind(0, objName) < 0)
   {
      ObjectCreate(0, objName, OBJ_TREND, 0, st, price, et, price);
   }
   else
   {
      ObjectMove(0, objName, 0, st, price);
      ObjectMove(0, objName, 1, et, price);
   }
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, style);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   ObjectSetString(0, objName, OBJPROP_TEXT, label);
}

void TriggerAlert(string msg)
{
   if(InpAlertS1 || InpAlertS2 || InpAlertCross)
   {
      if(InpSound) Alert(msg);
      if(InpPush)  SendNotification(msg);
   }
}

void SavePrior()
{
   g_pri.dt  = g_SessionRes.sessionStart;
   g_pri.hi  = g_SessionRes.sessionHigh;
   g_pri.lo  = g_SessionRes.sessionLow;
   g_pri.poc = g_ProfileRes.POC;
   g_pri.vah = g_ProfileRes.VAH;
   g_pri.val = g_ProfileRes.VAL;
}

void LoadPrior()
{
   g_pri.dt  = 0;
   g_pri.hi  = 0;
   g_pri.lo  = 0;
   g_pri.poc = 0;
   g_pri.vah = 0;
   g_pri.val = 0;
}

void DrawIB(datetime ct)
{
   if(g_SessionRes.ibHigh > 0 && g_SessionRes.ibLow < DBL_MAX)
   {
      DrawLvl("IBH", ct, g_SessionRes.ibHigh, InpColIB, STYLE_DOT, "IB High");
      DrawLvl("IBL", ct, g_SessionRes.ibLow,  InpColIB, STYLE_DOT, "IB Low");
   }
}

void DrawPrior(int rt)
{
   if(g_pri.vah > 0 && g_pri.val > 0)
   {
      DrawLvl("PVAH", TimeCurrent(), g_pri.vah, InpColPrior, STYLE_DASH, "Prior VAH");
      DrawLvl("PPOC", TimeCurrent(), g_pri.poc, InpColPrior, STYLE_DASH, "Prior POC");
      DrawLvl("PVAL", TimeCurrent(), g_pri.val, InpColPrior, STYLE_DASH, "Prior VAL");
   }
}

void DrawLvl(string s, datetime et, double p, color clr, int stl, string lbl)
{
   if(p <= 0) return;
   string objName = g_P + "LVL_" + s;
   if(ObjectFind(0, objName) < 0)
   {
      ObjectCreate(0, objName, OBJ_HLINE, 0, 0, p);
   }
   ObjectSetDouble(0, objName, OBJPROP_PRICE, p);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, stl);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
   ObjectSetString(0, objName, OBJPROP_TEXT, lbl);
}

void CreateDash()
{
   int x = 200, y = 30, dy = 18;
   MkLbl("D_HDR", x, y, "MTF BIAS MATRIX", clrGold, 9); y += dy;
   for(int i=0; i<6; i++)
   {
      MkLbl("D_LBL"+IntegerToString(i), x, y, g_mtfN[i] + " K2/EMA200:", clrWhite, 8);
      MkLbl("D_K2"+IntegerToString(i), x + 100, y, "--", clrGray, 8);
      MkLbl("D_E2"+IntegerToString(i), x + 150, y, "--", clrGray, 8);
      y += dy;
   }
}

void MkLbl(string s, int x, int y, string t, color c, int fs)
{
   string objName = g_P + s;
   if(ObjectFind(0, objName) < 0)
   {
      ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, fs);
      ObjectSetString(0, objName, OBJPROP_FONT, "Calibri");
   }
   ObjectSetString(0, objName, OBJPROP_TEXT, t);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, c);
}

void UpdLbl(string s, string t, color c)
{
   string objName = g_P + s;
   if(ObjectFind(0, objName) >= 0)
   {
      ObjectSetString(0, objName, OBJPROP_TEXT, t);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, c);
   }
}

string TFName()
{
   switch(_Period)
   {
      case PERIOD_M1:  return "M1";
      case PERIOD_M5:  return "M5";
      case PERIOD_M15: return "M15";
      case PERIOD_M30: return "M30";
      case PERIOD_H1:  return "H1";
      case PERIOD_H4:  return "H4";
      case PERIOD_D1:  return "D1";
      default:         return "TF";
   }
}

bool Find(string src, string query)
{
   return (StringFind(src, query) >= 0);
}

string Lower(string str)
{
   string res = str;
   StringToLower(res);
   return res;
}
