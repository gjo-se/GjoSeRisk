//+------------------------------------------------------------------+
//|                                                      GjoSeRisk   |
//|                                      Copyright 2023, Gregory Jo  |
//|                                       http://www.gjo-se.com      |
//+------------------------------------------------------------------+

sinput string              Basics;    // ---------- Basics ---------
input double InpMaxSymbolCostLevel1Percent = 35; // Max Symbol-Cost % Equity Level 1
input double InpMaxSymbolCostLevel2Percent = 50; // Max Symbol-Cost % Equity Level 2
input double InpMaxAccountLeverageLevel1 = 5; // Max Account Leverage Level 1
input double InpMaxAccountLeverageLevel2 = 7.5; // Max Account Leverage Level 2

input double InpMaxSymboLossRiskLevel1Percent = 1.75; // Max Symbol-LossRisk % Equity Level 1
input double InpMaxSymbolLossRiskLevel2Percent = 2.5; // Max Symbol-LossRisk % Equity Level 2
input double InpMaxAccountLossRiskLevel1Percent = 17.5; // Max Account-LossRisk % Equity Level 1
input double InpMaxAccountLossRikLevel2Percent = 25; // Max Account-LossRisk % Equity Level 2

input double InpMinRRRLevel1 = 5; // MIN RRR Level 1
input double InpMinRRRLevel2 = 3; // MIN RRR Level 2

//+------------------------------------------------------------------+
