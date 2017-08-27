package old.importerStrategy 
{
	
	/**
	 * Интерфейс для стратегии импортера
	 * @author Shatalov Andrey
	 */
	public interface IImporter 
	{
		function CreateMovieClip():*
		function CreateImage():*
		function CreateSprite():*
		function CreateTexfield():*
	}
	
}