//+------------------------------------------------------------------+
//|                                                    GjoSeRisk     |
//|                                   Copyright 2023, Gregory Jo     |
//|                                        http://www.gjo-se.com     |
//+------------------------------------------------------------------+

void createTableHeadlineAccount(const string pTableHeadlineString, const string pTableHeadlineLabeltext, const int pXCord) {

   string positionStringLabelObjectName = OBJECT_NAME_PREFIX + pTableHeadlineString;
   if(ObjectFind(ChartID(), positionStringLabelObjectName) < 0) {
      createLabel(positionStringLabelObjectName, pXCord, yCordAccountTableHeadline, pTableHeadlineLabeltext, headLine2FontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
   } else {
      ObjectSetString(ChartID(), positionStringLabelObjectName, OBJPROP_TEXT, pTableHeadlineLabeltext);
   }
}

void createTableContentAccountBalance(const int pXCord) {

   string labelName = OBJECT_NAME_PREFIX + "_accountBalance";
   string labelText = DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 0) + " €";
   if(ObjectFind(ChartID(), labelName) < 0) {
      createLabel(labelName, pXCord, yCordAccountTableContent, labelText, fontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
   } else {
      ObjectSetString(ChartID(), labelName, OBJPROP_TEXT, labelText);
   }
}

void createTableContentAccountEquity(const int pXCord) {

   string labelName = OBJECT_NAME_PREFIX + "_accountEquity";
   string labelText = DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 0) + " €";
   if(ObjectFind(ChartID(), labelName) < 0) {
      createLabel(labelName, pXCord, yCordAccountTableContent, labelText, fontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPoint, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
   } else {
      ObjectSetString(ChartID(), labelName, OBJPROP_TEXT, labelText);
   }
}

void createTableContentAccountCost(const int pXCord) {

   string labelName = OBJECT_NAME_PREFIX + "_accountCost";
   double percent = accountStruct.cost / AccountInfoDouble(ACCOUNT_EQUITY);
   color textColor = labelDefaultColor;
   if(percent > InpMaxAccountLeverageLevel1) textColor = CLR_LEVEL_1;
   if(percent > InpMaxAccountLeverageLevel2) textColor = CLR_LEVEL_2;
   string labelText = DoubleToString(accountStruct.cost, 0)  +  " € (" + DoubleToString(percent, 1) + ")";
   if(ObjectFind(ChartID(), labelName) < 0) {
      createLabel(labelName, pXCord, yCordAccountTableContent, labelText, fontSize, textColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPointRight, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
   } else {
      ObjectSetString(ChartID(), labelName, OBJPROP_TEXT, labelText);
   }
}
void createTableContentAccountProfit(const int pXCord) {

   string labelName = OBJECT_NAME_PREFIX + "_accountProfit";
   double percent = accountStruct.profit / AccountInfoDouble(ACCOUNT_EQUITY) * 100;
   string labelText = DoubleToString(accountStruct.profit, 0)  +  " € (" + DoubleToString(percent, 0) + " %)";
   if(ObjectFind(ChartID(), labelName) < 0) {
      createLabel(labelName, pXCord, yCordAccountTableContent, labelText, fontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPointRight, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
   } else {
      ObjectSetString(ChartID(), labelName, OBJPROP_TEXT, labelText);
   }
}

void createTableContentAccountLossRisk(const int pXCord) {

   string labelName = OBJECT_NAME_PREFIX + "_accountRisk";
   double percent = accountStruct.lossRisk / AccountInfoDouble(ACCOUNT_EQUITY) * 100;
   string labelText = (accountStruct.lossRisk >= SL_TP_MIN_VALUE) ? DoubleToString(accountStruct.lossRisk, 0) +  " € (" + DoubleToString(percent, 1) + " %)" : "SL setzen";
   color textColor = labelDefaultColor;
   if(percent > InpMaxAccountLossRiskLevel1Percent) textColor = CLR_LEVEL_1;
   if(percent > InpMaxAccountLossRikLevel2Percent) textColor = CLR_LEVEL_2;
   if(ObjectFind(ChartID(), labelName) < 0) {
      createLabel(labelName, pXCord, yCordAccountTableContent, labelText, fontSize, textColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPointRight, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
   } else {
      ObjectSetString(ChartID(), labelName, OBJPROP_TEXT, labelText);
   }
}

void createTableContentAccountReward(const int pXCord) {

   string labelName = OBJECT_NAME_PREFIX + "_accountReward";
   double percent = accountStruct.reward / AccountInfoDouble(ACCOUNT_EQUITY) * 100;
   string labelText = (accountStruct.reward >= SL_TP_MIN_VALUE) ? DoubleToString(accountStruct.reward, 0) +  " € (" + DoubleToString(percent, 1) + " %)" : "TP setzen";
   if(ObjectFind(ChartID(), labelName) < 0) {
      createLabel(labelName, pXCord, yCordAccountTableContent, labelText, fontSize, labelDefaultColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPointRight, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
   } else {
      ObjectSetString(ChartID(), labelName, OBJPROP_TEXT, labelText);
   }
}

void createTableContentAccountRRR(const int pXCord) {

   string labelName = OBJECT_NAME_PREFIX + "_accountRRR";
   double rrr = accountStruct.reward / accountStruct.lossRisk;
   string labelText;
   color textColor = labelDefaultColor;
   if(rrr < InpMinRRRLevel1) textColor = CLR_LEVEL_1;
   if(rrr < InpMinRRRLevel2) textColor = CLR_LEVEL_2;
   if(accountStruct.lossRisk >= SL_TP_MIN_VALUE && accountStruct.reward >= SL_TP_MIN_VALUE) {
      labelText = DoubleToString(rrr, 0);
   } else {
      labelText = "SL | TP";
   }
   if(ObjectFind(ChartID(), labelName) < 0) {
      createLabel(labelName, pXCord, yCordAccountTableContent, labelText, fontSize, textColor, labelFontFamily, labelAngle, labelBaseCorner, labelAnchorPointRight, labelIsInBackground, labelIsSelectable, labelIsSelected, labelIsHiddenInList, labelZOrder, labelChartID, labelSubWindow);
   } else {
      ObjectSetString(ChartID(), labelName, OBJPROP_TEXT, labelText);
   }
}
//+------------------------------------------------------------------+
