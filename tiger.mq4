//+------------------------------------------------------------------+
//|                                                       tiger.mq4  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, zeshan tayyab malick, June 21st 2014"
#property link      "zmalick@hotmail.com"





extern double price_ma_period_fast =21; //slow ma
extern double price_ma_period_slow =89; //fast ma 

extern double LotFactor = 2; //lotsize factor
extern double StopLoss=50; //stop loss
extern double TakeProfit=100; //take profit
extern int MagicNumber=1234; //magi

extern double adxthreshold = 27; //adx threshold - must be greater than this to trade
extern double adxperiod = 14; //adx period
extern double rsiperiod = 14; //rsi period
extern double rsiupper = 65; //rsi upper bound, wont buy above this value
extern double rsilower = 35; //rsi lower bound, wont sell below this value

extern bool UseTrailingStop = true;
extern int  WhenToTrail =0;
extern int  TrailAmount=30;
extern double DrawdownPercent= 20;
extern double WhenToMoveToBE= 20;
extern double PipsToLockIn = 2;






double LotSize; //lotsize
double pips;
int cnt;
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {

{


double ticksize = MarketInfo(Symbol(), MODE_TICKSIZE);
   	if (ticksize == 0.00001 || ticksize == 0.001)
	   pips = ticksize*10;
	   else pips =ticksize;
	   
	   return(0);
	   
	   
	  

}
 

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

MaxDrawDown();

 {
if(IsNewCandle())
{
       Info();
       TrendDirection(); //find trend direction
       Logic(); //apply indicator logic
       Lot_Volume(); //calc lotsize
       CheckForTrade(); //trade - buy or sell
       MoveToBreakeven();
       
    if(UseTrailingStop)AdjustTrailATR();
    OrderClosing();
   }



  return(0);
  }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//insuring its a new candle function
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


bool IsNewCandle()
{
   static int BarsOnChart=0;
	if (Bars == BarsOnChart)
	return (false);
	BarsOnChart = Bars;
	return(true);
}
//+------------------------------------------------------------------+
//identifies the direction of the current trend
//+------------------------------------------------------------------+
bool TrendDirection()
{

//----
double CurrentFastMA,CurrentSlowMA;
CurrentFastMA = iMA(Symbol(),0,price_ma_period_fast,0,MODE_EMA,PRICE_CLOSE,0);
CurrentSlowMA = iMA(Symbol(),0,price_ma_period_slow,0,MODE_EMA,PRICE_CLOSE,0);

if (CurrentFastMA > CurrentSlowMA)// bullish
{
return(true);
}

if (CurrentFastMA < CurrentSlowMA)// bearish
{
return(false);
}

return(0);
}
//+------------------------------------------------------------------+
//applies logic from indicators ADX and RSI to determine if we can trade
//+------------------------------------------------------------------+


int Logic()
{
double adx,rsi;

adx = iADX(Symbol(),0,adxperiod,PRICE_CLOSE,MODE_MAIN,0);
rsi = iRSI(Symbol(),0,rsiperiod,PRICE_CLOSE,0);

if(adx > adxthreshold)
{
    if(rsi > rsilower && rsi < rsiupper)

return(1);
}
return(0);

}

//-----------------------------------------------------------------------//


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

//----------------------------------------------------------------------//



int CheckForTrade()
{
bool trenddirectionx, logicx;

trenddirectionx = TrendDirection();
logicx = Logic();


if(trenddirectionx == true && logicx == 1 )OrderEntry(0);
if(trenddirectionx == false && logicx == 1 )OrderEntry(1);

}

//-------------------------------------------------------------------//


void OrderEntry(int direction)
{
   if(direction==0)
   {
      double bsl=0;
      double btp=0;
      if(StopLoss!=0)bsl=Ask-(StopLoss*pips);
      if(TakeProfit!=0)btp=Ask+(TakeProfit*pips);
      if(OpenOrdersThisPair(Symbol())==0)int buyticket = OrderSend(Symbol(),OP_BUY,LotSize,Ask,3,0,0,NULL,MagicNumber,0,Green);
      if(buyticket>0)OrderModify(buyticket,OrderOpenPrice(),bsl,btp,0,CLR_NONE);
   }
   
   if(direction==1)
   {
      double ssl=0;
      double stp=0;
      if(StopLoss!=0)ssl=Bid+(StopLoss*pips);
      if(TakeProfit!=0)stp=Bid-(TakeProfit*pips);
      if(OpenOrdersThisPair(Symbol())==0)int sellticket = OrderSend(Symbol(),OP_SELL,LotSize,Bid,3,0,0,NULL,MagicNumber,0,Red);
      if(sellticket>0)OrderModify(sellticket,OrderOpenPrice(),ssl,stp,0,CLR_NONE);
   }
   
}

//-----------------------------------------------------------------------------------------------//
void AdjustTrailATR()
{
// definisco il moltiplcatore dell' atr
int molt=2;
//  OTTENGO I VALORI DELL' ATR
double ATRval= iATR(Symbol(),0,20,0);
// METTO IL MOLTIPLICATORE DELL ATR IL TRAILING DEVE ESSERE A X ATR SOTTO L' ATTUALE PREZZO
double ATRtrail= (molt*ATRval);
Comment(" il valore trailing è:"+ATRtrail);

//buy order section
      for(int b=OrdersTotal()-1;b>=0;b--)
	      {
         if(OrderSelect(b,SELECT_BY_POS,MODE_TRADES))
           if(OrderMagicNumber()==MagicNumber)
              if(OrderSymbol()==Symbol())
                  if(OrderType()==OP_BUY)
                     if(Bid-OrderOpenPrice()>WhenToTrail*pips) 
                        if(OrderStopLoss()<Bid-ATRtrail)
                           OrderModify(OrderTicket(),OrderOpenPrice(),Bid-ATRtrail,OrderTakeProfit(),0,Green);
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
                           OrderModify(OrderTicket(),OrderOpenPrice(),Ask+ATRtrail,OrderTakeProfit(),0,Green);
         }
}


double Lot_Volume()
{
double lot;

if (AccountBalance()>=50) lot=0.02;
if (AccountBalance()>=75) lot=0.03;
if (AccountBalance()>=100) lot=0.04;
if (AccountBalance()>=125) lot=0.05;
if (AccountBalance()>=150) lot=0.06;
if (AccountBalance()>=175) lot=0.07;
if (AccountBalance()>=200) lot=0.08;
if (AccountBalance()>=225) lot=0.09;
if (AccountBalance()>=250) lot=0.1;
if (AccountBalance()>=275) lot=0.11;
if (AccountBalance()>=300) lot=0.12;
if (AccountBalance()>=325) lot=0.13;
if (AccountBalance()>=350) lot=0.14;
if (AccountBalance()>=375) lot=0.15;
if (AccountBalance()>=400) lot=0.16;
if (AccountBalance()>=425) lot=0.17;
if (AccountBalance()>=450) lot=0.18;
if (AccountBalance()>=475) lot=0.19;
if (AccountBalance()>=500) lot=0.2;
if (AccountBalance()>=550) lot=0.24;
if (AccountBalance()>=600) lot=0.26;
if (AccountBalance()>=650) lot=0.28;
if (AccountBalance()>=700) lot=0.3;
if (AccountBalance()>=750) lot=0.32;
if (AccountBalance()>=800) lot=0.34;
if (AccountBalance()>=850) lot=0.36;
if (AccountBalance()>=900) lot=0.38;
if (AccountBalance()>=1000) lot=0.4;
if (AccountBalance()>=1500) lot=0.6;
if (AccountBalance()>=2000) lot=0.8;
if (AccountBalance()>=2500) lot=1.0;
if (AccountBalance()>=3000) lot=1.2;
if (AccountBalance()>=3500) lot=1.4;
if (AccountBalance()>=4000) lot=1.6;
if (AccountBalance()>=4500) lot=1.8;
if (AccountBalance()>=5000) lot=2.0;
if (AccountBalance()>=5500) lot=2.2;
if (AccountBalance()>=6000) lot=2.4;
if (AccountBalance()>=7000) lot=2.8;
if (AccountBalance()>=8000) lot=3.2;
if (AccountBalance()>=9000) lot=3.6;
if (AccountBalance()>=10000) lot=4.0;
if (AccountBalance()>=15000) lot=6.0;
if (AccountBalance()>=20000) lot=8.0;
if (AccountBalance()>=30000) lot=12;
if (AccountBalance()>=40000) lot=16;
if (AccountBalance()>=50000) lot=20;
if (AccountBalance()>=60000) lot=24;
if (AccountBalance()>=70000) lot=28;
if (AccountBalance()>=80000) lot=32;
if (AccountBalance()>=90000) lot=36;
if (AccountBalance()>=100000) lot=40;
if (AccountBalance()>=200000) lot=80;

LotSize=lot/LotFactor;
   return(LotSize);
}

bool MaxDrawDown()
{

 if((1-AccountEquity()/AccountBalance())*100>NormalizeDouble(DrawdownPercent,2))
 exitallorders();
 }



void exitallorders()
{

	for (int i=OrdersTotal()-1; i >=0; i--)
	{
		if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
		{
			if (OrderType() == OP_BUY && OrderMagicNumber()==MagicNumber)
			{
				while(true)//infinite loop must be escaped by break
				{
					bool result = OrderClose(OrderTicket(), OrderLots(), Bid, 3, Red);//actual order closing
					if (result != true)//if it did not close
					{
						int err = GetLastError(); Print("LastError = ",err);//get the reason why it didn't close
					}
					else {err = 0;break;}//if it did close it breaks out of while early DOES NOT RUN SWITCH
					switch(err)
					{
						case 129://INVALID_PRICE //if it was 129 it will run every line until it gets to the break.
						case 135://ERR_PRICE_CHANGED//same for 135
						case 136://ERR_OFF_QUOTES//and 136
						case 137://ERR_BROKER_BUSY//and 137
						case 138://ERR_REQUOTE//and 138
						case 146:Sleep(1000);RefreshRates();i++;break;//Sleeps,Refreshes and increments.Then breaks out of switch.
						// se non si chiude aspetta un secondo e riprova a chiuderlo
						default:break;//if the err does not match any of the above. It does not increment. and runs next order in series.
					}
					break;//after breaking out of switch it breaks out of while loop. which order it runs next depends on i++ or not.
				}
			}
		}
		
			if (OrderType() == OP_SELL && OrderMagicNumber()==MagicNumber)
			{
				while(true)//infinite loop must be escaped by break
				{
					result = OrderClose(OrderTicket(), OrderLots(), Ask, 3, Red);//actual order closing
					if (result != true)//if it did not close
					{
						err = GetLastError(); Print("LastError = ",err);//get the reason why it didn't close
					}
					else {err = 0;break;}//if it did close it breaks out of while early DOES NOT RUN SWITCH
					switch(err)
					{
						case 129://INVALID_PRICE //if it was 129 it will run every line until it gets to the break.
						case 135://ERR_PRICE_CHANGED//same for 135
						case 136://ERR_OFF_QUOTES//and 136
						case 137://ERR_BROKER_BUSY//and 137
						case 138://ERR_REQUOTE//and 138
						case 146:Sleep(1000);RefreshRates();i++;break;//Sleeps,Refreshes and increments.Then breaks out of switch.
						default:break;//if the err does not match any of the above. It does not increment. and runs next order in series.
					}
					break;//after breaking out of switch it breaks out of while loop. which order it runs next depends on i++ or not.
				}
			}
		}
		}
		
		
		void OrderClosing()
		{
		double CurrentFastMA,CurrentSlowMA,PreviousFastMA,PreviousSlowMA;
	CurrentFastMA = iMA(Symbol(),0,price_ma_period_fast,0,MODE_EMA,PRICE_CLOSE,0);
   CurrentSlowMA = iMA(Symbol(),0,price_ma_period_slow,0,MODE_EMA,PRICE_CLOSE,0);
   PreviousFastMA= iMA(Symbol(),0,price_ma_period_fast,0,MODE_EMA,PRICE_CLOSE,1);
   PreviousSlowMA= iMA(Symbol(),0,price_ma_period_slow,0,MODE_EMA,PRICE_CLOSE,1);
 		  for(cnt=0;cnt<OrdersTotal();cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderType()<=OP_SELL &&   // check for opened position 
         OrderSymbol()==Symbol())  // check for symbol
        {
         if(OrderType()==OP_BUY)   // long position is opened
           {
            // should it be closed?
             if(PreviousFastMA>PreviousSlowMA && CurrentFastMA<CurrentSlowMA)// segnale sell 
                {
                 OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet); // close position
                 return(0); // exit
                }
                }
                 else // go to short position
           {
            // should it be closed?
            if(PreviousFastMA<PreviousSlowMA && CurrentFastMA>CurrentSlowMA)// segnale buy
              {
               OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet); // close position
               return(0); // exit
              }
              }
              }
              }
              }
                
                
 void Info()
{
string AccountInfo,BrokerInfo,SwapLong,SwapShort;
AccountInfo= "il balance dell' Account è :" +AccountBalance();

BrokerInfo=  "il nome del broker è :" +AccountCompany();

SwapLong="l' interesse per posizioni long è :" +MarketInfo(Symbol(),MODE_SWAPLONG);

SwapShort="l' interesse per posizioni short è :" +MarketInfo(Symbol(),MODE_SWAPSHORT);


Comment(" Nome ExpertAdvisor= Tiger\n"
         +AccountInfo+ "\n"
         +BrokerInfo+ "\n"
         +SwapLong+ "\n"
         +SwapShort);

}