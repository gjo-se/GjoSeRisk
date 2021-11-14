/*

   IND_GjoSeRisk.mq5
   Copyright 2021, Gregory Jo
   https://www.gjo-se.com

   Doku: https://gjo-se.atlassian.net/wiki/spaces/FINALLG/pages/1106935918/Geldmanagement+-+GM

   Version History
   ===============

   1.0.0 Initial version

   ===============

//*/

#include <GjoSe\\Utilities\\InclBasicUtilities.mqh>
#include <GjoSe\\Objects\\InclLabel.mqh>
#include <GjoSe\\Objects\\InclHLine.mqh>
#include <GjoSe\\Objects\\InclTrendLine.mqh>

#property   copyright   "2021, GjoSe"
#property   link        "http://www.gjo-se.com"
#property   description "GjoSe Risk Management"
#define     VERSION "1.0"
#property   version VERSION
#property   strict

#property indicator_separate_window
#property indicator_plots               0
#property indicator_buffers             0
#property indicator_minimum             0.0
#property indicator_maximum             0.0

input int InpSymbolCount = 5;
input double InpMaxAccountRiskPercent = 10;
input double InpMaxPositionRiskPercent = 50;
input double InpMinRRR = 2;

input double InpPipValueCHFJPY = 7.60;
input double InpPipValueEURJPY = 7.60;
input double InpPipValueEURUSD = 8.60;
input double InpPipValueGBPAUD = 7.60;
input double InpPipValueGBPJPY = 7.60;
input double InpPipValueGBPUSD = 8.60;
input double InpPipValueXAUUSD = 8.60;

string objectNamePrefix = "GjoSeRisk_";
long     positionTickets[];
CPositions  Positions;
CNewBar     NewBar;
CTimer      Timer;

const string MY_INDICATOR_SHORTNAME = "GjoSeRisk";
const string RISK_LEVEL = "RiskLevel";

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {

   deleteObjects();
   calculateRisk();


   IndicatorSetString(INDICATOR_SHORTNAME, MY_INDICATOR_SHORTNAME);

   return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int pRatesTotal,
                const int pPrevCalculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {

   deleteObjects();
   calculateRisk();

   return(pRatesTotal);
}

void calculateRisk() {

   int subWindow = ChartWindowFind(0, MY_INDICATOR_SHORTNAME);
   if (subWindow <= 0) subWindow = 0;



   // LOGIK:
   // -  Positions holen
   // -  Risk je POS berechnen
   // -  POS zu Symbol addieren
   // -  POS zu Account Addieren
   // -  Comment als Label ausgeben - siehe createLabel()

   initializeArray(positionTickets);
   Positions.GetTickets(0, positionTickets);

   //string positionComment, symbolComment, accountComment;
   //long chartId;
   long    positionTicket = 0;
   string  positionSymbol;
   string  positionType;
   double  positionOpenPrice = 0;
   double  positionVolume = 0;
   double  positionStopLoss = 0;
   double  positionTakeProfit = 0;
   double  pipRisk = 0;
   double  pipProfit = 0;
   double hLineLevel;
   double trendLineLevel;
   double pipReward = 0;
   double pipBreakEven = 0;
   int    positionRisk = 0;
   int    positionProfit = 0;
   double riskLevelBuy;
   double riskLevelSell;
   int  positionReward = 0;
   //int   positionBreakEven = 0;
   double  symbolRisk = 0;
   double  accountRisk = 0;
   int   positionRRR = 0;
   bool positionIsSafe;
   int   headLineFontSize = 20;
   int   positionsAndOrdersFontSize = 15;
   int   fontSize = 10;
   color positionColor;



   int xCordHeadline = 500;
   int xCordPositionsHeadline = 200;
   int xCordOrdersHeadline = 800;
   int xCordPosition = 50;
   int xCordPosition2 = 245;


   int rowHigh = 18;

   int yCordTradesHeadline = 200;
   int yCordPositionsAndOrdersOffsetHeadline = 30;

   int yCordTradesPositionsAndOrdersHeadlineHeadline = yCordTradesHeadline + yCordPositionsAndOrdersOffsetHeadline;
   int yCordTradesPositionsAndOrders = yCordTradesPositionsAndOrdersHeadlineHeadline + rowHigh * 2;

//   double settingsXCord = 20;
//   double settingsYCord = 15;

//   double yCordPosition = 15;

//   double symbolXCord = 250;
//   double symbolYCord = 15;

   string positionLabelObject = "";
   string positionLabelObject2 = "";
   double maxAccountRisk = AccountInfoDouble(ACCOUNT_BALANCE) * InpMaxAccountRiskPercent / 100;
   double maxSymbolRisk = maxAccountRisk / InpSymbolCount;
   double maxPositionRisk = maxSymbolRisk * InpMaxPositionRiskPercent / 100;

   //createTradesHeadline
   createLabel(0, objectNamePrefix + "TradesHeadline", subWindow, xCordHeadline, yCordTradesHeadline, "Trades", headLineFontSize);
   createLabel(0, objectNamePrefix + "TradesPositionsHeadline", subWindow, xCordPositionsHeadline, yCordTradesPositionsAndOrdersHeadlineHeadline, "Positions", positionsAndOrdersFontSize);
   createLabel(0, objectNamePrefix + "TradesOrdersHeadline", subWindow, xCordOrdersHeadline, yCordTradesPositionsAndOrdersHeadlineHeadline, "Orders", positionsAndOrdersFontSize);

//   createLabel(0, objectNamePrefix + "Settings" + InpMaxAccountRiskPercent, subWindow, settingsXCord, settingsYCord + 0 * rowHigh, "MaxAccountRisk: " + InpMaxAccountRiskPercent + " % (" + IntegerToString(maxAccountRisk) + " €)", fontSize);
//   createLabel(0, objectNamePrefix + "Settings" + InpSymbolCount, subWindow, settingsXCord, settingsYCord + 1 * rowHigh, "MaxSymbolRisk: " + InpSymbolCount + " Stk. (" + IntegerToString(maxSymbolRisk) + " €)", fontSize);
//   createLabel(0, objectNamePrefix + "Settings" + InpMaxPositionRiskPercent, subWindow, settingsXCord, settingsYCord + 2 * rowHigh, "MaxPositionRisk: " + InpMaxPositionRiskPercent + " % (" + IntegerToString(maxPositionRisk) + " €)", fontSize, clrRed);
//   createLabel(0, objectNamePrefix + "Settings" + InpMinRRR, subWindow, settingsXCord, settingsYCord + 3 * rowHigh, "MinRiskRatio: " + NormalizeDouble(InpMinRRR, 1) , fontSize, clrOrange);



   for(int positionTicketIndex = 0; positionTicketIndex < ArraySize(positionTickets); positionTicketIndex++) {
      positionIsSafe = false;
      positionColor = clrBlack;
      positionTicket = positionTickets[positionTicketIndex];
      positionSymbol = PositionSymbol(positionTicket);
      if(PositionType(positionTicket)  == 0) positionType = "BUY";
      else positionType = "SELL";
      positionOpenPrice = PositionOpenPrice(positionTicket);
      positionVolume = PositionVolume(positionTicket);
      positionStopLoss = PositionStopLoss(positionTicket);
      positionTakeProfit = PositionTakeProfit(positionTicket);
      hLineLevel = getHlineLevelByText(RISK_LEVEL, getChartIDBySymbol(positionSymbol));
      trendLineLevel = getTrendlineLevelByText(RISK_LEVEL, positionSymbol, getChartIDBySymbol(positionSymbol));

//  ok - getRiskLevel funktion fertig
//  ok - sell-Seite
//  - Label anpassen, prüfen auf allen ChartSymbol
//  - CodeClean
//  ok - Warnings Journal
//  - Gitten
//  - Beispieltrades anlegen
//      ok - 3 Symbole a 2 Trades pro Richtung
//      ok - jeweils 1x ohne TP, 1x ohne SL

      // Berechnung aus MIN(RiskLine, SL)
      if(PositionType(positionTicket) == POSITION_TYPE_BUY) {

         riskLevelBuy = getRiskLevelBuy(positionStopLoss, hLineLevel, trendLineLevel);
         pipRisk = (positionOpenPrice - riskLevelBuy) / SymbolInfoDouble(positionSymbol,SYMBOL_POINT) / 10 ;
         pipReward = (positionTakeProfit - positionOpenPrice) / SymbolInfoDouble(positionSymbol,SYMBOL_POINT) / 10 ;
         pipProfit = (SymbolInfoDouble(positionSymbol,SYMBOL_BID) - positionOpenPrice) / SymbolInfoDouble(positionSymbol,SYMBOL_POINT) / 10 ;
//         Print("BUY: " + positionSymbol + " chartId: " + getChartIDBySymbol(positionSymbol) + " hLineLevel: " + hLineLevel + " trendLevel: " + trendLineLevel + " SL: " + positionStopLoss + " = RiskLevel: " + riskLevelBuy + " pipRisk: " + pipRisk + " pipReward: " + pipReward + " pipProfit: " + pipProfit);

      } else {
         riskLevelSell = getRiskLevelSell(positionStopLoss, hLineLevel, trendLineLevel);
         pipRisk = (riskLevelSell - positionOpenPrice) / SymbolInfoDouble(positionSymbol,SYMBOL_POINT) / 10 ;
         pipReward = (positionOpenPrice - positionTakeProfit) / SymbolInfoDouble(positionSymbol,SYMBOL_POINT) / 10 ;
         pipProfit = (positionOpenPrice - SymbolInfoDouble(positionSymbol,SYMBOL_BID)) / SymbolInfoDouble(positionSymbol,SYMBOL_POINT) / 10 ;

//         Print("SELL: " + positionSymbol + " chartId: " + getChartIDBySymbol(positionSymbol) + " hLineLevel: " + hLineLevel + " trendLevel: " + trendLineLevel + " SL: " + positionStopLoss + " = RiskLevel: " + riskLevelSell + " positionOpenPrice: " + positionOpenPrice + " pipRisk: " + pipRisk + " pipReward: " + pipReward + " pipProfit: " + pipProfit);

      }

      positionRisk = (int)(pipRisk * getPipValueBySymbol(PositionSymbol(positionTicket)) * positionVolume);
      positionProfit = (int)(pipProfit * getPipValueBySymbol(PositionSymbol(positionTicket)) * positionVolume);
      positionReward = (int)(pipReward * getPipValueBySymbol(PositionSymbol(positionTicket)) * positionVolume);

      positionRRR = positionReward / positionRisk;

     // Print(positionSymbol + " positionRisk: " + positionRisk +  " positionReward: " + positionReward + " positionRRR: " + positionRRR);

      //symbolRisk = symbolRisk + positionRisk;

      if((riskLevelBuy == 0 && riskLevelSell == 0)|| positionTakeProfit == 0) {
         positionLabelObject = positionSymbol + " - " + IntegerToString(positionTicket) + " SL & TP setzen!";
         positionColor = clrBlue;
      } else {
         if(positionRisk < 0) {
            positionLabelObject = positionSymbol + " - " + IntegerToString(positionTicket) + " | Position is safe!: " + IntegerToString(positionRisk * -1) + " €";
            positionColor = clrGreen;
         } else {
            positionLabelObject = positionSymbol + " - " + IntegerToString(positionTicket) + " - " + positionType + " | Vol: " + DoubleToString(positionVolume, 2) + " | ";
            positionLabelObject2 = "Risk: " + IntegerToString(positionRisk) + "€  | Reward: " +  IntegerToString(positionReward) + "€  | RRR: " + IntegerToString(positionRRR) + " | Profit: " + positionProfit + "€ (" + IntegerToString(pipProfit) + " Pip)";
            if(positionRRR < InpMinRRR) positionColor = clrOrange;
            if(positionRisk > maxPositionRisk) positionColor = clrRed;

         }

      }

      createLabel(0, objectNamePrefix + IntegerToString(positionTicket), subWindow, xCordPosition, yCordTradesPositionsAndOrders, positionLabelObject, fontSize, positionColor);
      if(positionLabelObject2 != "") createLabel(0, objectNamePrefix + IntegerToString(positionTicket) + "2", subWindow, xCordPosition + xCordPosition2, yCordTradesPositionsAndOrders, positionLabelObject2, fontSize, positionColor);
      yCordTradesPositionsAndOrders = yCordTradesPositionsAndOrders + rowHigh;
//      if(positionSymbol == Symbol()) {
//
//      }

      accountRisk = accountRisk + positionRisk;


   }

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
long getChartIDBySymbol(string pSymbol) {
   long prevChartID = ChartFirst();
   do {
      if(ChartSymbol(prevChartID) == pSymbol) return prevChartID;
      prevChartID = ChartNext(prevChartID);
   } while(prevChartID != -1);

   return -1;

}

double getRiskLevelBuy(const double pPositionStopLoss, const double pHLineLevel, const double pTrendLineLevel) {

   double riskLevel = 0;

   // pPositionStopLoss > 0
   if(pPositionStopLoss > 0 && pHLineLevel > 0 && pTrendLineLevel > 0) {
      riskLevel = MathMax(pHLineLevel, pTrendLineLevel);
      riskLevel = MathMax(riskLevel, pPositionStopLoss);
   }
   if(pPositionStopLoss > 0 && pHLineLevel == 0 && pTrendLineLevel > 0) {
      riskLevel = MathMax(pPositionStopLoss, pHLineLevel);
   }
   if(pPositionStopLoss > 0 && pHLineLevel > 0 && pTrendLineLevel == 0) {
      riskLevel = MathMax(pPositionStopLoss, pTrendLineLevel);
   }
   if(pPositionStopLoss > 0 && pHLineLevel == 0 && pTrendLineLevel == 0) {
      riskLevel = pPositionStopLoss;
   }

   // pPositionStopLoss == 0
   if(pPositionStopLoss == 0 && pHLineLevel > 0 && pTrendLineLevel > 0) {
      riskLevel = MathMax(pHLineLevel, pTrendLineLevel);
   }
   if(pPositionStopLoss == 0 && pHLineLevel == 0 && pTrendLineLevel > 0) {
      riskLevel = pTrendLineLevel;
   }
   if(pPositionStopLoss == 0 && pHLineLevel > 0 && pTrendLineLevel == 0) {
      riskLevel = pHLineLevel;
   }
   if(pPositionStopLoss == 0 && pHLineLevel == 0 && pTrendLineLevel == 0) {
      riskLevel = 0;
   }

   return riskLevel;
}

double getRiskLevelSell(const double pPositionStopLoss, const double pHLineLevel, const double pTrendLineLevel) {

   double riskLevel = 0;

   // pPositionStopLoss > 0
   if(pPositionStopLoss > 0 && pHLineLevel > 0 && pTrendLineLevel > 0) {
      riskLevel = MathMin(pHLineLevel, pTrendLineLevel);
      riskLevel = MathMin(riskLevel, pPositionStopLoss);
   }
   if(pPositionStopLoss > 0 && pHLineLevel == 0 && pTrendLineLevel > 0) {
      riskLevel = MathMin(pPositionStopLoss, pHLineLevel);
   }
   if(pPositionStopLoss > 0 && pHLineLevel > 0 && pTrendLineLevel == 0) {
      riskLevel = MathMin(pPositionStopLoss, pTrendLineLevel);
   }
   if(pPositionStopLoss > 0 && pHLineLevel == 0 && pTrendLineLevel == 0) {
      riskLevel = pPositionStopLoss;
   }

   // pPositionStopLoss == 0
   if(pPositionStopLoss == 0 && pHLineLevel > 0 && pTrendLineLevel > 0) {
      riskLevel = MathMin(pHLineLevel, pTrendLineLevel);
   }
   if(pPositionStopLoss == 0 && pHLineLevel == 0 && pTrendLineLevel > 0) {
      riskLevel = pTrendLineLevel;
   }
   if(pPositionStopLoss == 0 && pHLineLevel > 0 && pTrendLineLevel == 0) {
      riskLevel = pHLineLevel;
   }
   if(pPositionStopLoss == 0 && pHLineLevel == 0 && pTrendLineLevel == 0) {
      riskLevel = 0;
   }

   return riskLevel;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   deleteObjects();
}
//+------------------------------------------------------------------+

void deleteObjects() {

   int subWindow = ChartWindowFind(0, MY_INDICATOR_SHORTNAME);
   if (subWindow <= 0) subWindow = 0;

   string objname;
   for(int i = ObjectsTotal(0, subWindow, -1) - 1; i >= 0; i--) {
      objname = ObjectName(0, i);
      if(StringFind(objname, objectNamePrefix) == -1) {
         continue;
      } else {
         ObjectDelete(0, objname);
      }
   }

}
//+------------------------------------------------------------------+

double getPipValueBySymbol(string pPositionSymbol) {

   if(pPositionSymbol == "CHFJPY") return InpPipValueCHFJPY;
   if(pPositionSymbol == "EURJPY") return InpPipValueEURJPY;
   if(pPositionSymbol == "EURUSD") return InpPipValueEURUSD;
   if(pPositionSymbol == "GBPAUD") return InpPipValueGBPAUD;
   if(pPositionSymbol == "GBPJPY") return InpPipValueGBPJPY;
   if(pPositionSymbol == "GBPUSD") return InpPipValueGBPUSD;
   if(pPositionSymbol == "XAUUSD") return InpPipValueXAUUSD;

   return 0;

}
//+------------------------------------------------------------------+
