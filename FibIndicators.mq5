//+------------------------------------------------------------------+
//|                                     FibIndicators_Final.mq5 |
//|                         Copyright 2024, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "12.0"
#property description "Refactored Fibonacci Stochastic Indicator with all fixes and full implementation"

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
   CUSTOM_ZLEMA,   // Zero-Lag Exponential Moving Average
   CUSTOM_TEMA     // Triple Exponential Moving Average
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


//--- Forward Declarations for Optimized MA calculations
void SMA_Calculate(const int rates_total, const int prev_calculated, const int period, const double &in_series[], double &out_series[]);
void EMA_Calculate(const int rates_total, const int prev_calculated, const int period, const double &in_series[], double &out_series[]);
void LWMA_Calculate(const int rates_total, const int prev_calculated, const int period, const double &in_series[], double &out_series[]);
void SMMA_Calculate(const int rates_total, const int prev_calculated, const int period, const double &in_series[], double &out_series[]);
void HMA_Calculate(const int rates_total, const int prev_calculated, const int period, const double &in_series[], double &out_series[]);
void ZLEMA_Calculate(const int rates_total, const int prev_calculated, const int period, const double &in_series[], double &out_series[]);
void TEMA_Calculate(const int rates_total, const int prev_calculated, const int period, const double &in_series[], double &out_series[]);
void MA_Calculate(const int rates_total, const int prev_calculated, const int period, const double &in_series[], double &out_series[], ENUM_CUSTOM_MA_METHOD method);
void CustomStochastic(int k_period, int d_period, int slowing, ENUM_CUSTOM_MA_METHOD ma_method, const int rates_total, const int prev_calculated, const double &high[], const double &low[], const double &close[], double &k_buffer[], double &d_buffer[]);

void MA_Calculate(const int rates_total, const int prev_calculated, const int period, const double &in_series[], double &out_series[], ENUM_CUSTOM_MA_METHOD method)
{
    switch(method)
    {
        case CUSTOM_SMA:   SMA_Calculate(rates_total, prev_calculated, period, in_series, out_series); break;
        case CUSTOM_EMA:   EMA_Calculate(rates_total, prev_calculated, period, in_series, out_series); break;
        case CUSTOM_SMMA:  SMMA_Calculate(rates_total, prev_calculated, period, in_series, out_series); break;
        case CUSTOM_LWMA:  LWMA_Calculate(rates_total, prev_calculated, period, in_series, out_series); break;
        case CUSTOM_HMA:   HMA_Calculate(rates_total, prev_calculated, period, in_series, out_series); break;
        case CUSTOM_ZLEMA: ZLEMA_Calculate(rates_total, prev_calculated, period, in_series, out_series); break;
        case CUSTOM_TEMA:  TEMA_Calculate(rates_total, prev_calculated, period, in_series, out_series); break;
    }
}

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
      PlotIndexSetDouble(i, PLOT_EMPTY_VALUE, EMPTY_VALUE);

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

//--- Initialize indicator handles
   for(int i = 0; i < g_buff_num; i++)
     {
      if(in_ma_method < CUSTOM_HMA) // Standard MAs
        {
         g_stoch_handles[i] = iStochastic(Symbol(), Period(), g_fibonacci[i], g_fibonacci[i], in_slowing, (ENUM_MA_METHOD)in_ma_method, in_price_field);
        }
      else // Custom MAs
        {
         g_stoch_handles[i] = -1;
        }
     }

   IndicatorSetString(INDICATOR_SHORTNAME, "FibStoch(" + (string)in_slowing + ")");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Helper function to get a value from the correct Stoch buffer     |
//+------------------------------------------------------------------+
double GetStochValue(int index, int bar)
  {
   switch(index)
     {
      case 0: return StochBuffer0[bar];
      case 1: return StochBuffer1[bar];
      case 2: return StochBuffer2[bar];
      case 3: return StochBuffer3[bar];
      case 4: return StochBuffer4[bar];
      case 5: return StochBuffer5[bar];
      case 6: return StochBuffer6[bar];
      case 7: return StochBuffer7[bar];
      case 8: return StochBuffer8[bar];
      case 9: return StochBuffer9[bar];
      case 10: return StochBuffer10[bar];
      case 11: return StochBuffer11[bar];
      case 12: return StochBuffer12[bar];
      case 13: return StochBuffer13[bar];
      case 14: return StochBuffer14[bar];
      case 15: return StochBuffer15[bar];
      case 16: return StochBuffer16[bar];
      case 17: return StochBuffer17[bar];
      case 18: return StochBuffer18[bar];
      default: return 0.0;
     }
  }

//+------------------------------------------------------------------+
//| Helper function to get a reference to the correct Plot buffer    |
//+------------------------------------------------------------------+
double& GetPlotBuffer(int index)
  {
   switch(index)
     {
      case 0: return PlotBuffer0;
      case 1: return PlotBuffer1;
      case 2: return PlotBuffer2;
      case 3: return PlotBuffer3;
      case 4: return PlotBuffer4;
      case 5: return PlotBuffer5;
      case 6: return PlotBuffer6;
      case 7: return PlotBuffer7;
      case 8: return PlotBuffer8;
      case 9: return PlotBuffer9;
      case 10: return PlotBuffer10;
      case 11: return PlotBuffer11;
      case 12: return PlotBuffer12;
      case 13: return PlotBuffer13;
      case 14: return PlotBuffer14;
      case 15: return PlotBuffer15;
      case 16: return PlotBuffer16;
      case 17: return PlotBuffer17;
      case 18: return PlotBuffer18;
     }
   return PlotBuffer0; // Should not happen
  }

//+------------------------------------------------------------------+
//| Helper function to set a value in the correct Plot buffer        |
//+------------------------------------------------------------------+
void SetPlotValue(int index, int bar, double value)
  {
   switch(index)
     {
      case 0: PlotBuffer0[bar] = value; break;
      case 1: PlotBuffer1[bar] = value; break;
      case 2: PlotBuffer2[bar] = value; break;
      case 3: PlotBuffer3[bar] = value; break;
      case 4: PlotBuffer4[bar] = value; break;
      case 5: PlotBuffer5[bar] = value; break;
      case 6: PlotBuffer6[bar] = value; break;
      case 7: PlotBuffer7[bar] = value; break;
      case 8: PlotBuffer8[bar] = value; break;
      case 9: PlotBuffer9[bar] = value; break;
      case 10: PlotBuffer10[bar] = value; break;
      case 11: PlotBuffer11[bar] = value; break;
      case 12: PlotBuffer12[bar] = value; break;
      case 13: PlotBuffer13[bar] = value; break;
      case 14: PlotBuffer14[bar] = value; break;
      case 15: PlotBuffer15[bar] = value; break;
      case 16: PlotBuffer16[bar] = value; break;
      case 17: PlotBuffer17[bar] = value; break;
      case 18: PlotBuffer18[bar] = value; break;
     }
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
         CustomStochastic(g_fibonacci[i], g_fibonacci[i], in_slowing, in_ma_method, rates_total, prev_calculated, high, low, close, k_buffer, d_buffer);

         if(in_kd_type == KD_MAIN)
           {
            switch(i){
             case 0: ArrayCopy(StochBuffer0, k_buffer); break; case 1: ArrayCopy(StochBuffer1, k_buffer); break; case 2: ArrayCopy(StochBuffer2, k_buffer); break;
             case 3: ArrayCopy(StochBuffer3, k_buffer); break; case 4: ArrayCopy(StochBuffer4, k_buffer); break; case 5: ArrayCopy(StochBuffer5, k_buffer); break;
             case 6: ArrayCopy(StochBuffer6, k_buffer); break; case 7: ArrayCopy(StochBuffer7, k_buffer); break; case 8: ArrayCopy(StochBuffer8, k_buffer); break;
             case 9: ArrayCopy(StochBuffer9, k_buffer); break; case 10: ArrayCopy(StochBuffer10, k_buffer); break; case 11: ArrayCopy(StochBuffer11, k_buffer); break;
             case 12: ArrayCopy(StochBuffer12, k_buffer); break; case 13: ArrayCopy(StochBuffer13, k_buffer); break; case 14: ArrayCopy(StochBuffer14, k_buffer); break;
             case 15: ArrayCopy(StochBuffer15, k_buffer); break; case 16: ArrayCopy(StochBuffer16, k_buffer); break; case 17: ArrayCopy(StochBuffer17, k_buffer); break;
             case 18: ArrayCopy(StochBuffer18, k_buffer); break;
            }
           }
         else
           {
            switch(i){
             case 0: ArrayCopy(StochBuffer0, d_buffer); break; case 1: ArrayCopy(StochBuffer1, d_buffer); break; case 2: ArrayCopy(StochBuffer2, d_buffer); break;
             case 3: ArrayCopy(StochBuffer3, d_buffer); break; case 4: ArrayCopy(StochBuffer4, d_buffer); break; case 5: ArrayCopy(StochBuffer5, d_buffer); break;
             case 6: ArrayCopy(StochBuffer6, d_buffer); break; case 7: ArrayCopy(StochBuffer7, d_buffer); break; case 8: ArrayCopy(StochBuffer8, d_buffer); break;
             case 9: ArrayCopy(StochBuffer9, d_buffer); break; case 10: ArrayCopy(StochBuffer10, d_buffer); break; case 11: ArrayCopy(StochBuffer11, d_buffer); break;
             case 12: ArrayCopy(StochBuffer12, d_buffer); break; case 13: ArrayCopy(StochBuffer13, d_buffer); break; case 14: ArrayCopy(StochBuffer14, d_buffer); break;
             case 15: ArrayCopy(StochBuffer15, d_buffer); break; case 16: ArrayCopy(StochBuffer16, d_buffer); break; case 17: ArrayCopy(StochBuffer17, d_buffer); break;
             case 18: ArrayCopy(StochBuffer18, d_buffer); break;
            }
           }
        }
      else // Standard MA calculation
        {
         if(g_stoch_handles[i] == INVALID_HANDLE) continue;
         int line_type = (in_kd_type == KD_MAIN) ? MAIN_LINE : SIGNAL_LINE;
         switch(i)
           {
            case 0: CopyBuffer(g_stoch_handles[i], line_type, 0, rates_total, StochBuffer0); break;
            case 1: CopyBuffer(g_stoch_handles[i], line_type, 0, rates_total, StochBuffer1); break;
            case 2: CopyBuffer(g_stoch_handles[i], line_type, 0, rates_total, StochBuffer2); break;
            case 3: CopyBuffer(g_stoch_handles[i], line_type, 0, rates_total, StochBuffer3); break;
            case 4: CopyBuffer(g_stoch_handles[i], line_type, 0, rates_total, StochBuffer4); break;
            case 5: CopyBuffer(g_stoch_handles[i], line_type, 0, rates_total, StochBuffer5); break;
            case 6: CopyBuffer(g_stoch_handles[i], line_type, 0, rates_total, StochBuffer6); break;
            case 7: CopyBuffer(g_stoch_handles[i], line_type, 0, rates_total, StochBuffer7); break;
            case 8: CopyBuffer(g_stoch_handles[i], line_type, 0, rates_total, StochBuffer8); break;
            case 9: CopyBuffer(g_stoch_handles[i], line_type, 0, rates_total, StochBuffer9); break;
            case 10: CopyBuffer(g_stoch_handles[i], line_type, 0, rates_total, StochBuffer10); break;
            case 11: CopyBuffer(g_stoch_handles[i], line_type, 0, rates_total, StochBuffer11); break;
            case 12: CopyBuffer(g_stoch_handles[i], line_type, 0, rates_total, StochBuffer12); break;
            case 13: CopyBuffer(g_stoch_handles[i], line_type, 0, rates_total, StochBuffer13); break;
            case 14: CopyBuffer(g_stoch_handles[i], line_type, 0, rates_total, StochBuffer14); break;
            case 15: CopyBuffer(g_stoch_handles[i], line_type, 0, rates_total, StochBuffer15); break;
            case 16: CopyBuffer(g_stoch_handles[i], line_type, 0, rates_total, StochBuffer16); break;
            case 17: CopyBuffer(g_stoch_handles[i], line_type, 0, rates_total, StochBuffer17); break;
            case 18: CopyBuffer(g_stoch_handles[i], line_type, 0, rates_total, StochBuffer18); break;
           }
        }
     }

//--- Calculate plot buffers
   int limit = rates_total - prev_calculated - 1;
   if(prev_calculated == 0) limit = rates_total - 1;

   for(int bar = limit; bar >= 0; bar--)
     {
      // --- Create a temporary array of stochastic values for the current bar ---
      double current_stoch_values[19];
      for(int i = 0; i < g_buff_num; i++)
        {
         double stoch_val = GetStochValue(i, bar);
         if(stoch_val > 0.0 && stoch_val < 100.0)
           {
            current_stoch_values[i] = stoch_val;
           }
         else
           {
            current_stoch_values[i] = 0.0;
           }
        }

      for(int i = g_display_start; i <= g_display_end; i++)
        {
         double plot_value = EMPTY_VALUE;
         double current_stoch = current_stoch_values[i];

         if(current_stoch == EMPTY_VALUE)
           {
            SetPlotValue(i, bar, EMPTY_VALUE);
            continue;
           }

         // --- Select calculation type ---
         double &plot_buffer = GetPlotBuffer(i);
         switch(in_calc_type)
           {
            case CALC_NORMAL:  CalcPlotBufferNormal(i, bar, rates_total, current_stoch_values, plot_buffer); break;
            case CALC_SUM:     CalcPlotBufferSum(i, bar, rates_total, current_stoch_values, plot_buffer); break;
            case CALC_DIV:     CalcPlotBufferDiv(i, bar, rates_total, current_stoch_values, plot_buffer); break;
            case CALC_SIGN:    CalcPlotBufferSign(i, bar, rates_total, current_stoch_values, plot_buffer); break;
            case CALC_DIV_SUM: CalcPlotBufferDivSum(i, bar, rates_total, current_stoch_values, plot_buffer); break;
            case CALC_MULT:    CalcPlotBufferMult(i, bar, rates_total, current_stoch_values, plot_buffer); break;
            default:           plot_buffer[bar] = EMPTY_VALUE; break;
           }
        }
     }
   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Calculation Helper Functions                                     |
//+------------------------------------------------------------------+
int CalcPlotBufferNormal(int index, int bar, int rates_total, const double &stoch_values[], double &plot_buffer[]) {
    double val = stoch_values[index];
    if(val > 0.0 && val <= 100.0) plot_buffer[bar] = val;
    else plot_buffer[bar] = EMPTY_VALUE;
    return(INIT_SUCCEEDED);
}

int CalcPlotBufferSum(int index, int bar, int rates_total, const double &stoch_values[], double &plot_buffer[]) {
    double val = 0.0;
    double w_sum = 0.0;

    if(in_sum_type == SUM_FORWARD) { // Original SumType == 0
        for(int i = index; i < g_buff_num; i++) {
            double w = 1.0;
            w_sum += w;
            double stochVal = stoch_values[i];
            if(stochVal > 0.0 && stochVal <= 100.0) val += stochVal * w;
        }
    } else { // Original SumType != 0 (SUM_BACKWARD)
        w_sum = 1.0;
        for(int i = 0; i <= index; i++) {
            double stochVal = stoch_values[i];
            if(stochVal > 0.0 && stochVal <= 100.0) val += stochVal / (index + 1);
        }
    }

    plot_buffer[bar] = (w_sum > 0) ? (val / w_sum) : EMPTY_VALUE;
    return(INIT_SUCCEEDED);
}

int CalcPlotBufferDiv(int index, int bar, int rates_total, const double &stoch_values[], double &plot_buffer[]) {
    if(bar < rates_total - 1) {
        double current_stoch = stoch_values[index];
        double prev_stoch = GetStochValue(index, bar + 1); // Get previous bar's value
        if(current_stoch != EMPTY_VALUE && prev_stoch != EMPTY_VALUE) {
            double val = current_stoch - prev_stoch;
            plot_buffer[bar] = index * index * val;
        } else {
            plot_buffer[bar] = EMPTY_VALUE;
        }
    } else {
        plot_buffer[bar] = EMPTY_VALUE;
    }
    return(INIT_SUCCEEDED);
}

int CalcPlotBufferSign(int index, int bar, int rates_total, const double &stoch_values[], double &plot_buffer[]) {
    double val = 0.0;
    if(bar < rates_total - 1) {
        double stochVal = stoch_values[index];
        double prevStochVal = GetStochValue(index, bar + 1);
        if(stochVal > 0.0 && stochVal <= 100.0 && prevStochVal > 0.0 && prevStochVal <= 100.0) {
            val = (((stochVal - prevStochVal) > 0) * 2 - 1) * index;
        }
    }
    plot_buffer[bar] = (val != 0.0) ? val : EMPTY_VALUE;
    return(INIT_SUCCEEDED);
}

int CalcPlotBufferDivSum(int index, int bar, int rates_total, const double &stoch_values[], double &plot_buffer[]) {
    double val = 0.0;
    if(bar < rates_total - 1) {
        for(int i = index; i < g_buff_num; i++) {
            double stochCurr = GetStochValue(i, bar);
            double stochPrev = GetStochValue(i, bar + 1);
            if(stochCurr > 0.0 && stochCurr <= 100.0 && stochPrev > 0.0 && stochPrev <= 100.0) {
                double div = stochCurr - stochPrev;
                val += div / (g_buff_num - index);
            }
        }
    }
    plot_buffer[bar] = (val != 0.0) ? val : EMPTY_VALUE;
    return(INIT_SUCCEEDED);
}

int CalcPlotBufferMult(int index, int bar, int rates_total, const double &stoch_values[], double &plot_buffer[]) {
    double val = 1.0;
    for(int i = index; i < g_buff_num; i++) {
        double stochVal = stoch_values[i];
        if(stochVal > 0.0 && stochVal <= 100.0) val *= (stochVal / 100.0) / 0.5;
    }
    plot_buffer[bar] = (val > 0) ? MathLog10(val) : EMPTY_VALUE;
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Optimized MA Implementations                                     |
//+------------------------------------------------------------------+
void SMA_Calculate(const int rates_total, const int prev_calculated, const int period, const double &in_series[], double &out_series[])
{
    SimpleMAOnBuffer(rates_total, prev_calculated, 0, period, in_series, out_series);
}

void EMA_Calculate(const int rates_total, const int prev_calculated, const int period, const double &in_series[], double &out_series[])
{
    ExponentialMAOnBuffer(rates_total, prev_calculated, 0, period, in_series, out_series);
}

void LWMA_Calculate(const int rates_total, const int prev_calculated, const int period, const double &in_series[], double &out_series[])
{
    LinearWeightedMAOnBuffer(rates_total, prev_calculated, 0, period, in_series, out_series);
}

void SMMA_Calculate(const int rates_total, const int prev_calculated, const int period, const double &in_series[], double &out_series[])
{
    SmoothedMAOnBuffer(rates_total, prev_calculated, 0, period, in_series, out_series);
}

void HMA_Calculate(const int rates_total, const int prev_calculated, const int period, const double &in_series[], double &out_series[]) {
   if(period < 2) return;

   int half_period = period / 2 > 0 ? period / 2 : 1;
   int sqrt_period = (int)MathRound(MathSqrt(period));
   if(sqrt_period < 1) sqrt_period = 1;

   double lwma_half_buffer[], lwma_full_buffer[], intermediate_buffer[];
   ArrayResize(lwma_half_buffer, rates_total);
   ArrayResize(lwma_full_buffer, rates_total);
   ArrayResize(intermediate_buffer, rates_total);

   if(prev_calculated == 0) {
      ArrayInitialize(lwma_half_buffer, EMPTY_VALUE);
      ArrayInitialize(lwma_full_buffer, EMPTY_VALUE);
      ArrayInitialize(intermediate_buffer, EMPTY_VALUE);
   }

   LinearWeightedMAOnBuffer(rates_total, prev_calculated, 0, half_period, in_series, lwma_half_buffer);
   LinearWeightedMAOnBuffer(rates_total, prev_calculated, 0, period, in_series, lwma_full_buffer);

   int start_pos = (prev_calculated > 1) ? rates_total - prev_calculated -1 : 0;
   for(int i = start_pos; i < rates_total; i++) {
      if(lwma_half_buffer[i] != EMPTY_VALUE && lwma_full_buffer[i] != EMPTY_VALUE)
         intermediate_buffer[i] = 2 * lwma_half_buffer[i] - lwma_full_buffer[i];
      else
         intermediate_buffer[i] = EMPTY_VALUE;
   }

   LinearWeightedMAOnBuffer(rates_total, prev_calculated, 0, sqrt_period, intermediate_buffer, out_series);
}

void ZLEMA_Calculate(const int rates_total, const int prev_calculated, const int period, const double &in_series[], double &out_series[]) {
    if(period <= 0) return;
    int lag = (period - 1) / 2;
    double ema_arr[];
    ArrayResize(ema_arr, rates_total);
    if(prev_calculated == 0) ArrayInitialize(ema_arr, EMPTY_VALUE);

    ExponentialMAOnBuffer(rates_total, prev_calculated, 0, period, in_series, ema_arr);

    int start_pos = (prev_calculated > 1) ? rates_total - prev_calculated -1 : 0;
    for(int i = start_pos; i < rates_total; i++) {
        if (i + lag >= rates_total) {
            out_series[i] = EMPTY_VALUE;
            continue;
        }
        if (ema_arr[i] != EMPTY_VALUE && in_series[i] != EMPTY_VALUE && ema_arr[i + lag] != EMPTY_VALUE) {
            out_series[i] = ema_arr[i] + (in_series[i] - ema_arr[i + lag]);
        } else {
            out_series[i] = EMPTY_VALUE;
        }
    }
}

void TEMA_Calculate(const int rates_total, const int prev_calculated, const int period, const double &in_series[], double &out_series[]) {
   if(period < 2) return;

   double ema1[], ema2[], ema3[];
   ArrayResize(ema1, rates_total);
   ArrayResize(ema2, rates_total);
   ArrayResize(ema3, rates_total);

   if(prev_calculated == 0) {
      ArrayInitialize(ema1, EMPTY_VALUE);
      ArrayInitialize(ema2, EMPTY_VALUE);
      ArrayInitialize(ema3, EMPTY_VALUE);
   }

   ExponentialMAOnBuffer(rates_total, prev_calculated, 0, period, in_series, ema1);
   ExponentialMAOnBuffer(rates_total, prev_calculated, 0, period, ema1, ema2);
   ExponentialMAOnBuffer(rates_total, prev_calculated, 0, period, ema2, ema3);

   int start_pos = (prev_calculated > 1) ? rates_total - prev_calculated -1 : 0;
   for(int i = start_pos; i < rates_total; i++) {
      if(ema1[i] != EMPTY_VALUE && ema2[i] != EMPTY_VALUE && ema3[i] != EMPTY_VALUE)
         out_series[i] = 3 * ema1[i] - 3 * ema2[i] + ema3[i];
      else
         out_series[i] = EMPTY_VALUE;
   }
}

//+------------------------------------------------------------------+
//| Custom Stochastic Calculation                                    |
//+------------------------------------------------------------------+
void CustomStochastic(int k_period, int d_period, int slowing, ENUM_CUSTOM_MA_METHOD ma_method,
                      const int rates_total, const int prev_calculated, const double &high[], const double &low[], const double &close[],
                      double &k_buffer[], double &d_buffer[])
  {
   if(k_period <= 0 || d_period <= 0) return;
   double stoch_val[];
   ArrayResize(stoch_val, rates_total);

   // On first run, initialize the whole array to EMPTY_VALUE
   if(prev_calculated == 0)
      ArrayInitialize(stoch_val, EMPTY_VALUE);

   // Determine the starting position for calculation
   int start_pos = rates_total - 1;
   if(prev_calculated > 0)
      start_pos = rates_total - prev_calculated;
   if(start_pos < 0) start_pos = 0;

   for(int i = start_pos; i >= 0; i--)
     {
      // Ensure there are enough bars for the calculation
      if (i + k_period > rates_total) {
          stoch_val[i] = EMPTY_VALUE;
          continue;
      }

      double hh = high[ArrayMaximum(high, i, k_period)];
      double ll = low[ArrayMinimum(low, i, k_period)];
      double den = hh - ll;
      stoch_val[i] = (den != 0) ? 100.0 * (close[i] - ll) / den : 0.0;
     }

   if(slowing > 1)
     {
      SMA_Calculate(rates_total, prev_calculated, slowing, stoch_val, k_buffer);
     }
   else
     {
      // If not slowing, copy stoch_val directly to k_buffer for the calculated range
       for(int i = start_pos; i >= 0; i--)
         k_buffer[i] = stoch_val[i];
     }

   MA_Calculate(rates_total, prev_calculated, d_period, k_buffer, d_buffer, ma_method);
  }
//+------------------------------------------------------------------+