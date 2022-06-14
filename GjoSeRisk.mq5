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

   ===============

//*/

#include <GjoSe\\Utilities\\InclBasicUtilities.mqh>
#include <GjoSe\\Objects\\InclLabel.mqh>

#property   copyright   "2022, GjoSe"
#property   link        "http://www.gjo-se.com"
#property   description "GjoSe Risk Management"
#define     VERSION "1.5.1"
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

string objectNamePrefix = "GjoSeRisk_";
CPositions  Positions;
CPending    Pending;
CNewBar     NewBar;
CTimer      Timer;

bool isNewM1Bar = false;

const string MY_INDICATOR_SHORTNAME = "GjoSeRisk";
const int SORT_ASC = 0;
const int SORT_DESC = 1;

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

//   int      Reward;
//   double   RewardPercent;
//   double   RRR;
};

int symbolsCount;
PositionStruct symbolArray[];
//PositionStruct accountArray[];

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
   }

   calculateRisk();

   return(pRatesTotal);
}

void calculateRisk() {

   int subWindow = ChartWindowFind(0, MY_INDICATOR_SHORTNAME);
   if (subWindow <= 0) subWindow = 0;

   ArrayResize(symbolArray, 0);
//   ArrayResize(accountArray, 0);

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

   int yCordSymbolsHeadline = 200;
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
      int xCord = 140;
      int yCord = 240;
      createLabel(positionStringLabelObjectName, xCord, yCord, positionStringLabelText, headLine2FontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
   } else {
      ObjectSetString(ChartID(), positionStringLabelObjectName, OBJPROP_TEXT, positionStringLabelText);
   }

// Label OrdersString
   string ordersStringLabelObjectName = objectNamePrefix + "_ordersString";
   string ordersStringLabelText = "Orders";
   if(ObjectFind(ChartID(), ordersStringLabelObjectName) < 0) {
      int xCord = 330;
      int yCord = 240;
      createLabel(ordersStringLabelObjectName, xCord, yCord, ordersStringLabelText, headLine2FontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
   } else {
      ObjectSetString(ChartID(), ordersStringLabelObjectName, OBJPROP_TEXT, ordersStringLabelText);
   }

// Label PositionsOrdersDiffString
   string positionsOrdersDiffStringLabelObjectName = objectNamePrefix + "_positionsOrdersDiffString";
   string positionsOrdersDiffStringLabelText = "Diff";
   if(ObjectFind(ChartID(), positionsOrdersDiffStringLabelObjectName) < 0) {
      int xCord = 460;
      int yCord = 240;
      createLabel(positionsOrdersDiffStringLabelObjectName, xCord, yCord, positionsOrdersDiffStringLabelText, headLine2FontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
   } else {
      ObjectSetString(ChartID(), positionsOrdersDiffStringLabelObjectName, OBJPROP_TEXT, positionsOrdersDiffStringLabelText);
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

      // Account
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
   symbolsCount = 0;
   for(int symbolId = 0; symbolId < ArraySize(symbolArray); symbolId++) {
      symbolsCount++;
      bool symbolInRisk = false;
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
//                  Print("StartVolume: " + MathAbs(positionsVolumeDiff) + " buyPositionsLevelAverage: " + DoubleToString(buyPositionsLevelAverage, Digits()) + " sellOrderLevel: " + DoubleToString(sellOrderLevel, Digits()) + " Volume: " + sellOrderVolume + " positionRiskPoints: " + DoubleToString(positionRiskPoints, 0) + " positionRiskValue: " + DoubleToString(positionRiskValue, 0) + " symbolLossRiskValue: " + DoubleToString(symbolArray[symbolId].symbolLossRiskValue, 0) + " symbolTotalRiskValue: " + DoubleToString(symbolArray[symbolId].symbolTotalRiskValue, 0) + " RestVol: " + DoubleToString(positionsVolumeDiffLocal, 2));
               }
            }
         }

         if(positionsVolumeDiffLocal > 0) {
            symbolArray[symbolId].symbolLossRiskValue = AccountInfoDouble(ACCOUNT_EQUITY);
            symbolInRisk = true;
//             Print("Buy Volume nicht abgesichrt: " + " symbolLossRiskValue: " + DoubleToString(symbolArray[symbolId].symbolLossRiskValue, 0) + " RestVol: " + DoubleToString(positionsVolumeDiffLocal, 2));
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
//                  Print("StartVolume: " + MathAbs(positionsVolumeDiff) + " sellPositionsLevelAverage: " + DoubleToString(sellPositionsLevelAverage, Digits()) + " buyOrderLevel: " + DoubleToString(buyOrderLevel, Digits()) + " Volume: " + buyOrderVolume + " positionRiskPoints: " + DoubleToString(positionRiskPoints, 0) + " positionRiskValue: " + DoubleToString(positionRiskValue, 0) + " symbolRiskValue: " + DoubleToString(symbolArray[symbolId].symbolLossRiskValue, 0)+ " symbolTotalRiskValue: " + DoubleToString(symbolArray[symbolId].symbolTotalRiskValue, 0) + " RestVol: " + DoubleToString(positionsVolumeDiffLocal, 2));
               }
            }
         }

         if(positionsVolumeDiffLocal > 0) {
            symbolArray[symbolId].symbolLossRiskValue = AccountInfoDouble(ACCOUNT_EQUITY);
            symbolInRisk = true;
//             Print("Sell Volume nicht abgesichrt: " + " symbolLossRiskValue: " + DoubleToString(symbolArray[symbolId].symbolLossRiskValue, 0) + " RestVol: " + DoubleToString(positionsVolumeDiffLocal, 2));
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
         string buyPositionsLabelText = IntegerToString(symbolArray[symbolId].buyPositionsCount) + ": " + DoubleToString(symbolArray[symbolId].buyPositionsVolume, 2);
         color textColor = labelDefaultColor;
         if(symbolArray[symbolId].buyPositionsVolume < symbolArray[symbolId].sellPositionsVolume) textColor = clrGray;
         if(ObjectFind(ChartID(), buyPositionsLabelObjectName) < 0) {
            createLabel(buyPositionsLabelObjectName, xCordBuyPositionsLabel, yCordSymbolsPositionsAndOrders, buyPositionsLabelText, fontSize, textColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
         } else {
            ObjectSetString(ChartID(), buyPositionsLabelObjectName, OBJPROP_TEXT, buyPositionsLabelText);
         }
      }

      // Label SellPositions
      if(symbolArray[symbolId].sellPositionsCount > 0) {
         int xCordSellPositionsLabel = 160;
         string sellPositionsLabelObjectName = objectNamePrefix + symbolArray[symbolId].SymbolString + "_sellPositionsLabel";
         string sellPositionsLabelText = IntegerToString(symbolArray[symbolId].sellPositionsCount) + ": " + DoubleToString(symbolArray[symbolId].sellPositionsVolume, 2);
         color textColor = labelDefaultColor;
         if(symbolArray[symbolId].buyPositionsVolume > symbolArray[symbolId].sellPositionsVolume) textColor = clrGray;
         if(ObjectFind(ChartID(), sellPositionsLabelObjectName) < 0) {
            createLabel(sellPositionsLabelObjectName, xCordSellPositionsLabel, yCordSymbolsPositionsAndOrders, sellPositionsLabelText, fontSize, textColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
         } else {
            ObjectSetString(ChartID(), sellPositionsLabelObjectName, OBJPROP_TEXT, sellPositionsLabelText);
         }
      }

      // Label PositionsDiff
      string positionsDiffLabelObjectName = objectNamePrefix + symbolArray[symbolId].SymbolString + "_positionsDiffLabel";
      if(NormalizeDouble(positionsVolumeDiff, 2) != 0) {
         int xCordPositionsDiffLabel = 220;
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

      // Label BuyOrders
      if(symbolArray[symbolId].buyOrdersCount > 0) {
         int xCordBuyOrderssLabel = 280;
         string buyOrderssLabelObjectName = objectNamePrefix + symbolArray[symbolId].SymbolString + "_buyOrdersLabel";
         string buyOrderssLabelText = IntegerToString(symbolArray[symbolId].buyOrdersCount) + ": " + DoubleToString(symbolArray[symbolId].buyOrdersVolume, 2);
         color textColor = labelDefaultColor;
         if(symbolArray[symbolId].buyOrdersVolume < symbolArray[symbolId].sellOrdersVolume) textColor = clrGray;
         if(ObjectFind(ChartID(), buyOrderssLabelObjectName) < 0) {
            createLabel(buyOrderssLabelObjectName, xCordBuyOrderssLabel, yCordSymbolsPositionsAndOrders, buyOrderssLabelText, fontSize, textColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
         } else {
            ObjectSetString(ChartID(), buyOrderssLabelObjectName, OBJPROP_TEXT, buyOrderssLabelText);
         }
      }

      // Label SellOrders
      if(symbolArray[symbolId].sellOrdersCount > 0) {
         int xCordSellOrderssLabel = 340;
         string sellOrderssLabelObjectName = objectNamePrefix + symbolArray[symbolId].SymbolString + "_sellOrdersLabel";
         string sellOrderssLabelText = IntegerToString(symbolArray[symbolId].sellOrdersCount) + ": " + DoubleToString(symbolArray[symbolId].sellOrdersVolume, 2);
         color textColor = labelDefaultColor;
         if(symbolArray[symbolId].buyOrdersVolume > symbolArray[symbolId].sellOrdersVolume) textColor = clrGray;
         if(ObjectFind(ChartID(), sellOrderssLabelObjectName) < 0) {
            createLabel(sellOrderssLabelObjectName, xCordSellOrderssLabel, yCordSymbolsPositionsAndOrders, sellOrderssLabelText, fontSize, textColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
         } else {
            ObjectSetString(ChartID(), sellOrderssLabelObjectName, OBJPROP_TEXT, sellOrderssLabelText);
         }
      }

      // Label OrderssDiff
      string ordersDiffLabelObjectName = objectNamePrefix + symbolArray[symbolId].SymbolString + "_ordersDiffLabel";
      if(NormalizeDouble(orderVolumeDiff, 2) != 0) {
         int xCordOrdersDiffLabel = 400;
         string ordersDiffLabelText = DoubleToString(orderVolumeDiff, 2);
         if(ObjectFind(ChartID(), ordersDiffLabelObjectName) < 0) {
            createLabel(ordersDiffLabelObjectName, xCordOrdersDiffLabel, yCordSymbolsPositionsAndOrders, ordersDiffLabelText, fontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
         } else {
            ObjectSetString(ChartID(), ordersDiffLabelObjectName, OBJPROP_TEXT, ordersDiffLabelText);
         }
      } else {
         if(ObjectFind(ChartID(), ordersDiffLabelObjectName) >= 0) {
            deleteLabel(ordersDiffLabelObjectName, ChartID());
         }
      }

      // Label PositionsAndOrdersDiff
      string positionsAndOrdersDiffLabelObjectName = objectNamePrefix + symbolArray[symbolId].SymbolString + "_positionsAndOrdersDiffLabel";
      if(NormalizeDouble(positionsVolumeDiff + orderVolumeDiff, 2) != 0) {
         int xCordPositionsAndOrdersDiffLabel = 460;
         string positionsAndOrdersDiffLabelText = DoubleToString(volumeDiff, 2);
         color textColor = labelDefaultColor;
         if(symbolInRisk) textColor = clrRed;
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

      // Label SymbolRisk
//      string symbolRiskLabel = "Risk: " + DoubleToString(symbolArray[symbolId].symbolLossRiskValue, 0) +  " € (" + DoubleToString(symbolArray[symbolId].symbolLossRiskValue / AccountInfoDouble(ACCOUNT_EQUITY) * 100, 1) + " %) / ";
//      symbolRiskLabel += DoubleToString(symbolArray[symbolId].symbolTotalRiskValue, 0) +  " € (" + DoubleToString(symbolArray[symbolId].symbolTotalRiskValue / AccountInfoDouble(ACCOUNT_EQUITY) * 100, 1) + " %)";
//      createLabel(objectNamePrefix + symbolArray[symbolId].SymbolString + "_symbolRiskLabel", xCordSymbolRisk, yCordSymbolsPositionsAndOrders, symbolRiskLabel, fontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);

      // Label SymbolProfit
//      string symbolProfitLabel = "Profit: " + DoubleToString(symbolPositionProfit, 0) +  " € (" + DoubleToString(symbolPositionProfit / AccountInfoDouble(ACCOUNT_EQUITY) * 100, 1) + " %)";
//      createLabel(objectNamePrefix + symbolArray[symbolId].SymbolString + "_symbolProfitLabel", xCordSymbolProfit, yCordSymbolsPositionsAndOrders, symbolProfitLabel, fontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);

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
   }
}
//+------------------------------------------------------------------+
