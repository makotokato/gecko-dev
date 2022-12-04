/* -*- Mode: C++; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#include "nsAppShell.h"
#include "nsCOMPtr.h"
#include "nsDirectoryServiceDefs.h"
#include "nsIDocShell.h"
#include "nsIFile.h"
#include "nsIInterfaceRequestor.h"
#include "nsIInterfaceRequestorUtils.h"
#include "nsIObserverService.h"
#include "nsIRollupListener.h"
#include "nsIWebBrowserChrome.h"
#include "nsIWebProgressListener.h"
#include "nsIWidget.h"
#include "nsIWindowMediator.h"
#include "nsMemoryPressure.h"
#include "nsNetUtil.h"
#include "nsServiceManagerUtils.h"
#include "nsString.h"
#include "nsThreadUtils.h"

#import "GeckoThread.h"
#import "GeckoWebView.h"

#include "mozilla/Services.h"

nsAppShell* nsAppShell::gAppShell = NULL;
CFRunLoopRef nsAppShell::gRunLoop = nil;

#define ALOG(args...)    \
  fprintf(stderr, args); \
  fprintf(stderr, "\n")

// nsAppShell implementation

NS_IMETHODIMP
nsAppShell::ResumeNative(void) { return nsBaseAppShell::ResumeNative(); }

nsAppShell::nsAppShell()
    : mAutoreleasePool(NULL),
      mCFRunLoop(NULL),
      mCFRunLoopSource(NULL),
      mTerminated(false),
      mNotifiedWillTerminate(false) {
  gAppShell = this;
}

nsAppShell::~nsAppShell() {
  if (mAutoreleasePool) {
    [mAutoreleasePool release];
    mAutoreleasePool = NULL;
  }

  if (mCFRunLoop) {
    if (mCFRunLoopSource) {
      ::CFRunLoopRemoveSource(mCFRunLoop, mCFRunLoopSource, kCFRunLoopCommonModes);
      ::CFRelease(mCFRunLoopSource);
    }
    ::CFRelease(mCFRunLoop);
  }

  gAppShell = NULL;
}

// Init
//
// public
nsresult nsAppShell::Init() {
  mAutoreleasePool = [[NSAutoreleasePool alloc] init];

  // Add a CFRunLoopSource to the main native run loop.  The source is
  // responsible for interrupting the run loop when Gecko events are ready.
  mCFRunLoop = gRunLoop = [[NSRunLoop currentRunLoop] getCFRunLoop];
  NS_ENSURE_STATE(mCFRunLoop);
  ::CFRetain(mCFRunLoop);

  CFRunLoopSourceContext context;
  bzero(&context, sizeof(context));
  // context.version = 0;
  context.info = this;
  context.perform = ProcessGeckoEvents;

  mCFRunLoopSource = ::CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &context);
  NS_ENSURE_STATE(mCFRunLoopSource);

  ::CFRunLoopAddSource(mCFRunLoop, mCFRunLoopSource, kCFRunLoopCommonModes);

  nsCOMPtr<nsIObserverService> obs = mozilla::services::GetObserverService();

  obs->AddObserver(this, "profile-after-change", false);

  return nsBaseAppShell::Init();
}

NS_IMETHODIMP
nsAppShell::Observe(nsISupports* subject, const char* topic, const char16_t* data) {
  if (strcmp(topic, "profile-after-change") == 0) {
    [[GeckoThread sharedThread] notifyReady];
    return NS_OK;
  } else {
    return nsBaseAppShell::Observe(subject, topic, data);
  }
}

// ProcessGeckoEvents
//
// The "perform" target of mCFRunLoop, called when mCFRunLoopSource is
// signalled from ScheduleNativeEventCallback.
//
// protected static
void nsAppShell::ProcessGeckoEvents(void* aInfo) {
  nsAppShell* self = static_cast<nsAppShell*>(aInfo);
  self->NativeEventCallback();
  self->Release();
}

// WillTerminate
//
// public
void nsAppShell::WillTerminate() {
  mNotifiedWillTerminate = true;
  if (mTerminated) return;
  mTerminated = true;
  // We won't get another chance to process events
  NS_ProcessPendingEvents(NS_GetCurrentThread());

  // Unless we call nsBaseAppShell::Exit() here, it might not get called
  // at all.
  nsBaseAppShell::Exit();
}

// ScheduleNativeEventCallback
//
// protected virtual
void nsAppShell::ScheduleNativeEventCallback() {
  if (mTerminated) return;

  NS_ADDREF_THIS();

  // This will invoke ProcessGeckoEvents on the main thread.
  ::CFRunLoopSourceSignal(mCFRunLoopSource);
  ::CFRunLoopWakeUp(mCFRunLoop);
}

// ProcessNextNativeEvent
//
// protected virtual
bool nsAppShell::ProcessNextNativeEvent(bool aMayWait) {
// This seems to break stuff, not sure if it's needed anymore
#if 0
  if (mTerminated)
    return false;

  NSString* currentMode = nil;
  NSDate* waitUntil = nil;
  if (aMayWait)
    waitUntil = [NSDate distantFuture];
  NSRunLoop* currentRunLoop = [NSRunLoop currentRunLoop];

  BOOL eventProcessed = NO;
  do {
    currentMode = [currentRunLoop currentMode];
    if (!currentMode)
      currentMode = NSDefaultRunLoopMode;

    if (aMayWait)
      eventProcessed = [currentRunLoop runMode:currentMode beforeDate:waitUntil];
    else
      [currentRunLoop acceptInputForMode:currentMode beforeDate:waitUntil];
  } while(eventProcessed && aMayWait);
#endif
  return false;
}

// Run
//
// public
NS_IMETHODIMP
nsAppShell::Run(void) {
  ALOG("nsAppShell::Run");
  CFRunLoopRun();
  return NS_OK;
}

NS_IMETHODIMP
nsAppShell::Exit(void) {
  if (mTerminated) return NS_OK;

  mTerminated = true;
  return nsBaseAppShell::Exit();
}
