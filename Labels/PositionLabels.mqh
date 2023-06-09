//+------------------------------------------------------------------+
//|                                                      GjoSeRisk   |
//|                                      Copyright 2023, Gregory Jo  |
//|                                       http://www.gjo-se.com      |
//+------------------------------------------------------------------+

void createTableHeadlineSymbol(const string pTableHeadlineString, const string pTableHeadlineLabeltext, const int pXCord) {

   string positionStringLabelObjectName = OBJECT_NAME_PREFIX + pTableHeadlineString;
   if(ObjectFind(ChartID(), positionStringLabelObjectName) < 0) {
      createLabel(positionStringLabelObjectName, pXCord, yCordSymbolsTableHeadline, pTableHeadlineLabeltext, headLine2FontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
   } else {
      ObjectSetString(ChartID(), positionStringLabelObjectName, OBJPROP_TEXT, pTableHeadlineLabeltext);
   }
}

void createTableContentSymbol(const int pSymbolId, const int pXCord, const int pYCord) {

   string symbolStringLabelObjectName = OBJECT_NAME_PREFIX + symbolArray[pSymbolId].SymbolString;
   string positionCount;
   if(symbolArray[pSymbolId].count > 1) {
      positionCount = " (" + IntegerToString(symbolArray[pSymbolId].count) + ")";
   }

   string symbolStringLabelText = symbolArray[pSymbolId].SymbolString + positionCount ;
   if(ObjectFind(ChartID(), symbolStringLabelObjectName) < 0) {
      createLabel(symbolStringLabelObjectName, pXCord, pYCord, symbolStringLabelText, fontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
   } else {
      ObjectSetString(ChartID(), symbolStringLabelObjectName, OBJPROP_TEXT, symbolStringLabelText);
   }
}

void createTableContentHoldTime(const int pSymbolId, const int pXCord, const int pYCord) {

   string symbolStringLabelObjectName = OBJECT_NAME_PREFIX + symbolArray[pSymbolId].SymbolString + "_holdTime";
   string symbolStringLabelText = DoubleToString(((int)TimeCurrent() - (symbolArray[pSymbolId].openTime)) / 86400, 0);
   if(ObjectFind(ChartID(), symbolStringLabelObjectName) < 0) {
      createLabel(symbolStringLabelObjectName, pXCord, pYCord, symbolStringLabelText, fontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPointRight, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
   } else {
      ObjectSetString(ChartID(), symbolStringLabelObjectName, OBJPROP_TEXT, symbolStringLabelText);
   }
}

void createTableContentSize(const int pSymbolId, const int pXCord, const int pYCord) {

   string buyPositionsLabelObjectName = OBJECT_NAME_PREFIX + symbolArray[pSymbolId].SymbolString + "_size";
   string buyPositionsLabelText = DoubleToString(symbolArray[pSymbolId].size, 2);
   if(ObjectFind(ChartID(), buyPositionsLabelObjectName) < 0) {
      createLabel(buyPositionsLabelObjectName, pXCord, pYCord, buyPositionsLabelText, fontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPointRight, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
   } else {
      ObjectSetString(ChartID(), buyPositionsLabelObjectName, OBJPROP_TEXT, buyPositionsLabelText);
   }
}

void createTableContentEntryPrice(const int pSymbolId, const int pXCord, const int pYCord) {

   string entryPriceLabelObjectName = OBJECT_NAME_PREFIX + symbolArray[pSymbolId].SymbolString + "_entryPrice";
   string entryPriceLabelText = DoubleToString(symbolArray[pSymbolId].avgEntryPrice, 2) + " $";
   if(ObjectFind(ChartID(), entryPriceLabelObjectName) < 0) {
      createLabel(entryPriceLabelObjectName, pXCord, pYCord, entryPriceLabelText, fontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPointRight, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
   } else {
      ObjectSetString(ChartID(), entryPriceLabelObjectName, OBJPROP_TEXT, entryPriceLabelText);
   }
}

void createTableContentCost(const int pSymbolId, const int pXCord, const int pYCord) {

   string costLabelObjectName = OBJECT_NAME_PREFIX + symbolArray[pSymbolId].SymbolString + "_cost";
   double costPercent = symbolArray[pSymbolId].cost / AccountInfoDouble(ACCOUNT_EQUITY) * 100;
   string costLabelText = DoubleToString(symbolArray[pSymbolId].cost, 0) +  " € (" + DoubleToString(costPercent, 1) + " %)";
   color textColor = labelDefaultColor;
   if(costPercent > InpMaxSymbolCostLevel1Percent) textColor = CLR_LEVEL_1;
   if(costPercent > InpMaxSymbolCostLevel2Percent) textColor = CLR_LEVEL_2;
   if(ObjectFind(ChartID(), costLabelObjectName) < 0) {
      createLabel(costLabelObjectName, pXCord, pYCord, costLabelText, fontSize, textColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPointRight, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
   } else {
      ObjectSetString(ChartID(), costLabelObjectName, OBJPROP_TEXT, costLabelText);
   }
}

void createTableContentProfit(const int pSymbolId, const int pXCord, const int pYCord) {

   string profitLabelObjectName = OBJECT_NAME_PREFIX + symbolArray[pSymbolId].SymbolString + "_profit";
   double profitPercent = symbolArray[pSymbolId].profit / AccountInfoDouble(ACCOUNT_EQUITY) * 100;
   string profitLabelText = DoubleToString(symbolArray[pSymbolId].profit, 0) +  " € (" + DoubleToString(profitPercent, 1) + " %)";

   if(ObjectFind(ChartID(), profitLabelObjectName) < 0) {
      createLabel(profitLabelObjectName, pXCord, pYCord, profitLabelText, fontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPointRight, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
   } else {
      ObjectSetString(ChartID(), profitLabelObjectName, OBJPROP_TEXT, profitLabelText);
   }

}

void createTableContentLossRisk(const int pSymbolId, const int pXCord, const int pYCord) {

   string lossRiskLabelObjectName = OBJECT_NAME_PREFIX + symbolArray[pSymbolId].SymbolString + "_lossRisk";
   double lossRiskPercent = symbolArray[pSymbolId].lossRisk / AccountInfoDouble(ACCOUNT_EQUITY) * 100;
   string lossRiskLabelText;
   if(symbolArray[pSymbolId].lossRisk > 0){
      lossRiskLabelText = DoubleToString(symbolArray[pSymbolId].lossRisk, 0) +  " € (" + DoubleToString(lossRiskPercent, 1) + " %)";
   }
   else if(symbolArray[pSymbolId].lossRisk == 0){
      lossRiskLabelText = "-------";
   }else{
      lossRiskLabelText = "SL setzen";
   }
   color textColor = labelDefaultColor;
   if(lossRiskPercent > InpMaxSymboLossRiskLevel1Percent) textColor = CLR_LEVEL_1;
   if(lossRiskPercent > InpMaxSymbolLossRiskLevel2Percent) textColor = CLR_LEVEL_2;
   if(ObjectFind(ChartID(), lossRiskLabelObjectName) < 0) {
      createLabel(lossRiskLabelObjectName, pXCord, pYCord, lossRiskLabelText, fontSize, textColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPointRight, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
   } else {
      ObjectSetString(ChartID(), lossRiskLabelObjectName, OBJPROP_TEXT, lossRiskLabelText);
   }
}

void createTableContentReward(const int pSymbolId, const int pXCord, const int pYCord) {

   string rewardLabelObjectName = OBJECT_NAME_PREFIX + symbolArray[pSymbolId].SymbolString + "_reward";
   double rewardPercent = symbolArray[pSymbolId].reward / AccountInfoDouble(ACCOUNT_EQUITY) * 100;
   string rewardLabelText = (symbolArray[pSymbolId].reward >= SL_TP_MIN_VALUE) ? DoubleToString(symbolArray[pSymbolId].reward, 0) +  " € (" + DoubleToString(rewardPercent, 1) + " %)" : "TP setzen";
   if(ObjectFind(ChartID(), rewardLabelObjectName) < 0) {
      createLabel(rewardLabelObjectName, pXCord, pYCord, rewardLabelText, fontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPointRight, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
   } else {
      ObjectSetString(ChartID(), rewardLabelObjectName, OBJPROP_TEXT, rewardLabelText);
   }

}

void createTableContentRRR(const int pSymbolId, const int pXCord, const int pYCord) {

   string rrrLabelObjectName = OBJECT_NAME_PREFIX + symbolArray[pSymbolId].SymbolString + "_rrr";
   string rrrLabelText = (symbolArray[pSymbolId].rrr >= SL_TP_MIN_VALUE) ? DoubleToString(symbolArray[pSymbolId].rrr, 0) : "SL | TP";
   color textColor = labelDefaultColor;
   if(symbolArray[pSymbolId].rrr < InpMinRRRLevel1) textColor = CLR_LEVEL_1;
   if(symbolArray[pSymbolId].rrr < InpMinRRRLevel2) textColor = CLR_LEVEL_2;
   if(ObjectFind(ChartID(), rrrLabelObjectName) < 0) {
      createLabel(rrrLabelObjectName, pXCord, pYCord, rrrLabelText, fontSize, textColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPointRight, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
   } else {
      ObjectSetString(ChartID(), rrrLabelObjectName, OBJPROP_TEXT, rrrLabelText);
   }
}
//+------------------------------------------------------------------+
