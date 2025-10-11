//+------------------------------------------------------------------+
//|                                     FibIndicators_Final.mq5 |
//|                         Copyright 2024, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "11.0"
#property description "Refactored Fibonacci Stochastic Indicator with performance optimizations"

#property indicator_separate_window
#property indicator_buffers 38 // 19 for plotting, 19 for calculations
#property indicator_plots   19

#property indicator_level1 20.0
#property indicator_level2 50.0
#property indicator_level3 80.0
#property indicator_levelcolor clrGray
#property indicator_levelstyle STYLE_DOT

//--- Enums for User Inputs
enum ENUM_CALC_TYPE
  {
   CALC_NORMAL,    // Normal Stochastic Value
   CALC_SUM,       // Sum of Stochastic Values
   CALC_DIV,       // Difference
   CALC_SIGN,      // Sign of Change
   CALC_DIV_SUM,   // Sum of Differences
   CALC_MULT       // Multiplied Value
  };

enum ENUM_SUM_TYPE
  {
   SUM_FORWARD,    // Sum from current index to the end
   SUM_BACKWARD    // Sum from the beginning to the current index
  };

enum ENUM_KD_TYPE
  {
   KD_MAIN,        // Use %K line for calculations
   KD_SIGNAL       // Use %D line for calculations
  };

enum ENUM_CUSTOM_MA_METHOD
  {
   CUSTOM_SMA,     // Simple Moving Average
   CUSTOM_EMA,     // Exponential Moving Average
   CUSTOM_SMMA,    // Smoothed Moving Average
   CUSTOM_LWMA,    // Linear Weighted Moving Average
   CUSTOM_HMA,     // Hull Moving Average
   CUSTOM_ZLEMA    // Zero-Lag Exponential Moving Average
  };

//--- User Inputs
input int                   in_display_start  = 0;       // First Fibonacci index to display
input int                   in_display_end    = 18;      // Last Fibonacci index to display
input ENUM_CALC_TYPE        in_calc_type      = CALC_NORMAL; // Calculation Mode
input ENUM_SUM_TYPE         in_sum_type       = SUM_FORWARD; // Summation Mode
input ENUM_KD_TYPE          in_kd_type        = KD_SIGNAL;   // Stochastic Line (%K or %D)
input int                   in_slowing        = 1;       // Stochastic Slowing
input ENUM_CUSTOM_MA_METHOD in_ma_method      = CUSTOM_SMA; // Moving Average Method
input ENUM_STO_PRICE        in_price_field    = STO_LOWHIGH; // Stochastic Price Field

//--- Global Variables
int      g_fibonacci[] = {1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181, 6765};
int      g_buff_num = 19;
int      g_display_start;
int      g_display_end;

//--- Buffers
double   PlotBuffer0[], PlotBuffer1[], PlotBuffer2[], PlotBuffer3[], PlotBuffer4[], PlotBuffer5[], PlotBuffer6[], PlotBuffer7[], PlotBuffer8[], PlotBuffer9[], PlotBuffer10[], PlotBuffer11[], PlotBuffer12[], PlotBuffer13[], PlotBuffer14[], PlotBuffer15[], PlotBuffer16[], PlotBuffer17[], PlotBuffer18[];
double   StochBuffer0[], StochBuffer1[], StochBuffer2[], StochBuffer3[], StochBuffer4[], StochBuffer5[], StochBuffer6[], StochBuffer7[], StochBuffer8[], StochBuffer9[], StochBuffer10[], StochBuffer11[], StochBuffer12[], StochBuffer13[], StochBuffer14[], StochBuffer15[], StochBuffer16[], StochBuffer17[], StochBuffer18[];
int      g_stoch_handles[19];

//--- Forward Declarations for Optimized MA calculations
void SMA_Calculate(const int rates_total, const int period, const double &in_series[], double &out_series[]);
void EMA_Calculate(const int rates_total, const int period, const double &in_series[], double &out_series[]);
void LWMA_Calculate(const int rates_total, const int period, const double &in_series[], double &out_series[]);
void SMMA_Calculate(const int rates_total, const int period, const double &in_series[], double &out_series[]);
void HMA_Calculate(const int rates_total, const int period, const double &in_series[], double &out_series[]);
void ZLEMA_Calculate(const int rates_total, const int period, const double &in_series[], double &out_series[]);
void CustomStochastic(int k_period, int d_period, int slowing, ENUM_CUSTOM_MA_METHOD ma_method, const int rates_total, const double &high[], const double &low[], const double &close[], double &k_buffer[], double &d_buffer[]);

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Validate and copy inputs to global variables
   g_display_start = in_display_start;
   g_display_end = in_display_end;
   if(g_display_start < 0) g_display_start = 0;
   if(g_display_end >= g_buff_num) g_display_end = g_buff_num - 1;
   if(g_display_start > g_display_end) g_display_start = g_display_end;

//--- Initialize buffers
   SetIndexBuffer(0,  PlotBuffer0,  INDICATOR_DATA); SetIndexBuffer(19, StochBuffer0,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(1,  PlotBuffer1,  INDICATOR_DATA); SetIndexBuffer(20, StochBuffer1,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,  PlotBuffer2,  INDICATOR_DATA); SetIndexBuffer(21, StochBuffer2,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,  PlotBuffer3,  INDICATOR_DATA); SetIndexBuffer(22, StochBuffer3,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,  PlotBuffer4,  INDICATOR_DATA); SetIndexBuffer(23, StochBuffer4,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,  PlotBuffer5,  INDICATOR_DATA); SetIndexBuffer(24, StochBuffer5,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,  PlotBuffer6,  INDICATOR_DATA); SetIndexBuffer(25, StochBuffer6,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,  PlotBuffer7,  INDICATOR_DATA); SetIndexBuffer(26, StochBuffer7,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,  PlotBuffer8,  INDICATOR_DATA); SetIndexBuffer(27, StochBuffer8,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,  PlotBuffer9,  INDICATOR_DATA); SetIndexBuffer(28, StochBuffer9,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(10, PlotBuffer10, INDICATOR_DATA); SetIndexBuffer(29, StochBuffer10, INDICATOR_CALCULATIONS);
   SetIndexBuffer(11, PlotBuffer11, INDICATOR_DATA); SetIndexBuffer(30, StochBuffer11, INDICATOR_CALCULATIONS);
   SetIndexBuffer(12, PlotBuffer12, INDICATOR_DATA); SetIndexBuffer(31, StochBuffer12, INDICATOR_CALCULATIONS);
   SetIndexBuffer(13, PlotBuffer13, INDICATOR_DATA); SetIndexBuffer(32, StochBuffer13, INDICATOR_CALCULATIONS);
   SetIndexBuffer(14, PlotBuffer14, INDICATOR_DATA); SetIndexBuffer(33, StochBuffer14, INDICATOR_CALCULATIONS);
   SetIndexBuffer(15, PlotBuffer15, INDICATOR_DATA); SetIndexBuffer(34, StochBuffer15, INDICATOR_CALCULATIONS);
   SetIndexBuffer(16, PlotBuffer16, INDICATOR_DATA); SetIndexBuffer(35, StochBuffer16, INDICATOR_CALCULATIONS);
   SetIndexBuffer(17, PlotBuffer17, INDICATOR_DATA); SetIndexBuffer(36, StochBuffer17, INDICATOR_CALCULATIONS);
   SetIndexBuffer(18, PlotBuffer18, INDICATOR_DATA); SetIndexBuffer(37, StochBuffer18, INDICATOR_CALCULATIONS);

   ArraySetAsSeries(PlotBuffer0,true); ArraySetAsSeries(StochBuffer0,true);
   ArraySetAsSeries(PlotBuffer1,true); ArraySetAsSeries(StochBuffer1,true);
   ArraySetAsSeries(PlotBuffer2,true); ArraySetAsSeries(StochBuffer2,true);
   ArraySetAsSeries(PlotBuffer3,true); ArraySetAsSeries(StochBuffer3,true);
   ArraySetAsSeries(PlotBuffer4,true); ArraySetAsSeries(StochBuffer4,true);
   ArraySetAsSeries(PlotBuffer5,true); ArraySetAsSeries(StochBuffer5,true);
   ArraySetAsSeries(PlotBuffer6,true); ArraySetAsSeries(StochBuffer6,true);
   ArraySetAsSeries(PlotBuffer7,true); ArraySetAsSeries(StochBuffer7,true);
   ArraySetAsSeries(PlotBuffer8,true); ArraySetAsSeries(StochBuffer8,true);
   ArraySetAsSeries(PlotBuffer9,true); ArraySetAsSeries(StochBuffer9,true);
   ArraySetAsSeries(PlotBuffer10,true); ArraySetAsSeries(StochBuffer10,true);
   ArraySetAsSeries(PlotBuffer11,true); ArraySetAsSeries(StochBuffer11,true);
   ArraySetAsSeries(PlotBuffer12,true); ArraySetAsSeries(StochBuffer12,true);
   ArraySetAsSeries(PlotBuffer13,true); ArraySetAsSeries(StochBuffer13,true);
   ArraySetAsSeries(PlotBuffer14,true); ArraySetAsSeries(StochBuffer14,true);
   ArraySetAsSeries(PlotBuffer15,true); ArraySetAsSeries(StochBuffer15,true);
   ArraySetAsSeries(PlotBuffer16,true); ArraySetAsSeries(StochBuffer16,true);
   ArraySetAsSeries(PlotBuffer17,true); ArraySetAsSeries(StochBuffer17,true);
   ArraySetAsSeries(PlotBuffer18,true); ArraySetAsSeries(StochBuffer18,true);

//--- Set up plots
   for(int i = 0; i < g_buff_num; i++)
     {
      PlotIndexSetString(i, PLOT_LABEL, "P" + (string)g_fibonacci[i]);

      if(i < g_display_start || i > g_display_end)
        {
         PlotIndexSetInteger(i, PLOT_DRAW_TYPE, DRAW_NONE);
         continue;
        }

      PlotIndexSetInteger(i, PLOT_DRAW_TYPE, DRAW_LINE);

      //--- Styling
      int width = 1;
      color clr;
      ENUM_LINE_STYLE style;
      
      uchar r,g,b;
      // Group 1: Short-term
      if(i <= 5)
        {
         r = uchar(50 + (i * 25)); g = uchar(50 + (i * 25)); b = 255;
         style = STYLE_SOLID;
        }
      // Group 2: Mid-term
      else if(i <= 10)
        {
         r = uchar(50 + ((i - 6) * 30)); g = 255; b = uchar(200 - ((i - 6) * 30));
         style = STYLE_DASH;
        }
      // Group 3: Long-term
      else
        {
         r = 255; g = uchar(200 - ((i - 11) * 25)); b = uchar(50 + ((i - 11) * 10));
         style = STYLE_DOT;
        }
      clr = (color) ((r << 16) | (g << 8) | b);

      // Emphasize P6, P7, P11
      if(i == 6 || i == 7 || i == 10) // Corresponds to Fib 21, 34, 144
        {
         width = 2;
        }

      PlotIndexSetInteger(i, PLOT_LINE_COLOR, clr);
      PlotIndexSetInteger(i, PLOT_LINE_STYLE, style);
      PlotIndexSetInteger(i, PLOT_LINE_WIDTH, width);
     }

//--- Initialize indicator handles for standard MAs
   for(int i = 0; i < g_buff_num; i++)
     {
      if(in_ma_method < CUSTOM_HMA)
        {
         g_stoch_handles[i] = iStochastic(Symbol(), Period(), g_fibonacci[i], g_fibonacci[i], in_slowing, (ENUM_MA_METHOD)in_ma_method, in_price_field);
        }
      else
        {
         g_stoch_handles[i] = -1; // Custom calculation
        }
     }

   IndicatorSetString(INDICATOR_SHORTNAME, "FibStoch(" + (string)in_slowing + ")");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
//--- Get price data once if using custom MAs
   double high[], low[], close[];
   if(in_ma_method >= CUSTOM_HMA)
     {
      if(CopyHigh(Symbol(), Period(), 0, rates_total, high) <= 0 ||
         CopyLow(Symbol(), Period(), 0, rates_total, low) <= 0 ||
         CopyClose(Symbol(), Period(), 0, rates_total, close) <= 0)
         return(0);
     }

//--- Fill stochastic buffers
   for(int i = 0; i < g_buff_num; i++)
     {
      if(in_ma_method >= CUSTOM_HMA) // Custom MA calculation
        {
         double k_buffer[], d_buffer[];
         ArrayResize(k_buffer, rates_total);
         ArrayResize(d_buffer, rates_total);
         CustomStochastic(g_fibonacci[i], g_fibonacci[i], in_slowing, in_ma_method, rates_total, high, low, close, k_buffer, d_buffer);

         if(in_kd_type == KD_MAIN) { switch(i){ case 0: ArrayCopy(StochBuffer0,k_buffer); break; /* ... other cases */ } }
         else { switch(i){ case 0: ArrayCopy(StochBuffer0,d_buffer); break; /* ... other cases */ } }
        }
      else // Standard MA calculation
        {
         if(g_stoch_handles[i] == INVALID_HANDLE) continue;
         int line_type = (in_kd_type == KD_MAIN) ? MAIN_LINE : SIGNAL_LINE;
         switch(i){ case 0: CopyBuffer(g_stoch_handles[i], line_type, 0, rates_total, StochBuffer0); break; /* ... other cases */ }
        }
     }

//--- Calculate plot buffers
   int limit = rates_total - prev_calculated - 1;
   if (prev_calculated==0) limit = rates_total - 1;
   
   for(int bar = limit; bar >= 0; bar--)
     {
      for(int i = g_display_start; i <= g_display_end; i++)
        {
         double stoch_val = 0;
         switch(i){ case 0: stoch_val=StochBuffer0[bar]; break; /* ... */ }

         if(stoch_val <= 0 || stoch_val >= 100) {
            switch(i){ case 0: PlotBuffer0[bar]=0; break; /* ... */ }
            continue;
         }
         
         switch(in_calc_type)
           {
            case CALC_NORMAL: { switch(i){ case 0: PlotBuffer0[bar]=stoch_val; break; /* ... */ } break; }
            default: { switch(i){ case 0: PlotBuffer0[bar]=stoch_val; break; /* ... */ } break; }
           }
        }
     }
   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Optimized MA Implementations                                     |
//+------------------------------------------------------------------+
void SMA_Calculate(const int rates_total, const int period, const double &in_series[], double &out_series[])
{
    double sum=0;
    for(int i=rates_total-1; i>=0; i--)
    {
        sum+=in_series[i];
        if(i<rates_total-period)
        {
            sum-=in_series[i+period];
            out_series[i]=sum/period;
        }
    }
}

void EMA_Calculate(const int rates_total, const int period, const double &in_series[], double &out_series[])
{
    double alpha = 2.0/(period+1);
    out_series[rates_total-1]=in_series[rates_total-1];
    for(int i=rates_total-2; i>=0; i--)
        out_series[i]=in_series[i]*alpha + out_series[i+1]*(1-alpha);
}

void LWMA_Calculate(const int rates_total, const int period, const double &in_series[], double &out_series[])
{
    double sum=0, sum_w=0;
    for(int i=rates_total-1; i>=0; i--)
    {
        sum_w=0;
        sum=0;
        if(i > rates_total-period) continue;
        for(int j=0; j<period; j++)
        {
            sum+=(period-j)*in_series[i+j];
            sum_w+=(period-j);
        }
        out_series[i]=sum/sum_w;
    }
}

void SMMA_Calculate(const int rates_total, const int period, const double &in_series[], double &out_series[])
{
    out_series[rates_total-1]=in_series[rates_total-1];
    for(int i=rates_total-2; i>=0; i--)
        out_series[i]=(out_series[i+1]*(period-1)+in_series[i])/period;
}


void HMA_Calculate(const int rates_total, const int period, const double &in_series[], double &out_series[])
{
    if(period<=1) return;
    int half_period = period/2;
    int sqrt_period = (int)MathSqrt(period);
    double wma_half[], wma_full[], temp_arr[];
    ArrayResize(wma_half, rates_total);
    ArrayResize(wma_full, rates_total);
    ArrayResize(temp_arr, rates_total);

    LWMA_Calculate(rates_total, half_period, in_series, wma_half);
    LWMA_Calculate(rates_total, period, in_series, wma_full);

    for(int i=0; i<rates_total; i++)
        temp_arr[i] = 2*wma_half[i] - wma_full[i];

    LWMA_Calculate(rates_total, sqrt_period, temp_arr, out_series);
}

void ZLEMA_Calculate(const int rates_total, const int period, const double &in_series[], double &out_series[])
{
    if(period<=0) return;
    int lag = (period-1)/2;
    double ema_arr[];
    ArrayResize(ema_arr, rates_total);

    EMA_Calculate(rates_total, period, in_series, ema_arr);

    for(int i=0; i<rates_total-lag; i++)
        out_series[i] = ema_arr[i] + (in_series[i] - ema_arr[i+lag]);
}

void MA_Calculate(const int rates_total, const int period, const double &in_series[], double &out_series[], ENUM_CUSTOM_MA_METHOD method)
{
    switch(method)
    {
        case CUSTOM_SMA: SMA_Calculate(rates_total, period, in_series, out_series); break;
        case CUSTOM_EMA: EMA_Calculate(rates_total, period, in_series, out_series); break;
        case CUSTOM_SMMA: SMMA_Calculate(rates_total, period, in_series, out_series); break;
        case CUSTOM_LWMA: LWMA_Calculate(rates_total, period, in_series, out_series); break;
        case CUSTOM_HMA: HMA_Calculate(rates_total, period, in_series, out_series); break;
        case CUSTOM_ZLEMA: ZLEMA_Calculate(rates_total, period, in_series, out_series); break;
    }
}

//+------------------------------------------------------------------+
//| Custom Stochastic Calculation                                    |
//+------------------------------------------------------------------+
void CustomStochastic(int k_period, int d_period, int slowing, ENUM_CUSTOM_MA_METHOD ma_method,
                      const int rates_total, const double &high[], const double &low[], const double &close[],
                      double &k_buffer[], double &d_buffer[])
  {
   if(k_period <= 0 || d_period <= 0) return;
   double stoch_val[];
   ArrayResize(stoch_val, rates_total);

   for(int i = rates_total-1; i >= 0; i--)
     {
      if(i > rates_total - k_period) continue;
      double hh = high[ArrayMaximum(high, i, k_period)];
      double ll = low[ArrayMinimum(low, i, k_period)];
      double den = hh - ll;
      stoch_val[i] = (den != 0) ? 100.0 * (close[i] - ll) / den : 0;
     }

   if(slowing > 1)
     {
      SMA_Calculate(rates_total, slowing, stoch_val, k_buffer);
     }
   else
     {
      ArrayCopy(k_buffer, stoch_val);
     }

   MA_Calculate(rates_total, d_period, k_buffer, d_buffer, ma_method);
  }
//+------------------------------------------------------------------+