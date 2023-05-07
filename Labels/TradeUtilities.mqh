//+------------------------------------------------------------------+
//|                                                      GjoSeRisk   |
//|                                      Copyright 2023, Gregory Jo  |
//|                                       http://www.gjo-se.com      |
//+------------------------------------------------------------------+

struct PositionStruct {
   string            SymbolString;
   long              openTime;
   double            avgEntryPrice;
   double            size;
   double            cost;
   double            profit;
   double            lossRisk;
   double            reward;
   double            rrr;
};

PositionStruct buildPositionStructForSymbolArray(const long pPositionTicket) {

   positionStruct.SymbolString = PositionSymbol(pPositionTicket);
   positionStruct.openTime = PositionOpenTime(pPositionTicket);
   positionStruct.size = PositionVolume(pPositionTicket);
   positionStruct.avgEntryPrice = PositionOpenPrice(pPositionTicket);
   positionStruct.cost = PositionVolume(pPositionTicket) * PositionOpenPrice(pPositionTicket);
   positionStruct.profit = PositionProfit(pPositionTicket);

   if(PositionStopLoss(pPositionTicket) >= SL_TP_MIN_VALUE) {
      //double symbolPoints = SymbolInfoDouble(symbolArray[symbolId].SymbolString, SYMBOL_POINT);
      positionStruct.lossRisk = PositionVolume(pPositionTicket) * MathAbs(PositionOpenPrice(pPositionTicket) - PositionStopLoss(pPositionTicket));
   } else {
      positionStruct.lossRisk = SL_TP_MISSING;
   }

   if(PositionTakeProfit(pPositionTicket) >= SL_TP_MIN_VALUE) {
      positionStruct.reward = PositionVolume(pPositionTicket) * MathAbs(PositionTakeProfit(pPositionTicket) - PositionOpenPrice(pPositionTicket));
   } else {
      positionStruct.reward = SL_TP_MISSING;
   }

   if(positionStruct.lossRisk != SL_TP_MISSING && positionStruct.reward != SL_TP_MISSING) {
      positionStruct.rrr = positionStruct.reward / positionStruct.lossRisk;
   } else {
      positionStruct.rrr = SL_TP_MISSING;
   }

   return positionStruct;
}

//+------------------------------------------------------------------+
double getPointValueBySymbol(string pPositionSymbol) {
   return SymbolInfoDouble(pPositionSymbol, SYMBOL_TRADE_TICK_VALUE) / SymbolInfoDouble(pPositionSymbol, SYMBOL_TRADE_TICK_SIZE) * SymbolInfoDouble(pPositionSymbol, SYMBOL_POINT);
}
//+------------------------------------------------------------------+
