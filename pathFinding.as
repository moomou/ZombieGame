package
{
	import flash.display.MovieClip;
	import flash.events.*;
	import flash.geom.Point;
	
	public class pathFinding extends MovieClip
	{
		private static const lineCost:int=10;
		private static const diagonalCost:int=14;
		static const nodeSize=50;
		
		private var terrainArray1:Array=new Array(); //1 dimension
		private var terrainArray2:Array=new Array(); //2 dimension
		private var itemsArray:Array=new Array();
		
		private var openList:Array=new Array();	//for A* operation
		private var closeList:Array=new Array();
		
		private var currentScore:Object=new Object();
		
		private var currentSquare:Object=new Object();
		
		private var goalCoord:Point=new Point(9,9);		//set to a const at this time
		private var gridSizeX:Number=Math.floor(stage.stageWidth/nodeSize);
		private var gridSizeY:Number=Math.floor(stage.stageHeight/nodeSize);
		
		public function pathFinding()
		{
			for (var i:uint=0; i<10; i++)			//adding arrays into 2d terrain array
				terrainArray2.push(new Array());
			
			gatherItems();
			setSquares();
			determineWalkability();
			
			addToOpenList(0,0);				//hard coded here;
			findPath();
			
			stage.addEventListener(MouseEvent.CLICK,findNextSquare);		
		}
		private function gatherItems()
		{
			for (var i:uint=0; i<gamelevel.numChildren; i++)
			{
				var temp=gamelevel.getChildAt(i);
				if (temp is wall)
				{
					itemsArray.push(temp);
				}
			}
		}
		private function setSquares()
		{
			//placing squares
			for (var i:uint=0; i<10; i++)
			{
				for (var j:uint=0; j<10; j++)
				{
					var temp=new Object();
					temp.mc=new square();
					temp.mc.x=i*50;
					temp.mc.y=j*50;
					temp.mc.walkable.text=(i)+","+(j);
					
					temp.costG=0;
					temp.costH=0;
					temp.costF=0;
					temp.xx=i;
					temp.yy=j;
					
					temp.closed=false;
					temp.opened=false;
					temp.walkable=true;				
					
					terrainArray2[i][j]=temp;
					terrainArray1.push(terrainArray2[i][j]);
					addChild(temp.mc);
				}
			}
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
		private function determineWalkability()
		{
			for (var i:uint=0; i<terrainArray1.length; i++)
			{
				var tempT=terrainArray1[i];
				
				for (var j:uint=0; j<itemsArray.length; j++)
				{
					if (tempT.mc.hitTestObject(itemsArray[j]))
					{
						tempT.walkable=false;
						tempT.mc.walkable.text="X";
					}
				}
			}
		}
				
		private function findPath()
		{
			currentSquare.coordinate=findLowestFInOpenList();					
			findWalkableNearby(currentSquare.coordinate);						
		}		
		private function findWalkableNearby(start)
		{
			var startSearchAt:Point=new Point(start.x-1,start.y-1);
			
			if (addToCloseList(start))
			{				
				targetFound();
				return;
			}	
			
			for (var j:int=startSearchAt.y; j<=start.y+1; j++)
			{
				for (var i:int=startSearchAt.x; i<=start.x+1; i++)
				{
					if (i >=0 && j>=0 && i<gridSizeX && j<gridSizeY)
					{
						if (!terrainArray2[i][j].walkable)
							continue;
						if (terrainArray2[i][j].closed)
							continue;	//th
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
					
						//checkForDiagonalNearWall();	
						outputValue(i,j);						
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
				//removing from open list
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
		private function findLowestFInOpenList():Point
		{
			var tempX:int=0;
			var tempY:int=0;			
			var tempF:int=0;
			
			openList.sortOn("costF",Array.NUMERIC);
			//trace(openList.length)
			tempX=openList[0].xx;
			tempY=openList[0].yy;
			
			return new Point(tempX,tempY);			
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
		private function checkForDiagonalNearWall(i,j)
			{
				var currentlyChecking:Point=new Point(i,j);
				
				var up:Point=new Point(i,j-1);
				var down:Point=new Point(i,j+1);
				//var right:Point=new Point(i+1,j);
				//var left:Point=new Point(i-1,j);
				var tempArray:Array=[up,down];
				
					trace("");
					trace("");
			trace("current:"+currentlyChecking);
			trace("up:"+up);
			trace("down:"+down);
			//trace("right:"+right);
			//trace("left:"+left);
			
			
				for (var index:int=0; index<tempArray.length; index++)
				{
					if (checkForNeg(tempArray[index]))
						continue;
													 	
					if (!(terrainArray2[tempArray[index].x][tempArray[index].y].walkable))
					{
						trace("----Found----");
					trace("At: "+tempArray[index]);
					trace("-------------");
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
		private function outputValue(xLoc,yLoc)
		{
			terrainArray2[xLoc][yLoc].mc.gText.text=terrainArray2[xLoc][yLoc].costG;
			terrainArray2[xLoc][yLoc].mc.hText.text=terrainArray2[xLoc][yLoc].costH;
			terrainArray2[xLoc][yLoc].mc.fText.text=terrainArray2[xLoc][yLoc].costF;
			terrainArray2[xLoc][yLoc].mc.parentText.text=terrainArray2[xLoc][yLoc].parent.xx+","+terrainArray2[xLoc][yLoc].parent.yy;
		}
		private function targetFound()
		{
			//trace('found');
			stage.removeEventListener(MouseEvent.CLICK,findNextSquare);
			showPath();
		}
		private function showPath()
		{
			var parentX=goalCoord.x;
			var parentY=goalCoord.y;
					
			while (terrainArray2[parentX][parentY].parent!=undefined)
			{
				terrainArray2[parentX][parentY].parent.mc.gotoAndStop(4);
				
				var tempX=terrainArray2[parentX][parentY].parent.xx;
				var tempY=terrainArray2[parentX][parentY].parent.yy;
				
				parentX=tempX;
				parentY=tempY;				
			}
		}
	
		private function findNextSquare(event:Event)
		{
			findPath();			
		}
	
	
	}
}



















