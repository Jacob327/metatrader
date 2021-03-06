#property copyright "Copyright 2016, Jacob"
#property link "http://jacob-fx.com"

#property indicator_chart_window
#property indicator_buffers  3
#property indicator_color1   Red
#property indicator_color2   Blue
#property indicator_color3   Orange
#property  indicator_width1  3
#property  indicator_width2  3
#property  indicator_width3  4

int i, win, lose;
double Up[],Dn[],Sw[];
static int     LastAlert = 0;

// General Setting
string         IndicatorName = WindowExpertName();
int            BarsToCnt     = 1440 * 3;
static int     CountedBars   = 0; // This is to decide Bars to delete
static int     LastBars      = 0; // This is to decide Bars to delete

// win/lose Setting 
string         msg_win  = "o";
string         msg_lose = "x";
string         msg_draw = "=";
color          Clolor   = White;

// Calclator Setting
bool           calculation = true;
int            judgeStart  = -1;
int            judgeEnd    = -1;
static string  Percent     = "";


void OnDeinit(const int reason){
   Comment("");
   
   for(i=MathMin(Bars-1, BarsToCnt+CountedBars); i>=0; i--)
   {
      deleteObj(msg_win);
      deleteObj(msg_lose);
      deleteObj(msg_draw);
   }
   ObjectDelete(IndicatorName+"percent");
   
   return;
}


int OnInit(){
   SetIndexEmptyValue(0,EMPTY_VALUE);
   SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexEmptyValue(2,EMPTY_VALUE);
   
   SetIndexBuffer(0,Up);
   SetIndexStyle(0, DRAW_ARROW);
   SetIndexArrow(0, 233);
   SetIndexBuffer(1,Dn);
   SetIndexStyle(1, DRAW_ARROW);
   SetIndexArrow(1, 234);
   SetIndexBuffer(2,Sw);
   SetIndexStyle(2, DRAW_ARROW);
   SetIndexArrow(2, 159);  
   return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{   
   if(LastBars == 0 || LastBars < Bars){
      CountedBars++;
      LastBars = Bars;
   }
   
   int limit=MathMin(Bars-1, BarsToCnt);
   
   for(i=limit; i>=0; i--)
   {
      
      Up[i]=EMPTY_VALUE;
      Dn[i]=EMPTY_VALUE;
      Sw[i]=EMPTY_VALUE;
      
      if(BUY())
      {
         Up[i] = Low[i];
         if(i==0)
         {
            Sw[i] = Up[i];
            if(LastAlert == 0 || LastAlert<Bars)
            {
               ALERT();
               LastAlert=Bars;
            }
         }
         else
         {  
            Sw[i] = EMPTY_VALUE;
         }
      }
      if(SELL())
      {
         Dn[i] = High[i];
         if(i==0)
         {
            Sw[i] = Dn[i];
            if(LastAlert == 0 || LastAlert<Bars)
            {
               ALERT();
               LastAlert=Bars;
            }
         }
         else
         {
            Sw[i] = EMPTY_VALUE;
         }
      }
   }
   
   if(calculation){
      showPercent();
   }

   return(rates_total);
}

//+------------------+  
//|   LOGIC          |
//+------------------+
bool BUY(){
   
   if(
      // Buy Condition
      Close[i+2] > Open[i+2]//for example
      &&
      Close[i+1] > Open[i+1]
      )
      return true;
   
   return false;

}

bool SELL(){
   if(
      // Sell Condition
      Close[i+2] < Open[i+2]//for example
      &&
      Close[i+1] < Open[i+1]
      )
      return true;
   
   return false;

}

//+------------------+  
//|   ALERT          |
//+------------------+
void ALERT()
{  
   if(Up[i]!=EMPTY_VALUE)
   {
      Alert(Symbol(),"[",Period(),"] Up ");
      SendNotification(Symbol()+"["+string(Period())+"] Up ");
   
   }
   else if(Dn[i]!=EMPTY_VALUE)
   {
      Alert(Symbol(),"[",Period(),"] Dn ");
      SendNotification(Symbol()+"["+string(Period())+"] Dn ");
   }
   else return;
   
}


//+------------------+  
//|   SHOW Win/Lose  |
//+------------------+
void showPercent(){
   win = 0;
   lose = 0;
   for(i=MathMin(Bars-1, BarsToCnt+CountedBars); i>=0; i--)
   {
      if(Up[i]!=EMPTY_VALUE && i>MathAbs(judgeEnd))
      {
            if(Open[i+judgeStart] < Close[i+judgeEnd])
            {
               makeObj(msg_win);
               win++;
            }
            else if(Open[i+judgeStart] > Close[i+judgeEnd])
            {
               makeObj(msg_lose);
               lose++;
            }
            else if(Open[i+judgeStart] == Close[i+judgeEnd])
            {
               makeObj(msg_draw);
            }
      }
      if(Dn[i]!=EMPTY_VALUE && i>MathAbs(judgeEnd))
      {
            if(Open[i+judgeStart] > Close[i+judgeEnd])
            {
               makeObj(msg_win);
               win++;
            }
            else if(Open[i+judgeStart] < Close[i+judgeEnd])
            {
               makeObj(msg_win);
               lose++;
            }
            else if(Open[i+judgeStart] == Close[i+judgeEnd])
            {
               makeObj(msg_draw);
            }
      }
       
      string msg;
      if(win+lose==0)
      {
         msg="NoData...";
      }
      else
      {
         Percent = 100 * win/(win+lose);
         msg = Percent + "% o[" + win + "] x[" + lose + "]";
      }
      ObjectDelete(IndicatorName+"percent");
      ObjectCreate(IndicatorName+"percent", OBJ_LABEL, 0, 0, 0);
      ObjectSet(IndicatorName+"percent", OBJPROP_XDISTANCE, 15);
      ObjectSet(IndicatorName+"percent", OBJPROP_YDISTANCE, 20);
      ObjectSetText(IndicatorName+"percent", msg, 13, "明朝", Clolor);
   }
}

//+---------------------+  
//|   OBJECT OPERATION  |
//+---------------------+
void makeObj(string msg)
{
   string objName = IndicatorName + "." + msg + "." + TimeToString(Time[i]);
   ObjectDelete(objName);
   ObjectCreate(objName, OBJ_TEXT, 0, Time[i], Low[i]);
   ObjectSetText(objName, msg, 10, "MS明朝", Clolor);
}

void deleteObj(string msg)
{
   ObjectDelete(IndicatorName + msg + TimeToString(Time[i]));
}