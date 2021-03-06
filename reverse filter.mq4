//+------------------------------------------------------------------------------------+
//|                                            An Expert Advisor for the filters study |
//|                                                                  DC2008_revers.mq4 |
//|                                                          Copyright © DC2008, Sergy |
//+------------------------------------------------------------------------------------+
extern int        Filter_Hour=0;    // D-Filter: Trading by hours
//----
extern double     Lots=0.1;
extern int        Symb_magic=9001,
                  nORD_Buy = 5,     // max buy orders
                  nORD_Sell = 5;    // max sell orders
//----
double   PRC_Buy,
         PRC_Sell;
int      ord_ticket,
         nORDER,
         ORD_Buy,
         ORD_Sell,
         max_ORD = 1,               // max orders at one bar
         Slippage=10;
string   Name_Expert="DC2008_revers Orders Expert with filters";
bool     Signal_Bars,
         ORD_Close_Buy,
         ORD_Close_Sell,
         Signal_Buy,
         Signal_Sell;
//+------------------------------------------------------------------------------------+
int init()                                                                             {
   Signal_Bars=Bars;
   ORD_Close_Buy=true; 
   ORD_Close_Sell=true;
   return(0);
}
//+------------------------------------------------------------------------------------+
void deinit()                                                                          {
   Comment("");
}
//+------------------------------------------------------------------------------------+
int start()                                                                            {
   if(AccountBalance()<1000) return(0);
   Signal_Sell=false;   
   Signal_Buy=false;
   if(OrdersTotal()==0)                                                                {
      Signal_Bars=Bars;
      ORD_Close_Buy=true; 
      ORD_Close_Sell=true;
      ORD_Buy=0;
      ORD_Sell=0;
   }
   nORDER=OrdersTotal();
   //+---------------------------------------------------------------------------------+
   //   BUY Signals
   //+---------------------------------------------------------------------------------+
   if(true
      && High[0]<iLow(NULL,PERIOD_H1,1)
      && ORD_Buy<nORD_Buy
   //.........................................Filters...................................
      //---- filter ¹1
      && iOpen(NULL,PERIOD_H1,1)>iClose(NULL,PERIOD_H1,1)  
      //---- filter ¹2
      && (Hour()==0                       
         || Hour()==1                     
         || Hour()==6                     
         || Hour()==7                     
         || Hour()==9                     
         || Hour()==10 
         || Hour()==12 
         || Hour()==14 
         || Hour()==15 
         || Hour()==18 
         || Hour()==20 
         || Hour()==22 
         || Hour()==23
         )      
      )                                                                                {
   //----
      Signal_Buy=true; 
   }
   //+---------------------------------------------------------------------------------+
   //   SELL Signals
   //+---------------------------------------------------------------------------------+
   if(true
      && Low[0]>iHigh(NULL,PERIOD_H1,1)
      && ORD_Sell<nORD_Sell
   //.........................................Filters...................................
      //---- filter ¹1
      && iOpen(NULL,PERIOD_H1,1)<iClose(NULL,PERIOD_H1,1)
      //---- filter ¹2
      && (Hour()==0                       
         || Hour()==1                     
         || Hour()==6                     
         || Hour()==7                     
         || Hour()==9                     
         || Hour()==10 
         || Hour()==12 
         || Hour()==14 
         || Hour()==15 
         || Hour()==18 
         || Hour()==20 
         || Hour()==22 
         || Hour()==23
         )      
      )                                                                                {
   //----
      Signal_Sell=true; 
   }
   //+---------------------------------------------------------------------------------+
   if(ORD_Close_Buy==false)   StopBuy(Symb_magic);    // close orders
   if(ORD_Close_Sell==false)  StopSell(Symb_magic);   // close orders
   //+---------------------------------------------------------------------------------+
   // Trade: open several orders inside one bar
   //+---------------------------------------------------------------------------------+
   if (nORDER<max_ORD)                                                                 {
      if (Signal_Buy)                                                                  {
         OpenBuy(Symb_magic);
         return(0);
      }
      if (Signal_Sell)                                                                 {
         OpenSell(Symb_magic);
         return(0);
      }
   }
   //+---------------------------------------------------------------------------------+
   // Trade: open one order inside one bar
   //+---------------------------------------------------------------------------------+
   if (nORDER>=max_ORD)                                                                {
      if (Signal_Buy && Signal_Bars<Bars)                                              {
         OpenBuy(Symb_magic);
         return(0);
      }
      if (Signal_Sell && Signal_Bars<Bars)                                             {
         OpenSell(Symb_magic);
         return(0);
      }
   }
   return (0);
}
//+------------------------------------------------------------------------------------+
void OpenBuy(int Symbol_magic)                                                         { 
   ORD_Close_Buy=true;
   ORD_Close_Sell=false;
   if(ORD_Buy>=1 && Ask>PRC_Buy-5*Point) return(0);
   ord_ticket=OrderSend
      (Symbol(),OP_BUY,Lots,Ask,Slippage,0,0,Name_Expert,Symbol_magic,0,Blue); 
   if(ord_ticket<0)                                                                    {
      Print("Ticket ",ord_ticket," Error",GetLastError());
      return(0);
   }
   PRC_Buy=Ask;
   Signal_Bars=Bars;
   ORD_Buy++;
   ORD_Sell=0;
} 
//+------------------------------------------------------------------------------------+
void OpenSell(int Symbol_magic)                                                        { 
   ORD_Close_Sell=true;
   ORD_Close_Buy=false;
   if(ORD_Sell>=1 && Bid<PRC_Sell+5*Point) return(0);
   ord_ticket=OrderSend
      (Symbol(),OP_SELL,Lots,Bid,Slippage,0,0,Name_Expert,Symbol_magic,0,Red); 
   if(ord_ticket<0)                                                                    {
      Print("Ticket ",ord_ticket," Error",GetLastError());
      return(0);
   }
   PRC_Sell=Bid;
   Signal_Bars=Bars;
   ORD_Sell++;
   ORD_Buy=0;
} 
//+------------------------------------------------------------------------------------+
void StopBuy(int Symbol_magic)                                                         {
   for (int i=0; i<OrdersTotal(); i++)                                                 { 
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))                                  { 
          if (OrderSymbol()==Symbol() && OrderMagicNumber()==Symbol_magic)             {    
            if (OrderType()==OP_BUY)                                                   { 
               OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, Blue); 
            }
         } 
      } 
   }
}
//+------------------------------------------------------------------------------------+
void StopSell(int Symbol_magic)                                                        {
   for (int i=0; i<OrdersTotal(); i++)                                                 { 
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))                                  { 
         if (OrderSymbol()==Symbol() && OrderMagicNumber()==Symbol_magic)              {    
            if (OrderType()==OP_SELL)                                                  { 
               OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, Red); 
            }
         } 
      } 
   }
}
//+------------------------------------------------------------------------------------+

//+------------------------------------------------------------------------------------+
