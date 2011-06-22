package
{
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	//used to store constant strings and provide placement coordinate for weapons
	
	public class frameClass
	{
		//lables derived from movieclip frame labels. so mc labels need to be changed if these are to be modified
		public static const PLAYER_RIGHT:String="right";
		public static const PLAYER_LEFT:String="left";
		public static const PLAYER_FORWARD:String="forward";
		public static const PLAYER_BACK:String="back";
		public static const PLAYER_DIAGONAL_R:String="slantR";
		public static const PLAYER_DIAGONAL_L:String="slantL";
		public static const PLAYER_BDIAGONAL_L:String="bSlantL";
		public static const PLAYER_BDIAGONAL_R:String="bSlantR";
		public static const NO_DIR:String="no direction";
		
		public static const KNIFE:int=0;
		public static const PISTOL:int=1;
		public static const MACHINEGUN:int=2;
		public static const SHOTGUN:int=3;
		public static const GRENADE:int=4;
		public static const BARREL:int=5;
		public static const MINE:int=6;
		
		private static const offsetMine:Number=50;
		private	static const bulletPlacementOffset:int=15;		
		private static const offsetBarrel:Number=70;
		
		public function frameClass()
		{
			trace("NOT TO BE INSTANTIATED");
		}
		public static function getPlacementCoordinate(playerMC:MovieClip,isBarrel:Boolean):Point
		{
			var direction=playerMC.currentLabel;
			var tempPoint:Point=new Point;			
			var placeOffset=isBarrel?offsetBarrel:offsetMine;
			
			if (direction==PLAYER_DIAGONAL_L)
			{
				tempPoint.x=playerMC.x-placeOffset;
				tempPoint.y=playerMC.y-placeOffset;
			}
			else if (direction==PLAYER_DIAGONAL_R)
			{				
				tempPoint.x=playerMC.x+placeOffset;
				tempPoint.y=playerMC.y-placeOffset;			
			}
			else if (direction==PLAYER_BDIAGONAL_R)
			{				
				tempPoint.x=playerMC.x+placeOffset;
				tempPoint.y=playerMC.y+placeOffset+playerMC.wallCheckBox.height;;						
			}
			else if (direction==PLAYER_BDIAGONAL_L)
			{
				tempPoint.x=playerMC.x-placeOffset;
				tempPoint.y=playerMC.y+placeOffset+playerMC.wallCheckBox.height;;
			}
			else if (direction==PLAYER_FORWARD)
			{
				tempPoint.x=playerMC.x;
				tempPoint.y=playerMC.y-placeOffset;
			}
			else if (direction==PLAYER_BACK)
			{
				tempPoint.x=playerMC.x;
				tempPoint.y=playerMC.y+placeOffset;
			}			
			else if (direction==PLAYER_LEFT)
			{
				tempPoint.x=playerMC.x-placeOffset;
				tempPoint.y=playerMC.y+playerMC.wallCheckBox.height;	
			}
			else if (direction==PLAYER_RIGHT)
			{
				tempPoint.x=playerMC.x+placeOffset;
				tempPoint.y=playerMC.y+playerMC.wallCheckBox.height;
			}
			
			return tempPoint;
		}
		public static function determineDirection(direction,obj,rotationEnabled:Boolean=true)
		{
			if (direction==PLAYER_DIAGONAL_L)
			{
				obj.speedX=-obj.speed;
				obj.speedY=-obj.speed;
				
				obj.mc.gotoAndStop("nonSide");
				
				obj.mc.x-=bulletPlacementOffset;
				obj.mc.y-=bulletPlacementOffset;
				
				if (rotationEnabled)
					obj.mc.rotation=135;
			}
			else if (direction==PLAYER_DIAGONAL_R)
			{
				obj.speedX=obj.speed;
				obj.speedY=-obj.speed;
				
				obj.mc.gotoAndStop("nonSide");
								
				obj.mc.x+=bulletPlacementOffset;
				obj.mc.y-=bulletPlacementOffset;
								
				if (rotationEnabled)
					obj.mc.rotation=-135;
			}
			else if (direction==PLAYER_BDIAGONAL_R)
			{				
				obj.speedX=obj.speed;
				obj.speedY=obj.speed;
				
				obj.mc.gotoAndStop("nonSide");
				
				obj.mc.x+=bulletPlacementOffset;
				obj.mc.y+=bulletPlacementOffset;
				
				if (rotationEnabled)
					obj.mc.rotation=-45;				
			}
			else if (direction==PLAYER_BDIAGONAL_L)
			{
				obj.speedX=-obj.speed;
				obj.speedY=obj.speed;
				
				obj.mc.gotoAndStop("nonSide");
				
				obj.mc.x-=bulletPlacementOffset;
				obj.mc.y+=bulletPlacementOffset;
				
				if (rotationEnabled)
					obj.mc.rotation=45;
			}
			
			else if (direction==PLAYER_FORWARD)
			{
				obj.speedY=-obj.speed;
				obj.speedX=0;	
														
				obj.mc.gotoAndStop("nonSide");								
				obj.mc.y-=bulletPlacementOffset;
				
				obj.mc.rotation=-180;			
				
			}
			else if (direction==PLAYER_BACK)
			{
				obj.speedY=obj.speed;
				obj.speedX=0;
				
				obj.mc.gotoAndStop("nonSide");
				obj.mc.y+=bulletPlacementOffset;				
				
				if (rotationEnabled)
					obj.mc.rotation=0;				
			}
			
			else if (direction==PLAYER_LEFT)
			{
				obj.speedX=-obj.speed;
				obj.speedY=0;
								
				obj.mc.gotoAndStop("side");				
				obj.mc.x-=bulletPlacementOffset;
				obj.mc.y+=bulletPlacementOffset;
								
				if (rotationEnabled)
					obj.mc.rotation=0;				
			}
			else if (direction==PLAYER_RIGHT)
			{
				obj.speedX=obj.speed;
				obj.speedY=0;			
								
				obj.mc.gotoAndStop("side");
				obj.mc.x+=bulletPlacementOffset;
				obj.mc.y+=bulletPlacementOffset;				
				
				if (rotationEnabled)
					obj.mc.scaleX=-1;	
			}			
		}		 
		public static function changeDirection(flyingDirection,obj,smallHit:Boolean=false)			//change the direction after the obj hit something
		{
			if (flyingDirection==PLAYER_DIAGONAL_L || flyingDirection==PLAYER_DIAGONAL_R
				|| flyingDirection==PLAYER_BDIAGONAL_R || flyingDirection==PLAYER_BDIAGONAL_L)
			{
				obj.speedX*=smallHit ? -.5 : -.93;
				obj.speedY*=smallHit ? -.5 : -.93;
			}
			else if (flyingDirection==PLAYER_FORWARD || flyingDirection==PLAYER_BACK)
			{
				obj.speedY*=smallHit ? -.5 : -.93;
			}
			else if (flyingDirection==PLAYER_LEFT || flyingDirection==PLAYER_RIGHT)
			{
				obj.speedX*=smallHit ? -.5 : -.93;
			}
		}
	}
}