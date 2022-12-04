/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIView.h>

@class ViewGlue;
@class GeckoWebView;

__attribute__((visibility("default")))
@protocol GeckoWebViewNavigationDelegate

- (void)geckoView:(GeckoWebView*)view didCommitNavigation:(NSURL*)url;
- (void)geckoView:(GeckoWebView*)view didFinishNavigation:(NSURL*)url;

@end

__attribute__((visibility("default")))
@protocol GeckoWebViewUIDelegate

- (void)geckoView:(GeckoWebView*)view fullScreenChanged:(BOOL)fullScreen;

@end

__attribute__((visibility("default")))
@interface GeckoWebView : UIView {
 @private
  ViewGlue* mGlue;
  NSString* mTitle;
  id<GeckoWebViewNavigationDelegate> mNavigationDelegate;
  id<GeckoWebViewUIDelegate> mUIDelegate;
  NSURL* mURL;
}

@property(nonatomic, readonly, copy) NSString* title;

@property(nonatomic, weak) id<GeckoWebViewNavigationDelegate> navigationDelegate;
@property(nonatomic, weak) id<GeckoWebViewUIDelegate> UIDelegate;

@property(nonatomic, readonly) BOOL canGoBack;
@property(nonatomic, readonly) BOOL canGoForward;
@property(nonatomic, readonly, copy) NSURL* URL;

- (void)goBack;
- (void)goForward;
- (void)loadRequest:(NSURLRequest*)request;
- (void)stopLoading;
- (void)reload;
- (void)reloadFromOrigin;

@end
