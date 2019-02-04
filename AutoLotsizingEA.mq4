//+------------------------------------------------------------------+
//|                                              AutoLotsizingEA.mq4 |
//|                                     Copyright 2013, JimDandy1958 |
//|                                         http://jimdandyforex.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, JimDandy1958"
#property link      "http://jimdandyforex.com"

extern int  PadAmount=0;
extern int  CandlesBack=5;
extern double  RiskPercent=1;
extern double reward_ratio=2;
extern int  FastMA=5;
extern int  SlowMA=21;
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
int start()
{
   if(IsNewCandle())CheckForMaTrade();
   return(0);
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
   
   if(direction==0)
   {
      double bsl=buy_stop_price;
      double btp=buy_takeprofit_price;
      //LotSize=(100/(0.00500/0.00010)/10;
      LotSize=(RiskedAmount/ (pips_to_bsl/pips) )/10;
      if(OpenOrdersThisPair(Symbol())==0)int buyticket = OrderSend(Symbol(),OP_BUY,LotSize,Ask,3,0,0,NULL,MagicNumber,0,Green);
      if(buyticket>0)OrderModify(buyticket,OrderOpenPrice(),bsl,btp,0,CLR_NONE);
   }
   
   if(direction==1)
   {
      double ssl=sell_stop_price;
      double stp=sell_takeprofit_price;
      LotSize=(RiskedAmount/(pips_to_ssl/pips))/10;
      if(OpenOrdersThisPair(Symbol())==0)int sellticket = OrderSend(Symbol(),OP_SELL,LotSize,Bid,3,0,0,NULL,MagicNumber,0,Red);
      if(sellticket>0)OrderModify(sellticket,OrderOpenPrice(),ssl,stp,0,CLR_NONE);
   }
   
}
//+------------------------------------------------------------------+


