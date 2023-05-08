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
int  xCordSymbolsTableSize = 250;
int  xCordSymbolsTableEntryPrice = 300;
int  xCordSymbolsTableCost = 410;
int  xCordSymbolsTablePnL = 550;
int  xCordSymbolsTableLossRisk = 640;
int  xCordSymbolsTableReward = 770;
int  xCordSymbolsTableRRR = 900;

int xCordAccountBalance = 20;
int xCordAccountEquity = 150;
int xCordAccountCost = 410;
int xCordAccountPnL = 550;
int xCordAccountLossRisk = 640;
int xCordAccountReward = 770;
int xCordAccountRRR = 900;

//color clrLevel1 = clrCoral;
//color clrLevel2 = clrCrimson;
