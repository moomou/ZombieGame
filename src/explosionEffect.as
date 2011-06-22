package
{
	import flash.display.MovieClip;
	import flash.utils.Timer;
	
	//a class used to show explosion by animating two types of movieclip--a red particle and smoke particle
	
	public class explosionEffect extends MovieClip
	{
		private static const bigRadius:int=150;
		private static const smallRadius:int=120;
						
		private const animSteps:int = 100;
		private const animStepTime:int=900;
	
		private const numParticle:int=3;
		private const particleAlpha:Number=.75;
		
		private static var explosionRadius:Number=smallRadius;
		private static var particleSize:Number=5;
		
		private var animTimer:Timer;	
		private var tempHolder:Array;
		private var parentMC;

		public static function increaseExplosionRadius()	//used to enlarged blast radius upgrade	
		{
			explosionRadius=bigRadius;
			particleSize*=1.3;
			
			return;
		}
		public static function resetExplosionRadius()	//called at beginning to restore pre-play status
		{
			explosionRadius=smallRadius;
			particleSize=5;
						
			return;
		}
		
		public function explosionEffect(parent:MovieClip,targetX:Number,targetY:Number,targetAlpha:Number=particleAlpha)
		{		
			var targetDistance:Number=explosionRadius
			var particleCount:int=numParticle;
				
			for (var i:int=0; i<particleCount; i++)
			{
				parentMC=parent;
				tempHolder=new Array();
				
				var tempMC1:MovieClip=new explosion();
				var tempMC2:MovieClip=new smoke();				
								
				tempMC1.x=targetX+Math.random()*(targetDistance/2);
				tempMC1.y=targetY+Math.random()*(targetDistance/2);
				tempMC2.x=targetX+Math.random()*(targetDistance/2);
				tempMC2.y=targetY+Math.random()*(targetDistance/2);
				
				tempMC1.alpha=targetAlpha*Math.random()+targetAlpha/2;
				tempMC2.alpha=targetAlpha*Math.random()+targetAlpha/2;
				
				var tempSize1=particleSize*Math.random()+particleSize/2;
				tempMC1.scaleX=tempSize1;
				tempMC1.scaleY=tempSize1;
				
				var tempSize2=particleSize*Math.random()+particleSize/2;
				tempMC2.scaleX=tempSize2;
				tempMC2.scaleY=tempSize2;
				
				tempMC1.rotation=Math.random()*360;				
				tempMC2.rotation=Math.random()*360;
				
				parentMC.addChild(tempMC1);
				parentMC.addChild(tempMC2);	
				
				tempHolder.push(tempMC1);
				tempHolder.push(tempMC2);
			}			
		}
	}
}






















