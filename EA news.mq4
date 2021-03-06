//+------------------------------------------------------------------+
//|                                                      Ea news.mq4 |
//|                              Copyright 2015,Giovanni Bianciardi. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//Questo ea prende il minimo e il massimo di n candele indietro e ci posiziona ordini limit
//gli stop loss sono posizionati sull'apertura dell' ordine opposto, trailing stop con candele 
//
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

extern bool Scaling= true;
extern int gap=20;
extern int StopLoss= 500;
extern int TakeProfit= 700;
extern int  WhenToTrail=30;
extern int  TrailAmount=60;
extern bool UseMoveToBreakEven= true;
extern bool UseCandleTrail=true;
extern int  PadAmount=4;
extern int  CandlesBack=4;
extern int WhenToMoveToBE= 40;
extern int PipsToLockIn=8;

extern double PartialClosePips = 50;
extern string Data_evento= "2019.1.30 20:00"; // anno/mese/giorno ora:minuuti
extern double lot= 0.1;
extern int MagicNumber= 1234;
double pips;


int init()
  {
   	double ticksize = MarketInfo(Symbol(), MODE_TICKSIZE);
   	if (ticksize == 0.00001 || ticksize == 0.001)
	   pips = ticksize*10;
	   else pips =ticksize;
	   return(0);
  }


void OnTick()
  {
  if(OpenOrderthisPair(Symbol())>=1)
   {
      if(UseMoveToBreakEven)MoveToBreakEven();
      if(UseCandleTrail)AdjustTrail();
      if(Scaling)ScalingStop();
      
   }
   if(IsNewCandle())Orario();
  }
 


bool IsNewCandle()
{
   static int BarsOnChart=0;
	if (Bars == BarsOnChart)
	return (false);
	BarsOnChart = Bars;
	return(true);
}


void Orario()
{ 
   //se l' orario dell' input coincide con quello attuale allora return un segnale
   datetime Data_ev; 
    
   Data_ev=StrToTime(Data_evento);      // returns the current date with the given time 
   
   if (Data_ev == TimeCurrent())
      OrderEntry(1);
   
    
}



void OrderEntry(int direction)
{

   int buyStopCandle= iHighest(NULL,0,2,CandlesBack,1); 
   int sellStopCandle=iLowest(NULL,0,1,CandlesBack,1);
   double buy_stop_price =High[buyStopCandle];
   double sell_stop_price=Low[sellStopCandle];
   
     if(direction==1)
     if (OpenOrderthisPair(Symbol())==0)
     OrderSend(Symbol(),OP_BUYSTOP,lot,buy_stop_price,3,sell_stop_price,Ask+(TakeProfit*pips),NULL,MagicNumber,TimeCurrent()+600*60,Green);
     OrderSend(Symbol(),OP_SELLSTOP,lot,sell_stop_price,3,buy_stop_price,Bid-(TakeProfit*pips),NULL,MagicNumber,TimeCurrent()+600*60,Red);
     

}

int OpenOrderthisPair(string pair)
{
int total=0;
for (int i= OrdersTotal()-1; i>=0 ; i--)
 {
 OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
 if(OrderSymbol()== pair) total++;
 }
 return (total);
 }

 
void AdjustTrail()
{
int buyStopCandle= iLowest(NULL,0,1,CandlesBack,1); 
int sellStopCandle=iHighest(NULL,0,2,CandlesBack,1); 


//buy order section
      for(int b=OrdersTotal()-1;b>=0;b--)
	      {
         if(OrderSelect(b,SELECT_BY_POS,MODE_TRADES))
           if(OrderMagicNumber()==MagicNumber)
              if(OrderSymbol()==Symbol())
                  if(OrderType()==OP_BUY)
                     if(UseCandleTrail)
                        {if(IsNewCandle())
                           if(OrderStopLoss()<Low[buyStopCandle]-PadAmount*pips)
                              if(!OrderModify(OrderTicket(),OrderOpenPrice(),Low[buyStopCandle]-PadAmount*pips,OrderTakeProfit(),0,CLR_NONE))
                                 Print("error modifying buy order ",GetLastError());

                        }
                     else  if(Bid-OrderOpenPrice()>WhenToTrail*pips) 
                              if(OrderStopLoss()<Bid-pips*TrailAmount)
                                 if(!OrderModify(OrderTicket(),OrderOpenPrice(),Bid-(TrailAmount*pips),OrderTakeProfit(),0,CLR_NONE))
                                   Print("error modifying buy order ",GetLastError());

         }
//sell order section
      for(int s=OrdersTotal()-1;s>=0;s--)
	      {
         if(OrderSelect(s,SELECT_BY_POS,MODE_TRADES))
            if(OrderMagicNumber()== MagicNumber)
               if(OrderSymbol()==Symbol())
                  if(OrderType()==OP_SELL)
                    if(UseCandleTrail)
                       {   if(IsNewCandle())
                              if(OrderStopLoss()>High[sellStopCandle]+PadAmount*pips)
                                 if(!OrderModify(OrderTicket(),OrderOpenPrice(),High[sellStopCandle]+PadAmount*pips,OrderTakeProfit(),0,CLR_NONE))
                                    Print("error modifying sell order ",GetLastError());
                       }
                    else   if(OrderOpenPrice()-Ask>WhenToTrail*pips)
                              if(OrderStopLoss()>Ask+TrailAmount*pips)
                                 if(!OrderModify(OrderTicket(),OrderOpenPrice(),Ask+(TrailAmount*pips),OrderTakeProfit(),0,CLR_NONE))
                                    Print("error modifying sell order ",GetLastError());
         }
}
void MoveToBreakEven()
 {
  for(int b=OrdersTotal()-1; b >= 0; b--)
	{
	if(OrderSelect(b,SELECT_BY_POS,MODE_TRADES))
      if(OrderMagicNumber()== MagicNumber)
         if(OrderSymbol()==Symbol())
            if(OrderType()==OP_BUY)
               if(Bid-OrderOpenPrice()>WhenToMoveToBE*pips)
                  if(OrderOpenPrice()>OrderStopLoss())
                     OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+(PipsToLockIn*pips),OrderTakeProfit(),0,CLR_NONE);
   }
   for (int s=OrdersTotal()-1; s >= 0; s--)
	     {
         if(OrderSelect(s,SELECT_BY_POS,MODE_TRADES))
	        if(OrderMagicNumber()== MagicNumber)
	           if(OrderSymbol()==Symbol())
	              if(OrderType()==OP_SELL)
                  if(OrderOpenPrice()-Ask>WhenToMoveToBE*pips)
                     if(OrderOpenPrice()<OrderStopLoss())    
                        OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-(PipsToLockIn*pips),OrderTakeProfit(),0,CLR_NONE);
        }
}


void ScalingStop()
{
if (OrdersTotal())
{
    if(!OrderSelect(0,SELECT_BY_POS,MODE_TRADES))
       Print("incapace di selezionare un ordine");
       double op= OrderOpenPrice();
       int type= OrderType();
       double lots= OrderLots();
       double SL= OrderStopLoss();
       int ticket= OrderTicket();
       if (lots == lot)
       {
         if (type== OP_BUY && Bid < SL+(PartialClosePips*pips))
            {
               if(!OrderModify(ticket,lot*2,Bid,30,clrRed))
                 Print("impossibile chiudere l' ordine");
            }
         else if( type == OP_SELL && Ask > SL-(PartialClosePips*pips))
             if(!OrderModify(ticket,lot*2,Ask,30,clrRed))
                 Print ("impossibile chiudere l' ordine");
        }
       
}
}