#property copyright "Copyright 2013, JimDandy1958"
#property link      "http://www.jimdandyforex.com"

extern int TakeProfit=500;
extern int StopLoss=150;
extern double LotSize = 0.01;

extern bool UseMoveToBreakeven=false;
extern int 	WhenToMoveToBE=100;
extern int  PipsToLockIn=5;
extern bool UseTrailingStop = false;
extern int  WhenToTrail=200;
extern int  TrailAmount=200;
extern bool UseCandleTrail=false;
extern int  PadAmount=10;
extern int  CandlesBack=5;
extern bool UsePercentStop=false;
extern double  RiskPercent=2;//in the video these were integers. I changed them to doubles so that you could use 0.5% risk if you wish.
extern bool UsePercentTakeProfit=false;
extern double  RewardPercent=4;
extern int  FastMA=5;
extern int  FastMaShift=0;
extern int  FastMaMethod=1;
extern int  FastMaAppliedTo=0;
extern int  SlowMA=21;
extern int  SlowMaShift=0;
extern int  SlowMaMethod=1;
extern int  SlowMaAppliedTo=0;

extern int  MagicNumber = 1234;
double      pips;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
   	double ticksize = MarketInfo(Symbol(), MODE_TICKSIZE);
   	if (ticksize == 0.00001 || ticksize == 0.001)
	   pips = ticksize*10;
	   else pips =ticksize;
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
  
  if(OpenOrdersThisPair(Symbol())>=1)
   {
      if(UseMoveToBreakeven)MoveToBreakeven();
      if(UseTrailingStop)AdjustTrailATR();
   }
   if(IsNewCandle())CheckForMaTrade();
//----
   return(0);
  }
//+------------------------------------------------------------------+
//Move to breakeven function
//+------------------------------------------------------------------+
void MoveToBreakeven()
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
//+------------------------------------------------------------------+
//trailing stop function
//+------------------------------------------------------------------+
void AdjustTrailATR()
{
// definisco il moltiplcatore dell' atr
int molt=2;
//  OTTENGO I VALORI DELL' ATR
double ATRval= iATR(Symbol(),0,20,0);
// METTO IL MOLTIPLICATORE DELL ATR IL TRAILING DEVE ESSERE A X ATR SOTTO L' ATTUALE PREZZO
double ATRtrail= molt*ATRval;

//buy order section
      for(int b=OrdersTotal()-1;b>=0;b--)
	      {
         if(OrderSelect(b,SELECT_BY_POS,MODE_TRADES))
           if(OrderMagicNumber()==MagicNumber)
              if(OrderSymbol()==Symbol())
                  if(OrderType()==OP_BUY)
                     if(Bid-OrderOpenPrice()>WhenToTrail*pips) 
                        if(OrderStopLoss()<Bid-pips*ATRtrail)
                           OrderModify(OrderTicket(),OrderOpenPrice(),Bid-(pips*ATRtrail),OrderTakeProfit(),0,Green);
         }
//sell order section
      for(int s=OrdersTotal()-1;s>=0;s--)
	      {
         if(OrderSelect(s,SELECT_BY_POS,MODE_TRADES))
            if(OrderMagicNumber()== MagicNumber)
               if(OrderSymbol()==Symbol())
                  if(OrderType()==OP_SELL)
                     if(OrderOpenPrice()-Ask>WhenToTrail*pips)
                        if(OrderStopLoss()>Ask+ATRtrail*pips)
                           OrderModify(OrderTicket(),OrderOpenPrice(),Ask+(pips*ATRtrail),OrderTakeProfit(),0,Green);
         }
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
//order entry function
//+------------------------------------------------------------------+
void OrderEntry(int direction)
{
   double Equity=AccountEquity();
   double RiskedAmount=Equity*RiskPercent*0.01;
   double RewardAmount=Equity*RewardPercent*0.01;
   Comment(RewardAmount);
   if(direction==0)
   {
      double bsl=0;
      double btp=0;
      if(StopLoss!=0)bsl=Ask-(StopLoss*pips);
      if(UsePercentStop)bsl=Ask-(RiskedAmount/(LotSize*10))*pips;
      if(TakeProfit!=0)btp=Ask+(TakeProfit*pips);
      if(UsePercentTakeProfit)btp=Ask+(RewardAmount/(LotSize*10))*pips;
      if(OpenOrdersThisPair(Symbol())==0)int buyticket = OrderSend(Symbol(),OP_BUY,LotSize,Ask,3,0,0,NULL,MagicNumber,0,Green);
      if(buyticket>0)OrderModify(buyticket,OrderOpenPrice(),bsl,btp,0,CLR_NONE);
   }
   
   if(direction==1)
   {
      double ssl=0;
      double stp=0;
      if(StopLoss!=0)ssl=Bid+(StopLoss*pips);
      if(UsePercentStop)ssl=Bid+(RiskedAmount/(LotSize*10))*pips;
      if(TakeProfit!=0)stp=Bid-(TakeProfit*pips);
      if(UsePercentTakeProfit)stp=Bid-(RewardAmount/(LotSize*10))*pips;
      if(OpenOrdersThisPair(Symbol())==0)int sellticket = OrderSend(Symbol(),OP_SELL,LotSize,Bid,3,0,0,NULL,MagicNumber,0,Red);
      if(sellticket>0)OrderModify(sellticket,OrderOpenPrice(),ssl,stp,0,CLR_NONE);
   }
   
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