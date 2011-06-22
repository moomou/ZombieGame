package
{
	//3 channels; 1 for background, 1 for sound effects, and 1 for marking
	import caurina.transitions.*;
	
	import flash.events.Event;
	import flash.media.Sound;
	import flash.media.SoundChannel;
		
	public class SoundEffect extends Sound
	{			
		//different weapon sounds
		public static const KNIFE_SOUND:Sound=new knifeSound();
		public static const PISTOL_SOUND:Sound=new pistolSound();
		public static const MACHINEGUN_SOUND:Sound=new machineGunSound();
		public static const SHOTGUN_SOUND:Sound=new shotGunSound();
		
		//explosion sounds
		public static const GRENADE_SOUND:Sound=new grenadeSound();
		public static const BARREL_SOUND:Sound=new barrelSound();
		
		public static const ZOMBIE_ATTACK_SOUND:Sound=new zombieAttackSound();
		public static const ZOMBIE_HIT_SOUND:Sound=new zombieHitSound();
		public static const ZOMBIE_DEATH_SOUND:Sound=new zombieDeathSound();
		public static const HOSTAGE_DEATH_SOUND:Sound=new deathSound();
				
		//sound channels
		private static var stageChannel:SoundChannel=new SoundChannel(); //stage sound effects
		private static var weaponChannel:SoundChannel=new SoundChannel();	//marking sound effect
		private static var zombieChannel:SoundChannel=new SoundChannel();
		
		private static var currentSoundWeapon:Sound=null;
		private static var currentSoundStage:Sound=null;
		private static var currentZombieSound:Sound=null;
			
		private static var soundOn:Boolean=true;	
		
		public static function isWeaponReady():Boolean
		{
			if (currentSoundWeapon==null)
				return true;
			else
				return false;
		}
		
		
		public function SoundEffect()	//warning that no instance should be created
		{
			trace("Not to be instantiated.");
		}	
		public static function soundToggle()	//turning sound on and off
		{
			soundOn=!soundOn;							
		}		
		public static function stopWeapon()	//weapon sound
		{			
			if (weaponChannel!=null)
				weaponChannel.stop();					
			currentSoundWeapon=null;				
		}	
		public static function stopStage()	//stage sound
		{
			if (stageChannel!=null)
				stageChannel.stop();
			currentSoundStage=null;
		}
		public static function stopZombie()//zombies
		{
			if (zombieChannel!=null)
				zombieChannel.stop();
			currentZombieSound=null;			
		}
		public static function playWeapon(sound:Sound)	//get the weapon channel to play
		{
			if (!soundOn)						//if sound is off, don't play
				return;
				
			if (currentSoundWeapon!=sound)		//only play if current sound is different
			{
				if (weaponChannel!=null)		//stops the channel if playing
					weaponChannel.stop();
				
				currentSoundWeapon=sound;
			
				if (currentSoundWeapon!=null)	//play
				{
					weaponChannel=currentSoundWeapon.play();
					weaponChannel.addEventListener(Event.SOUND_COMPLETE,stopAll);				
				}	
			}			
		}
		public static function playStage(sound:Sound)
		{
			if (!soundOn)
				return;
				
			if (currentSoundStage!=sound)
			{
				if (stageChannel!=null)
					stageChannel.stop();
				
				currentSoundStage=sound;
				
				if (currentSoundStage!=null)
				{
					stageChannel=currentSoundStage.play();
					stageChannel.addEventListener(Event.SOUND_COMPLETE,stopAll);
				}
			}		
		}	
		public static function playZombie(sound:Sound)
		{
			if (!soundOn)
				return;
				
			if (currentZombieSound!=sound)
			{
				if (zombieChannel!=null)
					zombieChannel.stop();
					
				currentZombieSound=sound;
				
				if (zombieChannel!=null)
				{
					zombieChannel=currentZombieSound.play();
					zombieChannel.addEventListener(Event.SOUND_COMPLETE,stopAll);	
				}
			}			
		}
		private static function stopAll(event:Event)	//stops the sound channel after sound completes
		{
			var channelToStop=event.target;
			
			if (channelToStop==stageChannel)
				stopStage();
			else if (channelToStop==weaponChannel)
				stopWeapon();
			else if (channelToStop==zombieChannel)
				stopZombie();		
		}	
	}
}
