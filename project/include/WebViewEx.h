#ifndef WebViewEx
#define WebViewEx
	
namespace webviewex {
	void init(value _onDestroyedCallback, value _onURLChangingCallback, bool withPopup);
	void navigate(const char *url);
	void destroy();
	void setPosition(int x, int y);
	void setSize(int width, int height);
}

#endif