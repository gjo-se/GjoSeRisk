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

               double lastEntyrPriceVolume = symbolArray[symbolId].avgEntryPrice * symbolArray[symbolId].size;
               double currentEntyrPriceVolume = PositionOpenPrice(positionTicket) * PositionVolume(positionTicket);
               double currentSize = symbolArray[symbolId].size + PositionVolume(positionTicket);
               symbolArray[symbolId].avgEntryPrice = (lastEntyrPriceVolume + currentEntyrPriceVolume) / currentSize;

               symbolArray[symbolId].size += PositionVolume(positionTicket);

               double cost = PositionOpenPrice(positionTicket) * PositionVolume(positionTicket);
               symbolArray[symbolId].cost += cost;
               accountStruct.cost += cost;
               symbolArray[symbolId].profit += PositionProfit(positionTicket);
               accountStruct.profit += PositionProfit(positionTicket);

               if(symbolArray[symbolId].lossRisk >= SL_TP_MIN_VALUE && PositionStopLoss(positionTicket) >= SL_TP_MIN_VALUE) {
                  double lossRisk = PositionVolume(positionTicket) * MathAbs(PositionOpenPrice(positionTicket) - PositionStopLoss(positionTicket));
                  symbolArray[symbolId].lossRisk += lossRisk;
                  accountStruct.lossRisk += lossRisk;
               } else {
                  symbolArray[symbolId].lossRisk = SL_TP_MISSING;
                  accountStruct.lossRisk = SL_TP_MISSING;
               }

               if(symbolArray[symbolId].reward >= SL_TP_MIN_VALUE && PositionTakeProfit(positionTicket) >= SL_TP_MIN_VALUE) {
                  double reward = PositionVolume(positionTicket) * MathAbs(PositionTakeProfit(positionTicket) - PositionOpenPrice(positionTicket));
                  symbolArray[symbolId].reward += reward;
                  accountStruct.reward += reward;
               } else {
                  symbolArray[symbolId].reward = SL_TP_MISSING;
                  accountStruct.reward = SL_TP_MISSING;
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
   positionStruct.openTime = PositionOpenTime(pPositionTicket);
   positionStruct.size = PositionVolume(pPositionTicket);
   positionStruct.avgEntryPrice = PositionOpenPrice(pPositionTicket);
   accountStruct.cost += positionStruct.cost = PositionVolume(pPositionTicket) * PositionOpenPrice(pPositionTicket);
   accountStruct.profit += positionStruct.profit = PositionProfit(pPositionTicket);

   if(PositionStopLoss(pPositionTicket) >= SL_TP_MIN_VALUE) {
      //double symbolPoints = SymbolInfoDouble(symbolArray[symbolId].SymbolString, SYMBOL_POINT);
      double lossRisk = PositionVolume(pPositionTicket) * MathAbs(PositionOpenPrice(pPositionTicket) - PositionStopLoss(pPositionTicket));
      positionStruct.lossRisk = lossRisk;
      accountStruct.lossRisk += lossRisk;
   } else {
      positionStruct.lossRisk = SL_TP_MISSING;
      accountStruct.lossRisk = SL_TP_MISSING;
   }

   if(PositionTakeProfit(pPositionTicket) >= SL_TP_MIN_VALUE) {
      double reward = PositionVolume(pPositionTicket) * MathAbs(PositionTakeProfit(pPositionTicket) - PositionOpenPrice(pPositionTicket));
      positionStruct.reward = reward;
      accountStruct.reward += reward;
   } else {
      positionStruct.reward = SL_TP_MISSING;
      accountStruct.reward = SL_TP_MISSING;
   }

   if(positionStruct.lossRisk != SL_TP_MISSING && positionStruct.reward != SL_TP_MISSING) {
      positionStruct.rrr = positionStruct.reward / positionStruct.lossRisk;
   } else {
      positionStruct.rrr = SL_TP_MISSING;
   }

   return positionStruct;
}
