/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>

__attribute__((visibility("default")))
@interface GeckoThread : NSThread {
 @private
  NSCondition* mCondition;
  BOOL mReady;
}

+ (GeckoThread*)sharedThread;
+ (void)startup;

@property(readonly) BOOL ready;

- (void)waitUntilReady;
- (void)notifyReady;

@end
