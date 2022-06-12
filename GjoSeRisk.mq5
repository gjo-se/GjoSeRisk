/*

   IND_GjoSeRisk.mq5
   Copyright 2021, Gregory Jo
   https://www.gjo-se.com

   Doku: https://gjo-se.atlassian.net/wiki/spaces/FINALLG/pages/1106935918/Geldmanagement+-+GM

   Version History
   ===============

   1.0.0    Initial version
   1.4      added GBP
   1.4.1    delete Print

   ===============

//*/

#include <GjoSe\\Utilities\\InclBasicUtilities.mqh>
#include <GjoSe\\Objects\\InclLabel.mqh>
#include <GjoSe\\Objects\\InclHLine.mqh>
#include <GjoSe\\Objects\\InclTrendLine.mqh>

#property   copyright   "2021, GjoSe"
#property   link        "http://www.gjo-se.com"
#property   description "GjoSe Risk Management"
#define     VERSION "1.4.1"
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

//input double InpPipValueCADJPY = 7.60;
//input double InpPipValueCHFJPY = 7.60;
//input double InpPipValueEURJPY = 7.60;
//input double InpPipValueEURUSD = 8.60;
//input double InpPipValueGBPAUD = 7.60;
//input double InpPipValueGBPJPY = 7.60;
//input double InpPipValueGBPUSD = 8.60;
//input double InpPipValueUSDJPY = 7.60;
//input double InpPipValueXAUUSD = 8.60;

string objectNamePrefix = "GjoSeRisk_";
CPositions  Positions;
CPending    Pending;
CNewBar     NewBar;
CTimer      Timer;


const string MY_INDICATOR_SHORTNAME = "GjoSeRisk";
const string RISK_LEVEL = "RiskLevel";

struct PositionStruct {
   string            SymbolString;
   int               buyPositionsCount;
   double            buyPositionsVolume;
   double            buyPositionsLevelVolume;
   double            buyOrdersLevelVolumeArray[][2];
   double            buyPositionsProfit;

   int               sellPositionsCount;
   double            sellPositionsVolume;
   double            sellPositionsLevelVolume;
   double            sellOrdersLevelVolumeArray[][2];
   double            sellPositionsProfit;

   int               buyOrdersCount;
   double            buyOrdersVolume;
   int               sellOrdersCount;
   double            sellOrdersVolume;

   double            symbolLossRiskValue;
   double            symbolTotalRiskValue;
//   double            symbolRiskPercent;

//   int      Reward;
//   double   RewardPercent;
//   double   RRR;
//   int      Profit;
//   int      ProfitPip;
};

PositionStruct symbolArray[];
PositionStruct accountArray[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {

   deleteObjects();
//   calculateRisk();


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

   ArrayResize(symbolArray, 0);
//   ArrayResize(accountArray, 0);

//string positionComment, symbolComment, accountComment;
//long chartId;
   long    positionTicket = 0;
   long    pendingTicket = 0;
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
   double positionRiskPercent = 0;
   int    positionProfit = 0;
   double riskLevelBuy;
   double riskLevelSell;
   int    positionReward = 0;
   double positionRewardPercent = 0;
//int   positionBreakEven = 0;
   double  symbolRisk = 0;
   double  accountRisk = 0;
   double  positionRRR = 0;
   double  symbolRRR = 0;
   bool positionIsSafe;

   int   headLineFontSize = 20;
   int   positionsAndOrdersFontSize = 15;
   int   fontSize = 10;
   color labelDefaultColor = clrBlack;
   string labelFontFamily = "Arial";
   double labelAngle = 0;
   ENUM_BASE_CORNER  labelBaseCorner = CORNER_LEFT_UPPER;
   ENUM_ANCHOR_POINT labelAnchorPoint = ANCHOR_LEFT_UPPER;
   bool labelIsInBackground = false;
   bool labelIsSelectable = false;
   bool labelIsSelected = false;
   bool labelIsHiddenInList = false;
   long labelZOrder = 2;
   long labelChartID = 0;
   int  labelSubWindow = subWindow;

   int xCordHeadline = 500;
   int xCordPositionsHeadline = 200;
   int xCordOrdersHeadline = 800;
   int xCordSymbolString = 20;
   int xCordSymbolPositionsAndOrders = 100;
   int xCordSymbolRisk = 450;
   int xCordSymbolProfit = 720;

   int rowHigh = 18;
   int yCordPositionsAndOrdersOffsetHeadline = 30;

   int yCordAccountHeadline = 50;
   int yCordAccountPositionsAndOrdersHeadlineHeadline = yCordAccountHeadline + yCordPositionsAndOrdersOffsetHeadline;
   int yCordAccountPositionsAndOrders = yCordAccountPositionsAndOrdersHeadlineHeadline + rowHigh * 2;

   int yCordSymbolsHeadline = 200;
   int yCordSymbolsPositionsAndOrdersHeadlineHeadline = yCordSymbolsHeadline + yCordPositionsAndOrdersOffsetHeadline;
   int yCordSymbolsPositionsAndOrders = yCordSymbolsPositionsAndOrdersHeadlineHeadline + rowHigh * 2;

   int yCordTradesHeadline = 350;
   int yCordTradesPositionsAndOrdersHeadlineHeadline = yCordTradesHeadline + yCordPositionsAndOrdersOffsetHeadline;
   int yCordTradesPositionsAndOrders = yCordTradesPositionsAndOrdersHeadlineHeadline + rowHigh * 2;

//   double settingsXCord = 20;
//   double settingsYCord = 15;

//   double yCordPosition = 15;

//   double symbolXCord = 250;
//   double symbolYCord = 15;

   string positionLabelObjectFix = "";
   string positionLabelObjectRisk = "";
   string positionLabelObjectProfit = "";
   double maxAccountRisk = AccountInfoDouble(ACCOUNT_BALANCE) * InpMaxAccountRiskPercent / 100;
   double maxSymbolRisk = maxAccountRisk / InpSymbolCount;
   double maxPositionRisk = maxSymbolRisk * InpMaxPositionRiskPercent / 100;

//createAccountHeadline
//   createLabel(0, objectNamePrefix + "AccountHeadline", subWindow, xCordHeadline, yCordAccountHeadline, "Account", headLineFontSize);
//   createLabel(0, objectNamePrefix + "AccountPositionsHeadline", subWindow, xCordPositionsHeadline, yCordAccountPositionsAndOrdersHeadlineHeadline, "Positions", positionsAndOrdersFontSize);
//   createLabel(0, objectNamePrefix + "AccountOrdersHeadline", subWindow, xCordOrdersHeadline, yCordAccountPositionsAndOrdersHeadlineHeadline, "Orders", positionsAndOrdersFontSize);
//

   //createSymbolsHeadline
   createLabel(objectNamePrefix + "SymbolsHeadline", xCordHeadline, yCordSymbolsHeadline, "Symbols", headLineFontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);

   // Positions
   long  positionTickets[];
   ulong magicNumber = 0;
   initializeArray(positionTickets);
   Positions.GetTickets(magicNumber, positionTickets);
   for(int positionTicketId = 0; positionTicketId < ArraySize(positionTickets); positionTicketId++) {
      positionTicket = positionTickets[positionTicketId];

//      //positionRisk = (int)(pipRisk * getPipValueBySymbol(PositionSymbol(positionTicket)) * positionVolume);
//      positionRiskPercent = positionRisk / AccountInfoDouble(ACCOUNT_BALANCE) * 100;
//      //positionProfit = (int)(pipProfit * getPipValueBySymbol(PositionSymbol(positionTicket)) * positionVolume);
//      //positionReward = (int)(pipReward * getPipValueBySymbol(PositionSymbol(positionTicket)) * positionVolume);
//      positionRewardPercent = positionReward / AccountInfoDouble(ACCOUNT_BALANCE) * 100;
//
//      positionRRR = (double)positionReward / (double)positionRisk;

//      if((riskLevelBuy == 0 && riskLevelSell == 0) || positionTakeProfit == 0) {
//         positionLabelObjectFix = positionSymbol + " - " + IntegerToString(positionTicket) + " SL & TP setzen!";
//         positionColor = clrBlue;
//      } else {
//         if(positionRisk < 0) {
//            positionLabelObjectFix = positionSymbol + " - " + IntegerToString(positionTicket) + " | Position is safe!: " + IntegerToString(positionRisk * -1) + " €";
//            positionColor = clrGreen;
//         } else {
//            positionLabelObjectFix = positionSymbol + " - " + IntegerToString(positionTicket) + " - " + positionType + " | Vol: " + DoubleToString(positionVolume, 2) + " | ";
//            positionLabelObjectRisk = "Risk: " + IntegerToString(positionRisk) + "€ (" + NormalizeDouble(positionRiskPercent, 1) + "%) | Reward: " +  IntegerToString(positionReward) + "€  (" + NormalizeDouble(positionRewardPercent, 1) + "%) | RRR: " + NormalizeDouble(positionRRR, 1) + " | ";
//            positionLabelObjectProfit = "Profit: " + positionProfit + "€ (" + IntegerToString(pipProfit) + " Pip)";
//            if(positionRRR < InpMinRRR) positionColor = clrOrange;
//            if(positionRisk > maxPositionRisk) positionColor = clrRed;
//         }
//      }

      if(ArraySize(symbolArray) == 0) {
         ArrayResize(symbolArray, ArraySize(symbolArray) + 1);
         symbolArray[ArraySize(symbolArray) - 1] = buildPositionStructForSymbolArray(positionTicket);
      } else {
         bool symbolFound = false;
         for(int symbolId = 0; symbolId < ArraySize(symbolArray); symbolId++) {
            if(PositionSymbol(positionTicket) == symbolArray[symbolId].SymbolString) {
               if(PositionType(positionTicket) == ORDER_TYPE_BUY) {
                  symbolArray[symbolId].buyPositionsCount += 1;
                  symbolArray[symbolId].buyPositionsVolume +=  PositionVolume(positionTicket);
                  symbolArray[symbolId].buyPositionsLevelVolume +=  PositionVolume(positionTicket) * PositionOpenPrice(positionTicket);
                  symbolArray[symbolId].buyPositionsProfit +=  PositionProfit(positionTicket);

                  if(PositionStopLoss(positionTicket) != 0) {
                     ArrayResize(symbolArray[symbolId].sellOrdersLevelVolumeArray, ArrayRange(symbolArray[symbolId].sellOrdersLevelVolumeArray, 0) + 1);
                     symbolArray[symbolId].sellOrdersLevelVolumeArray[ArrayRange(symbolArray[symbolId].sellOrdersLevelVolumeArray, 0) - 1][0] = PositionStopLoss(positionTicket);
                     symbolArray[symbolId].sellOrdersLevelVolumeArray[ArrayRange(symbolArray[symbolId].sellOrdersLevelVolumeArray, 0) - 1][1] = PositionVolume(positionTicket);
                     symbolArray[symbolId].sellOrdersVolume += PositionVolume(positionTicket);
                  }
               }
               if(PositionType(positionTicket) == ORDER_TYPE_SELL) {
                  symbolArray[symbolId].sellPositionsCount += 1;
                  symbolArray[symbolId].sellPositionsVolume += PositionVolume(positionTicket);
                  symbolArray[symbolId].sellPositionsLevelVolume += PositionVolume(positionTicket) * PositionOpenPrice(positionTicket);
                  symbolArray[symbolId].sellPositionsProfit += PositionProfit(positionTicket);

                  if(PositionStopLoss(positionTicket) != 0) {
                     ArrayResize(symbolArray[symbolId].buyOrdersLevelVolumeArray, ArrayRange(symbolArray[symbolId].buyOrdersLevelVolumeArray, 0) + 1);
                     symbolArray[symbolId].buyOrdersLevelVolumeArray[ArrayRange(symbolArray[symbolId].buyOrdersLevelVolumeArray, 0) - 1][0] = PositionStopLoss(positionTicket);
                     symbolArray[symbolId].buyOrdersLevelVolumeArray[ArrayRange(symbolArray[symbolId].buyOrdersLevelVolumeArray, 0) - 1][1] = PositionVolume(positionTicket);
                     symbolArray[symbolId].buyOrdersVolume += PositionVolume(positionTicket);
                  }
               }

               symbolFound = true;

            }
         }

         if(symbolFound == false) {
            ArrayResize(symbolArray, ArraySize(symbolArray) + 1);
            symbolArray[ArraySize(symbolArray) - 1] = buildPositionStructForSymbolArray(positionTicket);
         }

      }

//      positionStruct.Reward = positionReward;
//      positionStruct.RewardPercent = positionRewardPercent;

//
//      // Account
//      if(ArraySize(accountArray) > 0) {
//         for(int symbolId = 0; symbolId < ArraySize(accountArray); symbolId++) {
//            accountArray[symbolId].Count += 1;
//            accountArray[symbolId].Volume += positionVolume;
//            accountArray[symbolId].Risk += positionRisk;
//            accountArray[symbolId].RiskPercent += positionRiskPercent;
//            accountArray[symbolId].Reward += positionReward;
//            accountArray[symbolId].RewardPercent += positionRewardPercent;
//            accountArray[symbolId].Profit += positionProfit;
//            accountArray[symbolId].ProfitPip += pipProfit;
//         }
//      } else {
//         ArrayResize(accountArray, ArraySize(accountArray) + 1);
//         accountArray[ArraySize(accountArray) - 1] = positionStruct;
//      }
   }

// Symbols
   Print("---------------------------------");
   for(int symbolId = 0; symbolId < ArraySize(symbolArray); symbolId++) {
      double positionsVolumeDiff = symbolArray[symbolId].buyPositionsVolume - symbolArray[symbolId].sellPositionsVolume;
      double orderVolumeDiff = symbolArray[symbolId].buyOrdersVolume - symbolArray[symbolId].sellOrdersVolume;
      double volumeDiff = positionsVolumeDiff + orderVolumeDiff;
      double buyPositionsLevelAverage = symbolArray[symbolId].buyPositionsLevelVolume / symbolArray[symbolId].buyPositionsVolume;
      double sellPositionsLevelAverage = symbolArray[symbolId].sellPositionsLevelVolume / symbolArray[symbolId].sellPositionsVolume;
      double buyPositionsProfit = symbolArray[symbolId].buyPositionsProfit;
      double sellPositionsProfit = symbolArray[symbolId].sellPositionsProfit;
      double symbolPositionProfit = buyPositionsProfit + sellPositionsProfit;
      double buyOrdersLevelVolumeSortedArray[][2];
      double sellOrdersLevelVolumeSortedArray[][2];
      ArraySort2D(symbolArray[symbolId].buyOrdersLevelVolumeArray, buyOrdersLevelVolumeSortedArray, 0);
      ArraySort2D(symbolArray[symbolId].sellOrdersLevelVolumeArray, sellOrdersLevelVolumeSortedArray, 0, SORT_DESC);

      string printString = symbolId + ": " + symbolArray[symbolId].SymbolString + " " ;
      // Positions
      printString += symbolArray[symbolId].buyPositionsCount + ": " + symbolArray[symbolId].buyPositionsVolume + " / ";
      printString += symbolArray[symbolId].sellPositionsCount + ": " + symbolArray[symbolId].sellPositionsVolume;
      printString += " (" + positionsVolumeDiff + ")";

      printString += " || ";
      // Orders
      printString += symbolArray[symbolId].buyOrdersCount + ": " + symbolArray[symbolId].buyOrdersVolume + " / ";
      printString += symbolArray[symbolId].sellOrdersCount + ": " + symbolArray[symbolId].sellOrdersVolume;
      printString += " (" + orderVolumeDiff + ")";

      printString += " || ";

      // Summe
      printString += " (" + volumeDiff + ")";

      printString += " buyPositionsLevelAverage: " + DoubleToString(buyPositionsLevelAverage, 2);
      printString += " sellPositionsLevelAverage: " + DoubleToString(sellPositionsLevelAverage, 2);

      printString += " buyPositionsProfit: " + DoubleToString(buyPositionsProfit, 2);
      printString += " sellPositionsProfit: " + DoubleToString(sellPositionsProfit, 2);


      ArrayPrint(buyOrdersLevelVolumeSortedArray);
      ArrayPrint(sellOrdersLevelVolumeSortedArray);

      // Risk LONG POS
      if(positionsVolumeDiff > 0) {
         double positionsVolumeDiffLocal = positionsVolumeDiff;
         if(ArrayRange(sellOrdersLevelVolumeSortedArray, 0) > 0) {
            for(int sellOrderLevelVolumeId = 0; sellOrderLevelVolumeId < ArrayRange(sellOrdersLevelVolumeSortedArray, 0); sellOrderLevelVolumeId++) {

               if(positionsVolumeDiffLocal > 0) {
                  double sellOrderLevel = sellOrdersLevelVolumeSortedArray[sellOrderLevelVolumeId][0];
                  double sellOrderVolume = sellOrdersLevelVolumeSortedArray[sellOrderLevelVolumeId][1];
                  double positionRiskVolume = MathMin(sellOrderVolume, positionsVolumeDiff);
                  double positionRiskPoints = buyPositionsLevelAverage / Point() - sellOrderLevel / Point();
                  double positionRiskValue = sellOrderVolume * positionRiskPoints * getPointValueBySymbol(symbolArray[symbolId].SymbolString);
                  symbolArray[symbolId].symbolLossRiskValue += positionRiskValue;
                  symbolArray[symbolId].symbolLossRiskValue = MathMin(AccountInfoDouble(ACCOUNT_EQUITY), symbolArray[symbolId].symbolLossRiskValue);
                  symbolArray[symbolId].symbolTotalRiskValue = symbolArray[symbolId].symbolLossRiskValue + buyPositionsProfit + sellPositionsProfit;
                  positionsVolumeDiffLocal -= sellOrderVolume;

                  Print("StartVolume: " + MathAbs(positionsVolumeDiff) + " buyPositionsLevelAverage: " + DoubleToString(buyPositionsLevelAverage, Digits()) + " sellOrderLevel: " + DoubleToString(sellOrderLevel, Digits()) + " Volume: " + sellOrderVolume + " positionRiskPoints: " + DoubleToString(positionRiskPoints, 0) + " positionRiskValue: " + DoubleToString(positionRiskValue, 0) + " symbolLossRiskValue: " + DoubleToString(symbolArray[symbolId].symbolLossRiskValue, 0) + " symbolTotalRiskValue: " + DoubleToString(symbolArray[symbolId].symbolTotalRiskValue, 0) + " RestVol: " + DoubleToString(positionsVolumeDiffLocal, 2));

               }
            }
         }

         if(positionsVolumeDiffLocal > 0) {
             symbolArray[symbolId].symbolLossRiskValue = AccountInfoDouble(ACCOUNT_EQUITY);
             Print("Buy Volume nicht abgesichrt: " + " symbolLossRiskValue: " + DoubleToString(symbolArray[symbolId].symbolLossRiskValue, 0) + " RestVol: " + DoubleToString(positionsVolumeDiffLocal, 2));
         }
      }

      // Risk SHORT POS
      if(positionsVolumeDiff < 0) {
         double positionsVolumeDiffLocal = MathAbs(positionsVolumeDiff);
         if(ArrayRange(buyOrdersLevelVolumeSortedArray, 0) > 0) {
            for(int buyOrderLevelVolumeId = 0; buyOrderLevelVolumeId < ArrayRange(buyOrdersLevelVolumeSortedArray, 0); buyOrderLevelVolumeId++) {

               if(positionsVolumeDiffLocal > 0) {
                  double buyOrderLevel = buyOrdersLevelVolumeSortedArray[buyOrderLevelVolumeId][0];
                  double buyOrderVolume = buyOrdersLevelVolumeSortedArray[buyOrderLevelVolumeId][1];
                  double positionRiskVolume = MathMin(buyOrderVolume, positionsVolumeDiffLocal);
                  double positionRiskPoints = buyOrderLevel / Point() - sellPositionsLevelAverage / Point();
                  double positionRiskValue = buyOrderVolume * positionRiskPoints * getPointValueBySymbol(symbolArray[symbolId].SymbolString);
                  symbolArray[symbolId].symbolLossRiskValue += positionRiskValue;
                  symbolArray[symbolId].symbolLossRiskValue = MathMin(AccountInfoDouble(ACCOUNT_EQUITY), symbolArray[symbolId].symbolLossRiskValue);
                  symbolArray[symbolId].symbolTotalRiskValue = symbolArray[symbolId].symbolLossRiskValue + buyPositionsProfit + sellPositionsProfit;
                  positionsVolumeDiffLocal -= buyOrderVolume;

                  Print("StartVolume: " + MathAbs(positionsVolumeDiff) + " sellPositionsLevelAverage: " + DoubleToString(sellPositionsLevelAverage, Digits()) + " buyOrderLevel: " + DoubleToString(buyOrderLevel, Digits()) + " Volume: " + buyOrderVolume + " positionRiskPoints: " + DoubleToString(positionRiskPoints, 0) + " positionRiskValue: " + DoubleToString(positionRiskValue, 0) + " symbolRiskValue: " + DoubleToString(symbolArray[symbolId].symbolLossRiskValue, 0)+ " symbolTotalRiskValue: " + DoubleToString(symbolArray[symbolId].symbolTotalRiskValue, 0) + " RestVol: " + DoubleToString(positionsVolumeDiffLocal, 2));

               }
            }
         }

         if(positionsVolumeDiffLocal > 0) {
             symbolArray[symbolId].symbolLossRiskValue = AccountInfoDouble(ACCOUNT_EQUITY);
             Print("Sell Volume nicht abgesichrt: " + " symbolLossRiskValue: " + DoubleToString(symbolArray[symbolId].symbolLossRiskValue, 0) + " RestVol: " + DoubleToString(positionsVolumeDiffLocal, 2));
         }
      }

      Print(printString);

      //      symbolRRR = (double)symbolArray[index].Reward / (double)symbolArray[index].Risk;
      string themeDivider = " || ";
      string symbolStringLabelText = symbolArray[symbolId].SymbolString + " ";
      createLabel(objectNamePrefix + symbolArray[symbolId].SymbolString, xCordSymbolString, yCordSymbolsPositionsAndOrders, symbolStringLabelText, fontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);

      string symbolPositionsLabelText = symbolArray[symbolId].buyPositionsCount + ": " + symbolArray[symbolId].buyPositionsVolume + " / ";
      symbolPositionsLabelText += symbolArray[symbolId].sellPositionsCount + ": " + symbolArray[symbolId].sellPositionsVolume;
      symbolPositionsLabelText += " (" + positionsVolumeDiff + ")";
      string symbolOrdersLabelText = symbolArray[symbolId].buyOrdersCount + ": " + symbolArray[symbolId].buyOrdersVolume + " / ";
      symbolOrdersLabelText += symbolArray[symbolId].sellOrdersCount + ": " + symbolArray[symbolId].sellOrdersVolume;
      symbolOrdersLabelText += " (" + orderVolumeDiff + ")";
      string symbolPositionsAndOrdersLabelText = (symbolArray[symbolId].buyPositionsCount + symbolArray[symbolId].sellPositionsCount + symbolArray[symbolId].buyOrdersCount + symbolArray[symbolId].sellOrdersCount) + ": ";
      symbolPositionsAndOrdersLabelText += " (" + volumeDiff + ")";
      string symbolPositionAndOrdersLabel = symbolPositionsLabelText + themeDivider + symbolOrdersLabelText + themeDivider + symbolPositionsAndOrdersLabelText;
      createLabel(objectNamePrefix + symbolArray[symbolId].SymbolString + "_symbolPositionAndOrdersLabel", xCordSymbolPositionsAndOrders, yCordSymbolsPositionsAndOrders, symbolPositionAndOrdersLabel, fontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);

      string symbolRiskLabel = "Risk: " + DoubleToString(symbolArray[symbolId].symbolLossRiskValue, 0) +  " € (" + DoubleToString(symbolArray[symbolId].symbolLossRiskValue / AccountInfoDouble(ACCOUNT_EQUITY) * 100, 1) + " %) / ";
      symbolRiskLabel += DoubleToString(symbolArray[symbolId].symbolTotalRiskValue, 0) +  " € (" + DoubleToString(symbolArray[symbolId].symbolTotalRiskValue / AccountInfoDouble(ACCOUNT_EQUITY) * 100, 1) + " %)";
      createLabel(objectNamePrefix + symbolArray[symbolId].SymbolString + "_symbolRiskLabel", xCordSymbolRisk, yCordSymbolsPositionsAndOrders, symbolRiskLabel, fontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);

      string symbolProfitLabel = "Profit: " + DoubleToString(symbolPositionProfit, 0) +  " € (" + DoubleToString(symbolPositionProfit / AccountInfoDouble(ACCOUNT_EQUITY) * 100, 1) + " %)";
      createLabel(objectNamePrefix + symbolArray[symbolId].SymbolString + "_symbolProfitLabel", xCordSymbolProfit, yCordSymbolsPositionsAndOrders, symbolProfitLabel, fontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);



      //      string positionSymbolObjectProfit = "Profit: " + symbolArray[index].Profit +  "€";

//      createLabel(objectNamePrefix + "SymbolsHeadline", xCordHeadline, yCordSymbolsHeadline, "Symbols", headLineFontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);

      //      createLabel(0, objectNamePrefix + symbolArray[index].SymbolString + "Risk", subWindow, , yCordSymbolsPositionsAndOrders, positionSymbolObjectRisk, fontSize, positionColor);
      //      createLabel(0, objectNamePrefix + symbolArray[index].SymbolString + "Profit", subWindow, xCordPositionProfit, yCordSymbolsPositionsAndOrders, positionSymbolObjectProfit, fontSize, positionColor);
            yCordSymbolsPositionsAndOrders += rowHigh;



   }

// Account
//   for(int index = 0; index < ArraySize(accountArray); index++) {
//      symbolRRR = (double)accountArray[index].Reward / (double)accountArray[index].Risk;
//      string positionSymbolObjectFix = "Count: " + accountArray[index].Count + " | Vol: " + accountArray[index].Volume;
//      string positionSymbolObjectRisk = "Risk: " + accountArray[index].Risk +  "€ (" + NormalizeDouble(accountArray[index].RiskPercent, 1) +  "%) | Reward: " + accountArray[index].Reward + "€ (" + NormalizeDouble(accountArray[index].RewardPercent, 1) +  "%) | RRR: " + NormalizeDouble(symbolRRR, 1);
//      string positionSymbolObjectProfit = "Profit: " + accountArray[index].Profit +  "€";
//
////      createLabel(0, objectNamePrefix + "account", subWindow, xCordPositionFix, yCordAccountPositionsAndOrders, positionSymbolObjectFix, fontSize, positionColor);
////      createLabel(0, objectNamePrefix + "account" + "Risk", subWindow, xCordPositionRisk, yCordAccountPositionsAndOrders, positionSymbolObjectRisk, fontSize, positionColor);
////      createLabel(0, objectNamePrefix + "account" + "Profit", subWindow, xCordPositionProfit, yCordAccountPositionsAndOrders, positionSymbolObjectProfit, fontSize, positionColor);
//      yCordAccountPositionsAndOrders += rowHigh;
//   }

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getPointValueBySymbol(string pPositionSymbol) {
   return SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE) / SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE) * Point();
}

PositionStruct buildPositionStructForSymbolArray(const long pPositionTicket) {

   PositionStruct positionStruct;
   positionStruct.SymbolString = PositionSymbol(pPositionTicket);

   positionStruct.buyPositionsCount = 0;
   positionStruct.buyPositionsLevelVolume = 0;
   positionStruct.buyPositionsVolume = 0;
   ArrayResize(positionStruct.buyOrdersLevelVolumeArray, 0);
   positionStruct.buyPositionsProfit = 0;

   positionStruct.sellPositionsCount = 0;
   positionStruct.sellPositionsVolume = 0;
   positionStruct.sellPositionsLevelVolume = 0;
   ArrayResize(positionStruct.sellOrdersLevelVolumeArray, 0);
   positionStruct.sellPositionsProfit = 0;

   positionStruct.buyOrdersCount = 0;
   positionStruct.buyOrdersVolume = 0;
   positionStruct.sellOrdersCount = 0;
   positionStruct.sellOrdersVolume = 0;

   positionStruct.symbolLossRiskValue = 0;
   positionStruct.symbolTotalRiskValue = 0;

   if(PositionType(pPositionTicket) == ORDER_TYPE_BUY) {
      positionStruct.buyPositionsCount = 1;
      positionStruct.buyPositionsVolume = PositionVolume(pPositionTicket);
      positionStruct.buyPositionsLevelVolume =  PositionVolume(pPositionTicket) * PositionOpenPrice(pPositionTicket);
      positionStruct.buyPositionsProfit =  PositionProfit(pPositionTicket);
      if(PositionStopLoss(pPositionTicket) != 0) {
         ArrayResize(positionStruct.sellOrdersLevelVolumeArray, ArrayRange(positionStruct.sellOrdersLevelVolumeArray, 0) + 1);
         positionStruct.sellOrdersLevelVolumeArray[ArrayRange(positionStruct.sellOrdersLevelVolumeArray, 0) - 1][0] = PositionStopLoss(pPositionTicket);
         positionStruct.sellOrdersLevelVolumeArray[ArrayRange(positionStruct.sellOrdersLevelVolumeArray, 0) - 1][1] = PositionVolume(pPositionTicket);
         positionStruct.sellOrdersVolume += PositionVolume(pPositionTicket);
      }
    }
   if(PositionType(pPositionTicket) == ORDER_TYPE_SELL) {
      positionStruct.sellPositionsCount = 1;
      positionStruct.sellPositionsVolume = PositionVolume(pPositionTicket);
      positionStruct.sellPositionsLevelVolume = PositionVolume(pPositionTicket) * PositionOpenPrice(pPositionTicket);
      positionStruct.sellPositionsProfit = PositionProfit(pPositionTicket);
      if(PositionStopLoss(pPositionTicket) != 0) {
         ArrayResize(positionStruct.buyOrdersLevelVolumeArray, ArrayRange(positionStruct.buyOrdersLevelVolumeArray, 0) + 1);
         positionStruct.buyOrdersLevelVolumeArray[ArrayRange(positionStruct.buyOrdersLevelVolumeArray, 0) - 1][0] = PositionStopLoss(pPositionTicket);
         positionStruct.buyOrdersLevelVolumeArray[ArrayRange(positionStruct.buyOrdersLevelVolumeArray, 0) - 1][1] = PositionVolume(pPositionTicket);
         positionStruct.buyOrdersVolume += PositionVolume(pPositionTicket);
      }
   }

   long pendingTickets[];
   Pending.GetTickets(PositionSymbol(pPositionTicket), pendingTickets);
   for(int pendingTicketsId = 0; pendingTicketsId < ArraySize(pendingTickets); pendingTicketsId++) {
      long pendingTicket = pendingTickets[pendingTicketsId];
      if(pendingTicket > 0) {
         if(OrderType(pendingTicket) == ORDER_TYPE_BUY_STOP) {
            positionStruct.buyOrdersCount += 1;
            positionStruct.buyOrdersVolume += OrderVolume(pendingTicket);

            ArrayResize(positionStruct.buyOrdersLevelVolumeArray, ArrayRange(positionStruct.buyOrdersLevelVolumeArray, 0) + 1);
            positionStruct.buyOrdersLevelVolumeArray[ArrayRange(positionStruct.buyOrdersLevelVolumeArray, 0) - 1][0] = OrderOpenPrice(pendingTicket);
            positionStruct.buyOrdersLevelVolumeArray[ArrayRange(positionStruct.buyOrdersLevelVolumeArray, 0) - 1][1] = OrderVolume(pendingTicket);
         }
         if(OrderType(pendingTicket) == ORDER_TYPE_SELL_STOP) {
            positionStruct.sellOrdersCount += 1;
            positionStruct.sellOrdersVolume += OrderVolume(pendingTicket);

            ArrayResize(positionStruct.sellOrdersLevelVolumeArray, ArrayRange(positionStruct.sellOrdersLevelVolumeArray, 0) + 1);
             positionStruct.sellOrdersLevelVolumeArray[ArrayRange(positionStruct.sellOrdersLevelVolumeArray, 0) - 1][0] = OrderOpenPrice(pendingTicket);
             positionStruct.sellOrdersLevelVolumeArray[ArrayRange(positionStruct.sellOrdersLevelVolumeArray, 0) - 1][1] = OrderVolume(pendingTicket);
         }
      }
   }

   return positionStruct;

}

const int SORT_ASC = 0;
const int SORT_DESC = 1;

void ArraySort2D(double &pSourceArray[][], double &pDestinationArray[][], const int pIndexToSort, const int pSortDirection = 0) {

   int liSize[2];
   liSize[0] = ArrayRange(pSourceArray, 0);
   liSize[1] = ArrayRange(pSourceArray, 1);
   int liPosition;

   for (int i = 0; i < liSize[0]; i++) {

      if(pSortDirection == SORT_ASC) {
         liPosition = 0;
         for (int j = 0; j < liSize[0]; j++) {
            if (pSourceArray[i][pIndexToSort] > pSourceArray[j][pIndexToSort]) {
               liPosition++;
            }
         }
         ArrayCopy(pDestinationArray, pSourceArray, liPosition * liSize[1], i * liSize[1],  liSize[1]);
      }

      if(pSortDirection == SORT_DESC) {
         liPosition = liSize[0] - 1;
         for (int j = 0; j < liSize[0]; j++) {
            if (pSourceArray[i][pIndexToSort] > pSourceArray[j][pIndexToSort]) {
               liPosition--;
            }
         }
         ArrayCopy(pDestinationArray, pSourceArray, liPosition * liSize[1], i * liSize[1],  liSize[1]);
      }
   }
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//long getChartIDBySymbol(string pSymbol) {
//   long prevChartID = ChartFirst();
//   do {
//      if(ChartSymbol(prevChartID) == pSymbol) return prevChartID;
//      prevChartID = ChartNext(prevChartID);
//   } while(prevChartID != -1);
//
//   return -1;
//
//}

//double getRiskLevelBuy(const double pPositionStopLoss, const double pHLineLevel, const double pTrendLineLevel) {
//
//   double riskLevel = 0;
//
//   // pPositionStopLoss > 0
//   if(pPositionStopLoss > 0 && pHLineLevel > 0 && pTrendLineLevel > 0) {
//      riskLevel = MathMax(pHLineLevel, pTrendLineLevel);
//      riskLevel = MathMax(riskLevel, pPositionStopLoss);
//   }
//   if(pPositionStopLoss > 0 && pHLineLevel == 0 && pTrendLineLevel > 0) {
//      riskLevel = MathMax(pPositionStopLoss, pHLineLevel);
//   }
//   if(pPositionStopLoss > 0 && pHLineLevel > 0 && pTrendLineLevel == 0) {
//      riskLevel = MathMax(pPositionStopLoss, pTrendLineLevel);
//   }
//   if(pPositionStopLoss > 0 && pHLineLevel == 0 && pTrendLineLevel == 0) {
//      riskLevel = pPositionStopLoss;
//   }
//
//   // pPositionStopLoss == 0
//   if(pPositionStopLoss == 0 && pHLineLevel > 0 && pTrendLineLevel > 0) {
//      riskLevel = MathMax(pHLineLevel, pTrendLineLevel);
//   }
//   if(pPositionStopLoss == 0 && pHLineLevel == 0 && pTrendLineLevel > 0) {
//      riskLevel = pTrendLineLevel;
//   }
//   if(pPositionStopLoss == 0 && pHLineLevel > 0 && pTrendLineLevel == 0) {
//      riskLevel = pHLineLevel;
//   }
//   if(pPositionStopLoss == 0 && pHLineLevel == 0 && pTrendLineLevel == 0) {
//      riskLevel = 0;
//   }
//
//   return riskLevel;
//}

//double getRiskLevelSell(const double pPositionStopLoss, const double pHLineLevel, const double pTrendLineLevel) {
//
//   double riskLevel = 0;
//
//   // pPositionStopLoss > 0
//   if(pPositionStopLoss > 0 && pHLineLevel > 0 && pTrendLineLevel > 0) {
//      riskLevel = MathMin(pHLineLevel, pTrendLineLevel);
//      riskLevel = MathMin(riskLevel, pPositionStopLoss);
//   }
//   if(pPositionStopLoss > 0 && pHLineLevel == 0 && pTrendLineLevel > 0) {
//      riskLevel = MathMin(pPositionStopLoss, pHLineLevel);
//   }
//   if(pPositionStopLoss > 0 && pHLineLevel > 0 && pTrendLineLevel == 0) {
//      riskLevel = MathMin(pPositionStopLoss, pTrendLineLevel);
//   }
//   if(pPositionStopLoss > 0 && pHLineLevel == 0 && pTrendLineLevel == 0) {
//      riskLevel = pPositionStopLoss;
//   }
//
//   // pPositionStopLoss == 0
//   if(pPositionStopLoss == 0 && pHLineLevel > 0 && pTrendLineLevel > 0) {
//      riskLevel = MathMin(pHLineLevel, pTrendLineLevel);
//   }
//   if(pPositionStopLoss == 0 && pHLineLevel == 0 && pTrendLineLevel > 0) {
//      riskLevel = pTrendLineLevel;
//   }
//   if(pPositionStopLoss == 0 && pHLineLevel > 0 && pTrendLineLevel == 0) {
//      riskLevel = pHLineLevel;
//   }
//   if(pPositionStopLoss == 0 && pHLineLevel == 0 && pTrendLineLevel == 0) {
//      riskLevel = 0;
//   }
//
//   return riskLevel;
//}
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

//double getPipValueBySymbol(string pPositionSymbol) {
//
//   double pipValue = 0;
//   string symbolAgainst = StringSubstr(pPositionSymbol, 3, 3);
//
//   if(symbolAgainst == "AUD") pipValue =  10 / SymbolInfoDouble("EURAUD", SYMBOL_BID);
//   if(symbolAgainst == "CAD") pipValue =  10 / SymbolInfoDouble("EURCAD", SYMBOL_BID);
//   if(symbolAgainst == "CHF") pipValue =  10 / SymbolInfoDouble("EURCHF", SYMBOL_BID);
//   if(symbolAgainst == "GBP") pipValue =  10 / SymbolInfoDouble("EURGBP", SYMBOL_BID);
//   if(symbolAgainst == "JPY") pipValue =  1000 / SymbolInfoDouble("EURJPY", SYMBOL_BID);
//   if(symbolAgainst == "NZD") pipValue =  10 / SymbolInfoDouble("EURNZD", SYMBOL_BID);
//   if(symbolAgainst == "USD") pipValue =  10 / SymbolInfoDouble("EURUSD", SYMBOL_BID);
//
//   return pipValue;
//
//}
//+------------------------------------------------------------------+
