/**
 * @author Shane Smit <Shane@DigitalLoom.org>
 * 
 * @version 1.4
 */
package old.ssmit
{
	import com.greensock.plugins.FrameBackwardPlugin;
	import flash.display.BitmapData;
	import flash.display.FrameLabel;
	import flash.display.Scene;
	import flash.geom.Point;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextRun;
	import starling.text.TextField;
	import starling.utils.deg2rad;
	import starling.utils.HAlign;
	import starling.utils.VAlign;
	
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;

	public final class FlashMovieClipImporter
	{
		private static var _atlases:Object;
		private static var _classNameFilter:RegExp = new RegExp('(\\[class |\\])', 'g');
		
		public static function AddAtlas(name:String, clipDataXML:XML, atlasBitmaps:Vector.<BitmapData>, generateMipMaps:Boolean = true ):Boolean
		{
			if (_atlases == null) _atlases = { };
			if (_atlases.hasOwnProperty(name)) throw new Error('Атласы под таким именем уже существуют');
			else 
			{
				var atlases: Vector.<TextureAtlas> = new Vector.<TextureAtlas>( clipDataXML.atlases[0].TextureAtlas.length(), true );
				
				for( var i:int=0; i<atlases.length; ++i )
				{
					var texture:Texture = Texture.fromBitmapData( atlasBitmaps[ i ], generateMipMaps);//наверное таким образом нельзя создавать текстуры больше чем 2048Х2048
					atlases[ i ] = new TextureAtlas( texture, clipDataXML.atlases[0].TextureAtlas[i] );
				}
				
				_atlases[name] = atlases;
				return true;
			}
		}
		
		/**
		 * Пытается получить текстуру из известных атласов по имени, когорое было задано объекту при добавлении его к текстурам
		 * @param	regionName имя региона в текстуре (или имя объекта, под которым он попал в атлас)
		 * @param	atlasName имя пула атласов
		 * @return	искомая текстура или null если такой не было найдено
		 */
		public static function GetTexture(objectName:String, clipDataXML:XML, atlasesName:String = "main"):Texture 
		{
			var targetObject:XML = clipDataXML.objects[0].object.(@name == objectName)[0];
			if (targetObject == null)
			{
				trace('4: Object has undifined: ' + targetObject);
				return null;
			}

			var textureXML:XML = targetObject.texture[0];
			var atlasIndex:int = textureXML.@atlas;
			var regionName:String = textureXML.@region;
			
			var atlases:Vector.<TextureAtlas> = GetAtlas(atlasesName);
			return atlases[ atlasIndex ].getTexture( regionName );
		}
		
		[Inline]
		private static function GetAtlas(name:String): Vector.<TextureAtlas>
		{
			//TODO проверить наличие
			return _atlases[name] as Vector.<TextureAtlas>;
		}
		
		public static function ImportMCFromXML(classDef:Class, clipDataXML:XML, atlasName:String, generateMipMaps:Boolean = true ) : DisplayObject
 		{
			//Получаем нормальное имя класса который нужен
			var className:String = String(classDef);
			className = className.replace(_classNameFilter, '');
			return ImportByName(className, clipDataXML, atlasName, generateMipMaps);
			//return ImportByName(className, clipDataXML, atlasBitmaps, generateMipMaps);
		}
		
		public static function ImportByName(className:String, clipDataXML:XML, atlasName:String, generateMipMaps:Boolean = true ) : DisplayObject
		{	
			// Создаем список атласов... 
/*			var atlases:Vector.<TextureAtlas> = new Vector.<TextureAtlas>( clipDataXML.atlases[0].TextureAtlas.length(), true );
			for( var i:int=0; i<atlases.length; ++i )
			{
				var texture:Texture = Texture.fromBitmapData( atlasBitmaps[ i ], generateMipMaps );
				atlases[ i ] = new TextureAtlas( texture, clipDataXML.atlases[0].TextureAtlas[i] );
			}*/
			
			var atlases:Vector.<TextureAtlas> = GetAtlas(atlasName);
			
			//получаем фреймрейт
			var version:String = clipDataXML.@version;	// TODO: Check version
			var frameRate:Number = clipDataXML.@frameRate;
			
			//trace(clipDataXML.objects[0].object.(@name == className));
			var targetObject:XML = clipDataXML.objects[0].object.(@name == className)[0];//обязательно должен быть типа movieclip или sprite
			if (targetObject == null || (targetObject.@type != 'movie clip' && targetObject.@type != 'sprite')) 
			{
				trace('4: Object is not movie clip or null: ' + targetObject);
				return null;
			}
			
			//var objectsXML:XML = <objects />;
			//Рекурсивно получаем список индексов на объекты, которые нам необходимо создать
			var indexes:Vector.<int> = new Vector.<int>();
			FindObjects(targetObject, indexes, clipDataXML);
			//trace('Complete indexes is: ' + indexes);
			
			//trace("indexes.length: ",indexes.length);
			//var objects:Vector.<DisplayObject> = new Vector.<DisplayObject>( objectsXML.object.length(), true );//создаем вектор заданной длины
			var objects:Object = { }; 
			
			var object:DisplayObject;
			for(var i:int =0; i<indexes.length; ++i )
			{
				var objectXML:XML = clipDataXML.objects[0].object[indexes[i]];
				var objectType:String = objectXML.@type;				
				switch( objectType )
				{
					case "movie clip":
						object = new DirectMovieClip();
						break;
					case "sprite":
						object = new Sprite();
						break;
					case "image":
						object = createImage( objectXML, atlases);
						break;
					case "text field":
						object = new TextField(1, 1, '');
						break;
					case 'ignore':
						continue;//TODO вот этот вариант с ignore вкорне не верен. Надо отсеивать стремные типы еще на этапе создания xml
						break;
					default:
						throw new Error( "Unhandled object type: " + objectType );
				}
				
				object.name = objectXML.@name;
				if( objectXML.transform.length() > 0 )
				{
					var matrixXML:XML = objectXML.transform[0];
					//Назначение коодират матрицы дает возможность напрямую точнее спозиционировать новые объекты. Если этого не делать то объекты "улетают"
					object.x = matrixXML.@tx;
					object.y = matrixXML.@ty;
					object.scaleX = matrixXML.@a;
					object.scaleY = matrixXML.@d;
					//После чего назначается сама матрица. В конце это делается для того, чтобы по неизвестно причине не сбивалось знаение поворота и масштаба у шейпов
					//Точнее когда есть и поворот и масштаб оба эти значения сбиваются. 
					object.transformationMatrix.setTo( matrixXML.@a, matrixXML.@b, matrixXML.@c, matrixXML.@d, matrixXML.@tx, matrixXML.@ty );
				}					
				else if( objectXML.position.length() > 0 )
				{
					var positionXML:XML = objectXML.position[0];
					object.x = positionXML.@x;
					object.y = positionXML.@y;
				}
				if( objectXML.alpha.length() > 0 )
					object.alpha = objectXML.alpha[0];
				
				objects[indexes[i]] = object;
			}
			
			// Now that all the objects exist... finalize the movie clips and sprites.			
			for( i=0; i<indexes.length; ++i )//для каждого объекта
			{
				if (objects[indexes[i]] != null)
				{
					objectXML = clipDataXML.objects[0].object[indexes[i]];
					objectType = objectXML.@type;
					if( objectType == "movie clip" )
					{
						// Fill in the frame data and scene data.
						var movieClip:DirectMovieClip = DirectMovieClip(objects[indexes[i]]);
						movieClip.frameRate = frameRate;
						movieClip.frameData = FrameData.importFromXML( objectXML.frames[ 0 ], objects );
						movieClip.sceneData = importSceneData( objectXML.scenes[ 0 ] ); 
						movieClip.initFrame();
					}
					else if( objectType == "sprite" )
					{
						// Add all the children.
						var sprite:Sprite = Sprite(objects[indexes[i]]);
						for each( var childXML:XML in objectXML.children[0].child )
						{
							var objectIndex:int = childXML.@object;
							if(objects[objectIndex] != null) sprite.addChild( objects[ objectIndex ] );
						}
					}
					else if ( objectType == "text field")
					{
						var tf:TextField = TextField(objects[indexes[i]]);
						
						//trace('data is',objectXML.data.toXMLString());	
						//	tf.autoScale = true;
						tf.autoSize = objectXML.data.@autoSize;
						tf.fontName = objectXML.data.@font;
						tf.fontSize = objectXML.data.@size;
						tf.color = objectXML.data.@color;
						tf.text = objectXML.data.@text;
						//tf.italic = objectXML.data.@italic;
						tf.bold = objectXML.data.@bold;
						tf.hAlign = objectXML.data.@align == 'null'? 'center' : objectXML.data.@align;
						tf.vAlign = VAlign.CENTER;//TODO если будут косяки с выравниванием по вертикали, то смотреть тут
						
						tf.width = Number(objectXML.data.@tw) + (tf.italic? Number(objectXML.data.@tw) * 0.1 : 0);
						tf.height = objectXML.data.@th;
						//tf.width *= 1.3;
						tf.height *= 1.3;
						//tf.pivotX = tf.pivotX + tf.width / 8.2;//8.2 примерновысчитанный коэффициент, определяющий разницу между отступами от текста в поле старнлинга и в поле tlftextfield
						if(tf.vAlign == VAlign.CENTER) tf.pivotY = tf.pivotY + tf.height / 8.4;
						
						//	tf.border = true;
				        //trace(tf.textBounds);//для отладки
					}
				}
			}
			
			// Return the first object, which is the root movie clip or sprite.
			return  DisplayObject(objects[indexes[0]]);
		}
		
		private static function FindObjects(targetObject:XML, indexes:Vector.<int>, clipDataXML:XML):void 
		{
			if (targetObject.@type != 'ignore' && indexes.indexOf(targetObject.childIndex())==-1) indexes.push(targetObject.childIndex());
			else return;
			//trace('objects is: '+objects);
			
			switch( targetObject.@type.toString() )
			{
				case "movie clip":
					for (var i:int = 0, size:int = targetObject.frames[0].frame.length(); i < size; i++ )
					{
						var frameXML:XML = targetObject.frames[0].frame[i];
						for (var j:int = 0, childCount:int = frameXML.child.length();  j < childCount; j++) 
						{
							//TODO проверять что элементов получено не более одного
							//FindObjects(clipDataXML.objects[0].object.(@name == frameXML.child[j].@name)[0], objects, clipDataXML);
							FindObjects(clipDataXML.objects[0].object[frameXML.child[j].@object], indexes, clipDataXML);
						}
					}
					break;
				case "sprite":
					var childXML:XML = targetObject.children[0];
					childCount = childXML.child.length();
					for (j = 0;  j < childCount; j++) 
					{
						//TODO проверять что элементов получено не более одного
						//FindObjects(clipDataXML.objects[0].object.(@name == childXML.child[j].@name)[0], objects, clipDataXML);
						FindObjects(clipDataXML.objects[0].object[childXML.child[j].@object], indexes, clipDataXML);
					}
					break;
				case "image": 
				case "text field": break;
				default:
					throw new Error( "Unhandled object type: " + targetObject.@type );
			}
		}
	
		public static function Dispose():void 
		{
			_atlases = null;
		}		
		
		private static function createImage( imageXML:XML, atlases:Vector.<TextureAtlas> ) : Image
		{
			var textureXML:XML = imageXML.texture[0];
			var atlasIndex:int = textureXML.@atlas;
			var regionName:String = textureXML.@region;
			
			return new Image(atlases[ atlasIndex ].getTexture( regionName ));
		}		
		
		private static function importSceneData( scenesXML:XML ) : Vector.<Scene>
		{
			var scenes:Vector.<Scene> = new Vector.<Scene>( scenesXML.scene.length(), true );
			
			for( var i:int=0; i<scenes.length; ++i )
			{
				var sceneXML:XML = scenesXML.scene[ i ];
				var labels:Array = [];
				for( var j:int=0; j<sceneXML.label.length(); ++j )
				{
					var labelXML:XML = sceneXML.label[ j ];
					labels.push( new FrameLabel( labelXML.@name, labelXML.@frame ) );
				}
				
				scenes[ i ] = new Scene( sceneXML.@name, labels, sceneXML.@numFrames );
			}
			
			return scenes;
		}
	}
}