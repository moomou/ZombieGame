package
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	public class blastRadius extends MovieClip
	{
		public const DAMAGE:uint=99;
		
		public static var blastRadiusBig:Boolean=false;
		 
		public var flyingDirection:String=frameClass.NO_DIR;
		public var removed:Boolean;
		
		static const timeToLive:int=700;
		static const offsetX:int=23;
		static const offsetY:int=23;
		
		private var timer:Timer;
		private var parentMC;
		
		public function blastRadius(parent,xx:Number,yy:Number,isGrenadeOrMine=false)
		{
			removed=false;
			parentMC=parent;
			
			if (!isGrenadeOrMine)
				SoundEffect.playStage(SoundEffect.BARREL_SOUND);
			
			if (blastRadiusBig)
			{
				this.scaleX=1.25;
				this.scaleY=1.25;
			}
			else if (isGrenadeOrMine)
			{
				this.scaleX=.8;
				this.scaleY=.8;
			}
			
			timer=new Timer(timeToLive);
			timer.addEventListener(TimerEvent.TIMER,del);
			
			this.x=xx+offsetX;
			this.y=yy+offsetY;
			
			parentMC.addChild(this);
			timer.start();			
		}
		private function del(event:Event)
		{
			deleteMe();
		}
		public function deleteMe()
		{		
			if (removed)
				return;
					
			removed=true;
			timer.stop();
			timer.removeEventListener(TimerEvent.TIMER,deleteMe);
		
			parentMC.removeChild(this);
			parentMC=null;
			timer=null;
			delete this;
		}		
	}
}












