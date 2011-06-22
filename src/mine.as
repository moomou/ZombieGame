package 
{
	import flash.display.MovieClip;

	public class mine extends MovieClip
	{		
		public const DAMAGE:uint=10;
					
		public static const defaultBulletCount=5;
		public static const bulletCountMax:int=15;		
		
		public static var totalBullets:int=defaultBulletCount;
		
		public var flyingDirection:String;
		public var removed:Boolean;		
		public var blasted:Boolean;
		public var pickedup:Boolean;
	
		private var effectsMC;			//for referring to play area where effects such as explosion will be added
	
		public function mine(tmc)
		{
			effectsMC=tmc;
			flyingDirection=frameClass.NO_DIR;	//will have no particular direction
			
			removed=false;			
		}
		public function trigger():MovieClip		//add explosion effects
		{
			SoundEffect.playStage(SoundEffect.GRENADE_SOUND);
			
			var newExplosion:explosionEffect=new explosionEffect(effectsMC,this.x,this.y);
			var blast:blastRadius=new blastRadius(effectsMC,this.x,this.y,true);
			
			if (this.stage!=null)
				this.parent.removeChild(this);
				
			return blast;								
		}
		public function deleteMe()
		{
			if (removed)
				return;
			if (this.stage!=null)
				this.parent.removeChild(this);
				
			removed=true;
			delete this;			
		}
		
	}
}