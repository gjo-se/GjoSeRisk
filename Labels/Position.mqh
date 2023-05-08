//+------------------------------------------------------------------+
//|                                                      GjoSeRisk   |
//|                                      Copyright 2023, Gregory Jo  |
//|                                       http://www.gjo-se.com      |
//+------------------------------------------------------------------+

void createPositionStructForSymbolArray() {

   long  positionTicket = 0;
   long  positionTickets[];
   ulong magicNumber = 0;
   initializeArray(positionTickets);
   Positions.GetTickets(magicNumber, positionTickets);
   for(int positionTicketId = 0; positionTicketId < ArraySize(positionTickets); positionTicketId++) {
      positionTicket = positionTickets[positionTicketId];

      if(ArraySize(symbolArray) == 0) {
         ArrayResize(symbolArray, ArraySize(symbolArray) + 1);
         accountStruct.cost = 0;
         accountStruct.profit = 0;
         accountStruct.lossRisk = 0;
         accountStruct.reward = 0;
         symbolArray[ArraySize(symbolArray) - 1] = buildPositionStructForSymbolArray(positionTicket);
      } else {
         bool symbolFound = false;
         for(int symbolId = 0; symbolId < ArraySize(symbolArray); symbolId++) {
            if(PositionSymbol(positionTicket) == symbolArray[symbolId].SymbolString) {

               symbolFound = true;

               symbolArray[symbolId].count += 1;
               double lastEntyrPriceVolume = symbolArray[symbolId].avgEntryPrice * symbolArray[symbolId].size;
               double currentEntyrPriceVolume = PositionOpenPrice(positionTicket) * PositionVolume(positionTicket);
               double currentSize = symbolArray[symbolId].size + PositionVolume(positionTicket);
               symbolArray[symbolId].avgEntryPrice = (lastEntyrPriceVolume + currentEntyrPriceVolume) / currentSize;

               symbolArray[symbolId].size += PositionVolume(positionTicket);
               double symbolPoints = SymbolInfoDouble(symbolArray[symbolId].SymbolString, SYMBOL_POINT);

               double cost = PositionVolume(positionTicket) * PositionOpenPrice(positionTicket) / symbolPoints * getPointValueBySymbol(symbolArray[symbolId].SymbolString);
               symbolArray[symbolId].cost += cost;
               accountStruct.cost += cost;

               double profit = MathAbs(PositionOpenPrice(positionTicket) - Bid(symbolArray[symbolId].SymbolString)) / symbolPoints * getPointValueBySymbol(symbolArray[symbolId].SymbolString);
               symbolArray[symbolId].profit += profit;
               accountStruct.profit += profit;

               if(symbolArray[symbolId].lossRisk >= SL_TP_MIN_VALUE && PositionStopLoss(positionTicket) >= SL_TP_MIN_VALUE) {
                  double lossRisk = MathAbs(PositionOpenPrice(positionTicket) - PositionStopLoss(positionTicket)) / symbolPoints * getPointValueBySymbol(symbolArray[symbolId].SymbolString) * PositionVolume(positionTicket);
                  symbolArray[symbolId].lossRisk += lossRisk;
                  accountStruct.lossRisk += lossRisk;
               } else {
                  symbolArray[symbolId].lossRisk = SL_TP_MISSING;
               }

               if(symbolArray[symbolId].reward >= SL_TP_MIN_VALUE && PositionTakeProfit(positionTicket) >= SL_TP_MIN_VALUE) {
                  double reward = MathAbs(PositionOpenPrice(positionTicket) - PositionTakeProfit(positionTicket)) / symbolPoints * getPointValueBySymbol(symbolArray[symbolId].SymbolString) * PositionVolume(positionTicket);
                  symbolArray[symbolId].reward += reward;
                  accountStruct.reward += reward;
               } else {
                  symbolArray[symbolId].reward = SL_TP_MISSING;
               }

               if(symbolArray[symbolId].lossRisk != SL_TP_MISSING && symbolArray[symbolId].reward != SL_TP_MISSING) {
                  symbolArray[symbolId].rrr = symbolArray[symbolId].reward / symbolArray[symbolId].lossRisk;
               } else {
                  symbolArray[symbolId].rrr = SL_TP_MISSING;
               }
            }
         }

         if(symbolFound == false) {
            ArrayResize(symbolArray, ArraySize(symbolArray) + 1);
            symbolArray[ArraySize(symbolArray) - 1] = buildPositionStructForSymbolArray(positionTicket);
         }

      }
   }
}
//+------------------------------------------------------------------+

PositionStruct buildPositionStructForSymbolArray(const long pPositionTicket) {

   positionStruct.SymbolString = PositionSymbol(pPositionTicket);
   positionStruct.count = 1;
   positionStruct.openTime = PositionOpenTime(pPositionTicket);
   positionStruct.size = PositionVolume(pPositionTicket);
   positionStruct.avgEntryPrice = PositionOpenPrice(pPositionTicket);

   double symbolPoints = SymbolInfoDouble(positionStruct.SymbolString, SYMBOL_POINT);
   double cost = PositionVolume(pPositionTicket) * PositionOpenPrice(pPositionTicket) / symbolPoints * getPointValueBySymbol(positionStruct.SymbolString);
   positionStruct.cost = cost;
   accountStruct.cost += cost;

   double profit = MathAbs(PositionOpenPrice(pPositionTicket) - Bid(positionStruct.SymbolString)) / symbolPoints * getPointValueBySymbol(positionStruct.SymbolString);
   positionStruct.profit = profit;
   accountStruct.profit += profit;

   if(PositionStopLoss(pPositionTicket) >= SL_TP_MIN_VALUE) {
      double lossRisk = MathAbs(PositionOpenPrice(pPositionTicket) - PositionStopLoss(pPositionTicket)) / symbolPoints * getPointValueBySymbol(positionStruct.SymbolString) * PositionVolume(pPositionTicket);
      positionStruct.lossRisk = lossRisk;
      accountStruct.lossRisk += lossRisk;
   } else {
      positionStruct.lossRisk = SL_TP_MISSING;
   }

   if(PositionTakeProfit(pPositionTicket) >= SL_TP_MIN_VALUE) {
      double reward = MathAbs(PositionOpenPrice(pPositionTicket) - PositionTakeProfit(pPositionTicket)) / symbolPoints * getPointValueBySymbol(positionStruct.SymbolString) * PositionVolume(pPositionTicket);
      positionStruct.reward = reward;
      accountStruct.reward += reward;
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
