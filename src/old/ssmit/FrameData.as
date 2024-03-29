/**
 * @author Shane Smit <Shane@DigitalLoom.org>
 */
package old.ssmit
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import starling.core.Starling;
	import starling.text.TextField;
	
	import starling.animation.IAnimatable;
	//import starling.old.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Sprite;

	internal final class FrameData
	{
		private var _frameList		: Vector.<Vector.<FrameDataVO>>;
		
		public function FrameData( frameCount:int )
		{
			_frameList = new Vector.<Vector.<FrameDataVO>>( frameCount, true );
		}
		
		
		internal function dispose() : void
		{
			// Clean out the frame data.
			for each( var objectList:Vector.<FrameDataVO> in _frameList )
			{
				for each( var objectFrameData:FrameDataVO in objectList )
					objectFrameData.dispose();
			}
			_frameList = null;
		}
		
		
		// Imports frame data from a Flash MovieClip
		internal static function importFromFlashMovieClip( movieClip:MovieClip, CallBack:Function, isFlipFrames:Boolean = false) : FrameData
		{//!!!!!!!!!!!!В этом коде косяки с определением уникального контента во фреймах!!!!!!!!!!!!!!!!!!!!!!!
			var frameData:FrameData = new FrameData( movieClip.totalFrames );
			
			for( var frame:int=1; frame<=movieClip.totalFrames; ++frame )
			{
				movieClip.gotoAndStop( frame );

				if(!isFlipFrames) 	frameData._frameList[ frame-1 ] = new Vector.<FrameDataVO>( movieClip.numChildren, true );//создается вектор фиксированный длины, равнок количеству потомков в кадре
				else 				frameData._frameList[ frame-1 ] = new Vector.<FrameDataVO>( 1, true ); //если сливаем содержимое мувиклипа, то и потомок один
				
				// Fetch the frame-by-frame information for each child in the movie clip.
				var childLength:int = isFlipFrames? 1: movieClip.numChildren;
				for( var i:int=0; i<childLength; ++i )
				{
					if (isFlipFrames == true) { //Костыль, который предположительно позволяет сливать весь фрейм мувиклипа в единое целое
						var shapeRect:Rectangle = movieClip.getBounds(movieClip);
						var matrix:Matrix = new Matrix();
						matrix.translate( (-shapeRect.left) + 1, (-shapeRect.top) + 1 );
						var bitmapData:BitmapData = new BitmapData( Math.ceil(movieClip.width) + (1*2), Math.ceil(movieClip.height) + (1*2), true, 0x00000000 );
						bitmapData.draw( movieClip, matrix );
						TextureList.CreateBorder(bitmapData);
						
						var child:flash.display.DisplayObject = new Bitmap(bitmapData);
						child.x = shapeRect.left;
						child.y = shapeRect.top;
					}
					else 
					{
						// Find or create a converted version of each child object.
						var child:flash.display.DisplayObject = movieClip.getChildAt( i );
						//пробуем подогнать масштаб
						//child.scaleX *= 2;
						//child.scaleY *= 2;
						
						/////////
						var shapeRect:Rectangle = child.getBounds(child);
						var matrix:Matrix = new Matrix();
						matrix.translate( (-shapeRect.left) + 1, (-shapeRect.top) + 1 );
						var bitmapData:BitmapData = new BitmapData( Math.ceil(child.width) + (1*2), Math.ceil(child.height) + (1*2), true, 0x00000000 );	// Assume transparency on everything.
						bitmapData.draw( child, matrix );
						TextureList.CreateBorder(bitmapData);
					}
					////////
					
					var objectFrameData:FrameDataVO = new FrameDataVO();
					var oldFrameData:FrameDataVO = frameData.findObjectFrameData( child , bitmapData);
					
					if(oldFrameData != null && oldFrameData.name == child.name)
					{
						//используем старую информацию
						objectFrameData.name = oldFrameData.name;
						objectFrameData.starlingObject = oldFrameData.starlingObject;
						objectFrameData.xmlObject = oldFrameData.xmlObject;
						//objectFrameData.isReference = true;
					}
					else
					{////////////видимо тут можно как то лучше сделать
						//trace('Новый объект');
						objectFrameData.name = child.name.slice();//получаем имя
						
						// I'm not too happy about how this ended up.
						var object:Object = CallBack( child );//тут либо создается контейнер либо запекается объект
						if( object is starling.display.DisplayObject )
							objectFrameData.starlingObject = starling.display.DisplayObject(object);
						else if( object is XML )
							objectFrameData.xmlObject = XML(object);
					}
					
					objectFrameData.bitmapData = bitmapData;
					
					//objectFrameData.flashObjectHeight = child.height;//В редких случаях по одной ссылке в objectFrameData могут находиться 2 разных объекта. Уникальную информацию о них нужно хранить отдельно
					//objectFrameData.flashObjectWidth = child.width;
					//objectFrameData.flashObject = child;
					objectFrameData.transformationMatrix = new Matrix();
					objectFrameData.transformationMatrix.copyFrom( child.transform.matrix );
					if( child is Shape || child is Bitmap )
					{
						// Child will be converted to a texture, compensate with offset.
						var childRect:Rectangle = child.getBounds( child );
						objectFrameData.transformationMatrix.tx += childRect.left;
						objectFrameData.transformationMatrix.ty += childRect.top;
					}
					objectFrameData.alpha = child.alpha;
					
					frameData._frameList[ frame-1 ][ i ] = objectFrameData;
					
	//!!!				child.scaleX /= 2;
					//child.scaleY /= 2;
				}
			}
			
			// Удаляем ненужные ссылки на исходный мувиклип
			for( frame=frameData._frameList.length-1; frame>=0; --frame )
			{
				for each( objectFrameData in frameData._frameList[ frame ] ) {
					//objectFrameData.flashObject = null;
					//objectFrameData.flashObjectHeight = undefined;
					//objectFrameData.flashObjectWidth = undefined;
					
					objectFrameData.bitmapData.dispose();
					objectFrameData.bitmapData = null;
				}
			}
			
			// Reset the original movie clip, just in case.
			movieClip.gotoAndStop(1);
			
			return frameData;
		}
		
		
		// finds an existing ObjectFrameData in prior frames, given a Flash DisplayObject.
		private function findObjectFrameData(child:flash.display.DisplayObject, bitmapData:BitmapData):FrameDataVO
		{
			for ( var frame:int = _frameList.length - 1; frame >= 0; --frame )
			{
				for each( var frameData:FrameDataVO in _frameList[ frame ] )
				{
					//if (frameData) trace('Objects is equal:',frameData.flashObject == object);
					//else trace('frame data is null');
					
					//if( frameData != null && (frameData.flashObject === object ))
					//if( frameData != null && (frameData.flashObject === object && (frameData.flashObjectWidth == object.width && frameData.flashObjectHeight == object.height)))
					//	return frameData;
					
					//Глубокая проверка
					if( frameData != null && (frameData.bitmapData.compare(bitmapData) == 0 )) return frameData;
				}
			}
			
			return null;
		}
		
		
		// Imports frame data from xml.
		internal static function importFromXML( xml:XML, objects:Object/*Vector.<DisplayObject>*/ ) : FrameData
		{
			var frameData:FrameData = new FrameData( xml.frame.length() );
			
			for( var i:int=0; i<frameData._frameList.length; ++i  )
			{
				var frameXML:XML = xml.frame[i];
				var objectList:Vector.<FrameDataVO> = new Vector.<FrameDataVO>( frameXML.child.length(), true );
				for( var j:int=0; j<objectList.length; ++j )
				{
					var childXML:XML = frameXML.child[j];
					var objectFrameData:FrameDataVO = new FrameDataVO();
					objectFrameData.name = childXML.@name;
					
					if( childXML.transform.length() > 0 )
					{
						var matrixXML:XML = childXML.transform[ 0 ];
						objectFrameData.transformationMatrix = new Matrix( matrixXML.@a, matrixXML.@b, matrixXML.@c, matrixXML.@d, matrixXML.@tx, matrixXML.@ty );
					}
					else if( childXML.position.length() > 0 )
					{
						var positionXML:XML = childXML.position[ 0 ];
						objectFrameData.transformationMatrix = new Matrix( 1, 0, 0, 1, positionXML.@x, positionXML.@y );
					}
					else
						objectFrameData.transformationMatrix = new Matrix();
					
					if( childXML.alpha.length() > 0 )
						objectFrameData.alpha = childXML.alpha[0];
					else
						objectFrameData.alpha = 1;
					
					var objectIndex:int = childXML.@object;
					objectFrameData.starlingObject = objects[ objectIndex ];//CloneObject(objects[ objectIndex ]);//тут изменения стабильного кода
					objectList[ j ] = objectFrameData;
				}
				
				frameData._frameList[ i ] = objectList;
			}
			
			return frameData;
		}
		
		private static function CloneObject(object:starling.display.DisplayObject):starling.display.DisplayObject 
		{
			if (object as DirectMovieClip) return (object as DirectMovieClip).clone();
			else if (object as Sprite) 	return cloneSprite(object as Sprite);
			else if (object as Image) 	return cloneImage(object as Image);
			else if (object as TextField) return CloneTextField(object as TextField);
			else return null;
		}
		
		private static function CloneTextField(tf:TextField):TextField 
		{
			var newTextField:TextField = new TextField(1, 1, '');

			newTextField.autoSize = tf.autoSize;
			newTextField.fontName = tf.fontName;
			newTextField.fontSize = tf.fontSize;
			newTextField.color = tf.color;
			newTextField.text = tf.text;

			newTextField.bold = tf.bold;
			newTextField.hAlign = tf.hAlign;
			newTextField.vAlign = tf.vAlign;
			
			newTextField.width = tf.width;
			newTextField.height = tf.height;
			
			return newTextField;
		}			
			
		// Exports the frame data to xml.
		internal function exportToXML() : XML
		{
			var xml:XML = <frames />;
			
			for ( var i:int = 0; i < _frameList.length; ++i )			
			{
				var objectList:Vector.<FrameDataVO> = _frameList[ i ];
				
				var frameXML:XML = <frame />;				
				for ( var j:int = 0; j < objectList.length; ++j )				
				{
					var objectFrameData:FrameDataVO = objectList[j];
					
//					var childXML:XML = <child idref={ objectFrameData.xmlObject.@id }/>;
					var childXML:XML = <child object = { objectFrameData.xmlObject.childIndex() }/>;
					childXML.@name = objectFrameData.name;//TODO тут именуются xml объекты
					
					//if ( objectFrameData.isReference) childXML.appendChild( <reference>1</reference>);
					if( objectFrameData.alpha != 1 ) childXML.appendChild( <alpha>{ objectFrameData.alpha }</alpha> );
					
					if( objectFrameData.transformationMatrix.a != 1
					 || objectFrameData.transformationMatrix.b != 0
					 || objectFrameData.transformationMatrix.c != 0
					 || objectFrameData.transformationMatrix.d != 1
					 || objectFrameData.transformationMatrix.tx != 0
					 || objectFrameData.transformationMatrix.ty != 0 )
					{
						var transformXML:XML = <transform />;
						transformXML.@a = objectFrameData.transformationMatrix.a;
						transformXML.@b = objectFrameData.transformationMatrix.b;
						transformXML.@c = objectFrameData.transformationMatrix.c;
						transformXML.@d = objectFrameData.transformationMatrix.d;
						transformXML.@tx = objectFrameData.transformationMatrix.tx;
						transformXML.@ty = objectFrameData.transformationMatrix.ty;
						childXML.appendChild( transformXML );
					}
					
					frameXML.appendChild( childXML );
				}
				
				xml.appendChild( frameXML );
			}
			
			return xml;
		}
		
		
		internal function clone() : FrameData
		{
			var newFrameData:FrameData = new FrameData( _frameList.length );
			
			for( var f:int=0; f<_frameList.length; ++f )
			{
				var objectList:Vector.<FrameDataVO> = _frameList[ f ];
				var newObjectList:Vector.<FrameDataVO> = new Vector.<FrameDataVO>( objectList.length, true ); 
				for( var obj:int=0; obj<objectList.length; ++obj )
				{
					var objectFrameData:FrameDataVO = objectList[ obj ];
					var newObjectFrameData:FrameDataVO = new FrameDataVO();
					
					// Shallow copy.
					newObjectFrameData.name = objectFrameData.name;
					newObjectFrameData.transformationMatrix = objectFrameData.transformationMatrix;
					newObjectFrameData.alpha = objectFrameData.alpha;
					newObjectFrameData.cloneSource = objectFrameData.starlingObject;
					
					// Deep copy the starling object.
					var oldObjectFrameData:FrameDataVO = newFrameData.findObjectFrameDataByCloneSource( objectFrameData.starlingObject );
					var newStarlingObject:starling.display.DisplayObject;
					
					if( oldObjectFrameData != null )
					{
						newStarlingObject = oldObjectFrameData.starlingObject;
					}
					else
					{
						if( objectFrameData.starlingObject is DirectMovieClip )
							newStarlingObject = DirectMovieClip(objectFrameData.starlingObject).clone();
						else if( objectFrameData.starlingObject is Sprite )
							newStarlingObject = cloneSprite( Sprite(objectFrameData.starlingObject) );
						else if( objectFrameData.starlingObject is Image )
							newStarlingObject = cloneImage( Image(objectFrameData.starlingObject) );
					}
					
					newObjectFrameData.starlingObject = newStarlingObject;
					
					newObjectList[ obj ] = newObjectFrameData;
				}
				newFrameData._frameList[ f ] = newObjectList;
			}
			
			// Clean out the cloneSource object references
			for( f=0; f<_frameList.length; ++f )
			{
				objectList = _frameList[ f ];
				for( obj=0; obj<objectList.length; ++obj )
					objectList[ obj ].cloneSource = null;
			}
			
			return newFrameData;
		}
		
		
		// finds an existing ObjectFrameData in prior frames, given a clone source object.
		private function findObjectFrameDataByCloneSource( cloneSource:starling.display.DisplayObject ) : FrameDataVO
		{
			for( var frame:int=_frameList.length-1; frame>=0; --frame )
			{
				for each( var frameData:FrameDataVO in _frameList[ frame ] )
				{
					if( frameData != null && frameData.cloneSource === cloneSource )
						return frameData;
				}
			}
			
			return null;
		}
		
		
		// Creates a deep copy of a child Sprite.
		private static function cloneSprite( sprite:Sprite ) : Sprite
		{
			var newSprite:Sprite = new Sprite();
			
			newSprite.name = sprite.name;
			newSprite.transformationMatrix.copyFrom( sprite.transformationMatrix );
			newSprite.alpha = sprite.alpha;
			newSprite.blendMode = sprite.blendMode;
			
			// Add the children to the new Sprite.
			for( var i:int=0; i<sprite.numChildren; ++i ) 
			{
				var child:starling.display.DisplayObject = sprite.getChildAt( i );
				newSprite.addChild( CloneObject(child) );
			}
			
			return newSprite;
		}
		
		
		// Creates a copy of a child image.  The texture is not duplicated.
		private static function cloneImage( image:Image ) : Image
		{
			var newImage:Image = new Image( image.texture );
			newImage.setTexCoords( 0, image.getTexCoords( 0 ) );
			newImage.setTexCoords( 1, image.getTexCoords( 1 ) );
			newImage.setTexCoords( 2, image.getTexCoords( 2 ) );
			newImage.setTexCoords( 3, image.getTexCoords( 3 ) );
			
			newImage.name = image.name;
			newImage.transformationMatrix.copyFrom( image.transformationMatrix );
			newImage.alpha = image.alpha;
			newImage.blendMode = image.blendMode;
			newImage.smoothing = image.smoothing;
			
			return newImage;
		}
		
		
		// Initializes the first frome of the animation.
		internal function initFrame( parent:DirectMovieClip ) : void
		{
			// Add the new children. And update their frame properties.
			var frameObjectList:Vector.<FrameDataVO> = _frameList[ 0 ];
			for( var i:int=0; i<frameObjectList.length; ++i )
			{
				var objectFrameData:FrameDataVO = frameObjectList[ i ];
				var object:starling.display.DisplayObject = objectFrameData.starlingObject;
				//TODO добавить проверку на существование object. Но пока делать не буду, потому что это стимулирует исправлять ошибки в экспорте
				object.transformationMatrix.copyFrom( objectFrameData.transformationMatrix );
				object.alpha = objectFrameData.alpha;
				
				if ( object is IAnimatable )
					parent.juggler.add( IAnimatable(object) );
				parent.addChildAt( object, i );
			}
		}
		
		
		// Change from the current global frame to another.  Does not have to be sequential. 
		internal function changeFrame( parent:DirectMovieClip, currentFrame:int, targetFrame:int ) : void
		{
			var object:starling.display.DisplayObject;
			
			// Avoid excessive child removal and addition.
			var curObjects:Dictionary = new Dictionary();	// Object indices from the current frame
			var newObjects:Dictionary = new Dictionary();	// Object indices in the new frame
			var allObjects:Dictionary = new Dictionary();	// Object indices in the new frame, and -1s for objects in the old frame.
			
			var curFrameObjectList:Vector.<FrameDataVO> = _frameList[ currentFrame - 1 ];
			var newFrameObjectList:Vector.<FrameDataVO> = _frameList[ targetFrame - 1 ];
			
			// Build a dictionary of every child in the current frame.
			for( var i:int=0; i<curFrameObjectList.length; ++i )
			{
				object = curFrameObjectList[ i ].starlingObject;
				curObjects[ object ] = i;
				allObjects[ object ] = -1;	// Mark this object to be removed.
			}
			
			// Determine which children should stick around, be added, or be removed.
			for( i=0; i<newFrameObjectList.length; ++i )
			{
				object = newFrameObjectList[ i ].starlingObject;
				newObjects[ object ] = i;	// This will also be the child index.
				allObjects[ object ] = i;	// Unmark the object to be removed if it existed in the current frame.
			}
			
			// Remove all the children still marked with a -1.
			for( var key:Object in allObjects )
			{
				var childIndex:int = allObjects[ key ];
				if( childIndex == -1 )
				{
					parent.removeChild( starling.display.DisplayObject(key) );
					if( key is IAnimatable )
						parent.juggler.remove( IAnimatable(key) );
				}
			}
			
			// Finally, add the new children or reorder the existing children. And update their frame properties.
			for( i=0; i<newFrameObjectList.length; ++i )
			{
				var frameData:FrameDataVO = newFrameObjectList[ i ];
				object = frameData.starlingObject;
				
				// Determine if the object was already a child.
				if( curObjects[ object ] != undefined )
				{
					if( curObjects[ object ] != i )
						parent.setChildIndex( object, i );
				}
				else
				{
					//т.к. объект еще не определен, то назначаем ему альфу и матрицу трансформации. 
					//если объект уже был определен, подразумевается, что эти характеристики ему уже были назначены
					object.transformationMatrix.copyFrom( frameData.transformationMatrix );
					object.alpha = frameData.alpha;
					
					if( object is IAnimatable )
						parent.juggler.add( IAnimatable(object) );
					parent.addChildAt( object, i );
				}
			}
		}
		
		
		internal function get totalFrames() : uint
		{
			return _frameList.length;
		}
	}
}


import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.geom.Matrix;

import starling.display.DisplayObject;

internal final class FrameDataVO
{
	public var name					: String;
	public var transformationMatrix	: Matrix;
	public var alpha				: Number;
	
	//public var flashObject			: flash.old.display.DisplayObject;
	public var starlingObject		: starling.display.DisplayObject;
	public var xmlObject			: XML;
	public var cloneSource			: starling.display.DisplayObject;
	
	/** Флаг определяет, является ли данная информация диблирующей по отношению к уже определенному объекту в другом кадре
	 * 	По логике эта ссылка должна помочь восстановить настоящую структуру мувиклипа, когда в нескольких кадрах может быть один объект*/
	//public var isReference			: Boolean = false;
	
	//public var flashObjectWidth		: Number;
	//public var flashObjectHeight	: Number;
	
	public var bitmapData			: BitmapData;
	
	public function dispose() : void
	{
		name = null;
		transformationMatrix = null;
		//flashObject = null;
		//flashObjectHeight = undefined;
		//flashObjectWidth = undefined;
		cloneSource = null;
		
		bitmapData = null;
		
		if( starlingObject != null )
		{
			starlingObject.dispose();
			starlingObject = null;
		}
		xmlObject = null;
	}
}