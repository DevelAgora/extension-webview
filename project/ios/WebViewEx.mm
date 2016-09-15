#import <UIKit/UIKit.h>
#include <hx/CFFI.h>
#include <WebViewEx.h>

typedef void (*OnUrlChangingFunctionType)(NSString *);
typedef void (*OnCloseClickedFunctionType)();
typedef void (*onOrientationChangedFunctionType)(NSNotification *);

@interface WebViewDelegate : NSObject <UIWebViewDelegate>
@property (nonatomic) OnUrlChangingFunctionType onUrlChanging;
@property (nonatomic) OnCloseClickedFunctionType onCloseClicked;
@property (nonatomic) onOrientationChangedFunctionType onOrientationChanged;
@end

@implementation WebViewDelegate
@synthesize onUrlChanging;
@synthesize onCloseClicked;
@synthesize onOrientationChanged;
- (BOOL)webView:(UIWebView *)instance shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	onUrlChanging([[request URL] absoluteString]);
    
    return YES;
}
- (void) onCloseButtonClicked:(UIButton *)closeButton {
    onCloseClicked();
}

- (void) onDeviceOrientationChanged:(NSNotification *)notification {
	onOrientationChanged(notification);
}
@end

namespace webviewex {
	UIWebView *instance;
	UIButton *closeButton;
	WebViewDelegate *webViewDelegate;
	AutoGCRoot *onDestroyedCallback = 0;
	AutoGCRoot *onURLChangingCallback = 0;
    int x = -1;
    int y = -1;
    int width = -1;
    int height = -1;
	void init(value, value, bool);
	void updateSize();
	void navigate(const char *);
	void destroy();
    void setPosition(int x, int y);
    void setSize(int width, int height);
	void onUrlChanging(NSString *);
    void onOrientationChanged (NSNotification *);

	void init(value _onDestroyedCallback, value _onURLChangingCallback, bool withPopup) {
		if(instance != nil) destroy();
		
		onDestroyedCallback = new AutoGCRoot(_onDestroyedCallback);
		onURLChangingCallback = new AutoGCRoot(_onURLChangingCallback);
		
		webViewDelegate = [[WebViewDelegate alloc] init];
		webViewDelegate.onUrlChanging = &onUrlChanging;
		webViewDelegate.onCloseClicked = &destroy;
		webViewDelegate.onOrientationChanged = &onOrientationChanged;
		        
        instance = [[UIWebView alloc] init];
		instance.delegate = webViewDelegate;
		instance.scalesPageToFit=YES;

		[[[UIApplication sharedApplication] keyWindow] addSubview:instance];
		
        if (withPopup) {
	        CGFloat screenScale = [[UIScreen mainScreen] scale];
	        NSString *dpi = @"mdpi";
			if(screenScale > 1.0) {
	            dpi = @"xhdpi";
	        }

        	UIImage *closeImage = [[UIImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource: [NSString stringWithFormat:@"assets/assets/extensions_webview_close_%@.png", dpi] ofType: nil]];
			closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
			[closeButton setImage:closeImage forState:UIControlStateNormal];
			closeButton.adjustsImageWhenHighlighted = NO;
			[closeButton addTarget:webViewDelegate action:@selector(onCloseButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
			[[[UIApplication sharedApplication] keyWindow] addSubview:closeButton];
        }

        updateSize();

        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
		[[NSNotificationCenter defaultCenter]
		   addObserver:webViewDelegate selector:@selector(onDeviceOrientationChanged:)
		   name:UIDeviceOrientationDidChangeNotification
		   object:[UIDevice currentDevice]];
	}

	void updateSize() {
		bool withPopup = closeButton != nil;
		CGRect screen = [[UIScreen mainScreen] bounds];
        CGFloat screenScale = [[UIScreen mainScreen] scale];

        int padding = 0;
        if(withPopup) {
            padding = (screenScale > 1.0) ? 59 : 58;
            padding /= 4;
        }

        int newX = x != -1 ? x : 0;
        int newY = y != -1 ? y : 0;
        int newWidth = width != -1 ? width : screen.size.width;
        int newHeight = height != -1 ? height : screen.size.height;

		if(instance != nil) {
			instance.frame = CGRectMake(newX + padding, newY + padding, newWidth - (padding * 2), newHeight - (padding * 2));
		}

		if(closeButton != nil) {
			closeButton.frame = CGRectMake(0, 0, padding*2, padding*2);
		}
	}
    
	void navigate (const char *url) {
		NSURL *_url = [[NSURL alloc] initWithString: [[NSString alloc] initWithUTF8String:url]];
		NSURLRequest *req = [[NSURLRequest alloc] initWithURL:_url];
		[instance loadRequest:req];
	}

	void destroy(){
		if(instance==nil) return;
		[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
		[[NSNotificationCenter defaultCenter]
		   removeObserver:webViewDelegate
		   name:UIDeviceOrientationDidChangeNotification
		   object:nil];
		val_call0(onDestroyedCallback->get());
		[instance stopLoading];
		[instance removeFromSuperview];
		if(closeButton != nil) {
			[closeButton removeFromSuperview];
		}
		[instance release];
		instance=nil;
	}

    void setPosition(int newX, int newY){
        x = newX;
        y = newY;
        updateSize();
    }

    void setSize(int newWidth, int newHeight){
        width = newWidth;
        height = newHeight;
        updateSize();
    }
	
	void onUrlChanging (NSString *url) {
		val_call1(onURLChangingCallback->get(), alloc_string([url cStringUsingEncoding:NSUTF8StringEncoding]));
	}

	void onOrientationChanged (NSNotification *notification) {
       updateSize();
    }
}
