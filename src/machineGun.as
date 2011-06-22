package
{
	import flash.display.MovieClip;
	import flash.events.*;
	
	public class machineGun extends MovieClip
	{
		public const DAMAGE:uint=1;	//very little damage
		
		public static const bulletCountMax:Number=300;
		public static const defaultBulletCount=100;			
		
		public static var totalBullets:int=defaultBulletCount;		
		public static var unlimited:Boolean=false;
		
		public var flyingDirection:String;
		public var removed:Boolean;		
	
		static const speed:Number=20;		
				
		private var obj:Object;
		private var mgMC:MovieClip;
		
		public static function increaseBulletCount(toIncrease:int)
		{
			if (totalBullets+toIncrease<bulletCountMax)
			{
				totalBullets+=toIncrease;
			}
			else
				totalBullets=bulletCountMax;			
		}
				
		public function machineGun(direction:String,playerX:Number,playerY:Number)
		{
			mgMC=this;
			removed=false;
			
			obj=new Object();
			obj.speedX=0;
			obj.speedY=0;
			obj.mc=mgMC;
			obj.speed=speed;
			
			flyingDirection=direction;
			mgMC.x=playerX;
			mgMC.y=playerY;
			
			frameClass.determineDirection(direction,obj);
			
			var variationX:int;
			var variationY:int;
			
			if (mgMC.currentLabel=="side")	//adding variation to bullet trajectory
			{
				variationX=0;
				variationY=1.5*(Math.random()>.5?-1:1);
			}
			else
			{
				variationY=0;
				variationX=1.5*(Math.random()>.5?-1:1);
			}
			
			obj.speedX+=variationX*Math.random()+variationX/2;
			obj.speedY+=variationY*Math.random()+variationY/2;
			
			addEventListener(Event.ENTER_FRAME,fly);
		}
		private function fly(event:Event)
		{
			mgMC.x+=obj.speedX;
			mgMC.y+=obj.speedY;		
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

