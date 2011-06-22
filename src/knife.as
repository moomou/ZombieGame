package
{
	import flash.display.MovieClip;
	import flash.events.Event;
	
	public class knife extends MovieClip
	{
		public const DAMAGE:uint=2;
		
		public var flyingDirection:String;
		public var removed:Boolean;		
	
		static const speed:Number=10;
		
		private var speedX;
		private var speedY;
		private var obj:Object;		
		private var knifeMC:MovieClip;
			
		public function knife(direction:String,playerX:Number,playerY:Number)
		{
			knifeMC=this;
			removed=false;
			
			knifeMC.x=playerX;
			knifeMC.y=playerY;
			
			obj=new Object();
			obj.speedX=0;
			obj.speedY=0;
			obj.mc=knifeMC;
			obj.speed=speed;
			
			flyingDirection=direction; 		//for use in the main class
			frameClass.determineDirection(direction,obj);
			
			addEventListener(Event.ENTER_FRAME,fly);
		}		
		private function fly(event:Event)
		{
			knifeMC.x+=obj.speedX;
			knifeMC.y+=obj.speedY;		
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