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
	void init(value, value, bool);
	void updateSize();
	void navigate(const char *);
	void destroy();
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
        
        int padding = 58;
        
        if(screenScale > 1.0) {
            padding = 59;
        }
        
        padding /= 4;
        if(!withPopup) padding = 0;

		if(instance != nil) {
			instance.frame = CGRectMake(padding, padding, screen.size.width - (padding * 2), screen.size.height - (padding * 2));
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
	
	void onUrlChanging (NSString *url) {
		val_call1(onURLChangingCallback->get(), alloc_string([url cStringUsingEncoding:NSUTF8StringEncoding]));
	}

	void onOrientationChanged (NSNotification *notification) {
       updateSize();
    }
}
