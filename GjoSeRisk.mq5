/*

   IND_GjoSeRisk.mq5
   Copyright 2023, Gregory Jo
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

//+------------------------------------------------------------------+
//| Includes                                                         |
//+------------------------------------------------------------------+
#include "Basics\\Includes.mqh"

//+------------------------------------------------------------------+
//| Headers                                                          |
//+------------------------------------------------------------------+
#property   copyright   "2023, GjoSe"
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

//+------------------------------------------------------------------+
int OnInit() {

   deleteLabelLike(OBJECT_NAME_PREFIX);
   calculateRisk();

   IndicatorSetString(INDICATOR_SHORTNAME, MY_INDICATOR_SHORTNAME);

   return(0);
}

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
      deleteLabelLike(OBJECT_NAME_PREFIX);
      calculateRisk();
   }

   return(pRatesTotal);
}

void calculateRisk() {

   if (subWindow <= 0) subWindow = 0;
   ArrayResize(symbolArray, 0);

   int yCordSymbolsPositionsAndOrders = yCordSymbolsTableHeadline + rowHigh * 2;

   // Account
   createTableHeadlineAccount("_accountTableHeadlineBalance", "Balance", xCordAccountBalance);
   createTableHeadlineAccount("_accountTableHeadlineEquity", "Equity", xCordAccountEquity);
   createTableHeadlineAccount("_accountTableHeadlineCost", "Cost (%)", xCordAccountCost);
   createTableHeadlineAccount("_accountTableHeadlinePnL", "PnL (%)", xCordAccountPnL);
   createTableHeadlineAccount("_accountTableHeadlineLossRisk", "LossRisk (%)", xCordAccountLossRisk);
   createTableHeadlineAccount("_accountTableHeadlineReward", "Reward (%)", xCordAccountReward);
   createTableHeadlineAccount("_accountTableHeadlineRRR", "RRR", xCordAccountRRR);

   createTableContentAccountBalance(xCordAccountBalance);
   createTableContentAccountEquity(xCordAccountEquity);
   createTableContentAccountCost(xCordAccountCost);
   createTableContentAccountProfit(xCordAccountPnL);
   createTableContentAccountLossRisk(xCordAccountLossRisk);
   createTableContentAccountReward(xCordAccountReward);
   createTableContentAccountRRR(xCordAccountRRR);

   // Symbols
   createTableHeadlineSymbol("_symbolTableHeadlineSymbol", "Symbol (" + IntegerToString(symbolsCount) + ")", xCordSymbolsTableSymbol);
   createTableHeadlineSymbol("_symbolHoldTimeString", "Hold Time", xCordSymbolsTableHoldTime);
   createTableHeadlineSymbol("_symbolSizeString", "Size", xCordSymbolsTableSize);
   createTableHeadlineSymbol("_symbolEntryPriceString", "Entry Price", xCordSymbolsTableEntryPrice);
   createTableHeadlineSymbol("_symbolCostString", "Cost (%)", xCordSymbolsTableCost);
   createTableHeadlineSymbol("_symbolPnLString", "PnL (%)", xCordSymbolsTablePnL);
   createTableHeadlineSymbol("_symbolLossRiskString", "LossRisk (%)", xCordSymbolsTableLossRisk);
   createTableHeadlineSymbol("_symbolRewardString", "Reward (%)", xCordSymbolsTableReward);
   createTableHeadlineSymbol("_symbolRRRString", "RRR", xCordSymbolsTableRRR);

   createPositionStructForSymbolArray();

   symbolsCount = 0;
   for(int symbolId = 0; symbolId < ArraySize(symbolArray); symbolId++) {
      symbolsCount++;

      createTableContentSymbol(symbolId, xCordSymbolsTableSymbol, yCordSymbolsPositionsAndOrders);
      createTableContentHoldTime(symbolId, xCordSymbolsTableHoldTime, yCordSymbolsPositionsAndOrders);
      createTableContentSize(symbolId, xCordSymbolsTableSize, yCordSymbolsPositionsAndOrders);
      createTableContentEntryPrice(symbolId, xCordSymbolsTableEntryPrice, yCordSymbolsPositionsAndOrders);
      createTableContentCost(symbolId, xCordSymbolsTableCost, yCordSymbolsPositionsAndOrders);
      createTableContentProfit(symbolId, xCordSymbolsTablePnL, yCordSymbolsPositionsAndOrders);
      createTableContentLossRisk(symbolId, xCordSymbolsTableLossRisk, yCordSymbolsPositionsAndOrders);
      createTableContentReward(symbolId, xCordSymbolsTableReward, yCordSymbolsPositionsAndOrders);
      createTableContentRRR(symbolId, xCordSymbolsTableRRR, yCordSymbolsPositionsAndOrders);

      yCordSymbolsPositionsAndOrders += rowHigh;
   }
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   deleteLabelLike(OBJECT_NAME_PREFIX);
}

//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam) {

   if(id == CHARTEVENT_OBJECT_DRAG) {
      deleteLabelLike(OBJECT_NAME_PREFIX);
      calculateRisk();
   }
}
//+------------------------------------------------------------------+