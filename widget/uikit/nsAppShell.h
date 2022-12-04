/* -*- Mode: C++; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/*
 * Runs the main native UIKit run loop, interrupting it as needed to process
 * Gecko events.
 */

#ifndef nsAppShell_h_
#define nsAppShell_h_

#include "nsBaseAppShell.h"
#include "nsTArray.h"

#include <CoreFoundation/CFRunLoop.h>
#include <Foundation/NSAutoreleasePool.h>
#include <UIKit/UIWindow.h>

class nsAppShell : public nsBaseAppShell {
 public:
  NS_IMETHOD ResumeNative(void) override;

  nsAppShell();

  nsresult Init();

  NS_IMETHOD Run(void) override;
  NS_IMETHOD Exit(void) override;
  // Called by the application delegate
  void WillTerminate(void);

  NS_IMETHOD Observe(nsISupports* subject, const char* topic, const char16_t* data) override;

  static nsAppShell* gAppShell;
  static CFRunLoopRef gRunLoop;

 protected:
  virtual ~nsAppShell();

  static void ProcessGeckoEvents(void* aInfo);
  virtual void ScheduleNativeEventCallback() override;
  virtual bool ProcessNextNativeEvent(bool aMayWait) override;

  NSAutoreleasePool* mAutoreleasePool;
  CFRunLoopRef mCFRunLoop;
  CFRunLoopSourceRef mCFRunLoopSource;

  bool mTerminated;
  bool mNotifiedWillTerminate;
};

inline void RunBlockOnMainThread(void (^block)(void)) {
  MOZ_ASSERT(nsAppShell::gRunLoop);
  CFRunLoopPerformBlock(nsAppShell::gRunLoop, kCFRunLoopDefaultMode, block);
  CFRunLoopWakeUp(nsAppShell::gRunLoop);
}

inline void RunBlockOnUIThread(void (^block)(void)) {
  CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopDefaultMode, block);
  CFRunLoopWakeUp(CFRunLoopGetMain());
}

#endif  // nsAppShell_h_
