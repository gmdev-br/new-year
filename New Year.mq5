//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "© GM, 2020, 2021, 2022, 2023"
#property description "New Year"
#property indicator_chart_window

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum enum_modo {
   Manual,
   Auto,
};

enum enum_modo_forcado {
   ForceTypical, // Typical
   ForceOpen, // Open
   ForceClose, // Close
   ForceMax, // High
   ForceMin, // Low
   ForceArrow // Arrow
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input int                        id = 1;
input datetime                   DefaultInitialDate = "2023.1.2 9:0:00";          // Data inicial padrão
input bool                       shortMode = false;
input int                        input_start = 0;
input int                        input_end = 0;
input enum_modo                  modo = Auto;
input enum_modo_forcado          modo_forcado = ForceArrow;
input double                     percentual_inicial = 0.3;
input double                     percentualMaximo = 20;
input double                     inputIntervalo = 0.5;
input color                      corInicial = clrYellow;
input color                      corPrincipalTypical = clrRoyalBlue;
input color                      corPrincipalHigh = clrRed;
input color                      corPrincipalLow = clrLime;
input int                        largura = 3;
input int                        WaitMilliseconds = 300000;  // Timer (milliseconds) for recalculation
input bool                       extendLines = true;
input ENUM_TIMEFRAMES            input_period = PERIOD_D1;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime                         data_inicial;
int                              barFrom;
string                           uniqueId;
int                              qtdLinhas;
color                            corPrincipal, corSecundaria;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {

   uniqueId = "pullback_" + id + "_";

   data_inicial = DefaultInitialDate;
   barFrom = iBarShift(NULL, PERIOD_CURRENT, data_inicial, false);
   qtdLinhas = percentualMaximo / inputIntervalo;

   _updateTimer = new MillisecondTimer(WaitMilliseconds, false);
   EventSetMillisecondTimer(WaitMilliseconds);

   Update();

   ChartRedraw();

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   delete(_updateTimer);
   if(reason == REASON_REMOVE)
      ObjectsDeleteAll(0, uniqueId);
   ChartRedraw();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Update() {

   data_inicial = DefaultInitialDate;
   int primeiraBarra = WindowFirstVisibleBar();
   datetime dataPrimeiraBarra = iTime(NULL, PERIOD_CURRENT, primeiraBarra);
   datetime data_final = iTime(NULL, PERIOD_CURRENT, 0);
   barFrom = iBarShift(NULL, PERIOD_CURRENT, data_inicial, false);

//for(int i = 0; i <= qtdLinhas; i++) {
   ObjectsDeleteAll(0, uniqueId + "mid_");
   ObjectsDeleteAll(0, uniqueId + "up_");
   ObjectsDeleteAll(0, uniqueId + "dn_");
//}

   double preco, range, max, min;

//+------------------------------------------------------------------+
//| Auto max                                                         |
//+------------------------------------------------------------------+
   if (modo == Auto) {

      if (DefaultInitialDate > iTime(NULL, PERIOD_CURRENT, 0))
         return true;

      int totalRates = SeriesInfoInteger(_Symbol, PERIOD_CURRENT, SERIES_BARS_COUNT);
      int indexTemp = iBarShift(NULL, input_period, data_inicial, false);
      max = iHigh(NULL, input_period, indexTemp);
      min = iLow(NULL, input_period, indexTemp);

      range = MathAbs(max - min);
      //data_inicial = iTime(NULL, PERIOD_CURRENT, indexTemp);
      //if (dataPrimeiraBarra >= data_inicial)
      //   data_inicial = dataPrimeiraBarra;

      ObjectCreate(0, uniqueId + "high", OBJ_TREND, 0, data_inicial, max, data_final, max);
      ObjectSetInteger(0, uniqueId + "high", OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, uniqueId + "high", OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, uniqueId + "high", OBJPROP_WIDTH, 5);
      ObjectSetInteger(0, uniqueId + "high", OBJPROP_RAY_RIGHT, extendLines);

      ObjectCreate(0, uniqueId + "mid", OBJ_TREND, 0, data_inicial, min + range / 2, data_final, min + range / 2);
      ObjectSetInteger(0, uniqueId + "mid", OBJPROP_COLOR, clrYellow);
      ObjectSetInteger(0, uniqueId + "mid", OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, uniqueId + "mid", OBJPROP_WIDTH, 5);
      ObjectSetInteger(0, uniqueId + "mid", OBJPROP_RAY_RIGHT, extendLines);

      ObjectCreate(0, uniqueId + "low", OBJ_TREND, 0, data_inicial, min, data_final, min);
      ObjectSetInteger(0, uniqueId + "low", OBJPROP_COLOR, clrLime);
      ObjectSetInteger(0, uniqueId + "low", OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, uniqueId + "low", OBJPROP_WIDTH, 5);
      ObjectSetInteger(0, uniqueId + "low", OBJPROP_RAY_RIGHT, extendLines);



      for(int i = 1; i <= qtdLinhas; i++) {
         ObjectCreate(0, uniqueId + "up_" + i, OBJ_TREND, 0, data_inicial, max + i * inputIntervalo * range, data_final, max + i * inputIntervalo * range);
         ObjectSetInteger(0, uniqueId + "up_" + i, OBJPROP_RAY_RIGHT, extendLines);
         ObjectSetInteger(0, uniqueId + "up_" + i, OBJPROP_COLOR, clrOrange);
         ObjectSetInteger(0, uniqueId + "up_" + i, OBJPROP_STYLE, STYLE_DOT);
      }

      for(int i = 1; i <= qtdLinhas; i++) {
         ObjectCreate(0, uniqueId + "dn_" + i, OBJ_TREND, 0, data_inicial, min - i * inputIntervalo * range, data_final, min - i * inputIntervalo * range);
         ObjectSetInteger(0, uniqueId + "dn_" + i, OBJPROP_RAY_RIGHT, extendLines);
         ObjectSetInteger(0, uniqueId + "dn_" + i, OBJPROP_COLOR, clrRoyalBlue);
         ObjectSetInteger(0, uniqueId + "dn_" + i, OBJPROP_STYLE, STYLE_DOT);
      }
   }

   if (shortMode) {
      datetime start_time = iTime(_Symbol, PERIOD_CURRENT, 0) + PeriodSeconds() * input_start;
      datetime end_time = iTime(_Symbol, PERIOD_CURRENT, 0) + PeriodSeconds() * input_end;

      for(int i = 0; i <= qtdLinhas; i++) {
         double price = ObjectGetDouble(0, uniqueId + "up_" + i, OBJPROP_PRICE);
         ObjectMove(0, uniqueId + "up_" + i, 0, start_time, price);
         ObjectMove(0, uniqueId + "up_" + i, 1, end_time, price);
         price = ObjectGetDouble(0, uniqueId + "dn_" + i, OBJPROP_PRICE);
         ObjectMove(0, uniqueId + "dn_" + i, 0, start_time, price);
         ObjectMove(0, uniqueId + "dn_" + i, 1, end_time, price);
      }

      ObjectMove(0, uniqueId + "high", 0, start_time, max);
      ObjectMove(0, uniqueId + "high", 1, end_time, max);
      ObjectMove(0, uniqueId + "low", 0, start_time, min);
      ObjectMove(0, uniqueId + "low", 1, end_time, min);
      ObjectMove(0, uniqueId + "mid", 0, start_time, min + range / 2);
      ObjectMove(0, uniqueId + "mid", 1, end_time, min + range / 2);
   }

   _lastOK = false;

   ChartRedraw();

   return true;
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[]) {
   return (1);
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
   CheckTimer();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckTimer() {
   EventKillTimer();

   if(_updateTimer.Check() || !_lastOK) {
      _lastOK = Update();
      //Print("Pullbacks " + " " + _Symbol + ":" + GetTimeFrame(Period()) + " ok");

      EventSetMillisecondTimer(WaitMilliseconds);

      _updateTimer.Reset();
   } else {
      EventSetTimer(1);
   }
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
   //if(id == CHARTEVENT_CHART_CHANGE) {
   //   _lastOK = false;
   //   CheckTimer();
   //   ChartRedraw();
   //}
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MillisecondTimer {

 private:
   int               _milliseconds;
 private:
   uint              _lastTick;

 public:
   void              MillisecondTimer(const int milliseconds, const bool reset = true) {
      _milliseconds = milliseconds;

      if(reset)
         Reset();
      else
         _lastTick = 0;
   }

 public:
   bool              Check() {
      uint now = getCurrentTick();
      bool stop = now >= _lastTick + _milliseconds;

      if(stop)
         _lastTick = now;

      return(stop);
   }

 public:
   void              Reset() {
      _lastTick = getCurrentTick();
   }

 private:
   uint              getCurrentTick() const {
      return(GetTickCount());
   }

};

//+---------------------------------------------------------------------+
//| GetTimeFrame function - returns the textual timeframe               |
//+---------------------------------------------------------------------+
string GetTimeFrame(int lPeriod) {
   switch(lPeriod) {
   case PERIOD_M1:
      return("M1");
   case PERIOD_M2:
      return("M2");
   case PERIOD_M3:
      return("M3");
   case PERIOD_M4:
      return("M4");
   case PERIOD_M5:
      return("M5");
   case PERIOD_M6:
      return("M6");
   case PERIOD_M10:
      return("M10");
   case PERIOD_M12:
      return("M12");
   case PERIOD_M15:
      return("M15");
   case PERIOD_M20:
      return("M20");
   case PERIOD_M30:
      return("M30");
   case PERIOD_H1:
      return("H1");
   case PERIOD_H2:
      return("H2");
   case PERIOD_H3:
      return("H3");
   case PERIOD_H4:
      return("H4");
   case PERIOD_H6:
      return("H6");
   case PERIOD_H8:
      return("H8");
   case PERIOD_H12:
      return("H12");
   case PERIOD_D1:
      return("D1");
   case PERIOD_W1:
      return("W1");
   case PERIOD_MN1:
      return("MN1");
   }
   return IntegerToString(lPeriod);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int WindowFirstVisibleBar() {
   return((int)ChartGetInteger(0, CHART_FIRST_VISIBLE_BAR));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool _lastOK = false;
MillisecondTimer *_updateTimer;
//+------------------------------------------------------------------+
