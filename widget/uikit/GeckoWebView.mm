/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UITouch.h>
#import <UIKit/UIView.h>

#include "InputData.h"

#include "MainThreadUtils.h"
#include "nsAppShell.h"
#include "nsIBaseWindow.h"
#include "nsIDOMDocument.h"
#include "nsIDocShell.h"
#include "nsIDocument.h"
#include "nsIInterfaceRequestorUtils.h"
#include "nsIObserverService.h"
#include "nsISHistory.h"
#include "nsISHistoryListener.h"
#include "nsISimpleEnumerator.h"
#include "nsIURI.h"
#include "nsIWebNavigation.h"
#include "nsIWebProgress.h"
#include "nsIWebProgressListener.h"
#include "nsIWindowWatcher.h"
#include "nsNetUtil.h"
#include "nsPIDOMWindow.h"
#include "nsString.h"
#include "nsWeakReference.h"
#include "nsWindow.h"

#include "mozilla/Preferences.h"
#include "mozilla/layers/APZThreadUtils.h"

#include "base/message_loop.h"

#import "GeckoThread.h"
#import "GeckoWebView.h"
#import "GeckoWebViewPrivate.h"

using namespace mozilla;
using namespace mozilla::layers;
using namespace mozilla::widget;

// #define LOG(args...) fprintf(stderr, args); fprintf(stderr, "\n")
#define LOG(args...) (void)0;

static MessageLoop* sUIMessageLoop = nil;

static ScreenIntPoint UIKitPointsToDevPixels(CGPoint aPoint, CGFloat aBackingScale) {
  return ScreenIntPoint(NSToIntRound(aPoint.x * aBackingScale),
                        NSToIntRound(aPoint.y * aBackingScale));
}

static ScreenIntRect UIKitPointsToDevPixels(CGRect aRect, CGFloat aBackingScale) {
  return ScreenIntRect(NSToIntRound(aRect.origin.x * aBackingScale),
                       NSToIntRound(aRect.origin.y * aBackingScale),
                       NSToIntRound(aRect.size.width * aBackingScale),
                       NSToIntRound(aRect.size.height * aBackingScale));
}

class WindowReadyListener;
class ContentListener;

@interface InputBridge : UIView <UIKeyInput, UITextInputTraits> {
  nsWindow* mWidget;
}

@property(nonatomic) nsWindow* widget;

@end

@implementation InputBridge

@synthesize widget = mWidget;

- (BOOL)canBecomeFirstResponder {
  return YES;
}

- (void)insertText:(NSString*)text {
  RunBlockOnMainThread(^{
    mWidget->InsertText([text UTF8String]);
  });
}

- (void)deleteBackward {
  RunBlockOnMainThread(^{
    mWidget->DeleteCharacter();
  });
}

- (BOOL)hasText {
  return true;
}

@end

@interface ViewGlue : NSObject {
 @public
  nsCOMPtr<nsPIDOMWindow> mChromeWindow;
  nsCOMPtr<nsIDocShell> mBrowserDocShell;
  nsCOMPtr<nsIWebNavigation> mWebNavigation;

  InputBridge* mInputBridge;
  RefPtr<nsWindow> mWidget;
  GeckoWebView* mView;

  RefPtr<WindowReadyListener> mReadyListener;
  RefPtr<ContentListener> mContentListener;

  BOOL mCanGoBack;
  BOOL mCanGoForward;

  CFMutableDictionaryRef mTouches;
  int mNextTouchID;

  NSURLRequest* mPendingRequest;
}

@property(nonatomic, weak) GeckoWebView* view;

- (id)initWithView:(GeckoWebView*)view;

- (void)openWindow;
- (void)closeWindow;
- (void)setContentDocShell:(nsISupports*)window;
- (void)resize:(ScreenIntRect)rect;

- (void)sendTouchEvent:(MultiTouchInput::MultiTouchType)aType touches:(NSSet*)aTouches;

- (void)goBack;
- (void)goForward;
- (void)loadRequest:(NSURLRequest*)request;
- (void)stopLoading;
- (void)reload:(BOOL)force;

- (void)updateCanGo;

- (void)viewDestroyed;

@end

class WindowReadyListener final : public nsIObserver {
 public:
  NS_DECL_ISUPPORTS

  WindowReadyListener(ViewGlue* aGlue) : mGlue(aGlue) {
    nsCOMPtr<nsIObserverService> obsServ = mozilla::services::GetObserverService();
    MOZ_ASSERT(obsServ);

    obsServ->AddObserver(this, "Window:Ready", false);
  }

  NS_IMETHODIMP Observe(nsISupports* aSubject, const char* aTopic, const char16_t* aData) override {
    if (strcmp(aTopic, "Window:Ready") == 0) {
      nsCOMPtr<nsPIDOMWindow> window = do_GetInterface(aSubject);
      MOZ_ASSERT(window);

      nsCOMPtr<nsIWidget> widget = WidgetUtils::DOMWindowToWidget(window);
      MOZ_ASSERT(widget);

      widget = widget->GetTopLevelWidget();
      if (widget != mGlue->mWidget) {
        // This event belongs to a different window
        return NS_OK;
      }

      [mGlue setContentDocShell:aSubject];

      // We're done
      nsCOMPtr<nsIObserverService> obsServ = mozilla::services::GetObserverService();
      obsServ->RemoveObserver(this, "Window:Ready");
    }
    return NS_OK;
  }

 private:
  ~WindowReadyListener() {}

  ViewGlue* mGlue;
};

NS_IMPL_ISUPPORTS(WindowReadyListener, nsIObserver)

class ContentListener final : public nsIWebProgressListener,
                              public nsISHistoryListener,
                              public nsSupportsWeakReference {
 public:
  NS_DECL_ISUPPORTS

  ContentListener(ViewGlue* aGlue) : mGlue(aGlue) {}

  void Listen() {
    mWebProgress = do_QueryInterface(mGlue->mBrowserDocShell);
    mWebProgress->AddProgressListener(
        this, nsIWebProgress::NOTIFY_LOCATION | nsIWebProgress::NOTIFY_STATE_ALL);

    nsCOMPtr<nsIWebNavigation> nav = do_QueryInterface(mGlue->mBrowserDocShell);

    nsISHistory* history;
    nav->GetSessionHistory(&history);

    history->AddSHistoryListener(this);
  }

  virtual NS_IMETHODIMP OnProgressChange(nsIWebProgress* aProgress, nsIRequest* aRequest,
                                         int32_t aCurProgress, int32_t aMaxSelfProgress,
                                         int32_t aCurTotalProgress,
                                         int32_t aMaxTotalProgress) override {
    return NS_OK;
  }

  virtual NS_IMETHODIMP OnLocationChange(nsIWebProgress* aProgress, nsIRequest* aRequest,
                                         nsIURI* aLocation, uint32_t aFlags) override {
    nsAutoCString spec;
    aLocation->GetSpec(spec);

    [mGlue updateCanGo];

    if (mGlue.view.navigationDelegate) {
      __block NSString* specStr = [NSString stringWithCString:spec.get()
                                                     encoding:NSUTF8StringEncoding];
      RunBlockOnUIThread(^{
        NSURL* url = [NSURL URLWithString:specStr];
        [mGlue.view setURL:url];
        [mGlue.view.navigationDelegate geckoView:mGlue.view didCommitNavigation:url];
      });
    }
    return NS_OK;
  }

  virtual NS_IMETHODIMP OnStateChange(nsIWebProgress* aWebProgress, nsIRequest* aRequest,
                                      uint32_t aStateFlags, nsresult aStatus) override {
    bool loading;
    aWebProgress->GetIsLoadingDocument(&loading);

    bool topLevel;
    aWebProgress->GetIsTopLevel(&topLevel);

    if ((aStateFlags & nsIWebProgressListener::STATE_IS_NETWORK) &&
        (aStateFlags & nsIWebProgressListener::STATE_STOP) && !loading && topLevel &&
        mGlue.view.navigationDelegate) {
      [mGlue updateCanGo];
      RunBlockOnUIThread(^{
        [mGlue.view.navigationDelegate geckoView:mGlue.view didFinishNavigation:mGlue.view.URL];
      });
    }
    return NS_OK;
  }

  virtual NS_IMETHODIMP OnStatusChange(nsIWebProgress* aWebProgress, nsIRequest* aRequest,
                                       nsresult aStatus, const char16_t* aMessage) override {
    return NS_OK;
  }

  virtual NS_IMETHODIMP OnSecurityChange(nsIWebProgress* aProgress, nsIRequest* aRequest,
                                         uint32_t aState) override {
    return NS_OK;
  }

  virtual NS_IMETHODIMP OnHistoryNewEntry(nsIURI* aURI) override { return NS_OK; }

  virtual NS_IMETHODIMP OnHistoryGoBack(nsIURI* aURI, bool* canGoBack) override {
    *canGoBack = true;
    return NS_OK;
  }

  virtual NS_IMETHODIMP OnHistoryGoForward(nsIURI* aURI, bool* canGoForward) override {
    *canGoForward = true;
    return NS_OK;
  }

  virtual NS_IMETHODIMP OnHistoryReload(nsIURI* aURI, uint32_t aFlags, bool* canReload) override {
    *canReload = true;
    return NS_OK;
  }

  virtual NS_IMETHODIMP OnHistoryGotoIndex(int32_t aIndex, nsIURI* aGotoURI,
                                           bool* canGotoIndex) override {
    *canGotoIndex = true;
    return NS_OK;
  }

  virtual NS_IMETHODIMP OnHistoryPurge(int32_t aNumEntries, bool* canPurge) override {
    *canPurge = true;
    return NS_OK;
  }

  virtual NS_IMETHODIMP OnHistoryReplaceEntry(int32_t aIndex) override { return NS_OK; }

 private:
  ~ContentListener() {}

  ViewGlue* mGlue;
  nsCOMPtr<nsIWebProgress> mWebProgress;
};

NS_IMPL_ISUPPORTS(ContentListener, nsIWebProgressListener, nsISHistoryListener,
                  nsISupportsWeakReference)

@implementation ViewGlue

@synthesize view = mView;

- (id)initWithView:(GeckoWebView*)view {
  self = [super init];
  mView = view;  // weak reference, it owns us
  mTouches = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, nullptr, nullptr);
  mNextTouchID = 0;
  mInputBridge = [[InputBridge alloc] init];

  [view addSubview:mInputBridge];

  return self;
}

- (void)openWindow {
  RunBlockOnMainThread(^{
    mReadyListener = new WindowReadyListener(self);

    nsCOMPtr<nsIWindowWatcher> ww = do_GetService(NS_WINDOWWATCHER_CONTRACTID);
    MOZ_ASSERT(ww);

    nsAdoptingCString url = Preferences::GetCString("toolkit.defaultChromeURI");
    if (!url) {
      url = NS_LITERAL_CSTRING("chrome://browser/content/browser.xul");
    }

    // It's a little naughty to call this outside of the UI thread, but
    // works in practice. The bounds after setup:, so otherwise we would need
    // to cache the bounds in layerSubviews.
    ScreenIntRect r = UIKitPointsToDevPixels([mView bounds], [mView contentScaleFactor]);

    char flags[256];
    snprintf(flags, 256, "chrome,dialog=no,scrollbars=1,all,width=%d,height=%d", r.width, r.height);

    nsCOMPtr<nsIDOMWindow> opened;
    ww->OpenWindow(nullptr, url, "_blank", flags, nullptr, getter_AddRefs(opened));
    MOZ_ASSERT(opened);

    mChromeWindow = do_GetInterface(opened);
    MOZ_ASSERT(mChromeWindow);

    nsCOMPtr<nsIWidget> widget = WidgetUtils::DOMWindowToWidget(mChromeWindow);
    MOZ_ASSERT(widget);

    mWidget = (nsWindow*)widget.get();
    mWidget->SetNativeData(NS_NATIVE_WIDGET, (uintptr_t)mView);
    mInputBridge.widget = mWidget;

    mWidget->Show(true);

    RunBlockOnUIThread(^{
      mWidget->ConfigureAPZControllerThread();
    });
  });
}

- (void)closeWindow {
  MOZ_ASSERT(NS_IsMainThread());
  mChromeWindow->Close();
}

- (void)setContentDocShell:(nsISupports*)docShell {
  // This is called on the Gecko thread by WindowReadyListener

  mBrowserDocShell = do_QueryInterface(docShell);
  mWebNavigation = do_QueryInterface(mBrowserDocShell);

  mContentListener = new ContentListener(self);
  mContentListener->Listen();

  mReadyListener = nullptr;

  // Load any pending request
  if (mPendingRequest) {
    NSURLRequest* req = mPendingRequest;
    mPendingRequest = nil;
    [self loadRequest:req];
    [req release];
  }
}

- (void)resize:(ScreenIntRect)rect {
  if (mWidget) {
    __block ScreenIntRect r = rect;

    // We do this from the UI thread to avoid being blocked by Gecko
    mWidget->ResizeCompositor(r.width, r.height);

    RunBlockOnMainThread(^{
      // Adjust the XUL window size to match
      mWidget->Resize(r.width, r.height, false);
    });
  }
}

- (void)sendTouchEvent:(MultiTouchInput::MultiTouchType)aType touches:(NSSet*)aTouches {
  MultiTouchInput input(aType, PR_IntervalNow(), TimeStamp(), 0);

  input.mTouches.SetCapacity([aTouches count]);
  for (UITouch* touch in aTouches) {
    ScreenIntPoint loc =
        UIKitPointsToDevPixels([touch locationInView:mView], [mView contentScaleFactor]);
    void* value;
    if (!CFDictionaryGetValueIfPresent(mTouches, touch, (const void**)&value)) {
      // This shouldn't happen.
      NS_ASSERTION(false, "Got a touch that we didn't know about");
      continue;
    }
    uintptr_t id = reinterpret_cast<uintptr_t>(value);
    SingleTouchData data(
        id, loc, ScreenSize::FromUnknownSize(gfx::Size([touch majorRadius], [touch majorRadius])),
        0.0f, 1.0f);
    input.mTouches.AppendElement(data);
  }
  mWidget->DispatchTouchInput(input);
}

- (void)goBack {
  RunBlockOnMainThread(^{
    if (mWebNavigation) {
      mWebNavigation->GoBack();
    }
  });
}

- (void)goForward {
  RunBlockOnMainThread(^{
    if (mWebNavigation) {
      mWebNavigation->GoForward();
    }
  });
}

- (void)loadRequest:(NSURLRequest*)request {
  __block NSURLRequest* r = [request retain];
  RunBlockOnMainThread(^{
    if (mWebNavigation) {
      nsString uri = NS_ConvertUTF8toUTF16([[[r URL] absoluteString] UTF8String]);
      mWebNavigation->LoadURI(uri.get(), 0, nullptr, nullptr, nullptr);
      [r release];
    } else {
      mPendingRequest = r;
    }
  });
}

- (void)stopLoading {
  RunBlockOnMainThread(^{
    if (mWebNavigation) {
      mWebNavigation->Stop(nsIWebNavigation::STOP_NETWORK);
    }
  });
}

- (void)reload:(BOOL)force {
  RunBlockOnMainThread(^{
    if (mWebNavigation) {
      mWebNavigation->Reload(force ? nsIWebNavigation::LOAD_FLAGS_BYPASS_CACHE |
                                         nsIWebNavigation::LOAD_FLAGS_BYPASS_PROXY
                                   : 0);
    }
  });
}

- (void)updateCanGo {
  // This is called on the Gecko thread from the ContentListener
  bool val;
  mWebNavigation->GetCanGoBack(&val);
  mCanGoBack = (BOOL)val;

  mWebNavigation->GetCanGoForward(&val);
  mCanGoForward = (BOOL)val;
}

- (void)viewDestroyed {
  mView = nil;
  if (mWidget) {
    mWidget->NativeViewDestroyed();
  }
}

- (void)dealloc {
  // GeckoWebView makes sure we get released on the main thread
  MOZ_ASSERT(NS_IsMainThread());

  [self closeWindow];
  CFRelease(mTouches);
  [super dealloc];
}

@end

@implementation GeckoWebView
+ (Class)layerClass {
  // We're going to draw this view with EAGL
  return [CAEAGLLayer class];
}

+ (MessageLoop*)UIMessageLoop {
  return sUIMessageLoop;
}

@synthesize title = mTitle;
@synthesize navigationDelegate = mNavigationDelegate;
@synthesize UIDelegate = mUIDelegate;
@synthesize URL = mURL;

- (nsWindow*)widget {
  return mGlue->mWidget;
}

- (void)setWidget:(nsWindow*)widget {
  mGlue->mWidget = widget;
}

- (id)initWithFrame:(CGRect)inFrame {
  self = [super initWithFrame:inFrame];
  [self setup];
  return self;
}

- (id)initWithCoder:(NSCoder*)decoder {
  self = [super initWithCoder:decoder];
  [self setup];
  return self;
}

- (void)dealloc {
  __block ViewGlue* glue = mGlue;
  RunBlockOnMainThread(^{
    [glue release];
  });
  [super dealloc];
}

- (void)setup {
  mGlue = [[ViewGlue alloc] initWithView:self];

  if (!sUIMessageLoop) {
    // We need a Gecko message loop on the iOS UI thread, because we're going
    // to use this as the APZ controller thread, and it uses PostTask() and
    // stuff like that.
    sUIMessageLoop = new MessageLoop(MessageLoop::TYPE_UI);
    sUIMessageLoop->set_thread_name("iOS UI");
    sUIMessageLoop->Attach();
    APZThreadUtils::SetControllerThread(sUIMessageLoop);
  }

  if (![GeckoThread sharedThread]) {
    [GeckoThread startup];
  }

  // These are the recommended settings for a UIView drawn with EAGL. Not sure
  // if we want something else or not.
  self.multipleTouchEnabled = YES;
  self.opaque = YES;
  self.alpha = 1.0;

  [[GeckoThread sharedThread] waitUntilReady];
  [mGlue openWindow];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  [mGlue resize:UIKitPointsToDevPixels([self bounds], [self contentScaleFactor])];
}

- (void)widgetDestroyed {
  // mWindow = nullptr;
}

- (BOOL)canBecomeFirstResponder {
  return YES;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
  LOG("[GeckoWebView[%p] touchesBegan", self);
  [self becomeFirstResponder];
  for (UITouch* touch : touches) {
    CFDictionaryAddValue(mGlue->mTouches, touch, (void*)mGlue->mNextTouchID);
    mGlue->mNextTouchID++;
  }
  [mGlue sendTouchEvent:MultiTouchInput::MULTITOUCH_START touches:[event allTouches]];
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event {
  LOG("[GeckoWebView[%p] touchesCancelled", self);
  [mGlue sendTouchEvent:MultiTouchInput::MULTITOUCH_CANCEL touches:touches];
  for (UITouch* touch : touches) {
    CFDictionaryRemoveValue(mGlue->mTouches, touch);
  }
  if (CFDictionaryGetCount(mGlue->mTouches) == 0) {
    mGlue->mNextTouchID = 0;
  }
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
  LOG("[GeckoWebView[%p] touchesEnded", self);
  [mGlue sendTouchEvent:MultiTouchInput::MULTITOUCH_END touches:touches];
  for (UITouch* touch : touches) {
    CFDictionaryRemoveValue(mGlue->mTouches, touch);
  }
  if (CFDictionaryGetCount(mGlue->mTouches) == 0) {
    mGlue->mNextTouchID = 0;
  }
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
  LOG("[GeckoWebView[%p] touchesMoved", self);
  [mGlue sendTouchEvent:MultiTouchInput::MULTITOUCH_MOVE touches:[event allTouches]];
}

// For some reason we need an empty impl here
- (void)drawRect:(CGRect)aRect {
}

- (void)drawRect:(CGRect)aRect inContext:(CGContextRef)aContext {
}

- (void)setURL:(NSURL*)url {
  [mURL release];
  mURL = [url copy];
}

- (void)fullScreenChanged:(BOOL)fullscreen {
  if (self.UIDelegate) {
    [self.UIDelegate geckoView:self fullScreenChanged:fullscreen];
  }
}

- (void)setKeyboardEnabled:(BOOL)enabled {
  if (enabled) {
    [mGlue->mInputBridge becomeFirstResponder];
  } else {
    [mGlue->mInputBridge resignFirstResponder];
  }
}

- (BOOL)canGoBack {
  return mGlue->mCanGoBack;
}

- (BOOL)canGoForward {
  return mGlue->mCanGoForward;
}

- (void)goBack {
  [mGlue goBack];
}

- (void)goForward {
  [mGlue goForward];
}

- (void)loadRequest:(NSURLRequest*)request {
  [mGlue loadRequest:request];
}

- (void)stopLoading {
  [mGlue stopLoading];
}

- (void)reload {
  [mGlue reload:false];
}

- (void)reloadFromOrigin {
  [mGlue reload:true];
}

@end
