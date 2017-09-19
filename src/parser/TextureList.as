/**
 * @author Shane Smit <Shane@DigitalLoom.org>
 */
package parser
{
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

import parser.content.BitmapInfo;

	// The list of textures created from a ConvertedMovieClip
	public final class TextureList
	{
		internal static const PADDING		: int	= 1;	// Add padding pixels to avoid bleeding in mipmaps.
		
		/** Счетчик, позволяющий задавать уникальные неповторяющиеся имена*/
		private static var _nameCounter		: Number = 0;
		
		/** Содержит сырую информацию о всей графике*/
		private var _bitmapInfoList			: Vector.<BitmapInfo>;
		
		// Creates a TextureList.
		public function TextureList()
		{
			_bitmapInfoList = new <BitmapInfo>[];
		}
		
		// Disposes all the textures in the list.
		internal function dispose() : void
		{
			for each( var info:BitmapInfo in _bitmapInfoList )
				info.dispose();
			_bitmapInfoList = null;
		}
		
		
		/**
		 * Эта функция позволяет запекать объект на сцене в bitmapdata
		 * @param	displayObject
		 * @return	bitmapdata
		 * 
		 * Gets (or creates) a BitmapInfo structure from a Flash DisplayObject.
		 */
		internal function getBitmapInfoFromDisplayObject( displayObject:DisplayObject ) : BitmapInfo
		{
			//Пробуем увеличивать масштаб всех приходящих на запекание объектов
			//displayObject.scaleX *= 2;
			//displayObject.scaleY *= 2;
			
			// Capture the shape into a BitmapData.
			//trace('Старт запекания displayObject');
			var shapeRect:Rectangle = displayObject.getBounds(displayObject);
			var matrix:Matrix = new Matrix();
			matrix.translate( (-shapeRect.left) + PADDING, (-shapeRect.top) + PADDING ); //приведение координат к нулевой точке + смещение для границы
			var bitmapData:BitmapData = new BitmapData( Math.ceil(shapeRect.width) + (PADDING*2), Math.ceil(shapeRect.height) + (PADDING*2), true, 0xFF0000 );	// Assume transparency on everything.
			bitmapData.draw( displayObject, matrix);
			CreateBorder(bitmapData);			
			
			var info:BitmapInfo = findBitmapInfo( bitmapData);
			if( info != null )
			{
				bitmapData.dispose();
				bitmapData = info._bitmapData;
			}
			else
			{
				// Create a new bitmap info and add it to the list.
				info = new BitmapInfo();
				info._bitmapData = bitmapData;
				info._name = displayObject.name.slice()+'i'+_nameCounter++;//создается уникальное имя для новой сабтекстуры
				_bitmapInfoList.push( info );//тут содержится вся сырая информации о графике
			}
			
			return info;
		}
		
		[Inline]
		public static function CreateBorder(bitmapData:BitmapData):void 
		{
			var width:int = bitmapData.width;
			var height:int = bitmapData.height;
			
			bitmapData.copyPixels(bitmapData, new Rectangle(1, 1, width-1, 1), new Point(1, 0));			
			bitmapData.copyPixels(bitmapData, new Rectangle(width - 2, 0, 1, height - 1),  new Point(width - 1, 0));			
			bitmapData.copyPixels(bitmapData, new Rectangle(1, height - 2, width - 1, 1), new Point(1, height-1));
			bitmapData.copyPixels(bitmapData, new Rectangle(1, 0, 1, height), new Point(0, 0));
		}
		
		/**
		 * Finds an existing bitmap given the bitmapData
		 * @param	bitmapData искомая картинка
		 * @return  info, если искомая картинка найдена среди ранее созданных
		 */
		private function findBitmapInfo(bitmapData:BitmapData) : BitmapInfo
		{
			for each( var info:BitmapInfo in _bitmapInfoList )
			{
				if(bitmapData.compare(info._bitmapData) == 0) return info;
			}
			
			return null;
		}
		
		
		// Convert the list of bitmaps to Starling TextureAtlases.
		/*internal function createTextureAtlases( sortBitmaps:Boolean=true, generateMipMaps:Boolean=true ) : Vector.<TextureAtlas>
		{
			var bitmaps:Vector.<BitmapData> = TexturePacker.pack( _bitmapInfoList, sortBitmaps );
			
			// Create the Atlases from the packed bitmaps.
			var atlases:Vector.<TextureAtlas> = new Vector.<TextureAtlas>( bitmaps.length, true );
			for( var i:int=0; i<atlases.length; ++i )
			{
				var texture:Texture = Texture.fromBitmapData( bitmaps[ i ], generateMipMaps );
				atlases[ i ] = new TextureAtlas( texture );
			}
			
			// Add the texture regions to the atlases
			for each( info in _bitmapInfoList )
			{
				var atlas:TextureAtlas = atlases[ info._atlasIndex ];
				atlas.addRegion( info._name, new Rectangle( info._atlasX, info._atlasY, info._bitmapData.width, info._bitmapData.height ) );//TODO 
			}
			
			// Assign the atlased textures to the images.
			for each( var info:BitmapInfo in _bitmapInfoList )
			{
				for each( var image:Image in info._imageList )
				{
					image.texture.dispose();	// Dispose the dummy texture.
					image.texture = atlases[ info._atlasIndex ].getTexture( info._name );
				}
			}
			
			return atlases;
		}*/
		
		
		internal function exportTextureAtlases( atlasesXML:XML, sortBitmaps:Boolean=true ) : Vector.<BitmapData>
		{
			/*var bitmaps:Vector.<BitmapData> = TexturePacker.pack( _bitmapInfoList, sortBitmaps );
			
			// Write region info:
			for( var i:int=0; i<bitmaps.length; ++i )
				atlasesXML.appendChild( <TextureAtlas /> );
			
			for each( var info:BitmapInfo in _bitmapInfoList )
			{
				var atlasXML:XML = atlasesXML.TextureAtlas[ info._atlasIndex ].appendChild( <SubTexture /> );
				var textureXML:XML = atlasXML.SubTexture[ atlasXML.SubTexture.length() - 1 ];
				textureXML.@name = info._name;
				//Добавление PADDING позволяет игнорировать границы, которые создаются при запекании объектов в текстырый атлас
				textureXML.@x = info._atlasX + PADDING;
				textureXML.@y = info._atlasY + PADDING;
				textureXML.@width = info._bitmapData.width - PADDING * 2;
				textureXML.@height = info._bitmapData.height - PADDING * 2;
			}
			
			// Assign the atlased textures to the images.
			for each( info in _bitmapInfoList )
			{
				for each( var imageXML:XML in info._xmlList )
				{
					textureXML = <texture />;
					textureXML.@atlas = info._atlasIndex;
					textureXML.@region = info._name;
					imageXML.appendChild( textureXML );
				}
			}
			
			return bitmaps;*/

			return null;
		}
	}
}
