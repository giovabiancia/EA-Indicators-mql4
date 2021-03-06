//+------------------------------------------------------------------+
//|                                                  babazzo_new.mq4 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"



extern bool   Use_MA_Trail= True;
extern int    MA_Period=60;
extern bool   UseCandleTrail= False;
extern bool   UseTrailngStop= False;


extern int    WhenToTrail=20;
extern int    TrailAmount= 10;
extern bool    UseMoveToBreakEven= True;
extern int    WhenToMoveToBE= 20;
extern int    PipsToLockIn=3;

extern int  PadAmount=0;
extern int  CandlesBack=5;

extern double  RiskPercent=5;
extern double  RewardRatio=2;

double pips;
int    MagicNumber = 1234;

datetime  triggerBarTime=0;
string Bias="none";


int init()
  {
   	double ticksize = MarketInfo(Symbol(), MODE_TICKSIZE);
   	if (ticksize == 0.00001 || ticksize == 0.001)
	   pips = ticksize*10;
	   else pips =ticksize;
  }
//-------------------------------------------------------------


int deinit()
{

return(0);
}
//-------------------------------------------------------------


int start()

{

// è importante che la funzione is new candle venga dichiarata solamente
// allo start e non richiamata da ness un altra funzione. 
  if(IsNewCandle()){
  CheckForMaTrade();
   if (OpenOrdersThisPair(Symbol())>=1)
      {
      if(UseMoveToBreakEven)MoveToBreakEven();
      if(UseTrailngStop)AdjustTrail();
      if(Use_MA_Trail)MA_Trail();
      }
      }
      
 
 }
 
 //-------------------------------------------//
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
 
 
 void DeleteOrder()
  {
  
   for( int i= OrdersTotal()- 1; i >=0 ; i--)
   {
      if( !OrderSelect(i,SELECT_BY_POS, MODE_TRADES)) continue;
       if(OrderMagicNumber() == MagicNumber&&
        OrderSymbol()== Symbol()&&
         OrderType()>OP_SELL)
           if(!OrderDelete(OrderTicket(),CLR_NONE))
            Print("Order Close failed, order number: ",OrderTicket(),"Error: ", GetLastError());
    }
    
    }
 
 //----------------------------------------------------------------------//
 
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

//--------------------------------------------------------------------------//
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



//--------------------------------//
void CheckForMaTrade()
{
      
 
 
 double CurrentSmallFish1 =  iMA(NULL,60,3,0,1,0,1);
 double CurrentSmallFish2 =  iMA(NULL,60,5,0,1,0,1);
 double CurrentSmallFish3 =  iMA(NULL,60,8,0,1,0,1);
 double CurrentSmallFish4 =  iMA(NULL,60,10,0,1,0,1);
 double CurrentSmallFish5 =  iMA(NULL,60,12,0,1,0,1);
 double CurrentSmallFish6 = iMA(NULL,60,15,0,1,0,1);
 double CurrentBigFish1 =  iMA(NULL,60,30,0,1,0,1);
 double CurrentBigFish2 =  iMA(NULL,60,35,0,1,0,1);
 double CurrentBigFish3 =  iMA(NULL,60,40,0,1,0,1);
 double CurrentBigFish4 =  iMA(NULL,60,45,0,1,0,1);
 double CurrentBigFish5 =  iMA(NULL,60,50,0,1,0,1);
 double CurrentBigFish6 = iMA(NULL,60,60,0,1,0,1);
 double ema21 =            iMA(NULL,60,21,0,1,0,1);
 
   if(Bias=="none")
   if(CurrentSmallFish1 > CurrentSmallFish2)
   if(CurrentSmallFish2 > CurrentSmallFish3)
   if(CurrentSmallFish3 > CurrentSmallFish4)   
   if(CurrentSmallFish4 > CurrentSmallFish5)
   if(CurrentSmallFish5 > CurrentSmallFish6)
   if(CurrentSmallFish6 > CurrentBigFish1)
   if(CurrentBigFish1 > CurrentBigFish2)
   if(CurrentBigFish2 > CurrentBigFish3)
   if(CurrentBigFish3 > CurrentBigFish4)   
   if(CurrentBigFish4 > CurrentBigFish5)
   if(CurrentBigFish5 > CurrentBigFish6)
  { triggerBarTime = Time[1];
  // la funzione Time da il tempo in secondi trascorsi dal 1970 quidi è
  // un numero enorme.
   Bias = "up";
   // bias significa inclinazione
   Comment("Bias is: "+Bias+" since: "+TimeToStr(triggerBarTime,TIME_DATE|TIME_MINUTES));
   }
   //----------------------------------------------------------------------//
   
   if (Bias=="up" && Low[1]<ema21 && Close[1]>CurrentBigFish6){
     OrderEntry(0);
    }
     if(Bias=="up"&& Close[1]<CurrentBigFish6){
     Bias="none";
     Comment("Bias is: "+Bias+" since: "+TimeToStr(triggerBarTime,TIME_DATE|TIME_MINUTES));

     DeleteOrder();
     }
     if (Bias=="none")
   if(CurrentSmallFish1 < CurrentSmallFish2)
   if(CurrentSmallFish2 < CurrentSmallFish3)
   if(CurrentSmallFish3 < CurrentSmallFish4)   
   if(CurrentSmallFish4 < CurrentSmallFish5)
   if(CurrentSmallFish5 < CurrentSmallFish6)
   if(CurrentSmallFish6 < CurrentBigFish1)
   if(CurrentBigFish1 < CurrentBigFish2)
   if(CurrentBigFish2 < CurrentBigFish3)
   if(CurrentBigFish3 < CurrentBigFish4)   
   if(CurrentBigFish4 < CurrentBigFish5)
   if(CurrentBigFish5 < CurrentBigFish6)
  { triggerBarTime = Time[1];
  // in questo modo ottieni il tempo della candela dove si verificano le condizioni
   Bias = "down";
   Comment("Bias is: "+Bias+" since: "+TimeToStr(triggerBarTime,TIME_DATE|TIME_MINUTES));
   }
 //---------------------------------------------------------------------------------------//
    if (Bias=="down" && High[1]>ema21 && Close[1]<CurrentBigFish6){
     OrderEntry(1);
    }
     if(Bias=="down" && Close[1]>CurrentBigFish6){
     Bias="none";
    Comment("Bias is: "+Bias+" since: "+TimeToStr(triggerBarTime,TIME_DATE|TIME_MINUTES));

     DeleteOrder();
     }
   
  
  
  }
  //----------------------------------------------------------------
  
  
  
   void OrderEntry (int direction)
   {
   
     
     int TotalNumberOfOrders;  // il numero di ordini presenti
     TotalNumberOfOrders= OrdersTotal();
     
     
     double LotSize=0;
     double Equity= AccountEquity();
     double RiskedAmount= Equity*RiskPercent*0.01;
     
     int iTBT= iBarShift(NULL,60,triggerBarTime,true); 
     // se gli mandi un certo tempo e quella candela si trova 10 barre indietro
     // rispetto a quella che si sta formando ti darà indietro 10
     // per farti sapere dove si trova quella candela 
     // in questo caso gli hai dato come tempo "triggerbartime"
     // ci dice quante candele indietro è stato piazzato l' ordine buy.
     
     int  iHH= iHighest(NULL,60,MODE_HIGH,iTBT+1, 0);
     // inizia a contare da iTBT barre fà  a ora e dimmi quante candele fa 
     // c' è stato il massimo relativo 
     double buyprice = High [iHH]+ PadAmount*pips;
     // dimmi qual è il massimo della candela che ho trovato con la funzione precedente
     
     
     
    
     int  iLL= iLowest(NULL,60,MODE_LOW,iTBT+1, 0);
     double sellprice = Low [iLL]- PadAmount*pips;
     
     
     
     
     double buy_stop_price= iMA (NULL,60,60,0,1,0,1)-PadAmount*pips;
     double pips_to_bsl= buyprice - buy_stop_price;
     double buy_takeprofit_price= (pips_to_bsl*RewardRatio)+ buyprice;
    
     double sell_stop_price= iMA(NULL,60,60,0,1,0,1)+PadAmount*pips;
     double pips_to_ssl= sell_stop_price - sellprice;
     double sell_takeprofit_price= sellprice - (pips_to_ssl*RewardRatio);
     
     
   
   if ( direction==1 ) 
   
    { 
      
      double bsl= buy_stop_price;
      double btp= buy_takeprofit_price;
      LotSize = ( RiskedAmount/(pips_to_bsl/pips))/10;
     
      if (OpenOrdersThisPair(Symbol())==0)
      {
      int BuyTicketOrder = OrderSend( Symbol(),OP_BUYSTOP,LotSize,buyprice,3, bsl,btp,NULL,MagicNumber,0,clrGreen);
      // la funzione order send restituisce -1 se non riesce a inviare l' ordine
      
          if (BuyTicketOrder >0 )
          {
          Print("Order Placed #", BuyTicketOrder);
          }
          else
          {
          Print("Order Send Failed, error #", GetLastError());
          }
          
          }
          }
          
          
          
     if ( direction==0 ) 
   
    { 
      
      double ssl= sell_stop_price;
      double stp= sell_takeprofit_price;
      LotSize = ( RiskedAmount/(pips_to_ssl/pips))/10;
      if (OpenOrdersThisPair(Symbol())==0)
      {
      int SellTicketOrder = OrderSend( Symbol(),OP_SELLSTOP,LotSize,sellprice,3, ssl,stp,NULL,MagicNumber,0,clrRed);
      // la funzione order send restituisce -1 se non riesce a inviare l' ordine
      
          if (SellTicketOrder >0 )
          {
          Print("Order Placed #", SellTicketOrder);
          }
          else
          {
          Print("Order Send Failed, error #", GetLastError());
          }
          }
          }
          }
  
  
  //--------------------------------------------------------------//
  void MA_Trail()
  {
  
  for (int b=OrdersTotal()-1; b>=0; b--)
   {
     if(OrderSelect(b,SELECT_BY_POS,MODE_TRADES))
      if(OrderMagicNumber()==MagicNumber)
       if(OrderSymbol()== Symbol())
        if(OrderType()==OP_BUY)
         if(OrderStopLoss()<iMA(NULL,0,60,0,1,0,0)-PadAmount*pips)
            OrderModify(OrderTicket(),OrderOpenPrice(),iMA(NULL,0,60,0,1,0,0)-PadAmount*pips,OrderTakeProfit(),0,CLR_NONE);
          }
          
   
   
   for (int s=OrdersTotal()-1; s>=0; s--)
   {
     if(OrderSelect(s,SELECT_BY_POS,MODE_TRADES))
      if(OrderMagicNumber()==MagicNumber)
       if(OrderSymbol()== Symbol())
        if(OrderType()==OP_SELL)
         if(OrderStopLoss()>iMA(NULL,0,60,0,1,0,0)+PadAmount*pips)
            OrderModify(OrderTicket(),OrderOpenPrice(),iMA(NULL,0,60,0,1,0,0)+PadAmount*pips,OrderTakeProfit(),0,CLR_NONE);
          }
          
   }