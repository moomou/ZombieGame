package
{
	import caurina.transitions.*;
	
	import flash.display.MovieClip;
	import flash.events.*;

	public class shotGun extends MovieClip
	{		
		static const speed:Number=20;
		
		public const DAMAGE:uint=8;
		public static const bulletCountMax:Number=40;
		public static const defaultBulletCount=20;
			
		public static var bigShotGun:Boolean=false;
		public static var unlimited:Boolean=false;
		public static var totalBullets:int=defaultBulletCount;			
		
		public var flyingDirection:String;
		public var removed:Boolean;
				
		private var obj:Object;
		private var shotGunMC:MovieClip;
		
		public static function increaseBulletCount(toIncrease:int)
		{
			if (totalBullets+toIncrease<bulletCountMax)
			{
				totalBullets+=toIncrease;
			}
			else
				totalBullets=bulletCountMax;			
		}
			
		public function shotGun(direction:String,playerX:Number,playerY:Number)
		{
			shotGunMC=this;
			removed=false;
			
			obj=new Object();
			obj.speedX=0;
			obj.speedY=0;
			obj.mc=shotGunMC;
			obj.speed=speed;
			
			flyingDirection=direction;
			shotGunMC.x=playerX;
			shotGunMC.y=playerY;
			
			frameClass.determineDirection(direction,obj);
			
			var variationX:int;
			var variationY:int;
			
			if (shotGunMC.currentLabel=="side")	//adding deviation to bullet path
			{
				variationX=0;
				variationY=2*(Math.random()>.5?-1:1);
			}
			else
			{
				variationY=0;
				variationX=2*(Math.random()>.5?-1:1);
			}
			
			obj.speedX+=variationX*Math.random()+variationX/2;
			obj.speedY+=variationY*Math.random()+variationY/2;
			obj.rotation=Math.atan2(obj.speedY,obj.speedX);
			
			addEventListener(Event.ENTER_FRAME,fly);
		}	
		private function fly(event:Event)
		{
			shotGunMC.x+=obj.speedX;
			shotGunMC.y+=obj.speedY;		
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
