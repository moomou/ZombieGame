package
{
	import caurina.transitions.*;
	import flash.display.MovieClip;
	
	public class deathBlood extends MovieClip
	{
		public function deathBlood()
		{
			Tweener.addTween(this,{alpha:0,time:10,onComplete:deleteMe,transition:"linear"});
		}
		private function deleteMe()
		{
			this.parent.removeChild(this);
			delete this;
		}

	}
}