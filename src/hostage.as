package
{
	import flash.display.MovieClip;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;

	public class hostage extends MovieClip
	{		
		static const GAME_OVER:String="gameOver";

		static const limit:Number=.2;
		static const findPlayerInterval:Number=500;	//recalculate player position at this interval
		static const safetyCircle:int=50;			//when this close to player, stops moving
		static const maxSpeed:int=50;				//max walking speed
		static const offset:int=50;					//make the hostage follow a point behind playerMC
		
		public static var backDrop;		//for referring to backdrop in the main stage
		
		private var speed:Number;
		private var health:Number;
		
		private var moveX:Number;
		private var moveY:Number;
		private var MC:MovieClip;
		
		private var now:Number;
		private var then:Number;
		private var timer:Timer;
		private var followPlayerEnabled:Boolean;

		public function hostage()
		{
			moveX=0;
			moveY=0;
			
			speed=maxSpeed;
			then=getTimer();
			now=then;

			health=1;			//can be customized to provide multiple hit to kill
					
			MC=this;
			followPlayerEnabled=true;
			timer=new Timer(findPlayerInterval);
		
			timer.addEventListener(TimerEvent.TIMER,findPlayer);
			MC.addEventListener(Event.ENTER_FRAME,followMe);
			
			timer.start();			
		}
		public function toggleFollow():Boolean
		{
			followPlayerEnabled=!followPlayerEnabled;			
			return followPlayerEnabled;
		}	
		public function hostageAttacked(damage:int)
		{
			health-=damage;
			
			if (health<=0)
				iAmKilled();
				
			return;
		}		
//---------------------------------------------------------------------------		
		private function iAmKilled()
		{
			SoundEffect.playStage(SoundEffect.HOSTAGE_DEATH_SOUND);
			MC.removeEventListener(Event.ENTER_FRAME,followMe);
			MC.gotoAndStop("dead");
			
			timer.stop();
			timer.removeEventListener(TimerEvent.TIMER,findPlayer);
			
			var blood:MovieClip=new deathBlood();
			blood.scaleX=1.5;
			blood.scaleY=1.5;
			blood.x=MC.x;
			blood.y=MC.y;
			
			backDrop.addChild(blood);
			backDrop.addChild(MC);
			
			dispatchEvent(new Event(GAME_OVER));
			
			return;
		}		
		private function followMe(event:Event)
		{				
			if (followPlayerEnabled)
				moveHostage();
			else
			{
				then=getTimer();
				now=then;
			}
			
			return;			
		}
		private function moveHostage()
		{
			if (Math.abs(MC.x-player.playerCurX)<=safetyCircle && Math.abs(MC.y-MC.height/2-player.playerCurY)<=safetyCircle) 
			{
				moveX=0;
				moveY=0;
			}
			
			then=now;
			now=getTimer();
			
			var diffTime=now-then
			diffTime/=1000;
			
			MC.x+=moveX*diffTime;
			MC.y+=moveY*diffTime;		
		}		
		private function findPlayer(event:TimerEvent)
		{
			var diffX:Number=player.playerCurX-MC.x;;
			var diffY:Number=player.playerCurY-MC.y;
						
			var angle:Number=Math.atan2(diffY,diffX);
					
			moveX=speed*Math.cos(angle);
			moveY=speed*Math.sin(angle);
			
			if (moveX>limit && moveY>limit)
			 	MC.gotoAndStop(frameClass.PLAYER_BDIAGONAL_R);
			else if (moveX<-limit && moveY>limit)
			 	MC.gotoAndStop(frameClass.PLAYER_BDIAGONAL_L);
			else if (moveX<-limit && moveY<-limit)
			 	MC.gotoAndStop(frameClass.PLAYER_DIAGONAL_L);
			else if (moveX>limit && moveY<-limit)
			 	MC.gotoAndStop(frameClass.PLAYER_DIAGONAL_R);
			
			else if (moveX>limit && Math.abs(moveY)<limit)
			 	MC.gotoAndStop(frameClass.PLAYER_RIGHT);
			else if (moveX<-limit && Math.abs(moveY)<limit)
				MC.gotoAndStop(frameClass.PLAYER_LEFT);
			else if (moveY>limit && Math.abs(moveX)<limit)
			 	MC.gotoAndStop(frameClass.PLAYER_BACK);
			else if (moveY<-limit && Math.abs(moveX)<limit)
				MC.gotoAndStop(frameClass.PLAYER_FORWARD);
		}		
	}
}