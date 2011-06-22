package
{
	import flash.display.MovieClip;

	public class barrel extends MovieClip
	{
		public const DAMAGE:uint=0;	//no damages
		
		public static const bulletCountMax:int=20;
		public static const defaultBulletCount=5;
		
		public static var effectsMC;		
		public static var totalBullets:int=defaultBulletCount;
		
		public var flyingDirection:String;
		public var removed:Boolean;		
		public var pickedup:Boolean;		//whether picked up by the player
		public var obj:Object;	
			
		public function barrel()
		{		
			flyingDirection=frameClass.NO_DIR;		//no direction associated	
			removed=false;			
		}
		public function trigger():MovieClip	//triggering explosion 
		{
			SoundEffect.playStage(SoundEffect.BARREL_SOUND);
			
			var newExplosion:explosionEffect=new explosionEffect(effectsMC,this.x,this.y);
			var blast:blastRadius=new blastRadius(effectsMC,this.x,this.y);
			
			if (this.parent!=null)
				this.parent.removeChild(this);
				
			return blast;								
		}
		public function deleteMe()
		{
			if (removed)
				return;
			if (this.parent!=null)
				this.parent.removeChild(this);
					
			removed=true;			
			delete this;			
		}
		
	}
}