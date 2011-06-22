package
{
	import flash.display.MovieClip;
	import flash.events.*;
	import flash.text.*;
	import flash.utils.*;
	
	public class player extends MovieClip
	{
		public static var stageWidth:Number;
		public static var stageHeight:Number;
		public static var direction:String;
		public static var playerCurX:Number;
		public static var playerCurY:Number;

		private var speedX:Number=50;
		private var speedY:Number=50;
		private var health;
		
		private var upKey:Boolean;
		private var downKey:Boolean;
		private var leftKey:Boolean;
		private var rightKey:Boolean;

		private var now:int;
		private var then:int;
		private var playerMC:MovieClip;
		
		public function player()
		{
			playerMC=this;
			
			now=getTimer();			//initializing time
			then=now;
					
			stage.addEventListener(KeyboardEvent.KEY_DOWN,keyPress);
			stage.addEventListener(KeyboardEvent.KEY_UP,keyRelease);
			addEventListener(Event.ENTER_FRAME,playerBehavior);
		}
		public function gameIsOver()
		{
			stage.removeEventListener(KeyboardEvent.KEY_DOWN,keyPress);
			stage.removeEventListener(KeyboardEvent.KEY_UP,keyRelease);
			removeEventListener(Event.ENTER_FRAME,playerBehavior);
			playerMC.bulletCount.text="No...";
			return;
		}
		private function keyPress(event:KeyboardEvent)
		{		
			if (event.keyCode==37)//left
				leftKey=true;
			if (event.keyCode==40)//down
				downKey=true;
			if (event.keyCode==39)//right
				rightKey=true;			
			if (event.keyCode==38)//up
				upKey=true;
			
		}
		private function keyRelease(event:KeyboardEvent)
		{
			if (event.keyCode==37)//left
				leftKey=false;
			if (event.keyCode==40)//down
				downKey=false;
			if (event.keyCode==39)//right
				rightKey=false;			
			if (event.keyCode==38)//up
				upKey=false;
		}
		
		private function playerBehavior(event:Event)
		{
			movePlayer();		
		}
		private function movePlayer()
		{
			then=now;
			now=getTimer();
			playerMC.parent.setChildIndex(playerMC,playerMC.parent.numChildren-1);		//always putting the player in front of everything
			
			var diffTime:Number=now-then;
			diffTime/=1000;
						
			if (upKey)
			{
				playerMC.y-=speedY*diffTime;
				playerMC.gotoAndStop(frameClass.PLAYER_FORWARD);
			}
			else if (downKey)
			{
				playerMC.y+=speedY*diffTime;
				playerMC.gotoAndStop(frameClass.PLAYER_BACK);
			}
			
			if (leftKey)
			{
				playerMC.x-=speedX*diffTime;
				playerMC.gotoAndStop(frameClass.PLAYER_LEFT);
			}
			else if (rightKey)
			{
				playerMC.x+=speedX*diffTime;
				playerMC.gotoAndStop(frameClass.PLAYER_RIGHT);
			}
			
			if (rightKey && upKey)
				playerMC.gotoAndStop(frameClass.PLAYER_DIAGONAL_R);
			else if (leftKey && upKey)
				playerMC.gotoAndStop(frameClass.PLAYER_DIAGONAL_L);
			else if (rightKey && downKey)
				playerMC.gotoAndStop(frameClass.PLAYER_BDIAGONAL_R);
			else if (leftKey && downKey)
				playerMC.gotoAndStop(frameClass.PLAYER_BDIAGONAL_L);
			
			if (playerMC.x+playerMC.width/2>stageWidth)
				playerMC.x=stageWidth-playerMC.width/2;
			else if (playerMC.x-playerMC.width/2<0)
				playerMC.x=playerMC.width/2;
			if (playerMC.y+playerMC.height/2>stageHeight)
				playerMC.y=stageHeight-playerMC.height/2;
			else if (playerMC.y-playerMC.height/2<0)
				playerMC.y=playerMC.height/2;
				
			playerCurX=playerMC.x;
			playerCurY=playerMC.y;
			direction=playerMC.currentLabel;						
		}
	}
}



















