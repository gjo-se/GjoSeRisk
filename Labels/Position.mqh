//+------------------------------------------------------------------+
//|                                                      GjoSeRisk   |
//|                                      Copyright 2023, Gregory Jo  |
//|                                       http://www.gjo-se.com      |
//+------------------------------------------------------------------+

void createPositionStructForSymbolArray() {

   long    positionTicket = 0;
   long  positionTickets[];
   ulong magicNumber = 0;
   initializeArray(positionTickets);
   Positions.GetTickets(magicNumber, positionTickets);
   for(int positionTicketId = 0; positionTicketId < ArraySize(positionTickets); positionTicketId++) {
      positionTicket = positionTickets[positionTicketId];

      if(ArraySize(symbolArray) == 0) {
         ArrayResize(symbolArray, ArraySize(symbolArray) + 1);
         symbolArray[ArraySize(symbolArray) - 1] = buildPositionStructForSymbolArray(positionTicket);
      } else {
         bool symbolFound = false;
         for(int symbolId = 0; symbolId < ArraySize(symbolArray); symbolId++) {
            if(PositionSymbol(positionTicket) == symbolArray[symbolId].SymbolString) {

               double lastEntyrPriceVolume = symbolArray[symbolId].avgEntryPrice * symbolArray[symbolId].size;
               double currentEntyrPriceVolume = PositionOpenPrice(positionTicket) * PositionVolume(positionTicket);
               double currentSize = symbolArray[symbolId].size + PositionVolume(positionTicket);
               symbolArray[symbolId].avgEntryPrice = (lastEntyrPriceVolume + currentEntyrPriceVolume) / currentSize;

               symbolArray[symbolId].size += PositionVolume(positionTicket);
               symbolArray[symbolId].cost += PositionOpenPrice(positionTicket) * PositionVolume(positionTicket);
               symbolArray[symbolId].profit += PositionProfit(positionTicket);

               if(symbolArray[symbolId].lossRisk >= SL_TP_MIN_VALUE && PositionStopLoss(positionTicket) >= SL_TP_MIN_VALUE) {
                  symbolArray[symbolId].lossRisk += PositionVolume(positionTicket) * MathAbs(PositionOpenPrice(positionTicket) - PositionStopLoss(positionTicket));
               } else {
                  symbolArray[symbolId].lossRisk = SL_TP_MISSING;
               }

               if(symbolArray[symbolId].reward >= SL_TP_MIN_VALUE && PositionTakeProfit(positionTicket) >= SL_TP_MIN_VALUE) {
                  symbolArray[symbolId].reward += PositionVolume(positionTicket) * MathAbs(PositionTakeProfit(positionTicket) - PositionOpenPrice(positionTicket));
               } else {
                  symbolArray[symbolId].reward = SL_TP_MISSING;
               }

               if(symbolArray[symbolId].lossRisk != SL_TP_MISSING && symbolArray[symbolId].reward != SL_TP_MISSING) {
                  symbolArray[symbolId].rrr = symbolArray[symbolId].reward / symbolArray[symbolId].lossRisk;
               } else {
                  symbolArray[symbolId].rrr = SL_TP_MISSING;
               }

               symbolFound = true;

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
