//+------------------------------------------------------------------+
//|                                                      GjoSeRisk   |
//|                                      Copyright 2023, Gregory Jo  |
//|                                       http://www.gjo-se.com      |
//+------------------------------------------------------------------+

CPositions      Positions;

struct AccountStruct {
   double            cost;
   double            profit;
   double            lossRisk;
   double            reward;
};
AccountStruct  accountStruct;

struct PositionStruct {
   string            SymbolString;
   int               count;
   long              openTime;
   double            avgEntryPrice;
   double            size;
   double            cost;
   double            profit;
   double            lossRisk;
   double            reward;
   double            rrr;
};
PositionStruct  positionStruct;
PositionStruct  symbolArray[];

bool isNewM1Bar = false;
int symbolsCount;
int subWindow = ChartWindowFind(0, MY_INDICATOR_SHORTNAME);
int   headLine2FontSize = 15;
int   fontSize = 10;
color labelDefaultColor = clrBlack;
string labelFontFamily = "Arial";
double labelAngle = 0;
ENUM_BASE_CORNER  labelBaseCorner = CORNER_LEFT_UPPER;
ENUM_ANCHOR_POINT labelAnchorPoint = ANCHOR_LEFT_UPPER;
ENUM_ANCHOR_POINT labelAnchorPointRight = ANCHOR_RIGHT_UPPER;
bool labelIsInBackground = false;
bool labelIsSelectable = false;
bool labelIsSelected = false;
bool labelIsHiddenInList = false;
long labelZOrder = 2;
long labelChartID = 0;
int  labelSubWindow = subWindow;
int  rowHigh = 22;
int  yCordAccountTableHeadline = 50;
int  yCordAccountTableContent = 90;
int  yCordSymbolsTableHeadline = 150;

int  xCordSymbolsTableSymbol = 20;
int  xCordSymbolsTableHoldTime = 150;
int  xCordSymbolsTableHoldTimeContent = 190;
int  xCordSymbolsTableSize = 230;
int  xCordSymbolsTableSizeContent = 265;
int  xCordSymbolsTableEntryPrice = 300;
int  xCordSymbolsTableEntryPriceContent = 350;
int  xCordSymbolsTableCost = 410;
int  xCordSymbolsTableCostContent = 500;
int  xCordSymbolsTablePnL = 530;
int  xCordSymbolsTablePnLContent = 610;
int  xCordSymbolsTableLossRisk = 640;
int  xCordSymbolsTableLossRiskContent = 750;
int  xCordSymbolsTableReward = 770;
int  xCordSymbolsTableRewardContent = 870;
int  xCordSymbolsTableRRR = 920;
int  xCordSymbolsTableRRRContent = 950;

int xCordAccountBalance = 20;
int xCordAccountEquity = 150;
int xCordAccountCost = 410;
int xCordAccountCostContent = 500;
int xCordAccountPnL = 530;
int xCordAccountPnLContent = 610;
int xCordAccountLossRisk = 640;
int xCordAccountLossRiskContent = 750;
int xCordAccountReward = 770;
int xCordAccountRewardContent = 870;
int xCordAccountRRR = 920;
int xCordAccountRRRContent = 950;
//+------------------------------------------------------------------+
