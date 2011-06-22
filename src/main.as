package
{
	import caurina.transitions.*;
	
	import flash.display.MovieClip;
	import flash.events.*;
	import flash.geom.Point;
	import flash.text.*;
	import flash.ui.Keyboard;
	import flash.utils.*;
	
	public class main extends MovieClip
	{
		//changeable constants that affect gameplay
		static const THROW_SPEED:Number=6;
		static const increaseZombieSpeedBy:Number=.05;
		static const increaseZombieHealthBy:Number=1;
		static const numberOfZombieToCreate:int=2;
		static const maxNumberOfZombies:uint=40;
		
		static const zombieSpawnDelay:int=2500;
		static const zombieSpawnDelayLv2:int=2000;
		static const zombieSpawnDelayLv3:int=1500;
		
		static const bulletDisappearTime:int=700;
		static const pathCalculationInterval:Number=300;
	
		static const gameInfoDisplayTimer:Number=2.5;	
		static const flashEnabled:Boolean=true;	//whether the screens flashes when explosion occurs
		static const baseScoreForPrizes:int=1000; //all future upgrades based on the multiple of this number 
		static const deathCenterTime:Number=2;
		static const counterTime:int=3000;		
		
		//constants relating to mc in .fla (ie movieclip needs to be changed if these are changed)
		static const nodeSize:Number=50;
		static const fixDistance:Number=8;		
		static const gameInfoTextPosition:Point=new Point(400,320);	//x=default, y=show
		
		//text constants
		static const fontBold:Boolean=true;
		static const fontFace=new Arial();
		static const fontSize:int=27;
		
		//variables for .fla use
		private var portalArray:Array;
		private var backstageMoveLimits:Point;
		private var highScoreVariable:Object;		
		
		//for game menu, timer, info output etc
		private var currentLevel:String;
		
		private var timePast:Number;
		private var now:Number;
		private var then:Number;
		private var fixedTime:Number=3;
		private var back:SimpleButton;
		private var over:MovieClip;
		private var boxOccupied:Array;
		
		//var used in game-play								
		private var totalScore:int;	//main score 
		private var counter:int;	//zombie killed counting 
					
		private var availableWeapon:Array;	//knife,pistol,machine gun, shotgun,grenades,barrels, mines		
		private var zombieArray:Array;
		private var bulletArray:Array;	
		private var wallArray:Array;	//wall
		private var barrelArray:Array;	//barrel array
		private var dropCrate:Array;	//pickable box containing bullets
		private var mineArray:Array;	//mine array
		private var itemsArray:Array;	//for storing pickable objs
		private var thrownArray:Array; //for keeping track of thrown items
					
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
		private var currentDifficulty:int;		//used to indicate how difficult the current stage is
//-----------------------------------------------------------path variables
		private static const lineCost:int=10;
		private static const diagonalCost:int=14;
		
		private var terrainArray1:Array; //1 dimension
		private var terrainArray2:Array; //2 dimension		
		private var pathArray:Array;	//for storing path values
		
		private var openList:Array;	//for A* operation
		private var closeList:Array;//"""
		
		private var pathFound:Boolean;
		private var currentSquare:Object;	//current tile in consideration
		private var gridSizeX:int;			//tile size
		private var gridSizeY:int;		
		private var goalCoord:Point;	//destination point
//========================================================================game preparation	
		public function main()
		{
			initialize();
			
			//set high score to zero 
			highScoreVariable={stage1:0,stage2:0,stage3:0};					
		}
		private function initialize()	//initializing main variables here
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
			
			//weapon variables-knife, pistol, machine gun, shot gun, grenade,barrel, mine
			availableWeapon=[true,false,true,true,true,false,false];
			boxOccupied=[false,false,false,false];
			
			//setting default values for weapon
			pistol.totalBullets=pistol.defaultBulletCount;
			machineGun.totalBullets=machineGun.defaultBulletCount;
			shotGun.totalBullets=shotGun.defaultBulletCount;
			grenade.totalBullets=grenade.defaultBulletCount;
			barrel.totalBullets=barrel.defaultBulletCount;
			mine.totalBullets=mine.defaultBulletCount;
			
			zombie.globalHealth=zombie.D_HEALTH;
			zombie.difficulty=zombie.D_DIFFICULTY;
			zombie.chaseEnabled=false;
			
			explosionEffect.resetExplosionRadius();
			
			blastRadius.blastRadiusBig=false;
			machineGun.unlimited=false;
			shotGun.bigShotGun=false;		
			shotGun.unlimited=false;
			grenade.unlimited=false;	
			
			//timer uses in the game	
			zombieCreateTimer=new Timer(zombieSpawnDelay);
			zombiePathFinderTimer=new Timer(pathCalculationInterval);
			counterTimer=new Timer(counterTime);
		
			//flag variables of the player
			fireKey=false;
			released=true;	
			holding=false;
		
			pathFound=false;	//indicate whether a path is found or not
									
			totalScore=0;	//scores for a particular game
			counter=1;		//counting how many zombies were killed
			currentWeapon=0; //defaults to knife
			currentZombie=-1;	//index for referring to a specific zombie in the zombieArray
			currentDifficulty=1;	//a general number to indicate how many times increaseDifficulty has been called
				
			return;					
		}
				
		private function createNodes()	//creating the nodes for the A* alogrithm
		{
			terrainArray1=new Array(); //1 dimension			
			terrainArray2=new Array(); //2 dimension
			
			for (var k:uint=0; k<gridSizeX; k++)			//adding arrays into 2d terrain array
				terrainArray2.push(new Array());
			
			for (var i:uint=0; i<gridSizeX; i++)			//initializing nodes required
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
			for (var i:uint=0; i<gamelevel.numChildren; i++)	//for gathering wall
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
			for (var j:uint=0; j<backdrop.numChildren; j++)		//gathering barrel references so they can be picked up
			{
				var temp2=backdrop.getChildAt(j);
				
				if (temp2 is barrel)
				{
					barrelArray.push(temp2);
					itemsArray.push(temp2);					
				}
			}		
			
			return;
		}
		private function determineWalkability()	//checking for hits and non-hits to determine whether a node is walkable
		{
			for (var i:uint=0; i<terrainArray1.length; i++)
			{
				var tempT=terrainArray1[i];
				
				for (var j:uint=0; j<wallArray.length; j++)
					if (tempT.mc.hitTestObject(wallArray[j].mc))
					{
						tempT.walkable=false;
						tempT.mc.walkable.text="X";
					}				
			}
			
			zombie.wallArrayZombie=wallArray.slice(0,wallArray.length);			//updating zombies reference
			return;
		}
		private function preparegameInfoText()	 //game info texts popups
		{
			var textformat:TextFormat=new TextFormat();
			textformat.font=fontFace.name;
			textformat.bold=fontBold;
			textformat.align="center";
						
			gameInfo.embedFonts=true;
			gameInfo1.embedFonts=true;
			gameInfo2.embedFonts=true;
			gameInfo3.embedFonts=true;
			
			gameInfo.defaultTextFormat=textformat;
			gameInfo1.defaultTextFormat=textformat;
			gameInfo2.defaultTextFormat=textformat;
			gameInfo3.defaultTextFormat=textformat;	
			
			return;
		}
		
		private function startGame()
		{	
			zombieCounter.stop();
			
			//calculating gridsizes
			gridSizeX=Math.round(gamelevel.width/(new square()).height);	
			gridSizeY=Math.round(gamelevel.height/(new square()).height);		
				
			//storing references to movieclips on stage
			heroMC=gamelevel.hero;
			hostageMC=gamelevel.Hostage;
			hostageMC.addEventListener(hostage.GAME_OVER,GameOver);
			
			//initializing static variables of each class
			zombie.attackReference=hostageMC;
			zombie.backDrop=backdrop;	
			zombie.counterWorth=1;	
			
			player.stageHeight=gamelevel.height;
			player.stageWidth=gamelevel.width;
						
			hostage.backDrop=backdrop;
			barrel.effectsMC=gamelevel;		
					
			//calling preparation functions to initialize game
			createNodes();
			gatherObstacles();
			determineWalkability();		
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
			
			//start game by starting the timers			
			zombiePathFinderTimer.start();
			zombieCreateTimer.start();			
		}		
//==============================================================checking player interactions		
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
//=====================================================================path calculation == A*
		private function calculatePath(event:TimerEvent)
		{
			if (currentZombie<0 || zombieArray.length<1)	//if no zombies or index referring to a non-existing zombie
				return;			
	
			goalCoord=new Point(getCoordinate(hostageMC.x,true),getCoordinate(hostageMC.y,false));
		
			var tempX=getCoordinate(zombieArray[currentZombie].x,true);
			var tempY=getCoordinate(zombieArray[currentZombie].y,false);		
			
			cleanseTiles();				
			addToOpenList(tempX,tempY);
			findPath();				
		}		
		private function getCoordinate(value,isX:Boolean):int
		{
			var temp=Math.floor(value/nodeSize);
			
			if (isX)
			{
				if (temp>=gridSizeX)
					temp=gridSizeX-1;
				else if (temp<0)
					temp=0;				
			}
			else
			{
				if (temp>=gridSizeY)
					temp=gridSizeY-1;
				else if (temp<0)
					temp=0;				
			}
			
			return temp;			
			
		}
		private function cleanseTiles()
		{
			zombiePathFinderTimer.removeEventListener(TimerEvent.TIMER,calculatePath);
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
				currentSquare.coordinate=findLowestFInOpenList();					
				findWalkableNearby(currentSquare.coordinate);			
			}
			targetFound();
		}
		private function findLowestFInOpenList():Point
		{
			openList.sortOn("costF",Array.NUMERIC);
						
			var tempX:int=openList[0].xx;
			var tempY:int=openList[0].yy;			
				
			return new Point(tempX,tempY);			
		}
		private function findWalkableNearby(start)	//checking the 8 squares around to determine walkability
		{
			var startSearchAt:Point=new Point(start.x-1,start.y-1);
			
			if (pathFound=addToCloseList(start))
				return;
				
			for (var i:int=startSearchAt.x; i<=start.x+1; i++)
			{
				for (var j:int=startSearchAt.y; j<=start.y+1; j++)
				{
					if (i >=0 && j>=0 && i<gridSizeX && j<gridSizeY)
					{
						if (!terrainArray2[i][j].walkable)
							continue;
						if (terrainArray2[i][j].closed)
							continue;	//path must be walkable and open
							
						calculationOfG_H_F();
					}
				}
			}			
			function calculationOfG_H_F()
			{					
				if (!terrainArray2[i][j].opened && (i!=start.x || j!=start.y))
				{
					terrainArray2[i][j].parent=terrainArray2[start.x][start.y];
				
					terrainArray2[i][j].costG=getCostG(i,j)+terrainArray2[i][j].parent.costG;
					terrainArray2[i][j].costH=getCostH(i,j);
					terrainArray2[i][j].costF=terrainArray2[i][j].costG+terrainArray2[i][j].costH;
					
					checkForDiagonalNearWall(i,j);	
					addToOpenList(i,j);
					//outputValue(i,j);		
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
											
						//outputValue(i,j);						
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
	
		private function checkForDiagonalNearWall(i,j)	//artificially making zombies detour near wall corners 
		{
			var up:Point=new Point(i,j-1);
			var down:Point=new Point(i,j+1);
			var right:Point=new Point(i+1,j);
			var left:Point=new Point(i-1,j);
			var tempArray:Array=[up,down];
		
			for (var index:int=0; index<tempArray.length; index++)
			{
				if (checkForNeg(tempArray[index]))
					continue;
												 	
				if (!(terrainArray2[tempArray[index].x][tempArray[index].y].walkable))
				{
					terrainArray2[i][j].costF*=2;
					break;
					return;
				}			
			}			
		}
		private function checkForNeg(temptemp:Point):Boolean
		{
			if (temptemp.x<0 || temptemp.x>=gridSizeX)
			{
				return true;
			}
			else if (temptemp.y<0 || temptemp.y>=gridSizeY)
				return true;
			else
				return false;
		}
		
		private function outputValue(xLoc,yLoc)	//outputting calculated values to the screen for debugging purpose
		{
			terrainArray2[xLoc][yLoc].mc.gText.text=terrainArray2[xLoc][yLoc].costG;
			terrainArray2[xLoc][yLoc].mc.hText.text=terrainArray2[xLoc][yLoc].costH;
			terrainArray2[xLoc][yLoc].mc.fText.text=terrainArray2[xLoc][yLoc].costF;
			terrainArray2[xLoc][yLoc].mc.parentText.text=terrainArray2[xLoc][yLoc].parent.xx+","+terrainArray2[xLoc][yLoc].parent.yy;
		}
		private function targetFound()//after path identified, trace it and add to zombie's path
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
			
			//setting the values for the current path info for zombie
			zombieArray[currentZombie].pathArray=pathArray.slice(0,pathArray.length);
			zombieArray[currentZombie].pathSquareIndex=pathArray.length-1;
			
			//restart the timer for path finding
			getNextZombieIndex();
			zombiePathFinderTimer.addEventListener(TimerEvent.TIMER,calculatePath);
			zombiePathFinderTimer.start();		
		}
	
		private function getNextZombieIndex()	//increase array index to access next zombie
		{						
			if (currentZombie>0)
				currentZombie--;		
			else if (zombieArray.length>0)
				currentZombie=zombieArray.length-1;
			else if (zombieArray.length==0)
				zombiePathFinderTimer.stop();
			
			return;											
		}
//===========================================================================================================================weapons & zombies		
		private function keyDown(event:KeyboardEvent)
		{
			if (event.keyCode==Keyboard.SPACE && SoundEffect.isWeaponReady())//fire when the weapon is ready by checking if sound finished playing
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
			else if (event.keyCode==Keyboard.CONTROL)
			{
				if (hostageMC.toggleFollow())
					var follow:point=new point(gamelevel,"Follow me",heroMC.x,heroMC.y-15);
				else
					var noFollow:point=new point(gamelevel,"Wait",heroMC.x,heroMC.y-15);
			}
			
			//changing weapons
			if (event.keyCode==49)//1-knife
				changeCurrentWeapon(frameClass.KNIFE);
			else if (event.keyCode==50 && availableWeapon[1])//2-pistol
				changeCurrentWeapon(frameClass.PISTOL);
			else if (event.keyCode==51 && availableWeapon[2])//3-machine gun
				changeCurrentWeapon(frameClass.MACHINEGUN);
			else if (event.keyCode==52 && availableWeapon[3])//4-shotgun
				changeCurrentWeapon(frameClass.SHOTGUN);
			else if (event.keyCode==53 && availableWeapon[4])//5-grenade
				changeCurrentWeapon(frameClass.GRENADE);
			else if (event.keyCode==54 && availableWeapon[5])//6-barrel
				changeCurrentWeapon(frameClass.BARREL);
			else if (event.keyCode==55 && availableWeapon[6])//7 mines
				changeCurrentWeapon(frameClass.MINE);
			
			//if (event.keyCode==56)							//for toggling path calculation
				//for (var i:int=0; i<terrainArray1.length; i++)
					//terrainArray1[i].mc.visible=!terrainArray1[i].mc.visible;
		}
		private function changeCurrentWeapon(toThis:int)
		{
			currentWeapon=toThis;
			updatBulletLeftDisplay();
			
			return;
		}
		private function keyRelease(event:KeyboardEvent)
		{
			if (event.keyCode==32) //checking to see if the fire key is released 
			{
				released=true;
			}
		}
		private function fireGun()
		{		
			//movieclips to store bullet mc
			var newBullet:MovieClip;
			var newBullet2:MovieClip;
			var newBullet3:MovieClip;				
			var fired:Boolean=false;
				
			if (fireKey && released) //if fired and space released 
			{
				fireKey=false;
				
				switch (currentWeapon)	//create mcs based on current weapon
				{
					case frameClass.KNIFE:	//knife
					{
						SoundEffect.playWeapon(SoundEffect.KNIFE_SOUND);
						
						newBullet=new knife(heroMC.currentLabel,heroMC.x,heroMC.y);
						fired=true;
						
						break;
					}
					case frameClass.PISTOL:	//pistol
					{
						if (pistol.totalBullets>0)
						{
							SoundEffect.playWeapon(SoundEffect.PISTOL_SOUND);
							
							newBullet=new pistol(heroMC.currentLabel,heroMC.x,heroMC.y);
							fired=true;
							
							pistol.totalBullets--;
						}
						break;
					}					
					case frameClass.SHOTGUN: //shot gun==unlimited available
					{
						if (shotGun.totalBullets>0 || shotGun.unlimited)
						{
							SoundEffect.playWeapon(SoundEffect.SHOTGUN_SOUND);
							
							newBullet=new shotGun(heroMC.currentLabel,heroMC.x,heroMC.y);
							newBullet2=new shotGun(heroMC.currentLabel,heroMC.x,heroMC.y);
							newBullet3=new shotGun(heroMC.currentLabel,heroMC.x,heroMC.y);
							fired=true;
							
							if (!shotGun.unlimited)
								shotGun.totalBullets--;
						}
						break;	
					}
					case frameClass.GRENADE: //grenade==unlimited available
					{
						if (grenade.totalBullets>0 || grenade.unlimited)
						{
							newBullet=new grenade(heroMC.currentLabel,heroMC.x,heroMC.y)
							fired=true;
							
							if(!grenade.unlimited)
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
							itemsArray.push(newBarrel);
							
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
							
							itemsArray.push(newMine);							
							mineArray.push(newMine);							
							backdrop.addChild(newMine);
													
							fired=false;
							mine.totalBullets--;							
						}
					}
				}
			}
			else if (SoundEffect.isWeaponReady() && fireKey && currentWeapon==frameClass.MACHINEGUN)	//machine is special here because no delay in firing
			{
				if (machineGun.totalBullets>0 || machineGun.unlimited)
				{
					SoundEffect.playWeapon(SoundEffect.MACHINEGUN_SOUND);
					
					newBullet=new machineGun(heroMC.currentLabel,heroMC.x,heroMC.y);
					fired=true;
					
					if (!machineGun.unlimited)
						machineGun.totalBullets--;
				}		
			}
								
			if (fired)
			{
				gamelevel.addChild(newBullet);
				bulletArray.push(newBullet);
			}
			if (currentWeapon==3 && fired && shotGun.bigShotGun)	//if is shotgun and upgrade is earned
			{
				gamelevel.addChild(newBullet2);
				gamelevel.addChild(newBullet3);
				bulletArray.push(newBullet2);
				bulletArray.push(newBullet3);
			}
			
			updatBulletLeftDisplay(false);						
		}		
		private function checkForHit()	//main collision checking function with individual objects broken down
		{
			checkForBoundary();
			checkHostageHit();
			checkZombieHit();
			checkWallHit();
			checkBarrelHit();
			checkForMineHit();
			
			function checkForBoundary()	//delete bullets if they are out of view
			{
				for (var i:int=bulletArray.length-1; i>=0; i--)
				{
					if (bulletArray[i].removed)
					{
						bulletArray.splice(i,1);
						continue;
					}
					
					if (!(bulletArray[i] is grenade)) 
						if (bulletArray[i].x>=gamelevel.width || bulletArray[i].x<=0 || bulletArray[i].y<=0 || bulletArray[i].y>=gamelevel.height)
							bulletArray[i].deleteMe();	
				}
			}
			function checkHostageHit()	//check if the hostage is hit by the bullet
			{
				for (var i:int=bulletArray.length-1; i>=0; i--)
				{
					if (bulletArray[i].removed)
					{
						bulletArray.splice(i,1);
						continue;
					}
					if (bulletArray[i].hitTestObject(hostageMC) && bulletArray[i].DAMAGE>0)//to make sure the hostage is killed by thrown grenade unless it explodes
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
						
						hostageMC.hostageAttacked(99);				//instantly kills the hostage when shot
						break;						
					}
				} 
			}			
			function checkZombieHit()	//zombie interaction with objs
			{
				nonThrowZombieCheck();		//check if bullet hits zombie
				thrownZombieCheck();		//check if thrown obj hits zombie
				
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
								var newExplosion:explosionEffect=new explosionEffect(gamelevel,bulletArray[i].x-20,bulletArray[i].y-20);
								var blast:blastRadius=new blastRadius(gamelevel,bulletArray[i].x-20,bulletArray[i].y-20,true);
								
								bulletArray[i].deleteMe();							
								bulletArray.splice(i,1,blast);
							}							
						}
											
						var tempBullet=bulletArray[i];
						
						for (var j:int=zombieArray.length-1; j>=0; j--)
						{
							if (tempBullet.hitTestObject(zombieArray[j]) && !(tempBullet is grenade))
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
									dropBox(tempx,tempy);	//drops an upgrade (10% likelihood)
									increaseScore(tempFlag);//increase score
									zombieArray.splice(j,1);//remove from zombie array
									getNextZombieIndex();	//recalculate zombie index
									
									//animation showing score
									var newPoint:point=new point(gamelevel,tempFlag,tempx,tempy);
									var newHeart:fadeSprite=new fadeSprite(gamelevel,new heart(),hostageMC.x,hostageMC.y-25,4000);
								}
							}
							else if (tempBullet.hitTestObject(zombieArray[j]) && (tempBullet is grenade))	//if grenades hits, stop and deflect 
							{								
								zombieArray[j].fallBack(.1,tempBullet.flyingDirection);								
								frameClass.changeDirection(tempBullet.flyingDirection,tempBullet.obj,true);
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
								zombieArray[j].fallBack(1,thrownArray[i].flyingDirection);
								
								thrownArray[i].speedX*=.95;
								thrownArray[i].speedY*=.95;
							}
						}
					}
				}
			}
			function checkWallHit()		//if bullet hits wall, delete it
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
			function checkBarrelHit()	//barrel hitting wall, by other bullets, 
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
			function checkForMineHit()	//for zombie hit and other blasts affects mine
			{
				for (var i:int=zombieArray.length-1; i>=0; i--)
				{					
					for (var j:int=mineArray.length-1; j>=0; j--)
					{
						if (zombieArray[i].hitTestObject(mineArray[j]))
						{
							var tempBlast=mineArray[j].trigger();
							bulletArray.push(tempBlast);
								
							mineArray[j].deleteMe();
							mineArray.splice(j,1);
							
							break;
						}					
					}
				}
				for (var k:int=bulletArray.length-1; k>=0; k--)
				{
					if (!(bulletArray[k] is blastRadius))		//only other explosions can trigger mine
						continue;
					for (var h:int=mineArray.length-1; h>=0; h--)
						if (bulletArray[k].hitTestObject(mineArray[h]))
						{							
							var Blast=mineArray[h].trigger();
												
							mineArray[h].deleteMe();
							mineArray.splice(h,1);
							
							bulletArray.push(Blast);
							break;
						}						
				}
			}
			
			return;
		}

		private function pickupItemNearby()				//pickup objects near by
		{
			for (var k:int=itemsArray.length-1; k>=0; k--)
			{
				if (itemsArray[k].removed)
				{
					itemsArray.splice(k,1);
					continue;					
				}
				
				if (itemsArray[k].hitTestObject(heroMC)) //if touching, pickup
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
		private function throwObj()						//throw obj
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
			
			frameClass.determineDirection(heroMC.currentLabel,Throw,false); //base thrown obj's direction on heroMC's direction
			thrownArray.push(Throw);
			
			currentPickup.pickedup=false;
			holding=false;									
		}
		private function animateThrow()					//controlling how the thrown objects behave
		{			
			for (var i:int=thrownArray.length-1; i>=0; i--)
			{
				if (Math.abs(thrownArray[i].speedX)<=.1 && Math.abs(thrownArray[i].speedY)<=.1)	//when speeds fall below .1, remove it from animation
				{
					thrownArray[i].speedY=0;
					thrownArray[i].speedX=0;
					thrownArray.splice(i,1);
					continue;
				}
			
				thrownArray[i].speedY*=.97;	//decreasing the speed gradually
				thrownArray[i].speedX*=.97;
							
				thrownArray[i].mc.x+=thrownArray[i].speedX;
				thrownArray[i].mc.y+=thrownArray[i].speedY;	
				thrownArray[i].mc.rotation+=Throw.speedX;						
			}
		}
//=============================================================================================================================zombie Specifc	
		private function createZombie(event:TimerEvent)//creating zombies at a set interval
		{
			if (zombieArray.length >= maxNumberOfZombies)	//prevent zombie creation beyond cap
				return;
	
			for (var i:int=numberOfZombieToCreate; i>0; i--)
			{
				var tempZombie:MovieClip=new zombie();
				var tempIndex:int=Math.floor(Math.random()*portalArray.length);
				
				tempZombie.x=portalArray[tempIndex].x;	//appear at predetermine places as set in in-frame scripts of each stage
				tempZombie.y=portalArray[tempIndex].y;
				
				gamelevel.addChild(tempZombie);
				zombieArray.push(tempZombie);
			}
			
			getNextZombieIndex();						//update zombie indexes
		}
		private function wallCollision(testArray:Array)//player and hostage wall checking function
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
		private function centerPlayer(deathAnimation:Boolean=false)	//moving the stage to center the player
		{
			var tempPoint:Point;
			
			if (!deathAnimation)
			{	
				tempPoint=new Point(heroMC.x,heroMC.y);
			
				gamelevel.x = -tempPoint.x + stage.stageWidth/2;
				gamelevel.y = -tempPoint.y + stage.stageHeight/2;
				
				backdrop.x = -tempPoint.x + stage.stageWidth/2;
				backdrop.y = -tempPoint.y + stage.stageHeight/2;		
			}
			else
			{				
				tempPoint=new Point(hostageMC.x,hostageMC.y);
				
				var tempX:Number=-tempPoint.x + stage.stageWidth/2;
				var tempY:Number=-tempPoint.y + stage.stageHeight/2;
				
				Tweener.addTween(gamelevel,{x:tempX,y:tempY,time:deathCenterTime,transition:"linear"});
				Tweener.addTween(backdrop,{x:tempX,y:tempY,time:deathCenterTime,transition:"linear"});
			}
			
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
		private function itemPickUp()								//for picking up upgrades dropped by dead zombie
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
//-----------------------------------------------------------------scores
		private function increaseScore(score)
		{
			var leadingZero:String="000000";	//adjusting score displays
			var tempScore:int=totalScore;
			
			counterIncrease();
			totalScore+=score;
			
			if (totalScore>100000)
			{
				leadingZero="";
				increaseDifficulty();
			}			
			else if (totalScore>10000)
				leadingZero="0";
			else if (totalScore>1000)
				leadingZero="00";
			else if (totalScore>100)
				leadingZero="000";
			else if (totalScore>10)
				leadingZero="0000";						
			
			scoreText.text="Score:"+leadingZero+""+totalScore;			
			checkForPrizesAndDifficulty();		
		}
		private function counterIncrease()
		{
			counter++;				//increasing counters
			adjustDecreaseSpeed();
									
			counterTimer.reset();
			counterTimer.start();
		
			updateCounter();
		}
		private function adjustDecreaseSpeed()
		{
			//decreasing counter decrease speed based on current counter
			if (counter>=30)
			{
				counterTimer.delay=counterTime/3;	
			}
			else if (counter>=20)
			{
				counterTimer.delay=counterTime/2;
			}
			else if (counter>=10)
			{
				counterTimer.delay=Math.round(counterTime/1.5);
			}
			else
				counterTimer.delay=counterTime;
		}
		private function counterDecrease(event:TimerEvent) //counter decrease fired by timer
		{
			if (counter>1)
				counter--;
			else if (counter<=1)
			{	
				counter=1;
				counterTimer.stop();
			}
					
			updateCounter();			
		}
		private function updateCounter()
		{
			zombieCounter.counterText.text="x"+counter;
			zombie.counterWorth=counter;				//update counter worth in zombie
			zombieCounter.gotoAndPlay(1);
			
			if (counter<=1)
			{	
				counter=1;
				zombie.counterWorth=1;	
				zombieCounter.counterText.text="x"+1;				
				zombieCounter.gotoAndStop(1);		
			}	
		}
//----------------------------------------------------------------support functions
		private function checkForPrizesAndDifficulty()
		{
			//awards upgrades based on player's score	
			if (totalScore>=baseScoreForPrizes*150  && !availableWeapon[6])//mines
			{
				availableWeapon[6]=true;
				gameInfoTextUpdate("Press 7 for Mines.");
				
				increaseDifficulty();
				increaseDifficulty();
				increaseDifficulty();
			}
			else if (totalScore>=baseScoreForPrizes*120 && !grenade.unlimited)
			{
				grenade.unlimited=true;
				gameInfoTextUpdate("Grenade unlimited.");
			}
			else if (totalScore>=baseScoreForPrizes*100 && !blastRadius.blastRadiusBig)//blast upgrade
			{
				blastRadius.blastRadiusBig=true;
				explosionEffect.increaseExplosionRadius();
				gameInfoTextUpdate("Blast radius increased.");								
			}
			else if (totalScore>=baseScoreForPrizes*90 && !shotGun.unlimited)
			{				
				shotGun.unlimited=true;
				gameInfoTextUpdate("Shotgun unlimited.");
			
				increaseDifficulty();				
			}
			else if (totalScore>=baseScoreForPrizes*80 && !machineGun.unlimited)//unlimited upgrade for mg
			{
				machineGun.unlimited=true;
				gameInfoTextUpdate("Machine gun unlimited.");
			
				increaseDifficulty();				
			}
			else if (totalScore>=baseScoreForPrizes*55 && !availableWeapon[5])//barrels
			{	
				availableWeapon[5]=true;				
				gameInfoTextUpdate("Press 6 for Barrels.");
				
				increaseDifficulty();
			}			
			else if (totalScore>=baseScoreForPrizes*40 && !availableWeapon[4])//grenades
			{	
				availableWeapon[4]=true;
				gameInfoTextUpdate("Press 5 for Grenades.");
				
				increaseDifficulty();
			}
			else if (totalScore>=baseScoreForPrizes*30 && !shotGun.bigShotGun)//shotgun upgrade
			{
				shotGun.bigShotGun=true;
				gameInfoTextUpdate("Shotgun upgarded.");
			
				increaseDifficulty();
			}
			else if (totalScore>=baseScoreForPrizes*17 && !availableWeapon[3])//shotguns
			{	
				availableWeapon[3]=true;
				gameInfoTextUpdate("Press 4 for ShotGun.");
				
				increaseDifficulty();
			}
			else if (totalScore>=baseScoreForPrizes*7 && !availableWeapon[2])//machine gun
			{
				availableWeapon[2]=true;
				gameInfoTextUpdate("Press 3 for Machine Gun.");
				
				increaseDifficulty();
			}
			else if (totalScore>=baseScoreForPrizes && !availableWeapon[1])//pistol
			{
				availableWeapon[1]=true;
				gameInfoTextUpdate("Press 2 for Pistol.");
				
				increaseDifficulty();
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
				case frameClass.MACHINEGUN:
				{
					if (machineGun.unlimited)
						bulletCount="1/0";
					else
						bulletCount=String(machineGun.totalBullets);
	
					string="machine gun.";
					break;	
				}
				case frameClass.SHOTGUN:
				{
					if (shotGun.unlimited)
						bulletCount="1/0";
					else
						bulletCount=String(shotGun.totalBullets);
					string="shotgun.";
					break;	
				}
				case frameClass.GRENADE:
				{					
					if (grenade.unlimited)
						bulletCount="1/0";
					else
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
			if (Math.random()>.9)	//a 10% probability for dropping upgrade for any zombie killed
			{
				var newCrate=new crate(gamelevel,tempx,tempy);
				dropCrate.push(newCrate);
			}	
		}
		private function increaseWeaponBulletBy(totalAmount)	//increasing inventory with picked up boxes
		{			
			while (totalAmount!=0)
			{
				var randomIncrease:int=Math.round(Math.random()*6+1);
				
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
						if (shotGun.bulletCountMax!=shotGun.totalBullets && availableWeapon[3]
							&& !shotGun.unlimited)
						{
							shotGun.increaseBulletCount(totalAmount);
							gameInfoTextUpdate("Picked up shotgun.");
							totalAmount=0;
						}
						break;						
					}
					case 3:
					{
						if (grenade.bulletCountMax!=grenade.totalBullets && availableWeapon[4]
							&& !grenade.unlimited)
						{
							grenade.increaseBulletCount(totalAmount);
							gameInfoTextUpdate("Picked up grenades.");
							totalAmount=0;
						}
						break;						
					}
					case 4:
					{
						if (barrel.bulletCountMax!=barrel.totalBullets && availableWeapon[5])
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
						if (mine.bulletCountMax!=mine.totalBullets && availableWeapon[6])
						{
							mine.totalBullets+=totalAmount;
							
							if (mine.totalBullets>mine.bulletCountMax)
								mine.totalBullets=mine.bulletCountMax;
							
							gameInfoTextUpdate("Picked up mines.");
							totalAmount=0;					
						}
						break;
					}
					case 6:
					{
						if (machineGun.bulletCountMax!=machineGun.totalBullets 
						&& availableWeapon[2] && !machineGun.unlimited)
						{
							shotGun.increaseBulletCount(totalAmount);
							gameInfoTextUpdate("Picked up machine gun.");
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
		private function showFlash()	//show flash for explosion
		{
			var newFlash=new whiteBox();
							
			newFlash.x=250;
			newFlash.y=200;
			stage.addChild(newFlash);			
			Tweener.addTween(newFlash,{alpha:0,time:2,onComplete:removeMeFromStage,onCompleteParams:[newFlash]});		
		}		
		private function increaseDifficulty()	//increasing zombie health and speed
		{
			zombie.difficulty+=increaseZombieSpeedBy;
			zombie.globalHealth+=increaseZombieHealthBy;
			
			gameInfoTextUpdate("Current level: "+currentDifficulty++);
			
			if (currentDifficulty>=10)
				zombie.chaseEnabled=true;
				
			if (currentDifficulty>=30)
				zombieCreateTimer.delay=zombieSpawnDelayLv3;
			else if (currentDifficulty>=20)
				zombieCreateTimer.delay=zombieSpawnDelayLv2;
			
			return;
		}
//------------------------------------------------gameplay manage
		private function removeMeFromStage(me)		//a general cleanup function
		{
			stage.removeChild(me);
		}
		private function gameInfoTextUpdate(message:String)	//text message showing player info
		{
			if (!Tweener.isTweening(gameInfo))
			{
				gameInfo.text=message;
				tweenThisGameInfoBox(gameInfo);				
			}
			else if (!Tweener.isTweening(gameInfo1))
			{
				gameInfo1.text=message;
				tweenThisGameInfoBox(gameInfo1);
			}
			else if (!Tweener.isTweening(gameInfo2))
			{
				gameInfo2.text=message;
				tweenThisGameInfoBox(gameInfo2);
			}
			else if (!Tweener.isTweening(gameInfo3))
			{
				gameInfo3.text=message;
				tweenThisGameInfoBox(gameInfo3);				
			}			
		}
		private function tweenThisGameInfoBox(obj)
		{
			var currentBoxNum:int=findOpenPosition();
			Tweener.addTween(obj,{y:gameInfoTextPosition.y-obj.height*currentBoxNum,time:1,transition:"linear"});
			Tweener.addTween(obj,{alpha:0,y:-gameInfo.height,time:.5,delay:gameInfoDisplayTimer,onComplete:gameInfoTextClean,onCompleteParams:[obj,currentBoxNum]});
			
			return;
		}
		private function gameInfoTextClean(thisBox,number)		//clean out textboxes
		{
			thisBox.text="";
			thisBox.alpha=1;
			thisBox.y=gameInfoTextPosition.x;
			restoreOpenPosition(number);
			
			return;					
		}
		private function findOpenPosition():int					//returns the position available for info output
		{
			for (var i:int=0; i<boxOccupied.length; i++)
				if (!boxOccupied[i])
				{
					boxOccupied[i]=true;
					return i;
				}		
			return -1;
		}
		private function restoreOpenPosition(index:int)
		{
			boxOccupied[index]=false;
			return;
		}
		
		private function GameOver(event:Event)	//an event dispatched by hostage class to indicate game over
		{
			SoundEffect.playZombie(SoundEffect.HOSTAGE_DEATH_SOUND);
			
			stopGame();
								
			centerPlayer(true);	//used to center the camera on the dead hostage
			displayEndMessage();
		}
		private function stopGame()
		{
			removeEventListener(Event.ENTER_FRAME,mainLoop);	//removing event listeners and stop timers
			
			zombieCreateTimer.stop();
			zombiePathFinderTimer.stop();
			counterTimer.stop();
						
			zombieCreateTimer.removeEventListener(TimerEvent.TIMER,createZombie);
			zombiePathFinderTimer.removeEventListener(TimerEvent.TIMER,calculatePath);
			counterTimer.removeEventListener(TimerEvent.TIMER,counterDecrease);
			
			stage.removeEventListener(KeyboardEvent.KEY_DOWN,keyDown);
			stage.removeEventListener(KeyboardEvent.KEY_UP,keyRelease);
			heroMC.gameIsOver();
						
			
			switch(currentLevel)						//putting the score into appropriate variable for r
			{
				case "stage1":
					highScoreVariable.stage1=totalScore;
					break;
				case "stage2":
					highScoreVariable.stage2=totalScore;
					break;
				case "stage3":
					highScoreVariable.stage3=totalScore;
					break;
			}
								
		}
		private function displayEndMessage()
		{				
			over=new GAME_OVER();					//putting dead mark onto the stage
			over.x=stage.stageWidth/2;
			over.y=stage.stageHeight/2-over.height/2;
			over.alpha=0;
			
			back=new backBtn();						//display a back btn
			back.alpha=0;
			back.x=stage.stageWidth/2;
			back.y=350;
			
			addChild(back);
			addChild(over);						
						
			zombieCounter.visible=false;
			
			back.addEventListener(MouseEvent.CLICK,goBackToMenu);	
			
			Tweener.addTween(over,{alpha:1,time:3,delay:2});
			Tweener.addTween(back,{alpha:1,time:3,delay:2});
		}
		private function goBackToMenu(event:MouseEvent)
		{
			for (var i:int=terrainArray1.length-1; i>=0; i--)	//removing the tiles
				gamelevel.removeChild(terrainArray1[i].mc);		
			for (var j:int=zombieArray.length-1; j>=0; j--)		//removing the zombies
				zombieArray[j].cleanupZombie();
			
			back.removeEventListener(MouseEvent.CLICK,goBackToMenu);	//remove btn listener
			
			removeChild(back);
			removeChild(over);
			
			initialize();										//re-initialize variables for next game
			
			Tweener.removeAllTweens();
			gotoAndStop("stageChooser");
		}
	}
}



























