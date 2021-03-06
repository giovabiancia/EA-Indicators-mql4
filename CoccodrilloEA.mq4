#property show_inputs;
extern int TakeProfit= 400;
extern int StopLoss= 100;
extern double PartialClosePips = 50;
extern int JawPeriod=13;      
extern int JawShift=8;        
extern int TeethPeriod=8;     
extern int TeethShift=5;      
extern int LipsPeriod=5;      
extern int LipsShift=3;       
extern bool UseMoveToBreakEven= true;
extern int WhenToMoveToBE= 40;
extern bool UseCandleTrail=true;
extern int  PadAmount=4;
extern int  TrailAmount=60;
extern int  CandlesBack=10;
extern int PipsToLockIn=5;
extern int WhenToTrail = 25;
extern int TrailAmonunt=10;

extern double  RiskPercent=1;
extern double reward_ratio=2;
datetime  triggerBarTime=0;


extern int FastMA= 10;
extern int FastMaMethod=0;
extern int FastMaShift=0;
extern int FastMaAppliedto=0;
extern bool Scaling_in= true;

extern int SlowMA= 50;
extern int SlowMaMethod=0;
extern int SlowMaShift=0;
extern int SlowMaAppliedto=0;

extern double Lotsize= 0.10;
extern int MagicNumber= 1234;
double pips;



int init()

 {
double ticksize= MarketInfo(Symbol(),MODE_TICKSIZE);
if ( ticksize== 0.00001 || ticksize== 0.001)
pips= ticksize*10;
else pips= ticksize;
return(0);
 } 
 
void OnTick()
  {
  if(OpenOrderthisPair(Symbol())>=1)
   {
      if(UseMoveToBreakEven)MoveToBreakEven();
      if(UseCandleTrail)TrailCandle();
      if(Scaling_in)ScalingStop();
   }
   if(IsNewCandle())CheckAlligatorTrade();
   
  }
 
void DeleteOrder()
  {
  
   for( int i= OrdersTotal()- 1; i >=0 ; i--)
   {
      if( !OrderSelect(i,SELECT_BY_POS, MODE_TRADES)) continue;
       if(OrderMagicNumber() == MagicNumber&&OrderSymbol()== Symbol()&&OrderType()>OP_SELL)
           if(!OrderDelete(OrderTicket(),CLR_NONE))
            Print("Order Close failed, order number: ",OrderTicket(),"Error: ", GetLastError());
    }
    
    }


void CheckAlligatorTrade()
{

double JawCurr;
double TeethCurr;
double LipsCurr;
double JawPrev;
double TeethPrev;
double LipsPrev;
double FractalSopra;
double FractalSotto;

bool AlligatorTrendDown=false;
bool AlligatorTrendUp=false;
JawCurr=iAlligator(Symbol(),0,JawPeriod,JawShift,TeethPeriod,TeethShift,LipsPeriod,LipsShift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORJAW,0);
TeethCurr=iAlligator(Symbol(),0,JawPeriod,JawShift,TeethPeriod,TeethShift,LipsPeriod,LipsShift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORTEETH,0);
LipsCurr=iAlligator(Symbol(),0,JawPeriod,JawShift,TeethPeriod,TeethShift,LipsPeriod,LipsShift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORLIPS,0);
JawPrev=iAlligator(Symbol(),0,JawPeriod,JawShift,TeethPeriod,TeethShift,LipsPeriod,LipsShift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORJAW,1);
TeethPrev=iAlligator(Symbol(),0,JawPeriod,JawShift,TeethPeriod,TeethShift,LipsPeriod,LipsShift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORTEETH,1);
LipsPrev=iAlligator(Symbol(),0,JawPeriod,JawShift,TeethPeriod,TeethShift,LipsPeriod,LipsShift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORLIPS,1);
FractalSopra= iFractals(Symbol(),0,MODE_UPPER,5);
FractalSotto= iFractals(Symbol(),0,MODE_LOWER,5);


Print("il valore del Fractal è:"+FractalSopra);
Print("il valore del Fractal è:"+FractalSotto);
   
   if(JawCurr<TeethCurr && TeethCurr<LipsCurr && JawCurr>JawPrev && TeethCurr>TeethPrev && LipsCurr>LipsPrev && FractalSopra>TeethCurr && FractalSopra != 0 && Ask>TeethCurr){
    OrderEntry(0);
    }
   
   
   
   if(JawCurr>TeethCurr && TeethCurr>LipsCurr && JawCurr<JawPrev && TeethCurr<TeethPrev && LipsCurr<LipsPrev && FractalSotto<TeethCurr && FractalSotto != 0 && Bid<TeethCurr){ 
   OrderEntry(1);
    }
   
      
       
   
   }
 
void OrderEntry(int direction)
 {
double FractalSopra;
double FractalSotto;
double Pending_Buy;
double Pending_Sell;
FractalSopra= iFractals(Symbol(),0,MODE_UPPER,5);
Pending_Sell= Close[1] - 30*pips;
FractalSotto= iFractals(Symbol(),0,MODE_LOWER,5);
Pending_Buy= Close[1] + 30*pips;


 if(direction==0)
  if (OpenOrderthisPair(Symbol())==0)
    OrderSend(Symbol(),OP_BUYSTOP,Lotsize,Pending_Buy,3,Ask-(StopLoss*pips),Ask+(TakeProfit*pips),NULL,MagicNumber,TimeCurrent()+600*60,Green);
       
    
    
 if(direction==1)
   if (OpenOrderthisPair(Symbol())==0)
    OrderSend(Symbol(),OP_SELLSTOP,Lotsize,Pending_Sell,3,Bid+(StopLoss*pips),Bid-(TakeProfit*pips),NULL,MagicNumber,TimeCurrent()+600*60,Red);
      

} 

/*void OrderEntry(int direction)
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
      int buyticket;
      //LotSize=(100/(0.00500/0.00010)/10;
      LotSize=(RiskedAmount/ (pips_to_bsl/pips) )/10;
      if(OpenOrderthisPair(Symbol())==0)
      buyticket = OrderSend(Symbol(),OP_BUY,LotSize,Ask,3,0,0,NULL,MagicNumber,0,Green);
      if(buyticket>0)OrderModify(buyticket,OrderOpenPrice(),bsl,btp,0,CLR_NONE);
   }
   
   if(direction==1)
   {
      double ssl=sell_stop_price;
      double stp=sell_takeprofit_price;
      int sellticket;
      LotSize=(RiskedAmount/(pips_to_ssl/pips))/10;
      if(OpenOrderthisPair(Symbol())==0)
      sellticket = OrderSend(Symbol(),OP_SELL,LotSize,Bid,3,0,0,NULL,MagicNumber,0,Red);
      if(sellticket>0)OrderModify(sellticket,OrderOpenPrice(),ssl,stp,0,CLR_NONE);
   }
   
}
*/
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

bool IsNewCandle()
{
   static int BarsOnChart=0;
	if (Bars == BarsOnChart)
	return (false);
	BarsOnChart = Bars;
	return(true);
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
/*
void ScalingIn()
{
if (OrdersTotal())
{
    if(!OrderSelect(0,SELECT_BY_POS,MODE_TRADES))
       Print("incapace di selezionare un ordine");
       double op= OrderOpenPrice();
       int type= OrderType();
       double lots= OrderLots();
       int ticket= OrderTicket();
       if (lots == Lotsize)
       {
         if (type== OP_BUY && Bid-op > (PartialClosePips*pips))
            {
               if(!OrderClose(ticket,lots/2,Bid,30,clrRed))
                 Print("impossibile chiudere l' ordine");
            }
         else if( type == OP_SELL && op-Ask > (PartialClosePips*pips))
             if(!OrderClose(ticket,lots/2,Ask,30,clrRed))
                 Print ("impossibile chiudere l' ordine");
        }
       
}
}
*/
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
       if (lots == Lotsize)
       {
         if (type== OP_BUY && Bid < SL+(PartialClosePips*pips))
            {
               if(!OrderClose(ticket,lots/2,Bid,30,clrRed))
                 Print("impossibile chiudere l' ordine");
            }
         else if( type == OP_SELL && Ask > SL-(PartialClosePips*pips))
             if(!OrderClose(ticket,lots/2,Ask,30,clrRed))
                 Print ("impossibile chiudere l' ordine");
        }
       
}
}
//+------------------------------------------------------------------+
//trailing stop function
//+------------------------------------------------------------------+
void TrailCandle()
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

 