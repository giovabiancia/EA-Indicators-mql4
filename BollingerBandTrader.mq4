//+------------------------------------------------------------------+
//|                                          BollingerBandTrader.mq4 |
//|                                     Copyright 2013, JimDandy1958 |
//|                                         http://jimdandyforex.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, JimDandy1958"
#property link      "http://jimdandyforex.com"

extern bool UseMoveToBreakeven=false;
extern int 	WhenToMoveToBE=10;
extern int  PipsToLockIn=5;
extern double reward_ratio=2;
extern bool UseTrailingStop = true;
extern int  WhenToTrail=0;
extern int  TrailAmount=10;
extern bool UseCandleTrail=true;
extern int  PadAmount=10;
extern int  CandlesBack=6;
extern double AdxPeriod=28;
extern double AdxSoglia=24;
extern bool UsePercentStop=false;
extern double  RiskPercent=10;//in the video these were integers. I changed them to doubles so that you could use 0.5% risk if you wish.
extern bool UsePercentTakeProfit=false;
extern double  RewardPercent=4;
extern double Rsi=14;
  
   extern double StopLoss=60;
   extern double TakeProfit=80;
   extern int BollingerPeriod=20;
   extern int BollingerDeviation=2;
   extern int  Fast_Macd_Ema=21;
   extern int  Slow_Macd_Ema=89;
   extern double Macd_Threshold=50;
   
   double pips;
   extern int MagicNumber=1234;
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
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//----
      if(UseMoveToBreakeven)MoveToBreakeven();
      if(UseTrailingStop)AdjustTrail();
      if(IsNewCandle())
      CheckForBollingerBandTrade();
//----
   return(0);
  }
//+------------------------------------------------------------------+

void CheckForBollingerBandTrade()
{
   
   double MiddleBB=iBands(NULL,0,BollingerPeriod,BollingerDeviation,0,0,MODE_MAIN,1);
   double LowerBB=iBands(NULL,0,BollingerPeriod,BollingerDeviation,0,0,MODE_LOWER,1);
	double UpperBB=iBands(NULL,0,BollingerPeriod,BollingerDeviation,0,0,MODE_UPPER,1);
   double PrevMiddleBB=iBands(NULL,0,BollingerPeriod,BollingerDeviation,0,0,MODE_MAIN,2);
   double PrevLowerBB=iBands(NULL,0,BollingerPeriod,BollingerDeviation,0,0,MODE_LOWER,2);
	double PrevUpperBB=iBands(NULL,0,BollingerPeriod,BollingerDeviation,0,0,MODE_UPPER,2);
	
   if(Close[1]>LowerBB&&Close[2]<PrevLowerBB)OrderEntry(1);
   if(Close[1]<UpperBB&&Close[2]>PrevUpperBB)OrderEntry(0);
}
//+------------------------------------------------------------------------------

//void OrderEntry(int direction)
//{
//   if(direction==0)
//   {
//      double tp=Ask+TakeProfit*pips;
//      double sl=Ask-StopLoss*pips;
 //     if(OpenOrdersThisPair(Symbol())==0)
  //    int buyticket = OrderSend(Symbol(),OP_BUY,LotSize,Ask,3,0,0,NULL,MagicNumber,0,Green);
    //  if(buyticket>0)OrderModify(buyticket,OrderOpenPrice(),sl,tp,0,CLR_NONE);
  // }
   
 //  if(direction==1)
  // {
   //   tp=Bid-TakeProfit*pips;
     // sl=Bid+StopLoss*pips;
   //   if(OpenOrdersThisPair(Symbol())==0)
   //   int sellticket = OrderSend(Symbol(),OP_SELL,LotSize,Bid,3,0,0,NULL,MagicNumber,0,Red);
 //     if(sellticket>0)OrderModify(sellticket,OrderOpenPrice(),sl,tp,0,CLR_NONE);
 //  }

//}
void OrderEntry(int direction)
{
   double LotSize=0;
   double Equity=AccountEquity();
   double RiskedAmount=Equity*RiskPercent*0.01;
    
   if(direction==1)
   {
         
      double slb=Ask-StopLoss*pips;
      double tpb=Ask+TakeProfit*pips;
      double diff = Ask - slb;
      printf("diff="+diff);
      
      //LotSize=(100/(0.00500/0.00010)/10;
      LotSize=(RiskedAmount/ (diff/pips) )/10;
      double Lotsize=NormalizeDouble(LotSize,2);
      printf("lotsize="+Lotsize);
      if(OpenOrdersThisPair(Symbol())==0)
      int buyticket = OrderSend(Symbol(),OP_BUY,Lotsize,Ask,0,slb,tpb,NULL,MagicNumber,0,Green);
      
   }
   
   if(direction==0)
   {
      double sls=Bid+StopLoss*pips;
      double tps=Bid- TakeProfit*pips;
      double diffs= sls-Bid;
      LotSize=(RiskedAmount/(diffs/pips))/10;
      double Lotsizes=NormalizeDouble(LotSize,2);
      if(OpenOrdersThisPair(Symbol())==0)
      int sellticket = OrderSend(Symbol(),OP_SELL,Lotsizes,Bid,0,sls,tps,NULL,MagicNumber,0,Red);
      
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
                        {  if(IsNewCandle())
                              if(OrderStopLoss()<Low[buyStopCandle]-PadAmount*pips)
                                 OrderModify(OrderTicket(),OrderOpenPrice(),Low[buyStopCandle]-PadAmount*pips,OrderTakeProfit(),0,CLR_NONE);
                        }
                     else  if(Bid-OrderOpenPrice()>WhenToTrail*pips) 
                              if(OrderStopLoss()<Bid-pips*TrailAmount)
                                 OrderModify(OrderTicket(),OrderOpenPrice(),Bid-(TrailAmount*pips),OrderTakeProfit(),0,CLR_NONE);
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
                                 OrderModify(OrderTicket(),OrderOpenPrice(),High[sellStopCandle]+PadAmount*pips,OrderTakeProfit(),0,CLR_NONE);
                       }
                    else   if(OrderOpenPrice()-Ask>WhenToTrail*pips)
                              if(OrderStopLoss()>Ask+TrailAmount*pips)
                                 OrderModify(OrderTicket(),OrderOpenPrice(),Ask+(TrailAmount*pips),OrderTakeProfit(),0,CLR_NONE);
         }
}
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