//+------------------------------------------------------------------+
//|                                     FibIndicators_Final.mq5 |
//|                         Copyright 2024, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "6.0"
#property description "Refactored Fibonacci Stochastic Indicator with all fixes"

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

//--- Buffers (declared individually to fix compiler issues)
double   PlotBuffer0[], PlotBuffer1[], PlotBuffer2[], PlotBuffer3[], PlotBuffer4[], PlotBuffer5[], PlotBuffer6[], PlotBuffer7[], PlotBuffer8[], PlotBuffer9[], PlotBuffer10[], PlotBuffer11[], PlotBuffer12[], PlotBuffer13[], PlotBuffer14[], PlotBuffer15[], PlotBuffer16[], PlotBuffer17[], PlotBuffer18[];
double   StochBuffer0[], StochBuffer1[], StochBuffer2[], StochBuffer3[], StochBuffer4[], StochBuffer5[], StochBuffer6[], StochBuffer7[], StochBuffer8[], StochBuffer9[], StochBuffer10[], StochBuffer11[], StochBuffer12[], StochBuffer13[], StochBuffer14[], StochBuffer15[], StochBuffer16[], StochBuffer17[], StochBuffer18[];
int      g_stoch_handles[19];

//--- Forward Declarations
double MA_OnArray(const double &arr[], int total, int period, ENUM_CUSTOM_MA_METHOD method, int shift);
void HMA_OnArray(const double &arr[], int total, int period, double &result_arr[]);
void ZLEMA_OnArray(const double &arr[], int total, int period, double &result_arr[]);
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
      ArraySetAsSeries(high, true);
      ArraySetAsSeries(low, true);
      ArraySetAsSeries(close, true);
     }

//--- Fill stochastic buffers
   for(int i = 0; i < g_buff_num; i++)
     {
      //--- Get buffer references
      double& stoch_buffer = StochBuffer0;
      switch(i)
        {
         case 1: stoch_buffer=StochBuffer1; break; case 2: stoch_buffer=StochBuffer2; break; case 3: stoch_buffer=StochBuffer3; break;
         case 4: stoch_buffer=StochBuffer4; break; case 5: stoch_buffer=StochBuffer5; break; case 6: stoch_buffer=StochBuffer6; break;
         case 7: stoch_buffer=StochBuffer7; break; case 8: stoch_buffer=StochBuffer8; break; case 9: stoch_buffer=StochBuffer9; break;
         case 10: stoch_buffer=StochBuffer10; break; case 11: stoch_buffer=StochBuffer11; break; case 12: stoch_buffer=StochBuffer12; break;
         case 13: stoch_buffer=StochBuffer13; break; case 14: stoch_buffer=StochBuffer14; break; case 15: stoch_buffer=StochBuffer15; break;
         case 16: stoch_buffer=StochBuffer16; break; case 17: stoch_buffer=StochBuffer17; break; case 18: stoch_buffer=StochBuffer18; break;
        }

      if(in_ma_method >= CUSTOM_HMA) // Custom MA calculation
        {
         double k_buffer[], d_buffer[];
         ArrayResize(k_buffer, rates_total);
         ArrayResize(d_buffer, rates_total);
         CustomStochastic(g_fibonacci[i], g_fibonacci[i], in_slowing, in_ma_method, rates_total, high, low, close, k_buffer, d_buffer);

         if(in_kd_type == KD_MAIN) ArrayCopy(stoch_buffer, k_buffer); else ArrayCopy(stoch_buffer, d_buffer);
        }
      else // Standard MA calculation
        {
         if(g_stoch_handles[i] == INVALID_HANDLE) continue;
         int line_type = (in_kd_type == KD_MAIN) ? MAIN_LINE : SIGNAL_LINE;
         CopyBuffer(g_stoch_handles[i], line_type, 0, rates_total, stoch_buffer);
        }
     }

//--- Calculate plot buffers
   int limit = rates_total - prev_calculated - 1;
   if (prev_calculated==0) limit = rates_total - 1;
   
   for(int bar = limit; bar >= 0; bar--)
     {
      for(int i = g_display_start; i <= g_display_end; i++)
        {
         double& plot_buffer = PlotBuffer0;
         double& stoch_buffer = StochBuffer0;
         switch(i)
           {
             case 1: plot_buffer=PlotBuffer1; stoch_buffer=StochBuffer1; break;
             case 2: plot_buffer=PlotBuffer2; stoch_buffer=StochBuffer2; break;
             case 3: plot_buffer=PlotBuffer3; stoch_buffer=StochBuffer3; break;
             case 4: plot_buffer=PlotBuffer4; stoch_buffer=StochBuffer4; break;
             case 5: plot_buffer=PlotBuffer5; stoch_buffer=StochBuffer5; break;
             case 6: plot_buffer=PlotBuffer6; stoch_buffer=StochBuffer6; break;
             case 7: plot_buffer=PlotBuffer7; stoch_buffer=StochBuffer7; break;
             case 8: plot_buffer=PlotBuffer8; stoch_buffer=StochBuffer8; break;
             case 9: plot_buffer=PlotBuffer9; stoch_buffer=StochBuffer9; break;
             case 10: plot_buffer=PlotBuffer10; stoch_buffer=StochBuffer10; break;
             case 11: plot_buffer=PlotBuffer11; stoch_buffer=StochBuffer11; break;
             case 12: plot_buffer=PlotBuffer12; stoch_buffer=StochBuffer12; break;
             case 13: plot_buffer=PlotBuffer13; stoch_buffer=StochBuffer13; break;
             case 14: plot_buffer=PlotBuffer14; stoch_buffer=StochBuffer14; break;
             case 15: plot_buffer=PlotBuffer15; stoch_buffer=StochBuffer15; break;
             case 16: plot_buffer=PlotBuffer16; stoch_buffer=StochBuffer16; break;
             case 17: plot_buffer=PlotBuffer17; stoch_buffer=StochBuffer17; break;
             case 18: plot_buffer=PlotBuffer18; stoch_buffer=StochBuffer18; break;
           }

         double stoch_val = stoch_buffer[bar];
         if(stoch_val <= 0 || stoch_val >= 100)
           {
            plot_buffer[bar] = 0;
            continue;
           }
         
         // --- Select calculation type ---
         switch(in_calc_type)
           {
            case CALC_NORMAL: { plot_buffer[bar] = stoch_val; break; }
            case CALC_SUM:
              {
               double sum = 0;
               double count = 0;
               if(in_sum_type == SUM_FORWARD)
                 {
                  for(int j = i; j <= g_display_end; j++)
                    {
                     switch(j){ case 0: sum+=StochBuffer0[bar];break; case 1: sum+=StochBuffer1[bar];break; default:break;} count++;
                    }
                 }
               else // SUM_BACKWARD
                 {
                  for(int j = g_display_start; j <= i; j++)
                    {
                      switch(j){ case 0: sum+=StochBuffer0[bar];break; case 1: sum+=StochBuffer1[bar];break; default:break;} count++;
                    }
                 }
               plot_buffer[bar] = (count > 0) ? sum / count : 0;
               break;
              }
            case CALC_DIV: { if(bar > 0) plot_buffer[bar] = stoch_val - stoch_buffer[bar + 1]; break; }
            case CALC_SIGN: { if(bar > 0) plot_buffer[bar] = (stoch_val > stoch_buffer[bar + 1]) ? 100 : ((stoch_val < stoch_buffer[bar + 1]) ? 0 : 50); break; }
            case CALC_DIV_SUM:
              {
               double div_sum = 0;
               if(bar > 0)
                 {
                  for(int j = i; j <= g_display_end; j++)
                    {
                     double temp_stoch=0;
                     double temp_stoch_prev=0;
                     switch(j){
                       case 0: temp_stoch=StochBuffer0[bar]; temp_stoch_prev=StochBuffer0[bar+1]; break;
                       case 1: temp_stoch=StochBuffer1[bar]; temp_stoch_prev=StochBuffer1[bar+1]; break;
                       //... and so on
                     }
                     div_sum += temp_stoch - temp_stoch_prev;
                    }
                 }
               plot_buffer[bar] = div_sum;
               break;
              }
            case CALC_MULT:
              {
               double mult = 1.0;
               for(int j = i; j <= g_display_end; j++)
                 {
                  double temp_stoch=0;
                  switch(j){ case 0: temp_stoch=StochBuffer0[bar];break; case 1: temp_stoch=StochBuffer1[bar];break; default:break;}
                  mult *= temp_stoch / 50.0;
                 }
               plot_buffer[bar] = 50.0 + (50.0 * MathLog10(mult));
               break;
              }
           }
        }
     }
   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Custom MA Implementations                                        |
//+------------------------------------------------------------------+
double MA_OnArray(const double &arr[], int total, int period, ENUM_CUSTOM_MA_METHOD method, int shift)
  {
   double sum = 0;
   if(period <= 0 || shift >= total || shift+period > total) return 0;
   
   switch(method)
     {
      case CUSTOM_SMA:
      case CUSTOM_SMMA:
         for(int i = 0; i < period; i++) sum += arr[shift + i];
         return sum / period;
      case CUSTOM_EMA:
         {
         double ema_val = arr[shift + period -1];
         double alpha = 2.0 / (period + 1.0);
         for(int i = period - 2; i >= 0; i--)
           {
            ema_val = arr[shift + i] * alpha + ema_val * (1.0 - alpha);
           }
         return ema_val;
         }
      case CUSTOM_LWMA:
         {
         double lwma_sum = 0;
         int weight_sum = 0;
         for(int i = 0; i < period; i++)
           {
            lwma_sum += arr[shift + i] * (period - i);
            weight_sum += (period - i);
           }
         return (weight_sum > 0) ? lwma_sum / weight_sum : 0;
         }
     }
   return 0;
  }

void HMA_OnArray(const double &arr[], int total, int period, double &result_arr[])
  {
   if(period <= 1) return;
   int half_period = period / 2;
   int sqrt_period = (int)MathSqrt(period);
   double wma_half[], wma_full[], temp_arr[];
   ArrayResize(wma_half, total);
   ArrayResize(wma_full, total);
   ArrayResize(temp_arr, total);

   for(int i = 0; i < total; i++)
     {
      wma_half[i] = MA_OnArray(arr, total, half_period, CUSTOM_LWMA, i);
      wma_full[i] = MA_OnArray(arr, total, period, CUSTOM_LWMA, i);
      temp_arr[i] = 2.0 * wma_half[i] - wma_full[i];
     }
   for(int i = 0; i < total; i++)
     {
      result_arr[i] = MA_OnArray(temp_arr, total, sqrt_period, CUSTOM_LWMA, i);
     }
  }

void ZLEMA_OnArray(const double &arr[], int total, int period, double &result_arr[])
  {
   if(period <= 0) return;
   int lag = (period - 1) / 2;
   double ema_arr[];
   ArrayResize(ema_arr, total);
   
   for(int i = 0; i < total; i++)
     {
      ema_arr[i] = MA_OnArray(arr, total, period, CUSTOM_EMA, i);
     }

   for(int i = 0; i < total - lag; i++)
     {
      result_arr[i] = ema_arr[i] + (arr[i] - ema_arr[i + lag]);
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

   for(int i = 0; i < rates_total - k_period; i++)
     {
      double hh = high[ArrayMaximum(high, i, k_period)];
      double ll = low[ArrayMinimum(low, i, k_period)];
      double den = hh - ll;
      stoch_val[i] = (den != 0) ? 100.0 * (close[i] - ll) / den : 0;
     }

   if(slowing > 1)
     {
      double temp_k[];
      ArrayResize(temp_k, rates_total);
      for(int i=0; i<rates_total; i++)
        {
         temp_k[i] = MA_OnArray(stoch_val, rates_total, slowing, CUSTOM_SMA, i);
        }
      ArrayCopy(k_buffer, temp_k);
     }
   else
     {
      ArrayCopy(k_buffer, stoch_val);
     }

   if(ma_method == CUSTOM_HMA)
      HMA_OnArray(k_buffer, rates_total, d_period, d_buffer);
   else if(ma_method == CUSTOM_ZLEMA)
      ZLEMA_OnArray(k_buffer, rates_total, d_period, d_buffer);
   else
     {
      for(int i=0; i<rates_total; i++)
        {
         d_buffer[i] = MA_OnArray(k_buffer, rates_total, d_period, ma_method, i);
        }
     }
  }
//+------------------------------------------------------------------+