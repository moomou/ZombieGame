package 
{
	import caurina.transitions.*;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.text.*;
	import flash.utils.Timer;
	
	public class zombie extends MovieClip
	{		
		public static const D_DIFFICULTY:Number=1;
		public static const D_HEALTH:Number=5;
		
		public static var difficulty:Number=D_DIFFICULTY;	//for adjusting how fast zombies walk
		public static var globalHealth:Number=D_HEALTH;		//life points for zombie; dies when reaches zero
		public static var chaseEnabled:Boolean=false;
	
		//distances & time
		static const attackAttemptRadius:int=70; 	
		static const fixDistance:int=7;				//used to adjust how close to wall and then rebounce
		static const nodeHeight:int=50;				//used to calculating path
		static const limit:Number=0.2;				//used to adjust changing mc when zombie walking--ex: when moveX>limit, change mc	
		static const deathAnimationTime:Number=2;	//time for playing the death animation
		static const fallBackFactor:Number=.5;		//for controlling how far zombies move back when shot
		static const showBloodTime:int=1000;		//for controlling how long blood mc appears
		static const getNextSquareTime:int=1000;	//for setting next tile to walk to
		
		static const maxSpeed:int=3;
		
		//text constants
		static const fontBold:Boolean=true;
		static const fontFace=new Arial();
		static const fontSize:int=12;
		
		public static var backDrop:MovieClip;			//backdrop on the main stage
		public static var attackReference:MovieClip;	//hostage
		public static var wallArrayZombie:Array; 		//the wall array for zombie so zombie are stopped at wall
		public static var counterWorth:int=0;			//the score worth of zombie
		public static var zombieAttackDamage:int=3;
		
		public var pathSquareIndex:int;					//index used to refer to tiles in the path array
		public var pathArray:Array;						//stores path to the hostage
		public var nextSquare:Point;					//stores next tile to walk to
		
		private var speed:Number;					//determines the speed of zombie					
		private var moveX:Number;					//x displacement
		private var moveY:Number;					//y ""
		private var health:Number;
		
		private var killed:Boolean=false;			//if the zombie is killed
		private var hithit:Boolean=false;			//indicate the zombie is shot
		
		private var zombieMC:MovieClip;				//zombie
		private var bloodSpill:MovieClip;			
		private var chasing:Boolean;
		private var getNextSquareIndexTimer:Timer;
		
		public function zombie()
		{
			speed=maxSpeed*.1;
			moveX=moveY=0;
			
			hithit=killed=false;
			chasing=false;
			
			prepareZombieText();
			
			pathArray=new Array();			
			zombieMC=this;	
			health=globalHealth;
			
			getNextSquareIndexTimer=new Timer(getNextSquareTime);
			getNextSquareIndexTimer.addEventListener(TimerEvent.TIMER,getPath);
			
			zombieMC.addEventListener(Event.ENTER_FRAME,zombieBehavior);			
			getNextSquareIndexTimer.start();
		}
		public function hitZombie(damage,direction):Number		//decrease health and if dead, delete
		{
			health-=damage;
			
			playHitAnimation();
			fallBack(damage,direction);			
			addBloodSpill();
			
			if (health<=0)
			{
				var tempScore:int=counterWorth*100;								
				Tweener.addCaller(new Object(),{onUpdate:cleanupDeathSequence,count:1,time:1});	//animate death a little later to enable fallback	
							
				return tempScore;					//return score to help main class update
			}
			
			return 0;								//0 indicate no kill
		}
		public function fallBack(damage:int,direction)
		{		
			if (direction==frameClass.PLAYER_DIAGONAL_L)
			{
				moveX+=-damage*fallBackFactor;
				moveY+=-damage*fallBackFactor;
			}
			else if (direction==frameClass.PLAYER_DIAGONAL_R)
			{
				moveX+=damage*fallBackFactor;
				moveY+=-damage*fallBackFactor;
			}
			else if (direction==frameClass.PLAYER_BDIAGONAL_R)
			{				
				moveX+=damage*fallBackFactor;
				moveY+=damage*fallBackFactor;
			}
			else if (direction==frameClass.PLAYER_BDIAGONAL_L)
			{
				moveX+=-damage*fallBackFactor;
				moveY+=damage*fallBackFactor;
			}			
			else if (direction==frameClass.PLAYER_FORWARD)
			{
				moveY+=-damage*fallBackFactor;
			}
			else if (direction==frameClass.PLAYER_BACK)
			{
				moveY+=damage*fallBackFactor;
			}
			else if (direction==frameClass.PLAYER_LEFT)
			{
				moveX+=-damage*fallBackFactor;
			}
			else if (direction==frameClass.PLAYER_RIGHT)
			{
				moveX+=damage*fallBackFactor;
			}
			else if (direction==frameClass.NO_DIR)			
			{
				moveX*=-20;
				moveY*=-20;
			}
			return;
		
		}
		public function cleanupZombie()
		{			
			zombieMC.removeEventListener(Event.ENTER_FRAME,zombieBehavior);			
			getNextSquareIndexTimer.stop();
			getNextSquareIndexTimer.removeEventListener(TimerEvent.TIMER,getPath);
			removeMC();
			
			return;		
		}
		
		private function prepareZombieText()
		{
			var textformat:TextFormat=new TextFormat();
			textformat.font=fontFace.name;
			textformat.size=fontSize;
			textformat.bold=fontBold;
			textformat.align="center";
			
			zombieText.embedFonts=true;
			zombieText.defaultTextFormat=textformat;			
		}
		private function zombieBehavior(event:Event)
		{
			if (attackReference==null)	//if the game is over
			{
				cleanupZombie();
				return;
			}
			
			//when the difficulty raised enough, zombies run when near to attack hostage
			if (chaseEnabled && !chasing && 
				Math.abs(zombieMC.x-attackReference.x)<=attackAttemptRadius/1.5 && Math.abs(zombieMC.y-attackReference.y)<=attackAttemptRadius/1.5) 
			{
				chasing=true;
				moveX*=1.2;
				moveY*=1.2;
			}
			else if (chaseEnabled && chasing)
			{
				chasing=false;
				moveX/=1.2;
				moveY/=1.2;
			}
						
			zombieMC.x+=moveX;
			zombieMC.y+=moveY;	
					
			wallCollisionDetect(wallArrayZombie);			
			attack();		
		}
		private function setPathForZombie()
		{			
			nextSquare=new Point();
			nextSquare=pathArray[pathSquareIndex];
			
			if (pathSquareIndex>0)
				pathSquareIndex--;
		}	
		private function getPath(event:TimerEvent)
		{
			if (pathArray.length==0)
				return;			
		
			setPathForZombie();
			calculateNewMove();
			
			return;
		}		
		private function attack()
		{
			if (attackReference==null)			//if hostage reference no longer available
				return;
			if (Math.abs(zombieMC.x-attackReference.x) < attackAttemptRadius && Math.abs(zombieMC.y-attackReference.y) < attackAttemptRadius) 
			{	
				//if within attack attempt radius, play the animation and check if hit the hostage, if so, call hostage's attacked function
				playAttackAnimation();
				
				if (zombieMC.wallCheckBox.hitTestObject(attackReference) && attackReference.currentLabel!="dead")
					attackReference.hostageAttacked(zombieAttackDamage);
			}	
			return;
		}
		private function wallCollisionDetect(testArrayZombie:Array)
		{				
			for (var i:uint=0; i<testArrayZombie.length; i++)
			{
				var wallObj=testArrayZombie[i];
				checkFor(zombieMC.wallCheckBox,zombieMC);			//zombie hit wall with another embedded mc 		
			}
			
			function checkFor(checkingMC,fixMC)						//checking is the embedded; same as main class' wall collision
			{				
				if (checkingMC.hitTestObject(wallObj.mc))
				{
					if ((fixMC.x-fixMC.width/2-fixDistance <wallObj.rightside) && (fixMC.x+fixMC.width/2 >= wallObj.rightside)) //bumping left 
					{
						fixMC.x+=wallObj.rightside-(fixMC.x-fixMC.width/2)+fixDistance;
					}	
					else if (fixMC.y+fixMC.height+fixDistance  > wallObj.topside && fixMC.y <= wallObj.topside)	//bumping down 
					{
						fixMC.y-=(fixMC.y+checkingMC.height+fixDistance)-wallObj.topside;				
					}				
					else if (fixMC.y-fixDistance < wallObj.bottomside && fixMC.y+fixMC.height >= wallObj.bottomside) //bumping up o
					{
						fixMC.y+=wallObj.bottomside-fixMC.y+fixDistance;
					}
					
					else if ((fixMC.x+fixMC.width/2+fixDistance > wallObj.leftside) && (fixMC.x-fixMC.width/2 <= wallObj.leftside)) //bumping right
					{
						fixMC.x-=fixMC.x+fixMC.width/2+fixDistance -wallObj.leftside;
					}
				}
			}
		}
		private function calculateNewMove()
		{		
			var diffX:Number=nextSquare.x*nodeHeight+nodeHeight/2-zombieMC.x;
			var diffY:Number=nextSquare.y*nodeHeight+nodeHeight/2-zombieMC.y;
			var angle:Number=Math.atan2(diffY,diffX);
			
			moveX=speed*Math.cos(angle)*difficulty;
			moveY=speed*Math.sin(angle)*difficulty;
			
			if (moveX>limit && moveY>limit)								//change mc frame based on angle
			 	zombieMC.gotoAndStop(frameClass.PLAYER_BDIAGONAL_R);
			else if (moveX>limit && Math.abs(moveY)<limit)
			 	zombieMC.gotoAndStop(frameClass.PLAYER_RIGHT);
			else if (moveX<-limit && Math.abs(moveY)<limit)
				zombieMC.gotoAndStop(frameClass.PLAYER_LEFT);
			else if (moveY>limit && Math.abs(moveX)<limit)
			 	zombieMC.gotoAndStop(frameClass.PLAYER_BACK);
			else if (moveY<-limit && Math.abs(moveX)<limit)
				zombieMC.gotoAndStop(frameClass.PLAYER_FORWARD);
			else if (moveX<-limit && moveY>limit)
			 	zombieMC.gotoAndStop(frameClass.PLAYER_BDIAGONAL_L);
			else if (moveX<-limit && moveY<-limit)
			 	zombieMC.gotoAndStop(frameClass.PLAYER_DIAGONAL_L);
			else if (moveX>limit && moveY<-limit)
			 	zombieMC.gotoAndStop(frameClass.PLAYER_DIAGONAL_R);								
		}	
		private function addBloodSpill()		
		{
			var tempBlood:MovieClip=new bloodZombie();
			var newSpill:fadeSprite=new fadeSprite(backDrop,tempBlood,zombieMC.x,zombieMC.y, showBloodTime);
			
			return;			
		}	
		private function cleanupDeathSequence()	//can be customized to provide better animation
		{		
			SoundEffect.playZombie(SoundEffect.ZOMBIE_DEATH_SOUND);
			
			zombieMC.removeEventListener(Event.ENTER_FRAME,zombieBehavior);
			
			getNextSquareIndexTimer.removeEventListener(TimerEvent.TIMER,getPath);			
			getNextSquareIndexTimer.stop();			
			
			Tweener.addTween(zombieMC,{alpha:0,time:deathAnimationTime,onComplete:deleteZombie,transition:"linear"});
		}		
		private function playHitAnimation()//can be customized to provide better 
		{
			SoundEffect.playZombie(SoundEffect.ZOMBIE_HIT_SOUND);
			
			zombieText.alpha=1;
			zombieText.text="Ahh!";
			Tweener.addTween(zombieText,{alpha:0,time:1,transition:"linear",onComplete:removeAnimation});
		}
		private function playAttackAnimation()//can be customized to provide better 
		{
			SoundEffect.playZombie(SoundEffect.ZOMBIE_ATTACK_SOUND);
			
			zombieText.alpha=1
			zombieText.text="Graww!";
			Tweener.addTween(zombieText,{alpha:0,time:1,transition:"linear",onComplete:removeAnimation});
			
			return;
		}		
		private function removeAnimation()		//resets the textfield of zombie, for cosmetic effects
		{
			zombieText.text="";
			zombieText.alpha=1;
			
			return;			
		}
		
		private function deleteZombie()
		{
			if (!killed)
			{
				killed=true;
						
				bloodSpill=new deathBlood();
				bloodSpill.x=zombieMC.x;
				bloodSpill.y=zombieMC.y;
				backDrop.addChild(bloodSpill);
				backDrop.setChildIndex(bloodSpill,1);		//putting the blood below the zombies
				
				removeMC();
			}
		}
		private function removeMC()
		{
			zombieMC.parent.removeChild(zombieMC);
			zombieMC=null;
			delete this;
		}			
		
	}
}


















