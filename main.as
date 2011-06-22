package
{
	import caurina.transitions.*;
	
	import flash.display.MovieClip;
	import flash.ui.Keyboard;
	import flash.events.*;
	import flash.geom.Point;
	import flash.text.*;
	import flash.utils.Timer;
	
	public class main extends MovieClip
	{
		static const THROW_SPEED:Number=6;
		static const bulletPlacementOffset:int=15;
		static const numberOfZombieToCreate:int=1;
		static const maxNumberOfZombies:uint=30;
		static const bulletDisappearTime:int=700;
		static const zombieSpawnDelay:int=2000;
		static const scoreMarkTime:Number=5;
		static const pathCalculationInterval:Number=500;
		static const counterTime:int=3500;
		static const gameInfoDisplayTimer:Number=2.5;
		static const gameInfoTextPosition:Point=new Point(400,320);	//x=default, y=show
		
		private static var flashEnabled:Boolean=true;	//whether the screens flashes when explosion occurs
		
		//variables to be initialized by in-frame codes
		private var portalArray:Array;
		private var backstageMoveLimits:Point;		
		
		//for game mechanics
		private var back:SimpleButton;
		private var over:MovieClip;
		
		//text constants
		static const fontBold:Boolean=true;
		static const fontFace=new Arial();
		static const fontSize:int=27;
				
		private var totalScore:int;	
		private var counter:int; 
					
		private var availableWeapon:Array;	//knife,pistol,shotgun,grenades,barrels		
		private var zombieArray:Array;
		private var bulletArray:Array;
		private var wallArray:Array;
		private var barrelArray:Array;
		private var dropCrate:Array;
		private var mineArray:Array;
		private var thrownArray:Array;
					
		private var fireKey:Boolean;	//indicate whether space is pressed
		private var released:Boolean;	//must release to fire again
		private var holding:Boolean;	//indicate whether the player is holding something
		private var throwFlag:Boolean;		
		
		private var heroMC:MovieClip;
		private var hostageMC:MovieClip;
		private var currentPickup:MovieClip;
		private var currentWeapon:int;
		private var Throw:Object;
				
		private var zombieCreateTimer:Timer;
		private var counterTimer:Timer;
		private var zombiePathFinderTimer:Timer;
	
		private var currentZombie:int;	
//-----------------------------------------------------------path variables
		private static const lineCost:int=10;
		private static const diagonalCost:int=14;
		
		private var terrainArray1:Array; //1 dimension
		private var terrainArray2:Array; //2 dimension
		private var itemsArray:Array;
		private var pathArray:Array;
		
		private var openList:Array;	//for A* operation
		private var closeList:Array;
		
		private var pathFound:Boolean;
		private var currentSquare:Object;
		private var gridSizeX:int;
		private var gridSizeY:int;
		private var goalCoord:Point;	//destination point
//========================================================================game preparation	
		public function main()
		{	
			initialize();		
		}
		private function initialize()
		{
			itemsArray=new Array();	//for gameplay use
			thrownArray=new Array();
			mineArray=new Array();			
			zombieArray=new Array();
			bulletArray=new Array();
			wallArray=new Array();			
			barrelArray=new Array();
			dropCrate=new Array();		
			
			openList=new Array();	//for A* operation
			closeList=new Array();	
			pathArray=new Array();
			currentSquare=new Object();	
			
			//weapon variables
			availableWeapon=[true,true,true,true,true,true];
			
			pistol.totalBullets=pistol.defaultBulletCount;
			shotGun.totalBullets=shotGun.defaultBulletCount;
			grenade.totalBullets=grenade.defaultBulletCount;
			barrel.totalBullets=barrel.defaultBulletCount;
					
			//timer uses in the game	
			zombieCreateTimer=new Timer(zombieSpawnDelay);
			zombiePathFinderTimer=new Timer(pathCalculationInterval);
			counterTimer=new Timer(counterTime);
		
			//flag variables of the player
			fireKey=false;
			released=true;	
			holding=false;
		
			pathFound=false;
									
			totalScore=0;
			counter=0;
			currentWeapon=1; //defaults to knife
			
			return;					
		}
		
		private function createNodes()
		{
			terrainArray1=new Array(); //1 dimension			
			terrainArray2=new Array(); //2 dimension
			
			for (var k:uint=0; k<gridSizeX; k++)			//adding arrays into 2d terrain array
				terrainArray2.push(new Array());
			
			for (var i:uint=0; i<gridSizeX; i++)
			{
				for (var j:uint=0; j<gridSizeY; j++)
				{
					var temp=new Object();
					temp.mc=new square();
					temp.mc.x=i*temp.mc.height;
					temp.mc.y=j*temp.mc.height;
					temp.mc.walkable.text=(i)+","+(j);
					temp.mc.visible=false;
					
					temp.costG=0;
					temp.costH=0;
					temp.costF=0;
					temp.parent=undefined;
					temp.xx=i;
					temp.yy=j;
					
					temp.closed=false;
					temp.opened=false;
					temp.walkable=true;				
					
					terrainArray2[i][j]=temp;
					terrainArray1.push(terrainArray2[i][j]);
					gamelevel.addChild(temp.mc);
				}
			}
		}
		private function gatherObstacles()	//storing a reference to every obstacle on stage
		{
			for (var i:uint=0; i<gamelevel.numChildren; i++)
			{
				var temp=gamelevel.getChildAt(i);
				
				if (temp is wall)
				{
					var tempBrick:Object=new Object();
					tempBrick.mc=temp;
					tempBrick.leftside=temp.x;
					tempBrick.rightside=temp.x+tempBrick.mc.width;
					tempBrick.topside=temp.y;
					tempBrick.bottomside=temp.y+tempBrick.mc.height;
					wallArray.push(tempBrick);
				}				
			}
			for (var j:uint=0; j<backdrop.numChildren; j++)
			{
				var temp2=backdrop.getChildAt(j);
				
				if (temp2 is barrel)
				{
					barrelArray.push(temp2);
					addToItemsArray(temp2);					
				}
			}		
			
			return;
		}
		private function determineWalkability()
		{
			for (var i:uint=0; i<terrainArray1.length; i++)
			{
				var tempT=terrainArray1[i];
				
				for (var j:uint=0; j<wallArray.length; j++)
				{
					if (tempT.mc.hitTestObject(wallArray[j].mc))
					{
						tempT.walkable=false;
						tempT.mc.walkable.text="X";
					}					
				}
			}
		}		
		
		private function separateItems()	//needs to be checked again
		{		
			zombie.wallArrayZombie=wallArray.slice(0,wallArray.length);			//updating zombies reference
			
			return;
		}
		private function preparegameInfoText()
		{
			var textformat:TextFormat=new TextFormat();
			textformat.font=fontFace.name;
			textformat.size=fontSize;
			textformat.bold=fontBold;
			textformat.align="center";
			
			gameInfo.embedFonts=true;
			gameInfo.defaultTextFormat=textformat;			
		}
		
		private function startGame()
		{	
			gridSizeX=Math.round(gamelevel.width/(new square()).height);	
			gridSizeY=Math.round(gamelevel.height/(new square()).height);		
				
			heroMC=gamelevel.hero;
			hostageMC=gamelevel.Hostage;
			hostageMC.addEventListener(hostage.GAME_OVER,GameOver);
			
			zombie.attackReference=hostageMC;
			zombie.backDrop=backdrop;	
			zombie.counterWorth=1;		
			hostage.backDrop=backdrop;
			barrel.effectsMC=gamelevel;		
					
			createNodes();
			gatherObstacles();
			determineWalkability();
		
			separateItems();			
			getNextZombieIndex();
			updatBulletLeftDisplay();
			preparegameInfoText();
					
			//adding listeners to various timer 	
			zombieCreateTimer.addEventListener(TimerEvent.TIMER,createZombie);
			zombiePathFinderTimer.addEventListener(TimerEvent.TIMER,calculatePath);
			counterTimer.addEventListener(TimerEvent.TIMER,counterDecrease);
							
			//keyboard interactivity
			stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP,keyRelease);
			
			//mainloop
			addEventListener(Event.ENTER_FRAME,mainLoop);			
			
			//start game
		//	zombieCreateTimer.start();
			createZombie();
			zombiePathFinderTimer.start();			
		}		
//==============================================================		
		private function mainLoop(even:Event)
		{
			fireGun();
			checkForHit();			
			centerPlayer();
				
			wallCollision(wallArray);
			itemPickUp();				//for picking crates with bullets
			
			animateThrow();
			return;
		}		
//=========================================================================path calculation
		private function calculatePath(event:TimerEvent)
		{
			if (currentZombie<0)
				return;			
				
			cleanseTiles();
					
			var tempX=Math.round(zombieArray[currentZombie].x/50);
			var tempY=Math.round(zombieArray[currentZombie].y/50);
			
			if (tempX>=gridSizeX)
				tempX=gridSizeX-1;
			else if (tempX<0)
				tempX=0;
			if (tempY>=gridSizeY)
				tempY=gridSizeY-1;
			else if (tempY<0)
				tempY=0;				
			
			goalCoord=new Point(Math.round(hostageMC.x/50),Math.round(hostageMC.y/50));
			
			addToOpenList(tempX,tempY);
			findPath();		
		}
		private function cleanseTiles()
		{
			zombiePathFinderTimer.stop();
							
			for (var i:uint=0; i<terrainArray1.length; i++)
			{
				terrainArray1[i].closed=false;
				terrainArray1[i].opened=false;
				terrainArray1[i].costG=0;
				terrainArray1[i].costF=0;
				terrainArray1[i].costH=0;
				terrainArray1[i].parent=undefined;
				terrainArray1[i].mc.gText.text="";
				terrainArray1[i].mc.hText.text="";
				terrainArray1[i].mc.fText.text="";
				terrainArray1[i].mc.gotoAndStop(1);
			}
			
			openList=new Array();
			closeList=new Array();
			pathFound=false;
		}
		private function findPath()
		{
			while (!pathFound)
			{
				if (openList.length<=0)
				{
					break;
					calculatePath(null);					
					return;
				}
						
				currentSquare.coordinate=findLowestFInOpenList();					
				findWalkableNearby(currentSquare.coordinate);
			}
		}
		private function findLowestFInOpenList():Point
		{
			openList.sortOn("costF",Array.NUMERIC);
						
			var tempX:int=openList[0].xx;
			var tempY:int=openList[0].yy;			
				
			return new Point(tempX,tempY);			
		}
		private function findWalkableNearby(start)
		{
			var startSearchAt:Point=new Point(start.x-1,start.y-1);
			
			if (pathFound=addToCloseList(start))
			{				
				targetFound();
				return;
			}	
			
			for (var i:int=startSearchAt.x; i<=start.x+1; i++)
			{
				for (var j:int=startSearchAt.y; j<=start.y+1; j++)
				{
					if (i >=0 && j>=0 && i<gridSizeX && j<gridSizeY)
					{
						if (!terrainArray2[i][j].walkable)
							continue;
						if (terrainArray2[i][j].closed)
							continue;	//the chosen square must be walkable and non-closed
						
						if (!terrainArray2[i][j].opened && (i!=start.x || j!=start.y))
						{
							terrainArray2[i][j].parent=terrainArray2[start.x][start.y];
						
							terrainArray2[i][j].costG=getCostG(i,j)+terrainArray2[i][j].parent.costG;
							terrainArray2[i][j].costH=getCostH(i,j);
							terrainArray2[i][j].costF=terrainArray2[i][j].costG+terrainArray2[i][j].costH;
												
							outputValue(i,j);								
							addToOpenList(i,j);
						}
						else if (terrainArray2[i][j].opened && (i!=start.x || j!=start.y))
						{
							var tempCostG:int=0;
							tempCostG=getCostG(i,j)+terrainArray2[i][j].parent.costG;
							
							if (tempCostG<terrainArray2[i][j].costG)
							{								
								terrainArray2[i][j].parent=terrainArray2[start.x][start.y];
								terrainArray2[i][j].costG=tempCostG;
								terrainArray2[i][j].costF=terrainArray2[i][j].costG+terrainArray2[i][j].costH;
							
								outputValue(i,j);						
							}							
						}
					}					
				}
			}					
		}
		
		private function addToCloseList(cur):Boolean
		{
			if (!terrainArray2[cur.x][cur.y].closed)
			{
				terrainArray2[cur.x][cur.y].closed=true;
				terrainArray2[cur.x][cur.y].mc.gotoAndStop(3);
				closeList.push(terrainArray2[cur.x][cur.y]);
			}
			if (terrainArray2[cur.x][cur.y].opened)
			{
				removeFromOpenList(cur.x,cur.y);
			}			
			
			if (cur.x==goalCoord.x && cur.y==goalCoord.y)
				return true;
			else
				return false;			
		}
		private function addToOpenList(xxx,yyy)
		{
			if (!terrainArray2[xxx][yyy].opened)
			{
				terrainArray2[xxx][yyy].opened=true;
				terrainArray2[xxx][yyy].mc.gotoAndStop(2);
				openList.push(terrainArray2[xxx][yyy]);
			}						
		}
		
		private function removeFromOpenList(curX,curY)
		{
			for (var i:uint=0; i<openList.length; i++)
			{
				if (openList[i].xx==curX && openList[i].yy==curY)
				{
					openList.splice(i,1);
					break;
				} 
			}
		}		 
		private function getCostG(coX,coY):int
		{
			if (currentSquare.coordinate.x==coX+1 || coX-1==currentSquare.coordinate.x
				&& currentSquare.coordinate.y==coY)
			{
				return lineCost;
			}
			else if (currentSquare.coordinate.y==coY+1 || coY-1==currentSquare.coordinate.y
				&& currentSquare.coordinate.x==coX)
			{
				return lineCost;
			}
			else
			{
				return diagonalCost;
			}
			
		}
		private function getCostH(coX,coY):int
		{
			return lineCost*(Math.abs(coX-goalCoord.x)+Math.abs(coY-goalCoord.y))
		}
		
		private function outputValue(xLoc,yLoc)
		{
			terrainArray2[xLoc][yLoc].mc.gText.text=terrainArray2[xLoc][yLoc].costG;
			terrainArray2[xLoc][yLoc].mc.hText.text=terrainArray2[xLoc][yLoc].costH;
			terrainArray2[xLoc][yLoc].mc.fText.text=terrainArray2[xLoc][yLoc].costF;
			terrainArray2[xLoc][yLoc].mc.parentText.text=terrainArray2[xLoc][yLoc].parent.xx+","+terrainArray2[xLoc][yLoc].parent.yy;
		}
		private function targetFound()
		{			
			var parentX=goalCoord.x;
			var parentY=goalCoord.y;
			
			pathArray=new Array();
			
			while (terrainArray2[parentX][parentY].parent!=undefined)
			{
				terrainArray2[parentX][parentY].parent.mc.gotoAndStop(4);
				pathArray.push(new Point(parentX,parentY));
				
				var tempX=terrainArray2[parentX][parentY].parent.xx;
				var tempY=terrainArray2[parentX][parentY].parent.yy;
				
				parentX=tempX;
				parentY=tempY;				
			}
			
			zombieArray[currentZombie].pathArray=pathArray.slice(0,pathArray.length);
			zombieArray[currentZombie].pathSquareIndex=pathArray.length-1;
			
			getNextZombieIndex();
			zombiePathFinderTimer.start();
		}
	
		private function getNextZombieIndex()
		{
			if (currentZombie>0)
			{
				currentZombie--;		
			}
			else if (zombieArray.length>=1)
			{ 
				createZombie();						
			}
			
			if (zombieArray.length==0)
			{
				currentZombie=-1;
				zombiePathFinderTimer.stop();
			}											
		}
//===========================================================================================================================weapons & zombies		
		private function keyDown(event:KeyboardEvent)
		{
			if (event.keyCode==Keyboard.SPACE && SoundEffect.isWeaponReady())//fire when the weapon is ready
			{	
				fireKey=true;
				released=false;
			}
			if (event.keyCode==70)		//f key for picking up and throwing
			{			
				if (!holding)
					pickupItemNearby();
				else if (holding) 
					throwObj();
			}
			
			//changing weapons
			if (event.keyCode==49)//1-knife
				changeCurrentWeapon(frameClass.KNIFE);
			else if (event.keyCode==50 && availableWeapon[1])//2-pistol
				changeCurrentWeapon(frameClass.PISTOL);
			else if (event.keyCode==51 && availableWeapon[2])//3-shotgun
				changeCurrentWeapon(frameClass.SHOTGUN);
			else if (event.keyCode==52 && availableWeapon[3])//4-grenade
				changeCurrentWeapon(frameClass.GRENADE);
			else if (event.keyCode==53 && availableWeapon[4])//5-barrel
				changeCurrentWeapon(frameClass.BARREL);
			else if (event.keyCode==54 && availableWeapon[5])//6 mines
				changeCurrentWeapon(frameClass.MINE);
			
			if (event.keyCode==55)	//for toggling path calculation
				for (var i:int=0; i<terrainArray1.length; i++)
					terrainArray1[i].mc.visible=!terrainArray1[i].mc.visible;
		}
		private function changeCurrentWeapon(toThis:int)
		{
			currentWeapon=toThis;
			updatBulletLeftDisplay();
			return;
		}
		private function keyRelease(event:KeyboardEvent)
		{
			if (event.keyCode==32)//fire
			{
				released=true;
			}
		}
		private function fireGun()
		{
			if (fireKey && released)// && !holding
			{
				fireKey=false;
				
				var newBullet:MovieClip;
				var newBullet2:MovieClip;
				var newBullet3:MovieClip;				
				var fired:Boolean=false;
				
				switch (currentWeapon)
				{
					case frameClass.KNIFE:	//knife
					{
						SoundEffect.playWeapon(SoundEffect.KNIFE_SOUND);
						
						newBullet=new knife(heroMC.currentLabel,heroMC.x,heroMC.y+bulletPlacementOffset);
						fired=true;
						
						break;
					}
					case frameClass.PISTOL:	//pistol
					{
						if (pistol.totalBullets>0)
						{
							SoundEffect.playWeapon(SoundEffect.PISTOL_SOUND);
							
							newBullet=new pistol(heroMC.currentLabel,heroMC.x,heroMC.y+bulletPlacementOffset);
							fired=true;
							
							pistol.totalBullets--;
						}
						break;
					}
					case frameClass.SHOTGUN: //shot gun
					{
						if (shotGun.totalBullets>0)
						{
							SoundEffect.playWeapon(SoundEffect.SHOTGUN_SOUND);
							
							newBullet=new shotGun(heroMC.currentLabel,heroMC.x,heroMC.y+bulletPlacementOffset);
							newBullet2=new shotGun(heroMC.currentLabel,heroMC.x,heroMC.y+bulletPlacementOffset);
							newBullet3=new shotGun(heroMC.currentLabel,heroMC.x,heroMC.y+bulletPlacementOffset);
							fired=true;
							
							shotGun.totalBullets--;
						}
						break;	
					}
					case frameClass.GRENADE: //grenade
					{
						if (grenade.totalBullets>0)
						{
							newBullet=new grenade(heroMC.currentLabel,heroMC.x,heroMC.y+bulletPlacementOffset)
							fired=true;
							
							grenade.totalBullets--;
						}
						break;	
					}
					case frameClass.BARREL: //barrel	--can be picked
					{
						if (barrel.totalBullets>0)
						{
							var newBarrel:MovieClip=new barrel();
							var tempPoint:Point=frameClass.getPlacementCoordinate(heroMC,true);
															
							newBarrel.x=tempPoint.x;
							newBarrel.y=tempPoint.y;
							
							backdrop.addChild(newBarrel);
							barrelArray.push(newBarrel);
							addToItemsArray(newBarrel);
							
							fired=false;							
							barrel.totalBullets--;
						}
						break;
					}
					case frameClass.MINE:		//mine		--can be picked up
					{
						if (mine.totalBullets>0)
						{
							var newMine:MovieClip=new mine(gamelevel);							
							var tempPoint2:Point=frameClass.getPlacementCoordinate(heroMC,false);
															
							newMine.x=tempPoint2.x;
							newMine.y=tempPoint2.y;												
							
							addToItemsArray(newMine);							
							mineArray.push(newMine);							
							backdrop.addChild(newMine);
													
							fired=false;
							mine.totalBullets--;							
						}
					}
				}
								
				if (fired)
				{
					gamelevel.addChild(newBullet);
					addTobulletArray(newBullet);
				}
				if (currentWeapon==3 && fired && shotGun.bigShotGun)	//if is shotgun and upgrade is earned
				{
					gamelevel.addChild(newBullet2);
					gamelevel.addChild(newBullet3);
					addTobulletArray(newBullet2);
					addTobulletArray(newBullet3);
				}
				
				updatBulletLeftDisplay(false);						
			}			
		}		
		private function addTobulletArray(newBullet)
		{
			bulletArray.push(newBullet);	
		}
		private function checkForHit()
		{
			checkForBoundary();
			//checkHostageHit();
			checkZombieHit();
			checkWallHit();
			checkBarrelHit();
			checkForMineHit();
			
			function checkForBoundary()
			{
				for (var i:int=bulletArray.length-1; i>=0; i--)
				{
					if (bulletArray[i].removed)
					{
						bulletArray.splice(i,1);
						continue;
					}
					
					if (!bulletArray[i] is grenade) 
						if (bulletArray[i].x>=gamelevel.width || bulletArray[i].x<=0 || bulletArray[i].y<=0 || bulletArray[i].y>=gamelevel.height)
							bulletArray[i].deleteMe();	
				}
			}
			function checkHostageHit()
			{
				for (var i:int=bulletArray.length-1; i>=0; i--)
				{
					if (bulletArray[i].removed)
					{
						bulletArray.splice(i,1);
						continue;
					}
					if (bulletArray[i].hitTestObject(hostageMC) && bulletArray[i].DAMAGE>0)
					{
						if (!(bulletArray[i] is blastRadius))
						{							
							bulletArray[i].deleteMe();
							bulletArray.splice(i,1);
						}
						if (bulletArray[i] is mine)
						{
							var newBlast=bulletArray[i].trigger();
							bulletArray.splice(i,1,newBlast);
						}				
						
						hostageMC.iAmKilled();
						break;						
					}
				} 
			}			
			function checkZombieHit()
			{
				nonThrowZombieCheck();
				thrownZombieCheck();
				
				function nonThrowZombieCheck()
				{
					for (var i:int=bulletArray.length-1; i>=0; i--)
					{					
						if (bulletArray[i].removed)
						{
							bulletArray.splice(i,1);
							continue;
						}
						if (bulletArray[i] is grenade)
						{
							if (bulletArray[i].blasted)
							{
								var newExplosion:explosionEffect=new explosionEffect(gamelevel,bulletArray[i].x,bulletArray[i].y);
								var blast:blastRadius=new blastRadius(gamelevel,bulletArray[i].x,bulletArray[i].y,true);
								
								bulletArray[i].deleteMe();							
								bulletArray.splice(i,1,blast);
							}
							else
								continue;
						}
											
						var tempBullet=bulletArray[i];
						
						for (var j:int=zombieArray.length-1; j>=0; j--)
						{
							if (tempBullet.hitTestObject(zombieArray[j]))
							{								
								if (!(tempBullet is blastRadius))
								{
									tempBullet.deleteMe();
									bulletArray.splice(i,1);
								}
								
								var tempx=zombieArray[j].x;
								var tempy=zombieArray[j].y;
								
								var tempFlag=zombieArray[j].hitZombie(tempBullet.DAMAGE,tempBullet.flyingDirection);
								
								if (tempFlag>0) //if score is awarded, zombie must be dead
								{								
									dropBox(tempx,tempy);
									increaseScore(tempFlag);								
									zombieArray.splice(j,1);
									getNextZombieIndex();
									
									var newPoint:point=new point(gamelevel,tempFlag,tempx,tempy,0x9DC8D9);
									var newHeart:fadeSprite=new fadeSprite(gamelevel,new heart(),hostageMC.x,hostageMC.y-25,4000);
								}
							}
						}
					}	
				}
				function thrownZombieCheck()
				{
					for (var i:int=thrownArray.length-1; i>=0; i--)
					{
						for (var j:int=zombieArray.length-1; j>=0; j--)
						{
							if (thrownArray[i].mc.hitTestObject(zombieArray[j]))
							{
								zombieArray[j].fallBack(3,thrownArray[i].flyingDirection);
								
								thrownArray[i].speedX*=.9;
								thrownArray[i].speedY*=.9;
							}
						}
					}
				}
			}
			function checkWallHit()
			{
				nonThrowWallCheck();
				thrownWallCheck();
				
				function nonThrowWallCheck()
				{
					for (var i:int=bulletArray.length-1; i>=0; i--)
					{					
						if (bulletArray[i].removed)
						{
							bulletArray.splice(i,1);
							continue;
						}
						
						var tempBullet=bulletArray[i];	
												
						for (var j:int=wallArray.length-1; j>=0; j--)
						{
							if (tempBullet.hitTestObject(wallArray[j].mc) && !(tempBullet is grenade) && !(tempBullet is blastRadius))
							{	
								var temp:fadeSprite=new fadeSprite(gamelevel,new fireBall(),tempBullet.x,tempBullet.y,bulletDisappearTime);	
													
								tempBullet.deleteMe();
								bulletArray.splice(i,1);												
								break;
							}
							else if (tempBullet.hitTestObject(wallArray[j].mc) && tempBullet is grenade)
							{
								frameClass.changeDirection(tempBullet.flyingDirection,tempBullet.obj);
							}					
						}					
					}
				}
				function thrownWallCheck()
				{
					for (var i:int=thrownArray.length-1; i>=0; i--)
					{
						for (var j:int=wallArray.length-1; j>=0; j--)
						{
							if (thrownArray[i].mc.hitTestObject(wallArray[j].mc))
								frameClass.changeDirection(thrownArray[i].flyingDirection,thrownArray[i]);
						}
					}
				}
			}
			function checkBarrelHit()
			{				
				for (var i:int=bulletArray.length-1; i>=0; i--)
				{					
					if (bulletArray[i].removed)
					{
						bulletArray.splice(i,1);
						continue;
					}
					
					var tempBullet=bulletArray[i];	
											
					for (var j:int=barrelArray.length-1; j>=0; j--)
					{
						if (barrelArray[j].removed)	//safte check
						{
							barrelArray.splice(j,1);	
							continue;						
						}	
						if (tempBullet.hitTestObject(barrelArray[j]) && !barrelArray[j].pickedup)
						{
							if (flashEnabled)
								showFlash();
							
							var blast=barrelArray[j].trigger();
							
							barrelArray[j].deleteMe();
							barrelArray.splice(j,1);
							bulletArray.splice(i,1,blast);
							
							if (!(tempBullet is blastRadius))
								tempBullet.deleteMe();	
						}
					}
				}
			}
			function checkForMineHit()	//for zombie
			{
				for (var i:int=zombieArray.length-1; i>=0; i--)
				{					
					for (var j:int=mineArray.length-1; j>=0; j--)
					{
						if (zombieArray[i].hitTestObject(mineArray[j]))
						{
							var tempBlast=mineArray[j].trigger();
												
							mineArray[j].deleteMe();
							mineArray.splice(j,1);
							
							addTobulletArray(tempBlast);
							break;
						}					
					}
				}
				for (var k:int=bulletArray.length-1; k>=0; k--)
				{
					if (!(bulletArray[k] is blastRadius))
						continue;
					for (var h:int=mineArray.length-1; h>=0; h--)
						if (bulletArray[k].hitTestObject(mineArray[h]))
						{							
							var Blast=mineArray[h].trigger();
												
							mineArray[h].deleteMe();
							mineArray.splice(h,1);
							
							addTobulletArray(Blast);
							break;
						}						
				}
			}
			
			return;
		}

		private function addToItemsArray(pickupItem)
		{
			itemsArray.push(pickupItem);
			return;
		}
		private function pickupItemNearby()
		{
			for (var k:int=itemsArray.length-1; k>=0; k--)
			{
				if (itemsArray[k].removed)
				{
					itemsArray.splice(k,1);
					continue;					
				}
				
				if (itemsArray[k].hitTestObject(heroMC))
				{
					holding=true;
					itemsArray[k].pickedup=true;
					itemsArray[k].x=0
					itemsArray[k].y=-itemsArray[k].height/3;
					
					currentPickup=itemsArray[k];					
					heroMC.addChild(currentPickup);
					break;					
				}				
			}
			return;			
		}
		private function throwObj()
		{
			Throw=new Object();
			Throw.speedX=0;
			Throw.speedY=0;
			Throw.flyingDirection=heroMC.currentLabel;
			Throw.mc=currentPickup;
			Throw.speed=THROW_SPEED;
			
			currentPickup.x=heroMC.x;
			currentPickup.y=heroMC.y;
			backdrop.addChild(currentPickup);
			
			frameClass.determineDirection(heroMC.currentLabel,Throw,false);
			thrownArray.push(Throw);
			
			currentPickup.pickedup=false;
			holding=false;									
		}
		private function animateThrow()
		{			
			for (var i:int=thrownArray.length-1; i>=0; i--)
			{
				if (Math.abs(thrownArray[i].speedX)<=.1 && Math.abs(thrownArray[i].speedY)<=.1)
				{
					thrownArray[i].speedY=0;
					thrownArray[i].speedX=0;
					thrownArray.splice(i,1);
					continue;
				}
			
				if (thrownArray[i].mc.currentLabel=="side")
				{
					thrownArray[i].speedY*=.95;
					thrownArray[i].speedX*=.95;
				}
				else if (thrownArray[i].mc.currentLabel=="side")
					;//Throw.speedY=0;			
				else
				{
					thrownArray[i].speedX*=.95;
					thrownArray[i].speedY*=.95;			
				}				
							
				thrownArray[i].mc.x+=thrownArray[i].speedX;
				thrownArray[i].mc.y+=thrownArray[i].speedY;	
				//currentPickup.rotation+=Throw.speedX;						
			}
		}
//=============================================================================================================================zombie Specifc	
		private function createZombie()//event:Event
		{
			if (zombieArray.length >= maxNumberOfZombies)
				return;
				
			if (!zombiePathFinderTimer.running)
				zombiePathFinderTimer.start();
				
			for (var i:int=numberOfZombieToCreate; i>0; i--)
			{
				var tempZombie:MovieClip=new zombie();
				var tempIndex:int=Math.floor(Math.random()*portalArray.length);
				
				tempZombie.x=portalArray[tempIndex].x;
				tempZombie.y=portalArray[tempIndex].y;
				
				gamelevel.addChild(tempZombie);
				zombieArray.push(tempZombie);
			}
			
			currentZombie=zombieArray.length-1;
		}
		private function wallCollision(testArray:Array)
		{			
			for (var i:uint=0; i<testArray.length; i++)
			{
				var wallObj=testArray[i];
				
				checkFor(heroMC.wallCheckBox,heroMC);
				checkFor(hostageMC,hostageMC);
			}
			function checkFor(checkingMC,fixMC)
			{				
				if (checkingMC.hitTestObject(wallObj.mc))
				{
					if ((fixMC.x-fixMC.width/2 <wallObj.rightside) && (fixMC.x+fixMC.width/2 >= wallObj.rightside)) //bumping left 
					{
						fixMC.x+=wallObj.rightside-fixMC.x+fixMC.width/2;
					}	
					else if (fixMC.y+fixMC.height > wallObj.topside && fixMC.y <= wallObj.topside)	//bumping down 
					{
						fixMC.y-=(fixMC.y+checkingMC.height+2)-wallObj.topside;				
					}				
					else if (fixMC.y < wallObj.bottomside && fixMC.y+fixMC.height >= wallObj.bottomside) //bumping up o
					{
						fixMC.y+=wallObj.bottomside-fixMC.y;
					}
					
					else if ((fixMC.x+fixMC.width/2 > wallObj.leftside) && (fixMC.x-fixMC.width/2 <= wallObj.leftside)) //bumping right
					{
						fixMC.x-=fixMC.x+fixMC.width/2-wallObj.leftside;
					}
				}
			}
		}
		private function centerPlayer(deathAnimation:Boolean=false)	//moving the stage to center the player
		{
			var tempPoint:Point;
			
			if (!deathAnimation)
				tempPoint=new Point(heroMC.x,heroMC.y);
			else
				tempPoint=new Point(hostageMC.x,hostageMC.y);
			
			gamelevel.x = -tempPoint.x + stage.stageWidth/2;
			gamelevel.y = -tempPoint.y+ stage.stageHeight/2;
			backdrop.x = -tempPoint.x + stage.stageWidth/2;
			backdrop.y = -tempPoint.y+ stage.stageHeight/2;
			
			if (deathAnimation)	//if game over, okay to cross boundry
				return;
			
			if (gamelevel.x<backstageMoveLimits.x)
			{
				gamelevel.x=backstageMoveLimits.x;
				backdrop.x=backstageMoveLimits.x;
			}	
			else if (gamelevel.x>0)
			{
				gamelevel.x=0;
				backdrop.x=0;
			}
			
			if (gamelevel.y<backstageMoveLimits.y)
			{
				gamelevel.y=backstageMoveLimits.y;
				backdrop.y=backstageMoveLimits.y;
			}	
			else if (gamelevel.y>0)
			{
				gamelevel.y=0;
				backdrop.y=0;
			}
		}
		private function itemPickUp()
		{
			for (var i:int=dropCrate.length-1; i>=0; i--)
			{
				if (dropCrate[i].hitTestObject(heroMC))
				{
					increaseWeaponBulletBy(dropCrate[i].amount);
					gamelevel.removeChild(dropCrate[i]);
					dropCrate.splice(i,1);
					break;
				}
			}
		
		}
//=====================================================================================game mechanics	
		private function GameOver(event:Event)
		{
			SoundEffect.playZombie(SoundEffect.HOSTAGE_DEATH_SOUND);
			
			over=new GAME_OVER();
			over.x=stage.stageWidth/2;
			over.y=stage.stageHeight/2-over.height;
			over.alpha=0;
			
			back=new backBtn();
			back.alpha=0;
			back.x=stage.stageWidth/2;
			back.y=350;
			
			addChild(back);
			addChild(over);
			stopGame();
			centerPlayer(true);	//used to center the camera on the dead hostage			
			
			scoreText.visible=false;
			zombieCounter.visible=false;
			
			back.addEventListener(MouseEvent.CLICK,goBackToMenu);	
			Tweener.addTween(gamelevel,{alpha:0,time:3,delay:1.0});
			Tweener.addTween(over,{alpha:1,time:3,delay:1.5});
			Tweener.addTween(back,{alpha:1,time:3,delay:1.5});			
		}
//-----------------------------------------------scores
		private function increaseScore(score)
		{
			var leadingZero:String="000000";
			var tempScore:int=totalScore;
			
			counterIncrease();
			totalScore+=score;
			
			if (totalScore%10000==0)
				leadingZero="0";
			else if (totalScore%1000==0)
				leadingZero="00";
			else
				leadingZero="000";						
			
			scoreText.text="Score:"+leadingZero+""+totalScore;
			checkForPrizesAndDifficulty();			
		}
		private function counterIncrease()
		{
			counter++;
			updateCounter();
			//counterTimer.reset();
			
			if (!counterTimer.running)
				counterTimer.start();
		}
		private function counterDecrease(event:TimerEvent)
		{
			if (counter>1)
				counter--;
			
			if (counter<=1)
			{
				counter=1;
				counterTimer.stop();
			}
						
			updateCounter();			
		}
		private function updateCounter()
		{	
			zombieCounter.counterText.text="x"+counter;
			if (counter>1)
			{
				zombie.counterWorth=counter+1;
				zombieCounter.play();
			}
			else
			{
				zombie.counterWorth=1;
				zombieCounter.stop();
			}
		}
//-----------------------------------------------support functions
		private function checkForPrizesAndDifficulty()
		{
			//knife,pistol,shotgun,grenades,barrels	
			//private var availableWeapon:Array=[true,false,false,false,false];	
			if (totalScore>=2000 && !availableWeapon[5])
			{
				availableWeapon[5]=true;
				gameInfoTextUpdate("Press 6 for Mines.");
			}
			else if (totalScore>=1500 && !availableWeapon[4])//barrels
			{	
				availableWeapon[4]=true;
				gameInfoTextUpdate("Press 5 for Barrels.");
			}
			else if (totalScore>=1200 && !availableWeapon[3])//grenades
			{	
				availableWeapon[3]=true;
				zombie.difficulty+=.1;							//increasing difficulty
				gameInfoTextUpdate("Press 4 for Grenades.");
			}
			else if (totalScore>=1000 && !shotGun.bigShotGun)
			{
				shotGun.bigShotGun=true;
				gameInfoTextUpdate("Shotgun upgarded.");
			}
			else if (totalScore>=700 && !availableWeapon[2])//shotguns
			{	
				availableWeapon[2]=true;
				zombie.difficulty+=.1;							//increasing difficulty
				gameInfoTextUpdate("Press 3 for ShotGun.");
			}
			else if (totalScore>=300 && !availableWeapon[1])//pistol
			{
				availableWeapon[1]=true;
				gameInfoTextUpdate("Press 2 for Pistol.");
			}			
		}		
		private function updatBulletLeftDisplay(displayString:Boolean=true)
		{
			var bulletCount:String="0";
			var string:String;
			
			switch (currentWeapon)
			{
				case frameClass.KNIFE: 
				{
					bulletCount="1/0";
					string="knife.";
					break;	
				}
				case frameClass.PISTOL: 
				{
					bulletCount=String(pistol.totalBullets);
					string="pistol.";
					break;	
				}
				case frameClass.SHOTGUN:
				{
					bulletCount=String(shotGun.totalBullets);
					string="shotgun.";
					break;	
				}
				case frameClass.GRENADE:
				{
					bulletCount=String(grenade.totalBullets);
					string="grenade.";
					break;	
				}
				case frameClass.BARREL: 
				{
					bulletCount=String(barrel.totalBullets);
					string="barrel.";
					break;	
				}
				case frameClass.MINE:
				{
					bulletCount=String(mine.totalBullets)
					string="mine";
					break;
				}
			}
			
			if (bulletCount=="0")
			{
				gameInfoTextUpdate("Depleted. Switched to knife.");
				currentWeapon=frameClass.KNIFE;
			}
			if (displayString)
				gameInfoTextUpdate("You picked "+string);
				
			heroMC.bulletCount.text=bulletCount;
		}		
		private function dropBox(tempx,tempy)
		{			
			if (Math.random()>.8)
			{
				var newCrate=new crate(gamelevel,tempx,tempy);
				dropCrate.push(newCrate);
			}	
		}
		private function increaseWeaponBulletBy(totalAmount)
		{			
			while (totalAmount!=0)
			{
				var randomIncrease:int=Math.round(Math.random()*5+1);
				
				switch (randomIncrease)
				{
					case 1:
					{
						if (pistol.bulletCountMax!=pistol.totalBullets && availableWeapon[1])
						{
							pistol.increaseBulletCount(totalAmount);
							gameInfoTextUpdate("Picked up pistol.");
							totalAmount=0;	
						}
						break;
					}
					case 2:
					{
						if (shotGun.bulletCountMax!=shotGun.totalBullets && availableWeapon[2])
						{
							shotGun.increaseBulletCount(totalAmount);
							gameInfoTextUpdate("Picked up shot gun.");
							totalAmount=0;
						}
						break;						
					}
					case 3:
					{
						if (grenade.bulletCountMax!=grenade.totalBullets && availableWeapon[3])
						{
							grenade.increaseBulletCount(totalAmount);
							gameInfoTextUpdate("Picked up grenades.");
							totalAmount=0;
						}
						break;						
					}
					case 4:
					{
						if (barrel.bulletCountMax!=barrel.totalBullets && availableWeapon[4])
						{
							barrel.totalBullets+=totalAmount;
							
							if (barrel.totalBullets>barrel.bulletCountMax)
								barrel.totalBullets=barrel.bulletCountMax;
							
							gameInfoTextUpdate("Picked up barrels.");
							totalAmount=0;					
						}
						break;
					}
					case 5:
					{
						if (mine.bulletCountMax!=mine.totalBullets && availableWeapon[5])
						{
							mine.totalBullets+=totalAmount;
							
							if (mine.totalBullets>mine.bulletCountMax)
								mine.totalBullets=mine.bulletCountMax;
							
							gameInfoTextUpdate("Picked up mines.");
							totalAmount=0;					
						}
						break;
					}
					default:
					{
						gameInfoTextUpdate("Empty box...");
						totalAmount=0;
						break;
					}
				}
			}
			
			updatBulletLeftDisplay(false);
		}
		private function showFlash()
		{
			var newFlash=new whiteBox();
							
			newFlash.x=250;
			newFlash.y=200;
			stage.addChild(newFlash);			
			Tweener.addTween(newFlash,{alpha:0,time:2,onComplete:removeMeFromStage,onCompleteParams:[newFlash]});		
		}		
//------------------------------------------------gameplay manage
		private function removeMeFromStage(me)		//a general cleanup function
		{
			stage.removeChild(me);
		}
		private function gameInfoTextUpdate(message:String)
		{
			gameInfo.text=message;
			
			if (Tweener.isTweening(gameInfo))
			{
				Tweener.removeTweens(gameInfo);
				gameInfo.y=gameInfoTextPosition.x;
				gameInfo.alpha=1;				
			}
			
			Tweener.addTween(gameInfo,{y:gameInfoTextPosition.y,time:1,transition:"linear"});
			Tweener.addTween(gameInfo,{alpha:0,y:-gameInfo.height,time:2,delay:gameInfoDisplayTimer,onComplete:gameInfoTextClean});
		}
		private function gameInfoTextClean()
		{
			gameInfo.text="";
			gameInfo.alpha=1;
			gameInfo.y=gameInfoTextPosition.x;;						
		}
		private function stopGame()
		{
			removeEventListener(Event.ENTER_FRAME,mainLoop);
			
			zombieCreateTimer.stop();
			zombiePathFinderTimer.stop();
			counterTimer.stop();
						
			zombieCreateTimer.removeEventListener(TimerEvent.TIMER,createZombie);
			zombiePathFinderTimer.removeEventListener(TimerEvent.TIMER,calculatePath);
			counterTimer.removeEventListener(TimerEvent.TIMER,counterDecrease);
			
			stage.removeEventListener(KeyboardEvent.KEY_DOWN,keyDown);
			stage.removeEventListener(KeyboardEvent.KEY_UP,keyRelease);
			
			heroMC.bulletCount.text="";					
		}
		private function goBackToMenu(event:MouseEvent)
		{
			for (var i:int=terrainArray1.length-1; i>=0; i--)
				gamelevel.removeChild(terrainArray1[i].mc);
				
			back.removeEventListener(MouseEvent.CLICK,goBackToMenu);
			
			removeChild(back);
			removeChild(over);
			
			initialize();	
			
			gotoAndStop("stageChooser");
		}
	}
}



























