//+------------------------------------------------------------------+
//|                                              AutoLotsizingEA.mq4 |
//|                                     Copyright 2013, JimDandy1958 |
//|                                         http://jimdandyforex.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, JimDandy1958"
#property link      "http://jimdandyforex.com"

extern bool UseMoveToBreakeven=true;
extern int 	WhenToMoveToBE=100;
extern int  PipsToLockIn=5;
extern int  WhenToTrail=10;
extern int  TrailAmount=200;
extern bool UseCandleTrail=true;
extern int  PadAmount=10;
extern int  CandlesBack=10;
extern double  RiskPercent=1;
extern double reward_ratio=2;
extern int MaximumStopDistance=50;
extern int  FastMA=21;
extern int  SlowMA=89;
extern int  PercentK=5;
extern int  PercentD=3;
extern int  Slowing=3;
extern int  MagicNumber = 1234;
int  FastMaShift=0;
int  FastMaMethod=1;
int  FastMaAppliedTo=0;
int  SlowMaShift=0;
int  SlowMaMethod=1;
int  SlowMaAppliedTo=0;
double pips;

//+------------------------------------------------------------------+
int init()
  {
   double ticksize = MarketInfo(Symbol(), MODE_TICKSIZE);
   	if (ticksize == 0.00001 || ticksize == 0.001)
	   pips = ticksize*10;
	   else pips =ticksize;
   return(0);
  }

//+------------------------------------------------------------------+
int deinit()
  {
   return(0);
  }

//+------------------------------------------------------------------+
void OnTick()
{
   //if(IsNewCandle())CheckForMaTrade();
   
   if(OpenOrdersThisPair(Symbol())>=1)
   {
      if(UseMoveToBreakeven)MoveToBreakeven();
      if(UseCandleTrail)AdjustTrail();
   }
   if(IsNewCandle())CheckForStochasticTrade();
   
}

//+------------------------------------------------------------------+
//checks to see if any orders open on this currency pair.
//+------------------------------------------------------------------+
int OpenOrdersThisPair(string pair)
{
  int total=0;
   for(int i=OrdersTotal()-1; i >= 0; i--)
	  {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()== pair) total++;
	  }
	  return (total);
}

//+------------------------------------------------------------------+
//insuring its a new candle function
//+------------------------------------------------------------------+
bool IsNewCandle()
{
   static int BarsOnChart=0;
	if (Bars == BarsOnChart)
	return (false);
	BarsOnChart = Bars;
	return(true);
}
//+------------------------------------------------------------------+
//function that checks or an Ma cross
//+------------------------------------------------------------------+
void CheckForMaTrade()
{
double PreviousFast = iMA(NULL,0,FastMA,FastMaShift,FastMaMethod,FastMaAppliedTo,2); 
double CurrentFast = iMA(NULL,0,FastMA,FastMaShift,FastMaMethod,FastMaAppliedTo,1); 
double PreviousSlow= iMA(NULL,0,SlowMA,SlowMaShift,SlowMaMethod,SlowMaAppliedTo,2); 
double CurrentSlow = iMA(NULL,0,SlowMA,SlowMaShift,SlowMaMethod,SlowMaAppliedTo,1); 
if(PreviousFast<PreviousSlow && CurrentFast>CurrentSlow)OrderEntry(0);
if(PreviousFast>PreviousSlow && CurrentFast<CurrentSlow)OrderEntry(1);
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//order entry function
//+------------------------------------------------------------------+
void OrderEntry(int direction)
{
   double LotSize=0;
   double Equity=AccountEquity();
   double RiskedAmount=Equity*RiskPercent*0.01;
   int buyStopCandle= iLowest(NULL,0,1,CandlesBack,1); 
   int sellStopCandle=iHighest(NULL,0,2,CandlesBack,1); 
   double buy_stop_price =Low[buyStopCandle]-PadAmount*pips;
   double pips_to_bsl=Ask-buy_stop_price;
   double buy_takeprofit_price=Ask+pips_to_bsl*reward_ratio;
   double sell_stop_price=High[sellStopCandle]+PadAmount*pips;
   double pips_to_ssl=sell_stop_price-Bid;
   double sell_takeprofit_price=Bid-pips_to_ssl*reward_ratio;
   
   if(direction==0 && pips_to_bsl/pips<MaximumStopDistance)
   {
      double bsl=buy_stop_price;
      double btp=buy_takeprofit_price;
      //LotSize=(100/(0.00500/0.00010)/10;
      LotSize=(RiskedAmount/ (pips_to_bsl/pips) )/10;
      if(OpenOrdersThisPair(Symbol())==0)int buyticket = OrderSend(Symbol(),OP_BUY,LotSize,Ask,3,0,0,NULL,MagicNumber,0,Green);
      if(buyticket>0)OrderModify(buyticket,OrderOpenPrice(),bsl,NULL,0,CLR_NONE);
   }
   
   if(direction==1 && pips_to_ssl/pips<MaximumStopDistance)
   {
      double ssl=sell_stop_price;
      double stp=sell_takeprofit_price;
      LotSize=(RiskedAmount/(pips_to_ssl/pips))/10;
      if(OpenOrdersThisPair(Symbol())==0)int sellticket = OrderSend(Symbol(),OP_SELL,LotSize,Bid,3,0,0,NULL,MagicNumber,0,Red);
      if(sellticket>0)OrderModify(sellticket,OrderOpenPrice(),ssl,NULL,0,CLR_NONE);
   }
   
}

void CheckForStochasticTrade()
{
   double CurrentFast = iMA(NULL,0,FastMA,FastMaShift,FastMaMethod,FastMaAppliedTo,1); 
   double CurrentSlow = iMA(NULL,0,SlowMA,SlowMaShift,SlowMaMethod,SlowMaAppliedTo,1); 
   double K_Line=iStochastic(NULL,0,PercentK,PercentD,Slowing,0,0,MODE_MAIN,1);
   double D_Line=iStochastic(NULL,0,PercentK,PercentD,Slowing,0,0,MODE_SIGNAL,1);
   double Previous_K_Line=iStochastic(NULL,0,PercentK,PercentD,Slowing,0,0,MODE_MAIN,2);
   double Previous_D_Line=iStochastic(NULL,0,PercentK,PercentD,Slowing,0,0,MODE_SIGNAL,2);
   if(CurrentFast<CurrentSlow)
      if(Previous_K_Line > 80)
         if(Previous_K_Line > Previous_D_Line && K_Line < D_Line)
            OrderEntry(1);
   if(CurrentFast>CurrentSlow)
      if(Previous_K_Line < 20)
         if(Previous_K_Line < Previous_D_Line && K_Line > D_Line)
            OrderEntry(0);
}

//+------------------------------------------------------------------+
int CalculateCurrentOrders(string symbol)
  {
   int buys=0,sells=0;
//----
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      // SE NON CI SONO ORDINI FERMA.
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber)
      // SE CI SONO ORDINI E IL MAGICNUMBER è QUELLO DEL MIO EA ALLORA
        {
         if(OrderType()==OP_BUY)  buys++;
         if(OrderType()==OP_SELL) sells++;
        }
     }
//---- return orders volume
   if(buys>0) return(buys);
   if(sells>0) return(sells);
   Comment( "il numero di posizioni long è "+buys+" il numero di posizioni short è "+sells);
  }
  
 
void MoveToBreakeven()
{
   for(int b=OrdersTotal()-1; b >= 0; b--)
	{
	if(OrderSelect(b,SELECT_BY_POS,MODE_TRADES))
       if(OrderSymbol()==Symbol())
            if(OrderType()==OP_BUY)
               if(Bid-OrderOpenPrice()>WhenToMoveToBE*pips)
                  if(OrderOpenPrice()>OrderStopLoss())
                     if(!OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+(PipsToLockIn*pips),OrderTakeProfit(),0,CLR_NONE))
                        Print("error modifying buy order ",GetLastError());
   }
   for (int s=OrdersTotal()-1; s >= 0; s--)
	     {
         if(OrderSelect(s,SELECT_BY_POS,MODE_TRADES))
	         if(OrderSymbol()==Symbol())
	              if(OrderType()==OP_SELL)
                  if(OrderOpenPrice()-Ask>WhenToMoveToBE*pips)
                     if(OrderOpenPrice()<OrderStopLoss())    
                        if(!OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-(PipsToLockIn*pips),OrderTakeProfit(),0,CLR_NONE))
                           Print("error modifying sell order ",GetLastError());
        }
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