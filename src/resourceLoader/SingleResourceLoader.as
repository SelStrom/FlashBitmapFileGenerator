package resourceLoader {
import flash.display.DisplayObjectContainer;
import flash.display.Loader;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.html.ResourceLoader;
import flash.net.URLRequest;
import flash.system.ApplicationDomain;
import flash.system.LoaderContext;
import flash.system.Security;
import flash.system.SecurityDomain;

import parser.Logger;

/**
 * ...
 * @author Shatalov Andrey
 */
public final class SingleResourceLoader {
    private var _rscDomain:ApplicationDomain;
    private var _context:LoaderContext;
    public var onLoadComplete:Function = null;
    public var content:DisplayObjectContainer = null;

    private var _self:SingleResourceLoader;

    /**
     * Конструктор сразу при инициализации начинает загрузку флешки
     * @param    srcPath
     */
    public function SingleResourceLoader():void {
//        Security.allowDomain('*');
//        Security.allowInsecureDomain('*');

        _context = new LoaderContext(false, new ApplicationDomain());
        if (Security.sandboxType == Security.REMOTE) {
            _context.securityDomain = SecurityDomain.currentDomain;
        }
        _context.checkPolicyFile = true;
        _self = this;
    }

    public function load(srcPath:String):void {
        var loader:Loader = new Loader();
        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function onComplete(e:Event):void {
            e.currentTarget.removeEventListener(Event.COMPLETE, onComplete);
            try {
                _rscDomain = loader.contentLoaderInfo.applicationDomain;
            }
            catch (err:Error) {
                Logger.trace('Domain select error' + err);
            }

            content = loader.content as DisplayObjectContainer;
            loader.unload();
            if(onLoadComplete != null) {
                onLoadComplete(_self);
            }
        });
        loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onError);
        loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSequrityError);
        loader.load(new URLRequest(srcPath + '?' + Math.floor(Math.random() * 100)), _context);
    }

    private function onError(e:IOErrorEvent):void {
        //
    }

    private function onSequrityError(event:SecurityErrorEvent):void {
        //
    }
}
}