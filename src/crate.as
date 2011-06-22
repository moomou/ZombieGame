package
{
	import flash.display.MovieClip;
	
	public class crate extends MovieClip
	{
		public var amount:int;
				
		public function crate(pMC,xx,yy)
		{
			amount=Math.round(Math.random()*20+10);
			
			this.x=xx;
			this.y=yy;
			
			pMC.addChild(this);
		}

	}
}