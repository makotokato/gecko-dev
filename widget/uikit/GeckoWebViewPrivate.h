

class nsWindow;
class MessageLoop;

@interface GeckoWebView (Private)
@property nsWindow* widget;

+ (MessageLoop*)UIMessageLoop;

- (void)setURL:(NSURL*)url;

- (void)fullScreenChanged:(BOOL)fullscreen;
- (void)setKeyboardEnabled:(BOOL)enabled;

@end
