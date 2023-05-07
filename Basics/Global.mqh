//+------------------------------------------------------------------+
//|                                                      GjoSeRisk   |
//|                                      Copyright 2023, Gregory Jo  |
//|                                       http://www.gjo-se.com      |
//+------------------------------------------------------------------+

CPositions      Positions;
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
int  yCordSymbolsTableHeadline = 50;

int  xCordSymbolsTableSymbol = 20;
int  xCordSymbolsTableHoldTime = 150;
int  xCordSymbolsTableSize = 250;
int  xCordSymbolsTableEntryPrice = 300;
int  xCordSymbolsTableCost = 410;
int  xCordSymbolsTablePnL = 550;
int  xCordSymbolsTableLossRisk = 640;
int  xCordSymbolsTableReward = 770;
int  xCordSymbolsTableRRR = 900;

//color clrLevel1 = clrCoral;
//color clrLevel2 = clrCrimson;
