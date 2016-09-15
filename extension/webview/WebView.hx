package extension.webview;
	
class WebView  {

	private static var initialized :Bool = false;

	private static var APIInit:Dynamic=null;
	private static var APISetCallback:Dynamic=null;
	private static var APINavigate:Dynamic=null;
	private static var APIDestroy:Dynamic=null;
	private static var APISetPosition:Dynamic=null;
	private static var APISetSize:Dynamic=null;

	#if ios
	private static var listener:WebViewListener;
	#end

	#if android
	private static var _open :String -> Bool -> Bool -> Array<String> -> Array<String> -> Void = null;
	private static var _close :Void -> Void = null;
    private static var _setPosition :Int -> Int -> Void;
    private static var _setSize :Int -> Int -> Void;
	#end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	public static var onClose:Void->Void=null;
	public static var onURLChanging:String->Void=null;

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	public static function open (url: String = null, floating :Bool = false, preventBack:Bool = false, ?urlWhitelist :Array<String>, ?urlBlacklist :Array<String>) :Void {
		init();
		if(urlWhitelist!=null) urlWhitelist.push(url);
		
		#if android
			_open(url, floating, preventBack, urlWhitelist, urlBlacklist);
		#elseif ios
			if (listener == null) listener = new WebViewListener(urlWhitelist, urlBlacklist);
			APICall("init", [listener, floating]);
			navigate(url);
		#end
	}

    public static function close():Void {
        #if android
        _close();
        #elseif ios
        if (listener != null) APICall("destroy");
        #end
    }

    public static function setPosition(x:Int, y:Int):Void {
        if(!initialized)
            return;

        #if android
        _setPosition(x, y);
        #elseif ios
        APICall("setPosition", [x, y]);
        #end
    }

    public static function setSize(width:Int, height:Int):Void {
        #if android
        _setSize(width, height);
        #elseif ios
        APICall("setSize", [width, height]);
        #end
    }

	#if ios
	public static function navigate(url:String):Void {
		if (url==null) return;
		if (listener != null) APICall("navigate", [url]);
	}
	#end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	private static function init():Void {
		if(initialized == true) return;
		initialized = true;
		try {
			#if android
			_open = openfl.utils.JNI.createStaticMethod("extensions/webview/WebViewExtension", "open", "(Ljava/lang/String;ZZ[Ljava/lang/String;[Ljava/lang/String;)V");
			_close = openfl.utils.JNI.createStaticMethod("extensions/webview/WebViewExtension", "close", "()V");
            _setPosition = openfl.utils.JNI.createStaticMethod("extensions/webview/WebViewExtension", "setPosition", "(II)V");
			_setSize = openfl.utils.JNI.createStaticMethod("extensions/webview/WebViewExtension", "setSize", "(II)V");
			var _callbackFunc = openfl.utils.JNI.createStaticMethod("extensions/webview/WebViewExtension", "setCallback", "(Lorg/haxe/lime/HaxeObject;)V");
            _callbackFunc(WebView);

			#elseif ios
            APIInit     = cpp.Lib.load("webviewex","webviewAPIInit", 3);
			APINavigate = cpp.Lib.load("webviewex","webviewAPINavigate", 1);
			APIDestroy  = cpp.Lib.load("webviewex","webviewAPIDestroy", 0);
			APISetPosition  = cpp.Lib.load("webviewex","webviewAPISetPosition", 2);
			APISetSize  = cpp.Lib.load("webviewex","webviewAPISetSize", 2);
			#end

		} catch(e:Dynamic) {
			trace("INIT Exception: "+e);
		}
	}
	
	private static function APICall(method:String, args:Array<Dynamic> = null):Void	{
		init();
		try{
			#if android
			if (method == "init") {
				try {
					APIInit(args[1] == true);
				} catch (e :Dynamic) {
					APIInit(args[1] == true);
				}
			}
            if (method == "callback") APISetCallback(args[0]);
            if (method == "navigate") APINavigate(args[0]);
            if (method == "destroy") APIDestroy();
            if (method == "setPosition") APISetPosition(args[0], args[1]);
            if (method == "setSize") APISetSize(args[0], args[1]);
			#elseif ios
			if (method == "init") APIInit(args[0].onClose, args[0].onURLChanging, args[1]);
            if (method == "navigate") APINavigate(args[0]);
            if (method == "destroy") APIDestroy();
            if (method == "setPosition") APISetPosition(args[0], args[1]);
            if (method == "setSize") APISetSize(args[0], args[1]);
			#end
		} catch(e:Dynamic) {
			trace("APICall Exception [" + method + ", " + args + "]: "+e);
		}
	}
	
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#if ios
class WebViewListener {

	public var urlWhitelist :Array<String>;
	public var urlBlacklist :Array<String>;

	public function new(urlWhitelist :Array<String>, urlBlacklist :Array<String>) {
		this.urlBlacklist=urlBlacklist;
		this.urlWhitelist=urlWhitelist;
	}
	
	public function onClose():Void {
		if(WebView.onClose!=null) WebView.onClose();
	}

	private function find(urls :Array<String>, url:String):Bool{
		for(regex in urls){
			var r = new EReg(regex,"");
			if(r.match(url)) return true;
		}
		return false;
	}
	
	public function onURLChanging(url:Dynamic):Void {
		if(urlWhitelist!=null){	
			if(!find(urlWhitelist,url)){
				WebView.close();
				return;
			}
		}
		if(urlBlacklist!=null){
			if(find(urlBlacklist,url)){
				WebView.close();
				return;
			}
		}
		if(WebView.onURLChanging!=null) WebView.onURLChanging(url);
	}
}
#end
