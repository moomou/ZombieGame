package
{
	import caurina.transitions.*;
	
	import flash.display.MovieClip;
	import flash.events.*;

	public class pistol extends MovieClip
	{	
		public static var unlimited:Boolean=false;
		public static var totalBullets:int=defaultBulletCount;
			
		public static const bulletCountMax:Number=99;		
		public static const defaultBulletCount=35;
		private static const speed:Number=15;
				
		public const DAMAGE:uint=3;		
		
		public var flyingDirection:String;
		public var removed:Boolean;		
	
		private var obj:Object;				
		private var bulletMC:MovieClip;
		
		public static function increaseBulletCount(toIncrease:int)
		{
			if (totalBullets+toIncrease<bulletCountMax)
			{
				totalBullets+=toIncrease;
			}
			else
				totalBullets=bulletCountMax;			
		}
			
		public function pistol(direction:String,playerX:Number,playerY:Number)
		{
			bulletMC=this;
			removed=false;
			
			obj=new Object();
			obj.speedX=0;
			obj.speedY=0;
			obj.mc=bulletMC;
			obj.speed=speed;
			
			flyingDirection=direction;
			bulletMC.x=playerX;
			bulletMC.y=playerY;
			
			frameClass.determineDirection(direction,obj);
			
			addEventListener(Event.ENTER_FRAME,fly);
		}	
		private function fly(event:Event)
		{
			bulletMC.x+=obj.speedX;
			bulletMC.y+=obj.speedY;		
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
