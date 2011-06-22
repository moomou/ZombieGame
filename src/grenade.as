package
{
	import flash.display.MovieClip;
	import flash.events.*;
	import flash.utils.Timer;

	public class grenade extends MovieClip
	{
		public const DAMAGE:uint=0;	//0 damge because it will blasts off
		
		public static const bulletCountMax:int=25;
		public static const defaultBulletCount=10;	
		
		public static var totalBullets:int=defaultBulletCount;
		public static var unlimited:Boolean=false;
		
		//static const for controlling the behavior of grenades
		static const speed:Number=7;		
		static const explodeTime:int=2000;		
		static const gravity:Number=.1;	
		
		public var flyingDirection:String;
		public var removed:Boolean;		
		public var blasted:Boolean;
		public var obj:Object;				
		
		private var pillMC:MovieClip;
		private var explodeTimer:Timer;
		
		public function pill(direction:String,playerX:Number,playerY:Number)
		{			
			pillMC=this;
			removed=false;
			blasted=false;
			
			pillMC.x=playerX;
			pillMC.y=playerY;
			
			explodeTimer=new Timer(explodeTime);
			explodeTimer.addEventListener(TimerEvent.TIMER,blast);
						
			obj=new Object();
			obj.speedX=0;
			obj.speedY=0;
			obj.mc=grenadeMC;
			obj.speed=speed;
			
			flyingDirection=direction;
			frameClass.determineDirection(flyingDirection,obj);
			
			if (grenadeMC.currentLabel=="side")
				obj.speedY=-1;
			
			addEventListener(Event.ENTER_FRAME,fly);
			explodeTimer.start();			
		}
		private function blast(event:TimerEvent)
		{
			blasted=true;			
		}
		private function fly(event:Event)
		{			
			if (grenadeMC.currentLabel=="side" && obj.speedY<=.4)
			{
				obj.speedY+=gravity;
				obj.speedY*=.90;
				obj.speedX*=.95;
			}
			else if (grenadeMC.currentLabel=="side")
				obj.speedY=0;
			else
			{
				obj.speedX*=.95;
				obj.speedY*=.95;			
			}						
		}
		public function deleteMe()
		{
			if (removed)
				return;
				
			removed=true;		
			removeEventListener(Event.ENTER_FRAME,fly);
			
			this.parent.removeChild(this);
			delete this;
		}
		
	}
}