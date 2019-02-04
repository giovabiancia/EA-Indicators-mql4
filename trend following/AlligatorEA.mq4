//+------------------------------------------------------------------+
//|                                            EA-Alligator_v1-0.mq4 |
//|                                                    Luca Spinello |
//|                                https://mql4tradingautomation.com |
//+------------------------------------------------------------------+

#property copyright     "Luca Spinello - mql4tradingautomation.com"
#property link          "https://mql4tradingautomation.com"
#property version       "1.00"
#property strict
#property description   "This Expert Advisor open orders using the popular Alligator Indicator by Bill Williams"
#property description   " "
#property description   "DISCLAIMER: This code comes with no guarantee, you can use it at your own risk"
#property description   "We recommend to test it first on a Demo Account"

/*
The Alligator Indicator is basically a combination of 3 MA with different periods and shifts
ENTRY BUY: The three MA are going up and the fast MA are above the slow
ENTRY SELL: The three MA are going down and the fast MA are below the slow
EXIT: Can be fixed pips (Stop Loss and Take Profit) or triggered by the next opposite order
Only 1 order at a time
*/


extern double LotSize=0.1;             //Position size

extern bool UseEntryToExit=true;       //Use next entry to close the trade (if false uses take profit)
extern double StopLoss=20;             //Stop loss in pips
extern double TakeProfit=50;           //Take profit in pips

extern int Slippage=2;                 //Slippage in pips

extern bool TradeEnabled=true;         //Enable trade

//Functional variables
double ePoint;                         //Point normalized

bool CanOrder;                         //Check for risk management
bool CanOpenBuy;                       //Flag if there are buy orders open
bool CanOpenSell;                      //Flag if there are sell orders open

int OrderOpRetry=10;                   //Number of attempts to perform a trade operation
int SleepSecs=3;                       //Seconds to sleep if can't order
int MinBars=60;                        //Minimum bars in the graph to enable trading

datetime LastOpenOrder;                //Used to order only once per bar

//Functional variables to determine prices
double MinSL;
double MaxSL;
double TP;
double SL;
double Spread;
int Slip; 


//Variable initialization function
void Initialize(){          
   RefreshRates();
   ePoint=Point;
   Slip=Slippage;
   if (MathMod(Digits,2)==1){
      ePoint*=10;
      Slip*=10;
   }
   TP=TakeProfit*ePoint;
   SL=StopLoss*ePoint;
   CanOrder=TradeEnabled;
   CanOpenBuy=true;
   CanOpenSell=true;
}


//Check if orders can be submitted
void CheckCanOrder(){            
   if( Bars<MinBars ){
      Print("INFO - Not enough Bars to trade");
      CanOrder=false;
   }
   OrdersOpen();
   return;
}


//Check if there are open orders and what type
void OrdersOpen(){
   for( int i = 0 ; i < OrdersTotal() ; i++ ) {
      if( OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) == false ) {
         Print("ERROR - Unable to select the order - ",GetLastError());
         break;
      } 
      if( OrderSymbol()==Symbol() && OrderType() == OP_BUY) CanOpenBuy=false;
      if( OrderSymbol()==Symbol() && OrderType() == OP_SELL) CanOpenSell=false;
   }
   return;
}


//Close all the orders of a specific type and current symbol
void CloseAll(int Command){
   double ClosePrice=0;
   for( int i = 0 ; i < OrdersTotal() ; i++ ) {
      if( OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) == false ) {
         Print("ERROR - Unable to select the order - ",GetLastError());
         break;
      }
      if( OrderSymbol()==Symbol() && OrderType()==Command) {
         if(Command==OP_BUY) ClosePrice=Bid;
         if(Command==OP_SELL) ClosePrice=Ask;
         double Lots=OrderLots();
         int Ticket=OrderTicket();
         for(int j=1; j<OrderOpRetry; j++){
            bool res=OrderClose(Ticket,Lots,ClosePrice,Slip,Red);
            if(res){
               Print("TRADE - CLOSE - Order ",Ticket," closed at price ",ClosePrice);
               break;
            }
            else Print("ERROR - CLOSE - error closing order ",Ticket," return error: ",GetLastError());
         }
      }
   }
   return;
}


//Open new order of a given type
void OpenNew(int Command){
   RefreshRates();
   double OpenPrice=0;
   double SLPrice;
   double TPPrice;
   if(Command==OP_BUY){
      OpenPrice=Ask;
      SLPrice=OpenPrice-SL;
      if(UseEntryToExit==false) TPPrice=OpenPrice+TP;
   }
   if(Command==OP_SELL){
      OpenPrice=Bid;
      SLPrice=OpenPrice+SL;
      if(UseEntryToExit==false) TPPrice=OpenPrice-TP;
   }
   for(int i=1; i<OrderOpRetry; i++){
      int res=OrderSend(Symbol(),Command,LotSize,OpenPrice,Slip,NormalizeDouble(SLPrice,Digits),NormalizeDouble(TPPrice,Digits),"",0,0,Blue);
      if(res){
         Print("TRADE - NEW - Order ",res," submitted: Command ",Command," Volume ",LotSize," Open ",OpenPrice," Slippage ",Slip," Stop ",SLPrice," Take ",TPPrice);
         break;
      }
      else Print("ERROR - NEW - error sending order, return error: ",GetLastError());
   }
   return;
}


//Technical analysis of the indicators
extern int JawPeriod=13;      //Period of the Alligator Jaw
extern int JawShift=8;        //Shift of the Alligator Jaw
extern int TeethPeriod=8;     //Period of the Alligator Teeth
extern int TeethShift=5;      //Shift of the Alligator Teeth
extern int LipsPeriod=5;      //Period of the Alligator Lips
extern int LipsShift=3;       //Shift of the Alligator Lips
double JawCurr;
double TeethCurr;
double LipsCurr;
double JawPrev;
double TeethPrev;
double LipsPrev;
double Fractal;
bool AlligatorTrendDown=false;
bool AlligatorTrendUp=false;

void FindAlligatorTrend(){
   AlligatorTrendDown=false;
   AlligatorTrendUp=false;
   JawCurr=iAlligator(Symbol(),0,JawPeriod,JawShift,TeethPeriod,TeethShift,LipsPeriod,LipsShift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORJAW,0);
   TeethCurr=iAlligator(Symbol(),0,JawPeriod,JawShift,TeethPeriod,TeethShift,LipsPeriod,LipsShift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORTEETH,0);
   LipsCurr=iAlligator(Symbol(),0,JawPeriod,JawShift,TeethPeriod,TeethShift,LipsPeriod,LipsShift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORLIPS,0);
   JawPrev=iAlligator(Symbol(),0,JawPeriod,JawShift,TeethPeriod,TeethShift,LipsPeriod,LipsShift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORJAW,1);
   TeethPrev=iAlligator(Symbol(),0,JawPeriod,JawShift,TeethPeriod,TeethShift,LipsPeriod,LipsShift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORTEETH,1);
   LipsPrev=iAlligator(Symbol(),0,JawPeriod,JawShift,TeethPeriod,TeethShift,LipsPeriod,LipsShift,MODE_SMMA,PRICE_MEDIAN,MODE_GATORLIPS,1);
   Fractal= iFractals(Symbol(),0,MODE_MAIN,0);
   if(JawCurr<TeethCurr && TeethCurr<LipsCurr && JawCurr>JawPrev && TeethCurr>TeethPrev && LipsCurr>LipsPrev) AlligatorTrendUp=true;
   if(JawCurr>TeethCurr && TeethCurr>LipsCurr && JawCurr<JawPrev && TeethCurr<TeethPrev && LipsCurr<LipsPrev) AlligatorTrendDown=true;
}




//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   //Calling initialization, checks and technical analysis
   Initialize();
   CheckCanOrder();
   FindAlligatorTrend();
   //Check of Entry/Exit signal with operations to perform
   if(AlligatorTrendUp){
      if(UseEntryToExit) CloseAll(OP_SELL);
      if(CanOpenBuy && CanOpenSell && CanOrder && LastOpenOrder!=Time[0]){
         OpenNew(OP_BUY);
         LastOpenOrder=Time[0];
      }
   }
   if(AlligatorTrendDown){
      if(UseEntryToExit) CloseAll(OP_BUY);
      if(CanOpenSell && CanOpenBuy && CanOrder && LastOpenOrder!=Time[0]){
         OpenNew(OP_SELL);
         LastOpenOrder=Time[0];
      }
   }
  }
//+------------------------------------------------------------------+