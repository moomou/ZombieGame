package
{
	//need to make a font and linkage for actionscript
	//a class used to show fading texts
	
	import flash.display.*;
	import flash.events.*;
	import flash.text.*;
	import flash.utils.*;
	
	public class point extends Sprite
	{
		// text style
		static const myfontFace=new Arial();
		static const fontSize:int = 35;
		static const fontBold:Boolean = true;		
		static const time:Number=30;
		
		// animation
		static const animSteps:int = 50;
				
		static const startScale:Number = 0;
		static const endScale:Number = 2.0;
		
		private var tField:TextField;
		private var bSprite:Sprite;
		private var parentMC:MovieClip;
		private var animTimer:Timer;
		
		private var animStepTime:int;
				
		public function point(mc:MovieClip,pt:Object,x,y:Number,fontColor:Number=0xFFFFFF)
		{
			var textformat:TextFormat=new TextFormat();
			textformat.font=myfontFace.name;
			textformat.size=fontSize;
			textformat.bold=fontBold;
			textformat.color=fontColor;
			textformat.align="center";

			animStepTime=time;
			
			tField=new TextField();
			tField.embedFonts=true;
			tField.defaultTextFormat=textformat;
			tField.selectable=false;
			tField.autoSize = TextFieldAutoSize.CENTER;
			tField.text = String(pt);
			tField.x = -(tField.width/2);
			tField.y = -(tField.height/2);
			
			bSprite=new Sprite();
			bSprite.x=x;
			bSprite.y=y;
			bSprite.alpha=0;
			bSprite.scaleX=startScale;
			bSprite.scaleY=startScale;
			
			bSprite.addChild(tField);
			parentMC=mc;
			parentMC.addChild(bSprite);
			
			animTimer=new Timer(animStepTime,animSteps);
			animTimer.addEventListener(TimerEvent.TIMER,animation);
			animTimer.addEventListener(TimerEvent.TIMER_COMPLETE,remove);
			animTimer.start();			
		}
		
		private function animation(event:TimerEvent)
		{
			var percentDone:Number=event.target.currentCount/animSteps;
			
			bSprite.scaleX = (1.0-percentDone)*startScale + percentDone*endScale;
			bSprite.scaleY = (1.0-percentDone)*startScale + percentDone*endScale;
			bSprite.alpha = 1.0-percentDone;
			
		}
		private function remove(event:Event)
		{
			bSprite.removeChild(tField);
			parentMC.removeChild(bSprite);
			bSprite=null;
			parentMC=null;
			delete this;
		}
	}
}