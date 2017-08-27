package old.importerStrategy 
{
	/**
	 * ...
	 * @author Shatalov Andrey
	 */
	public final class BitmapStageImporter implements IImporter 
	{
		//{ region ------------------------ Константы
		public static const NAME:String = 'BitmapStageImporter';
		/**наименование класса для Debug-а */
		private const _TITLE_CLASS:String = "["+NAME+"] ";
		//} endregion --------------------- Константы
		//{ region ------------------------ Свойства
		
		//} endregion --------------------- Свойства
		//{ region ------------------------ Геттеры и сеттеры
		
		//} endregion --------------------- Геттеры и сеттеры
		
		public function BitmapStageImporter() 
		{
			
		}
		
		//{ region ------------------------ Public metods		
		/* INTERFACE old.importerStrategy.IImporter */
		
		public function CreateMovieClip():* 
		{
			
		}
		
		public function CreateImage():* 
		{
			
		}
		
		public function CreateSprite():* 
		{
			
		}
		
		public function CreateTexfield():* 
		{
			
		}
		
		//} endregion --------------------- Public metods		
		//{ region ------------------------ Private metods
		
		//} endregion --------------------- Private metods
	}

}