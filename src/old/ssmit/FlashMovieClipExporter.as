/**
 * @author Shane Smit <Shane@DigitalLoom.org>
 * 
 * @version 1.4
 */
package old.ssmit
{
	import fl.text.TCMText;
	import fl.text.TLFTextField;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.FrameLabel;
	import flash.display.MovieClip;
	import flash.display.Scene;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.text.TextFormat;

	public final class FlashMovieClipExporter
	{
		private static const VERSION		: String	= "1.4";
		
		private static var _textureList		: TextureList;
		private static var _objectsXML		: XML;
		
		// Extracts the frameInformation and big Bitmaps from a Flash MovieClip. 
		public static function exportAll( flashMC:flash.display.MovieClip, outAtlases:Vector.<BitmapData>, sortBitmaps:Boolean=true ) : XML
		{
			_textureList = new TextureList();
			_objectsXML = <objects />;
			
			exportRecursive( flashMC, true );
			
			var clipData:XML = <clipData />;
			clipData.@version = VERSION;
			//clipData.@frameRate = flashMC.loaderInfo.frameRate || flashMC.root.loaderInfo.frameRate || 60;
			clipData.@frameRate = 60;
			clipData.appendChild( _objectsXML );
			
			var regionInfo:XML = <atlases />;
			var outBitmaps:Vector.<BitmapData> = _textureList.exportTextureAtlases( regionInfo, sortBitmaps );
			clipData.appendChild( regionInfo );
			
			for( var i:int=0; i<outBitmaps.length; ++i )
				outAtlases.push( outBitmaps[ i ] );
			
			_textureList.dispose();
			_textureList = null;
			_objectsXML = null;
			
			return clipData;
		}
		
		/**
		 * Растрирует мувиклипы, расположенные на главной сцене.
		 * Все целевые клипы должны находиться на первом кадре. Желательно, чтобы больше ничего не было кроме них.
		 * @param	stageMC
		 * @param	outAtlases
		 * @param	sortBitmaps по умолчанию сортирует битмапы
		 * @return
		 */
		public static function ExportFromMC (stageMC:DisplayObjectContainer, sortBitmaps:Boolean = true ) : XML
		{
			return ExportClipData(function ExportMethod():void
			{
				//stageMC.gotoAndStop(1);
				for (var i:int = 0, size:int = stageMC.numChildren; i < size; i++) 
				{
					var mc:DisplayObject = stageMC.getChildAt(i);
					if (mc is flash.display.MovieClip /*|| mc is Sprite*/) 
					{
						var name:String = String(mc).replace(new RegExp('(\\[class |\\[object |\\])', 'g'), '');					
						exportRecursive(mc, true, name); //сразу добавляет в созданный объект в _objectsXML
						trace('Exporting complte: ' + name);
					}
				}
			},sortBitmaps);
		}
		
		/**
		 * Растрирует мувиклипы, расположенные в виде вектора с их определениями
		 * @param	flashMC вектор с определениями мувиклипов. Задаается через new, далее шаблон вектора и массив определений.
		 * @param	outAtlases
		 * @param	sortBitmaps по умолчанию сортирует битмапы
		 * @return
		 * 
		 * <p>Вектор задается  "new <Class>[...]"</p>
		 */
		public static function ExportMC (flashMC:Vector.<Class>, sortBitmaps:Boolean = true ) : XML
		{
			return ExportClipData(function ExportMethod():void
			{
				for (var i:int = 0, size:int = flashMC.length; i < size; i++)
				{
					var name:String = String(flashMC[i]);
					name = name.replace(new RegExp('(\\[class |\\])', 'g'), '');
					exportRecursive( DisplayObject(new flashMC[i]), true, name); //сразу добавляет созданный объект в _objectsXML
					trace('Exporting complte: ' + name);
				}
			},sortBitmaps);
		}
		
		private static function ExportClipData(ExportMethod:Function, sortBitmaps:Boolean = true) : XML
		{
			_textureList = new TextureList();
			_objectsXML = <objects />;
			
			ExportMethod();
			
			var clipData:XML = <clipData />;
			clipData.@frameRate = 60;//FIXME исправить устанавливаемый фреймрейт на текущий
			clipData.@version = VERSION;
			clipData.appendChild( _objectsXML );
			
			//CreateTextureAtlases(clipData, sortBitmaps);			
			return clipData;
		}
		
		public static function AppendTo(clipData:XML, stageMC:DisplayObjectContainer, sortBitmaps:Boolean = true) : XML
		{
			//_textureList = new TextureList();
			_objectsXML = clipData.objects[0]; //ссылка на ранее заполненный список объектов
			
			for (var i:int = 0, size:int = stageMC.numChildren; i < size; i++) 
			{
				var mc:DisplayObject = stageMC.getChildAt(i);
				if (mc is flash.display.MovieClip || mc is Sprite) 
				{
					var name:String = String(mc).replace(new RegExp('(\\[class |\\[object |\\])', 'g'), '');					
					exportRecursive(mc, true, name); //сразу добавляет в созданный объект в _objectsXML
					trace('Exporting complte: ' + name);
				}
			}
			
			return clipData;
		}
		
		/**
		 * 
		 * @param	clipData
		 * @param	fontXML
		 * @param	fontBitmap
		 */
		public static function AppendFontTo(clipData:XML, fontBitmap:Bitmap, name:String): XML
		{
			_objectsXML = clipData.objects[0]; //ссылка на ранее заполненный список объектов
			exportRecursive(fontBitmap, true, name);			
			
			return clipData;
		}
		
		/**
		 * Функция создает из собранный данных текстурые атласы и записывает информацию о них в clipData
		 * По завершению работы функции чистятся все статичные переменные. Если будет необходимо в разных местах программы
		 * дополнять атласы объектами, то эту функцию нужно вызывать после завершения добавления информации об объектах.
		 * @param	clipData
		 * @param	sortBitmaps
		 * @return  Vector.<BitmapData> массив, где элемент данные аталаса.
		 */
		public static function CreateTextureAtlases(clipData:XML, sortBitmaps:Boolean = true):Vector.<BitmapData>
		{
			var regionInfo:XML = <atlases />;
			var outBitmaps:Vector.<BitmapData> = _textureList.exportTextureAtlases( regionInfo, sortBitmaps );
			clipData.appendChild( regionInfo );
			
			var outAtlases:Vector.<BitmapData> = new Vector.<BitmapData>();
			for( var i:int=0; i<outBitmaps.length; ++i ) outAtlases.push( outBitmaps[ i ] );
			
			_textureList.dispose();
			_textureList = null;
			_objectsXML = null;
			
			return outAtlases;
		}
		
		// Walks though a Flash DisplayObject and extracts it's frame information (and it's children) to XML.
		private static function exportRecursive( displayObject:DisplayObject, ignoreTotalFrames:Boolean=false, forceName:String = null ) : XML
		{
			var objectXML:XML = <object />;
				
			// Assign common properties.
			objectXML.@name = forceName || displayObject.name; 
			if( displayObject.alpha != 1 )
				objectXML.appendChild( <alpha>{ displayObject.alpha }</alpha> );
			if( displayObject.transform.matrix.a != 1
			 || displayObject.transform.matrix.b != 0
			 || displayObject.transform.matrix.c != 0
			 || displayObject.transform.matrix.d != 1 )
			{
				var transformXML:XML = <transform />;
				transformXML.@a = displayObject.transform.matrix.a;
				transformXML.@b = displayObject.transform.matrix.b;
				transformXML.@c = displayObject.transform.matrix.c;
				transformXML.@d = displayObject.transform.matrix.d;
				transformXML.@tx = displayObject.transform.matrix.tx;
				transformXML.@ty = displayObject.transform.matrix.ty;
				objectXML.appendChild( transformXML );
			}
			else if( displayObject.x != 0 || displayObject.y != 0 )
			{
				var positionXML:XML = <position />;
				positionXML.@x = displayObject.x;
				positionXML.@y = displayObject.y;
				objectXML.appendChild( positionXML );
			}
			
			if( displayObject is flash.display.DisplayObjectContainer )
			{
				var container:flash.display.DisplayObjectContainer = displayObject as flash.display.DisplayObjectContainer;
				
				if( container is flash.display.MovieClip && ( ignoreTotalFrames || (container as flash.display.MovieClip).totalFrames > 1 ) )
				{
					objectXML.@type = "movie clip";			
					
					//это код полезен для исключения дублирования корневых объектов
					//var mcXML:* = _objectsXML.object.(@name == objectXML.@name); //TODO необходим аудит. Лучше сначала получить стабильную версию игры, а потом дорабатывать экспортер
					//if (mcXML.length() > 0) {
						////trace('4:Есть совпадение по мувиклипу:'/*, _objectsXML.object.(@name == objectXML.@name)*/);
						//return mcXML[0];//BUG видимо баг. Если объект с таким же именем и таким же типом создавался где-то еще, то объект не будет экспортирован в текущую ветвь. 
					//}
					
					var movieClip:MovieClip = container as flash.display.MovieClip;
					
					var isFlippFrames:Boolean = false;
					if (movieClip is FlippedMovieClip) isFlippFrames = true;
					
					var frameData:FrameData = FrameData.importFromFlashMovieClip( movieClip, exportFrameObject, isFlippFrames );
					
					objectXML.appendChild( frameData.exportToXML() );
					objectXML.appendChild( exportSceneData( movieClip ) );
				}
				else if (container is fl.text.TCMText)
				{
					objectXML.@type = 'sprite';
					var childrenXML:XML = <children />;
					
					var bitmapData:BitmapData = new BitmapData(container.width, container.height,true, 0);
					bitmapData.draw(container);
					var bitmap:Bitmap = new Bitmap(bitmapData);
					
					var childXML:XML = exportRecursive( bitmap );
					childrenXML.appendChild( <child object={ childXML.childIndex() } name = {childXML.@name.toString()}/> );
					
					objectXML.appendChild( childrenXML );
				} 
				else if (container is TLFTextField) 
				{
					//
					//objectXML.@type = "ignore";
					objectXML.@type = "text field";
					var tf:TLFTextField = container as TLFTextField;
					
					var textDataXML:XML = <data />;
					objectXML.appendChild(textDataXML);
					textDataXML.@text = tf.text;
					textDataXML.@color = tf.textColor;
					textDataXML.@font  = tf.getTextFormat().font;
					textDataXML.@size = tf.getTextFormat().size;
					textDataXML.@tw = tf.width;
					textDataXML.@th = tf.height;
					textDataXML.@italic = tf.getTextFormat().italic || false;
					textDataXML.@bold = tf.getTextFormat().bold || false;					
					textDataXML.@align = tf.getTextFormat().align == null? "left" : tf.getTextFormat().align;
					//textDataXML.@align = tf.getTextFormat().align;//TODO разобраться как в некоторых случаях получать точное значение align. В общих случаях будет передано Null
					textDataXML.@autoSize = tf.autoSize;
					//TODO добавить фильтры
				}
				else
				{
					objectXML.@type = "sprite";
					
					//var childrenXML:XML = <children />;
					childrenXML = <children />;
					
					// Add the children to the new Starling Sprite.
					for( var i:int=0; i<container.numChildren; ++i ) 
					{
						var child:DisplayObject = container.getChildAt( i );
						//var childXML:XML = exportRecursive( child );
						childXML = exportRecursive( child );
//						childrenXML.appendChild( <child idref={ childXML.@id } /> );
						childrenXML.appendChild( <child object={ childXML.childIndex() } name = {childXML.@name.toString()}/> );//в подобных местах мы даем ссылку на используемый объект
					}
					
					objectXML.appendChild( childrenXML );
				}
			}
			else
			{
				if( displayObject is Shape || displayObject is Bitmap )
				{
					objectXML.@type = "image";
					
					var bitmapInfo:BitmapInfo = _textureList.getBitmapInfoFromDisplayObject( displayObject ); //видимо сдесь создается графика
					
					var objectRect:Rectangle = displayObject.getBounds( displayObject );
					var imagePosX:Number = displayObject.x + objectRect.left;
					var imagePosY:Number = displayObject.y + objectRect.top;
					
					if( imagePosX != 0 || imagePosY != 0 )
					{
						if( positionXML == null )
						{
							positionXML = <position />;
							objectXML.appendChild( positionXML );
						}
						positionXML.@x = imagePosX; 
						positionXML.@y = imagePosY;
					}
					
					if( bitmapInfo._xmlList == null )
						bitmapInfo._xmlList = new <XML>[];
					bitmapInfo._xmlList.push( objectXML );
					
					//TODO Проверить не существует ли подобного объекта в базе
					//если существует, нужно удалить этот и вернуть ссылку на ранее созданный объект
					//!!!Бесполезно оптимизировать размещение объектов, пока не научусь создавать глубокие копии всех объектов
					//var imagesXML:XMLList = _objectsXML.object.(@type == "image");
					//for (var j:int = 0, size:int = imagesXML.length(); j < size; j++) 
					//{
						//var obj:XML = imagesXML[j];						
						//if (obj.position[0] == objectXML.position[0] && obj.texture[0] == obj.texture[0]) {
							////trace('Есть совпадение по изображению!');
							//return obj;
						//}
					//}
				} //TODO обработка MorphShape
				else
					throw new Error( "Unhandled child object " + displayObject.toString() );
			}
			
			_objectsXML.appendChild( objectXML );//тут удалять нельзя. Тут создается общий список всех объектов на сцене
			return objectXML;
		}
		
		
		private static function exportFrameObject( flashObject:flash.display.DisplayObject ) : XML
		{
			return exportRecursive( flashObject );
		}
		
		
		// Extracts the scene and label information from a Flash MovieClip to XML
		private static function exportSceneData( movieClip:MovieClip ) : XML
		{
			var scenesXML:XML = <scenes />;
			var sceneCount:int = movieClip.scenes.length;
			for( var sceneIndex:int=0; sceneIndex<sceneCount; ++sceneIndex )
			{
				var scene:Scene = movieClip.scenes[ sceneIndex ];
				var sceneXML:XML = <scene />;
				
				sceneXML.@name = scene.name;
				sceneXML.@numFrames = scene.numFrames;
				
				for each( var label:FrameLabel in scene.labels )
				{
					var labelXML:XML = <label />;
					labelXML.@name = label.name;
					labelXML.@frame = label.frame;
					sceneXML.appendChild( labelXML );
				}
				
				scenesXML.appendChild( sceneXML );
			}
			
			return scenesXML;
		}
	}
}