package old.importerStrategy 
{
	/**
	 * ...
	 * @author Shatalov Andrey
	 */
	public final class StarlingImporter implements IImporter 
	{
		//{ region ------------------------ Константы
		public static const NAME:String = 'StarlingImporter';
		/**наименование класса для Debug-а */
		private const _TITLE_CLASS:String = "["+NAME+"] ";
		//} endregion --------------------- Константы
		//{ region ------------------------ Свойства
		
		//} endregion --------------------- Свойства
		//{ region ------------------------ Геттеры и сеттеры
		
		//} endregion --------------------- Геттеры и сеттеры
		
		public function StarlingImporter() 
		{
			
		}
		
		//{ region ------------------------ Public metods
		function CreateMovieClip():*
		{
			return null; //заглушка
		}
		function CreateImage():*
		{
			return null; //заглушка
		}

		function CreateSprite():*
		{
			return null; //заглушка
		}

		function CreateTexfield():*
		{
			return null; //заглушка
		}

		//} endregion --------------------- Public metods		
		//{ region ------------------------ Private metods
		
		//} endregion --------------------- Private metods
	}

}