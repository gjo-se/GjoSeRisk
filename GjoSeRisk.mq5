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
   1.5.0    new Version auf RiskCalc inkl. Hedges
   1.5.1    fixed Positions and Orders Count & Volume
   1.5.2    fixed Volume Columns
   1.5.3    added Risk & ProfitLabels

   ===============

//*/

#include <GjoSe\\Utilities\\InclBasicUtilities.mqh>
#include <GjoSe\\Objects\\InclLabel.mqh>
#include <GjoSe\Export\CPairedDealInfo.mqh>

#property   copyright   "2022, GjoSe"
#property   link        "http://www.gjo-se.com"
#property   description "GjoSe Risk Management"
#define     VERSION "1.5.3"
#property   version VERSION
#property   strict

#property indicator_separate_window
#property indicator_plots               0
#property indicator_buffers             0
#property indicator_minimum             0.0
#property indicator_maximum             0.0

input int InpSymbolCount = 5;
input double InpMaxSymbolRiskLevel1Percent = 1;
input double InpMaxSymbolRiskLevel2Percent = 5;
input double InpMaxAccountRiskLevel1Percent = 15;
input double InpMaxAccountRiskLevel2Percent = 20;
input double InpMinRRR = 2;

string objectNamePrefix = "GjoSeRisk_";
CPositions      Positions;
CPending        Pending;
//CNewBar         NewBar;
//CTimer          Timer;
CPairedDealInfo TradeHistory;

bool isNewM1Bar = false;

const string MY_INDICATOR_SHORTNAME = "GjoSeRisk";
const int SORT_ASC = 0;
const int SORT_DESC = 1;

color clrLevel1 = clrCoral;
color clrLevel2 = clrCrimson;

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

   bool              ordersLoaded;
   int               buyOrdersCount;
   double            buyOrdersVolume;
   int               sellOrdersCount;
   double            sellOrdersVolume;

   bool              tradeHistoryLoaded;
   long              symbolFirstInDatetime;
   double            symbolTradeHistoryProfit;

   double            symbolRiskValue;
//   int      Reward;
//   double   RewardPercent;
//   double   RRR;
};

PositionStruct positionStruct;
int symbolsCount;
PositionStruct symbolArray[];
double accountRiskValue;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {

   deleteLabelLike(objectNamePrefix);
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

   (NewM1Bar()) ? isNewM1Bar = true : isNewM1Bar = false;

   if(isNewM1Bar) {
      deleteLabelLike(objectNamePrefix);
      calculateRisk();
   }

   return(pRatesTotal);
}

void calculateRisk() {

   int subWindow = ChartWindowFind(0, MY_INDICATOR_SHORTNAME);
   if (subWindow <= 0) subWindow = 0;

   ArrayResize(symbolArray, 0);
   accountRiskValue = 0;

   long    positionTicket = 0;
   long    pendingTicket = 0;

   int   headLineFontSize = 20;
   int   headLine2FontSize = 15;
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

   int rowHigh = 22;
   int yCordPositionsAndOrdersOffsetHeadline = 30;

   int yCordAccountHeadline = 50;
   int yCordAccountPositionsAndOrdersHeadlineHeadline = yCordAccountHeadline + yCordPositionsAndOrdersOffsetHeadline;
   int yCordAccountPositionsAndOrders = yCordAccountPositionsAndOrdersHeadlineHeadline + rowHigh * 2;

   int yCordSymbolsHeadline = 10;
   int yCordSymbolsPositionsAndOrdersHeadlineHeadline = yCordSymbolsHeadline + yCordPositionsAndOrdersOffsetHeadline;
   int yCordSymbolsPositionsAndOrders = yCordSymbolsPositionsAndOrdersHeadlineHeadline + rowHigh * 2;

//createAccountHeadline
//   createLabel(0, objectNamePrefix + "AccountHeadline", subWindow, xCordHeadline, yCordAccountHeadline, "Account", headLineFontSize);

//createSymbolsHeadline

// Label PositionsString
   string symbolsHeadlineLabelObjectName = objectNamePrefix + "SymbolsHeadline";
   string symbolsHeadlineLabelText = "Symbols (" + IntegerToString(symbolsCount) + ")";
   int xCordHeadline = 500;
   if(ObjectFind(ChartID(), symbolsHeadlineLabelObjectName) < 0) {
      createLabel(symbolsHeadlineLabelObjectName, xCordHeadline, yCordSymbolsHeadline, symbolsHeadlineLabelText, headLineFontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
   } else {
      ObjectSetString(ChartID(), symbolsHeadlineLabelObjectName, OBJPROP_TEXT, symbolsHeadlineLabelText);
   }

// Label PositionsString
   string positionStringLabelObjectName = objectNamePrefix + "_positionsString";
   string positionStringLabelText = "Positions";
   if(ObjectFind(ChartID(), positionStringLabelObjectName) < 0) {
      int xCord = 110;
      int yCord = 50;
      createLabel(positionStringLabelObjectName, xCord, yCord, positionStringLabelText, headLine2FontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
   } else {
      ObjectSetString(ChartID(), positionStringLabelObjectName, OBJPROP_TEXT, positionStringLabelText);
   }

// Label OrdersString
//   string ordersStringLabelObjectName = objectNamePrefix + "_ordersString";
//   string ordersStringLabelText = "Orders";
//   if(ObjectFind(ChartID(), ordersStringLabelObjectName) < 0) {
//      int xCord = 330;
//      int yCord = 50;
//      createLabel(ordersStringLabelObjectName, xCord, yCord, ordersStringLabelText, headLine2FontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
//   } else {
//      ObjectSetString(ChartID(), ordersStringLabelObjectName, OBJPROP_TEXT, ordersStringLabelText);
//   }

// Label RiskString
string riskLabelObjectName = objectNamePrefix + "_riskString";
string riskStringLabelText = "Risk";
if(ObjectFind(ChartID(), riskLabelObjectName) < 0) {
   int xCord = 330;
   int yCord = 50;
   createLabel(riskLabelObjectName, xCord, yCord, riskStringLabelText, headLine2FontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
} else {
   ObjectSetString(ChartID(), riskLabelObjectName, OBJPROP_TEXT, riskStringLabelText);
}

// Label ProfitString
   string profitLabelObjectName = objectNamePrefix + "_profitString";
   string profitStringLabelText = "Profit";
   if(ObjectFind(ChartID(), profitLabelObjectName) < 0) {
      int xCord = 740;
      int yCord = 50;
      createLabel(profitLabelObjectName, xCord, yCord, profitStringLabelText, headLine2FontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
   } else {
      ObjectSetString(ChartID(), profitLabelObjectName, OBJPROP_TEXT, profitStringLabelText);
   }

// Positions
   long  positionTickets[];
   ulong magicNumber = 0;
   initializeArray(positionTickets);
   Positions.GetTickets(magicNumber, positionTickets);
   for(int positionTicketId = 0; positionTicketId < ArraySize(positionTickets); positionTicketId++) {
      positionTicket = positionTickets[positionTicketId];

      if(ArraySize(symbolArray) == 0) {
         ArrayResize(symbolArray, ArraySize(symbolArray) + 1);
         symbolArray[ArraySize(symbolArray) - 1] = buildPositionStructForSymbolArray(positionTicket);
      } else {
         bool symbolFound = false;
         for(int symbolId = 0; symbolId < ArraySize(symbolArray); symbolId++) {
            if(PositionSymbol(positionTicket) == symbolArray[symbolId].SymbolString) {
               if(PositionType(positionTicket) == ORDER_TYPE_BUY) {
                  symbolArray[symbolId].buyPositionsCount += 1;
                  symbolArray[symbolId].buyPositionsVolume +=  NormalizeDouble(PositionVolume(positionTicket), 2);
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
                  symbolArray[symbolId].sellPositionsVolume += NormalizeDouble(PositionVolume(positionTicket), 2);
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
   }

// Symbols
   symbolsCount = 0;
   for(int symbolId = 0; symbolId < ArraySize(symbolArray); symbolId++) {
      symbolsCount++;
      bool symbolUndefinedRisk = false;
      double symbolPoints = SymbolInfoDouble(symbolArray[symbolId].SymbolString, SYMBOL_POINT);
      double symbolBid = Bid(symbolArray[symbolId].SymbolString);
      double positionsVolumeDiff = NormalizeDouble(symbolArray[symbolId].buyPositionsVolume, 2) - NormalizeDouble(symbolArray[symbolId].sellPositionsVolume, 2);
      double orderVolumeDiff = NormalizeDouble(symbolArray[symbolId].buyOrdersVolume, 2) - NormalizeDouble(symbolArray[symbolId].sellOrdersVolume, 2);
      double volumeDiff = positionsVolumeDiff + orderVolumeDiff;
      double buyPositionsLevelAverage = symbolArray[symbolId].buyPositionsLevelVolume / symbolArray[symbolId].buyPositionsVolume;
      double sellPositionsLevelAverage = symbolArray[symbolId].sellPositionsLevelVolume / symbolArray[symbolId].sellPositionsVolume;
      double buyPositionsProfit = symbolArray[symbolId].buyPositionsProfit;
      double sellPositionsProfit = symbolArray[symbolId].sellPositionsProfit;
      double symbolPositionProfit = buyPositionsProfit + sellPositionsProfit;
      double symbolTotalProfit = symbolPositionProfit + symbolArray[symbolId].symbolTradeHistoryProfit;
      double buyOrdersLevelVolumeSortedArray[][2];
      double sellOrdersLevelVolumeSortedArray[][2];
      ArraySort2D(symbolArray[symbolId].buyOrdersLevelVolumeArray, buyOrdersLevelVolumeSortedArray, 0);
      ArraySort2D(symbolArray[symbolId].sellOrdersLevelVolumeArray, sellOrdersLevelVolumeSortedArray, 0, SORT_DESC);
      color textColor;

      // Helper-Ausgabe as Print()
//      string printString = symbolId + ": " + symbolArray[symbolId].SymbolString + " " ;
//      // Positions
//      printString += symbolArray[symbolId].buyPositionsCount + ": " + symbolArray[symbolId].buyPositionsVolume + " / ";
//      printString += symbolArray[symbolId].sellPositionsCount + ": " + symbolArray[symbolId].sellPositionsVolume;
//      printString += " (" + positionsVolumeDiff + ")";
//
//      printString += " || ";
//      // Orders
//      printString += symbolArray[symbolId].buyOrdersCount + ": " + symbolArray[symbolId].buyOrdersVolume + " / ";
//      printString += symbolArray[symbolId].sellOrdersCount + ": " + symbolArray[symbolId].sellOrdersVolume;
//      printString += " (" + orderVolumeDiff + ")";
//
//      printString += " || ";
//
//      // Summe
//      printString += " (" + volumeDiff + ")";
//
//      printString += " buyPositionsLevelAverage: " + DoubleToString(buyPositionsLevelAverage, 2);
//      printString += " sellPositionsLevelAverage: " + DoubleToString(sellPositionsLevelAverage, 2);
//
//      printString += " buyPositionsProfit: " + DoubleToString(buyPositionsProfit, 2);
//      printString += " sellPositionsProfit: " + DoubleToString(sellPositionsProfit, 2);


      // PositionRisk BUY
      if(positionsVolumeDiff > 0) {
         double positionsVolumeDiffLocal = positionsVolumeDiff;
         if(ArrayRange(sellOrdersLevelVolumeSortedArray, 0) > 0) {
            for(int sellOrderLevelVolumeId = 0; sellOrderLevelVolumeId < ArrayRange(sellOrdersLevelVolumeSortedArray, 0); sellOrderLevelVolumeId++) {

               if(positionsVolumeDiffLocal > 0) {
                  double sellOrderLevel = sellOrdersLevelVolumeSortedArray[sellOrderLevelVolumeId][0];
                  double sellOrderVolume = sellOrdersLevelVolumeSortedArray[sellOrderLevelVolumeId][1];
                  double positionRiskVolume = MathMin(sellOrderVolume, positionsVolumeDiff);
                  double positionRiskPoints = (symbolBid - sellOrderLevel) / symbolPoints;
                  double positionRiskValue = sellOrderVolume * positionRiskPoints * getPointValueBySymbol(symbolArray[symbolId].SymbolString);
                  symbolArray[symbolId].symbolRiskValue += positionRiskValue;
                  symbolArray[symbolId].symbolRiskValue = MathMin(AccountInfoDouble(ACCOUNT_EQUITY), symbolArray[symbolId].symbolRiskValue);
                  positionsVolumeDiffLocal -= sellOrderVolume;
               }
            }
         }

         accountRiskValue += symbolArray[symbolId].symbolRiskValue;

         if(NormalizeDouble(positionsVolumeDiffLocal, 2) > 0) {
            symbolArray[symbolId].symbolRiskValue = AccountInfoDouble(ACCOUNT_EQUITY);
            accountRiskValue = AccountInfoDouble(ACCOUNT_EQUITY);
            symbolUndefinedRisk = true;
         }
      }

      // PositionRisk SELL
      if(positionsVolumeDiff < 0) {
         double positionsVolumeDiffLocal = MathAbs(positionsVolumeDiff);
         if(ArrayRange(buyOrdersLevelVolumeSortedArray, 0) > 0) {
            for(int buyOrderLevelVolumeId = 0; buyOrderLevelVolumeId < ArrayRange(buyOrdersLevelVolumeSortedArray, 0); buyOrderLevelVolumeId++) {

               if(positionsVolumeDiffLocal > 0) {
                  double buyOrderLevel = buyOrdersLevelVolumeSortedArray[buyOrderLevelVolumeId][0];
                  double buyOrderVolume = buyOrdersLevelVolumeSortedArray[buyOrderLevelVolumeId][1];
                  double positionRiskVolume = MathMin(buyOrderVolume, positionsVolumeDiffLocal);
                  double positionRiskPoints = (buyOrderLevel - symbolBid) / symbolPoints;
                  double positionRiskValue = buyOrderVolume * positionRiskPoints * getPointValueBySymbol(symbolArray[symbolId].SymbolString);
                  symbolArray[symbolId].symbolRiskValue += positionRiskValue;
                  symbolArray[symbolId].symbolRiskValue = MathMin(AccountInfoDouble(ACCOUNT_EQUITY), symbolArray[symbolId].symbolRiskValue);
                  positionsVolumeDiffLocal -= buyOrderVolume;
               }
            }
         }

         accountRiskValue += symbolArray[symbolId].symbolRiskValue;

         if(NormalizeDouble(positionsVolumeDiffLocal, 2) > 0) {
            symbolArray[symbolId].symbolRiskValue = AccountInfoDouble(ACCOUNT_EQUITY);
            accountRiskValue = AccountInfoDouble(ACCOUNT_EQUITY);
            symbolUndefinedRisk = true;
         }
      }

//      Print(printString);

      int xCordSymbolString = 20;
      int xCordSymbolPositionsAndOrders = 100;
      int xCordSymbolRisk = 450;
      int xCordSymbolProfit = 720;

      string themeDivider = " || ";

      // Label SymbolString
      string symbolStringLabelObjectName = objectNamePrefix + symbolArray[symbolId].SymbolString;
      string symbolStringLabelText = symbolArray[symbolId].SymbolString;
      if(ObjectFind(ChartID(), symbolStringLabelObjectName) < 0) {
         createLabel(symbolStringLabelObjectName, xCordSymbolString, yCordSymbolsPositionsAndOrders, symbolStringLabelText, fontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
      } else {
         ObjectSetString(ChartID(), symbolStringLabelObjectName, OBJPROP_TEXT, symbolStringLabelText);
      }

      // Label BuyPositions
      if(symbolArray[symbolId].buyPositionsCount > 0) {
         int xCordBuyPositionsLabel = 100;
         string buyPositionsLabelObjectName = objectNamePrefix + symbolArray[symbolId].SymbolString + "_buyPositionsLabel";
         string buyPositionsLabelText = DoubleToString(symbolArray[symbolId].buyPositionsVolume, 2);
         textColor = labelDefaultColor;
         if(NormalizeDouble(symbolArray[symbolId].buyPositionsVolume, 2) < NormalizeDouble(symbolArray[symbolId].sellPositionsVolume, 2)) textColor = clrGray;
         if(ObjectFind(ChartID(), buyPositionsLabelObjectName) < 0) {
            createLabel(buyPositionsLabelObjectName, xCordBuyPositionsLabel, yCordSymbolsPositionsAndOrders, buyPositionsLabelText, fontSize, textColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
         } else {
            ObjectSetString(ChartID(), buyPositionsLabelObjectName, OBJPROP_TEXT, buyPositionsLabelText);
         }
      }

      // Label SellPositions
      if(symbolArray[symbolId].sellPositionsCount > 0) {
         int xCordSellPositionsLabel = 140;
         string sellPositionsLabelObjectName = objectNamePrefix + symbolArray[symbolId].SymbolString + "_sellPositionsLabel";
         string sellPositionsLabelText = DoubleToString(symbolArray[symbolId].sellPositionsVolume, 2);
         textColor = labelDefaultColor;
         if(NormalizeDouble(symbolArray[symbolId].buyPositionsVolume, 2) > NormalizeDouble(symbolArray[symbolId].sellPositionsVolume, 2)) textColor = clrGray;
         if(ObjectFind(ChartID(), sellPositionsLabelObjectName) < 0) {
            createLabel(sellPositionsLabelObjectName, xCordSellPositionsLabel, yCordSymbolsPositionsAndOrders, sellPositionsLabelText, fontSize, textColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
         } else {
            ObjectSetString(ChartID(), sellPositionsLabelObjectName, OBJPROP_TEXT, sellPositionsLabelText);
         }
      }

      // Label PositionsDiff
      string positionsDiffLabelObjectName = objectNamePrefix + symbolArray[symbolId].SymbolString + "_positionsDiffLabel";
      if(NormalizeDouble(positionsVolumeDiff, 2) != 0) {
         int xCordPositionsDiffLabel = 180;
         string positionsDiffLabelText = DoubleToString(positionsVolumeDiff, 2);
         if(ObjectFind(ChartID(), positionsDiffLabelObjectName) < 0) {
            createLabel(positionsDiffLabelObjectName, xCordPositionsDiffLabel, yCordSymbolsPositionsAndOrders, positionsDiffLabelText, fontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
         } else {
            ObjectSetString(ChartID(), positionsDiffLabelObjectName, OBJPROP_TEXT, positionsDiffLabelText);
         }
      } else {
         if(ObjectFind(ChartID(), positionsDiffLabelObjectName) >= 0) {
            deleteLabel(positionsDiffLabelObjectName, ChartID());
         }
      }

      // Label PositionsAndOrdersDiff
      string positionsAndOrdersDiffLabelObjectName = objectNamePrefix + symbolArray[symbolId].SymbolString + "_positionsAndOrdersDiffLabel";
      if(symbolUndefinedRisk) {
         int xCordPositionsAndOrdersDiffLabel = 230;
         string positionsAndOrdersDiffLabelText = DoubleToString(volumeDiff, 2);
         textColor = clrRed;
         if(ObjectFind(ChartID(), positionsAndOrdersDiffLabelObjectName) < 0) {
            createLabel(positionsAndOrdersDiffLabelObjectName, xCordPositionsAndOrdersDiffLabel, yCordSymbolsPositionsAndOrders, positionsAndOrdersDiffLabelText, fontSize, textColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
         } else {
            ObjectSetString(ChartID(), positionsAndOrdersDiffLabelObjectName, OBJPROP_TEXT, positionsAndOrdersDiffLabelText);
            ObjectSetInteger(ChartID(), positionsAndOrdersDiffLabelObjectName, OBJPROP_COLOR, textColor);
         }
      } else {
         if(ObjectFind(ChartID(), positionsAndOrdersDiffLabelObjectName) >= 0) {
            deleteLabel(positionsAndOrdersDiffLabelObjectName, ChartID());
         }
      }

      // Label SymbolLossRisk
      string symbolLossRiskLabelObjectName = objectNamePrefix + symbolArray[symbolId].SymbolString + "_symbolLossRiskLabel";
      if(NormalizeDouble(symbolArray[symbolId].symbolRiskValue, 0) != 0) {
         int xCordSymbolLossRiskLabel = 270;
         double symbolLossRisk = symbolArray[symbolId].symbolRiskValue - symbolPositionProfit - symbolArray[symbolId].symbolTradeHistoryProfit;
         double symbolLossRiskPercent = symbolLossRisk / AccountInfoDouble(ACCOUNT_EQUITY) * 100;
         string symbolLossRiskLabelText = DoubleToString(symbolLossRisk, 0) +  " € (" + DoubleToString(symbolLossRiskPercent, 1) + " %)";
         textColor = labelDefaultColor;
         if(ObjectFind(ChartID(), symbolLossRiskLabelObjectName) < 0) {
            createLabel(symbolLossRiskLabelObjectName, xCordSymbolLossRiskLabel, yCordSymbolsPositionsAndOrders, symbolLossRiskLabelText, fontSize, textColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
         } else {
            ObjectSetString(ChartID(), symbolLossRiskLabelObjectName, OBJPROP_TEXT, symbolLossRiskLabelText);
            ObjectSetInteger(ChartID(), symbolLossRiskLabelObjectName, OBJPROP_COLOR, textColor);
         }
      } else {
         if(ObjectFind(ChartID(), symbolLossRiskLabelObjectName) >= 0) {
            deleteLabel(symbolLossRiskLabelObjectName, ChartID());
         }
      }

      // Label SymbolRisk
      string symbolRiskLabelObjectName = objectNamePrefix + symbolArray[symbolId].SymbolString + "_symbolRiskLabel";
      if(NormalizeDouble(symbolArray[symbolId].symbolRiskValue, 0) != 0) {
         int xCordSymbolRiskLabel = 370;
         double symbolRiskPercent = symbolArray[symbolId].symbolRiskValue / AccountInfoDouble(ACCOUNT_EQUITY) * 100;
         string symbolRiskLabelText = DoubleToString(symbolArray[symbolId].symbolRiskValue, 0) +  " € (" + DoubleToString(symbolRiskPercent, 1) + " %)";
         textColor = labelDefaultColor;
         if(symbolRiskPercent > InpMaxSymbolRiskLevel1Percent) textColor = clrLevel1;
         if(symbolRiskPercent > InpMaxSymbolRiskLevel2Percent) textColor = clrLevel2;
         if(ObjectFind(ChartID(), symbolRiskLabelObjectName) < 0) {
            createLabel(symbolRiskLabelObjectName, xCordSymbolRiskLabel, yCordSymbolsPositionsAndOrders, symbolRiskLabelText, fontSize, textColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
         } else {
            ObjectSetString(ChartID(), symbolRiskLabelObjectName, OBJPROP_TEXT, symbolRiskLabelText);
            ObjectSetInteger(ChartID(), symbolRiskLabelObjectName, OBJPROP_COLOR, textColor);
         }
      } else {
         if(ObjectFind(ChartID(), symbolRiskLabelObjectName) >= 0) {
            deleteLabel(symbolRiskLabelObjectName, ChartID());
         }
      }

      // Label BuyOrders
//      if(symbolArray[symbolId].buyOrdersCount > 0) {
//         int xCordBuyOrderssLabel = 280;
//         string buyOrderssLabelObjectName = objectNamePrefix + symbolArray[symbolId].SymbolString + "_buyOrdersLabel";
//         string buyOrderssLabelText = IntegerToString(symbolArray[symbolId].buyOrdersCount) + ": " + DoubleToString(symbolArray[symbolId].buyOrdersVolume, 2);
//         color textColor = labelDefaultColor;
//         if(symbolArray[symbolId].buyOrdersVolume < symbolArray[symbolId].sellOrdersVolume) textColor = clrGray;
//         if(ObjectFind(ChartID(), buyOrderssLabelObjectName) < 0) {
//            createLabel(buyOrderssLabelObjectName, xCordBuyOrderssLabel, yCordSymbolsPositionsAndOrders, buyOrderssLabelText, fontSize, textColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
//         } else {
//            ObjectSetString(ChartID(), buyOrderssLabelObjectName, OBJPROP_TEXT, buyOrderssLabelText);
//         }
//      }

      // Label SellOrders
//      if(symbolArray[symbolId].sellOrdersCount > 0) {
//         int xCordSellOrderssLabel = 340;
//         string sellOrderssLabelObjectName = objectNamePrefix + symbolArray[symbolId].SymbolString + "_sellOrdersLabel";
//         string sellOrderssLabelText = IntegerToString(symbolArray[symbolId].sellOrdersCount) + ": " + DoubleToString(symbolArray[symbolId].sellOrdersVolume, 2);
//         color textColor = labelDefaultColor;
//         if(symbolArray[symbolId].buyOrdersVolume > symbolArray[symbolId].sellOrdersVolume) textColor = clrGray;
//         if(ObjectFind(ChartID(), sellOrderssLabelObjectName) < 0) {
//            createLabel(sellOrderssLabelObjectName, xCordSellOrderssLabel, yCordSymbolsPositionsAndOrders, sellOrderssLabelText, fontSize, textColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
//         } else {
//            ObjectSetString(ChartID(), sellOrderssLabelObjectName, OBJPROP_TEXT, sellOrderssLabelText);
//         }
//      }

      // Label OrderssDiff
//      string ordersDiffLabelObjectName = objectNamePrefix + symbolArray[symbolId].SymbolString + "_ordersDiffLabel";
//      if(NormalizeDouble(orderVolumeDiff, 2) != 0) {
//         int xCordOrdersDiffLabel = 400;
//         string ordersDiffLabelText = DoubleToString(orderVolumeDiff, 2);
//         if(ObjectFind(ChartID(), ordersDiffLabelObjectName) < 0) {
//            createLabel(ordersDiffLabelObjectName, xCordOrdersDiffLabel, yCordSymbolsPositionsAndOrders, ordersDiffLabelText, fontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
//         } else {
//            ObjectSetString(ChartID(), ordersDiffLabelObjectName, OBJPROP_TEXT, ordersDiffLabelText);
//         }
//      } else {
//         if(ObjectFind(ChartID(), ordersDiffLabelObjectName) >= 0) {
//            deleteLabel(ordersDiffLabelObjectName, ChartID());
//         }
//      }

      // Label SymbolProfit LONG
      string symbolProfitLongLabelObjectName = objectNamePrefix + symbolArray[symbolId].SymbolString + "_symbolProfitLongLabel";
      if(buyPositionsProfit) {
         int xCordSymbolProfitLongLabel = 500;
         double symbolProfitLongPercent = buyPositionsProfit / AccountInfoDouble(ACCOUNT_EQUITY) * 100;
         string symbolProfitLongLabelText = DoubleToString(buyPositionsProfit, 0) +  " € (" + DoubleToString(symbolProfitLongPercent, 1) + " %)";
         textColor = labelDefaultColor;
         if(buyPositionsProfit > 0) textColor = clrGreen;
         if(ObjectFind(ChartID(), symbolProfitLongLabelObjectName) < 0) {
            createLabel(symbolProfitLongLabelObjectName, xCordSymbolProfitLongLabel, yCordSymbolsPositionsAndOrders, symbolProfitLongLabelText, fontSize, textColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
         } else {
            ObjectSetString(ChartID(), symbolProfitLongLabelObjectName, OBJPROP_TEXT, symbolProfitLongLabelText);
         }
      } else {
         if(ObjectFind(ChartID(), symbolProfitLongLabelObjectName) >= 0) {
            deleteLabel(symbolProfitLongLabelObjectName, ChartID());
         }
      }

      // Label SymbolProfit SHORT
      string symbolProfitShortLabelObjectName = objectNamePrefix + symbolArray[symbolId].SymbolString + "_symbolProfitShortLabel";
      if(sellPositionsProfit) {
         int xCordSymbolProfitShortLabel = 610;
         double symbolProfitShortPercent = sellPositionsProfit / AccountInfoDouble(ACCOUNT_EQUITY) * 100;
         string symbolProfitShortLabelText = DoubleToString(sellPositionsProfit, 0) +  " € (" + DoubleToString(symbolProfitShortPercent, 1) + " %)";
         textColor = labelDefaultColor;
         if(sellPositionsProfit > 0) textColor = clrGreen;
         if(ObjectFind(ChartID(), symbolProfitShortLabelObjectName) < 0) {
            createLabel(symbolProfitShortLabelObjectName, xCordSymbolProfitShortLabel, yCordSymbolsPositionsAndOrders, symbolProfitShortLabelText, fontSize, textColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
         } else {
            ObjectSetString(ChartID(), symbolProfitShortLabelObjectName, OBJPROP_TEXT, symbolProfitShortLabelText);
         }
      } else {
         if(ObjectFind(ChartID(), symbolProfitShortLabelObjectName) >= 0) {
            deleteLabel(symbolProfitShortLabelObjectName, ChartID());
         }
      }

      // Label SymbolProfit Position
      string symbolProfitLabelObjectName = objectNamePrefix + symbolArray[symbolId].SymbolString + "_symbolProfitLabel";
      int xCordSymbolProfitLabel = 720;
      double symbolProfitPercent = symbolPositionProfit / AccountInfoDouble(ACCOUNT_EQUITY) * 100;
      string symbolProfitLabelText = DoubleToString(symbolPositionProfit, 0) +  " € (" + DoubleToString(symbolProfitPercent, 1) + " %)";
      textColor = labelDefaultColor;
      if(symbolPositionProfit > 0) textColor = clrGreen;
      if(ObjectFind(ChartID(), symbolProfitLabelObjectName) < 0) {
         createLabel(symbolProfitLabelObjectName, xCordSymbolProfitLabel, yCordSymbolsPositionsAndOrders, symbolProfitLabelText, fontSize, textColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
      } else {
         ObjectSetString(ChartID(), symbolProfitLabelObjectName, OBJPROP_TEXT, symbolProfitLabelText);
      }

      // Label SymbolTradeHistoryProfit
      string symbolTradeHistoryProfitLabelObjectName = objectNamePrefix + symbolArray[symbolId].SymbolString + "_symbolTradeHistoryProfitLabel";
      int xCordSymbolTradeHistoryProfitLabel = 830;
      double symbolTradeHistoryProfitPercent = symbolArray[symbolId].symbolTradeHistoryProfit / AccountInfoDouble(ACCOUNT_EQUITY) * 100;
      string symbolTradeHistoryProfitLabelText = DoubleToString(symbolArray[symbolId].symbolTradeHistoryProfit, 0) +  " € (" + DoubleToString(symbolTradeHistoryProfitPercent, 1) + " %)";
      textColor = labelDefaultColor;
      if(symbolArray[symbolId].symbolTradeHistoryProfit > 0) textColor = clrGreen;
      if(ObjectFind(ChartID(), symbolTradeHistoryProfitLabelObjectName) < 0) {
         createLabel(symbolTradeHistoryProfitLabelObjectName, xCordSymbolTradeHistoryProfitLabel, yCordSymbolsPositionsAndOrders, symbolTradeHistoryProfitLabelText, fontSize, textColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
      } else {
         ObjectSetString(ChartID(), symbolTradeHistoryProfitLabelObjectName, OBJPROP_TEXT, symbolTradeHistoryProfitLabelText);
      }

      // Label SymbolTotalProfit
      string symbolTotalProfitLabelObjectName = objectNamePrefix + symbolArray[symbolId].SymbolString + "_symbolTotalProfitLabel";
      int xCordSymbolTotalProfitLabel = 940;
      double symbolTotalProfitPercent = symbolTotalProfit / AccountInfoDouble(ACCOUNT_EQUITY) * 100;
      string symbolTotalProfitLabelText = DoubleToString(symbolTotalProfit, 0) +  " € (" + DoubleToString(symbolTotalProfitPercent, 1) + " %)";
      textColor = labelDefaultColor;
      if(symbolTotalProfit > 0) textColor = clrGreen;
      if(ObjectFind(ChartID(), symbolTotalProfitLabelObjectName) < 0) {
         createLabel(symbolTotalProfitLabelObjectName, xCordSymbolTotalProfitLabel, yCordSymbolsPositionsAndOrders, symbolTotalProfitLabelText, fontSize, textColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
      } else {
         ObjectSetString(ChartID(), symbolTotalProfitLabelObjectName, OBJPROP_TEXT, symbolTotalProfitLabelText);
      }



      yCordSymbolsPositionsAndOrders += rowHigh;
   }

// Label AccountRisk
   string accountRiskLabelObjectName = objectNamePrefix + "_accountRiskLabel";
   if(NormalizeDouble(accountRiskValue, 0) != 0) {
      int xCordAccountRiskLabel = 20;
      double accountRiskPercent = accountRiskValue / AccountInfoDouble(ACCOUNT_EQUITY) * 100;
      string accountRiskLabelText = "AccountRisk: " + DoubleToString(accountRiskValue, 0) +  " € (" + DoubleToString(accountRiskPercent, 1) + " %)";
      color textColor = labelDefaultColor;
      if(accountRiskPercent > InpMaxAccountRiskLevel1Percent) textColor = clrLevel1;
      if(accountRiskPercent > InpMaxAccountRiskLevel2Percent) textColor = clrLevel2;
      if(ObjectFind(ChartID(), accountRiskLabelObjectName) < 0) {
         createLabel(accountRiskLabelObjectName, xCordAccountRiskLabel, 10, accountRiskLabelText, fontSize, textColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
      } else {
         ObjectSetString(ChartID(), accountRiskLabelObjectName, OBJPROP_TEXT, accountRiskLabelText);
         ObjectSetInteger(ChartID(), accountRiskLabelObjectName, OBJPROP_COLOR, textColor);
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getPointValueBySymbol(string pPositionSymbol) {
   return SymbolInfoDouble(pPositionSymbol, SYMBOL_TRADE_TICK_VALUE) / SymbolInfoDouble(pPositionSymbol, SYMBOL_TRADE_TICK_SIZE) * SymbolInfoDouble(pPositionSymbol, SYMBOL_POINT);
}

PositionStruct buildPositionStructForSymbolArray(const long pPositionTicket) {

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

   positionStruct.ordersLoaded = false;
   positionStruct.buyOrdersCount = 0;
   positionStruct.buyOrdersVolume = 0;
   positionStruct.sellOrdersCount = 0;
   positionStruct.sellOrdersVolume = 0;

   positionStruct.tradeHistoryLoaded = false;
   positionStruct.symbolFirstInDatetime = 0;
   positionStruct.symbolTradeHistoryProfit = 0;

   positionStruct.symbolRiskValue = 0;

   if(PositionType(pPositionTicket) == ORDER_TYPE_BUY) {
      positionStruct.buyPositionsCount = 1;
      positionStruct.buyPositionsVolume = NormalizeDouble(PositionVolume(pPositionTicket), 2);
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
      positionStruct.sellPositionsVolume = NormalizeDouble(PositionVolume(pPositionTicket), 2);
      positionStruct.sellPositionsLevelVolume = PositionVolume(pPositionTicket) * PositionOpenPrice(pPositionTicket);
      positionStruct.sellPositionsProfit = PositionProfit(pPositionTicket);
      if(PositionStopLoss(pPositionTicket) != 0) {
         ArrayResize(positionStruct.buyOrdersLevelVolumeArray, ArrayRange(positionStruct.buyOrdersLevelVolumeArray, 0) + 1);
         positionStruct.buyOrdersLevelVolumeArray[ArrayRange(positionStruct.buyOrdersLevelVolumeArray, 0) - 1][0] = PositionStopLoss(pPositionTicket);
         positionStruct.buyOrdersLevelVolumeArray[ArrayRange(positionStruct.buyOrdersLevelVolumeArray, 0) - 1][1] = PositionVolume(pPositionTicket);
         positionStruct.buyOrdersVolume += PositionVolume(pPositionTicket);
      }
   }


   if(positionStruct.ordersLoaded == false) {
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

      positionStruct.ordersLoaded = true;

   }

   if(positionStruct.symbolFirstInDatetime == 0 || PositionOpenTime(pPositionTicket) < positionStruct.symbolFirstInDatetime) positionStruct.symbolFirstInDatetime = PositionOpenTime(pPositionTicket);
   if(positionStruct.tradeHistoryLoaded == false) getTradeHistoryProfit(positionStruct.SymbolString, positionStruct.symbolFirstInDatetime);

   return positionStruct;
}

bool getTradeHistoryProfit(const string pSymbolString, const datetime pFirstInDatetime, datetime pToDatetime = 0) {

   ResetLastError();

   const datetime fromStartDatetime = 0;
   if(pToDatetime == 0) pToDatetime = TimeCurrent();
   if(!TradeHistory.HistorySelect(fromStartDatetime, pToDatetime)) {
      Alert("CPairedDealInfo::HistorySelect() failed!: " + IntegerToString(GetLastError()));
      return(false);
   }

   for(int tradeHistoryIndex = 0; tradeHistoryIndex < TradeHistory.Total(); tradeHistoryIndex++) {
      if(TradeHistory.SelectByIndex(tradeHistoryIndex)) {
         if(TradeHistory.Symbol() == pSymbolString && TradeHistory.TimeClose() >= pFirstInDatetime) {
            double   netProfit   = TradeHistory.Profit() + TradeHistory.Commission() + TradeHistory.Swap();
            positionStruct.symbolTradeHistoryProfit += netProfit;
         }
      }
   }

   positionStruct.tradeHistoryLoaded = true;

   return (true);
}

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
void OnDeinit(const int reason) {
   deleteLabelLike(objectNamePrefix);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam) {

   if(id == CHARTEVENT_OBJECT_DRAG) {
      deleteLabelLike(objectNamePrefix);
      calculateRisk();
   }
}
//+------------------------------------------------------------------+
