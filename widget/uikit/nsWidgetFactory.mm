/* -*- Mode: C++; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "nsISupports.h"
#include "mozilla/ModuleUtils.h"

#include "nsWidgetsCID.h"

#include "nsAppShell.h"
#include "nsAppShellSingleton.h"
#include "nsLookAndFeel.h"

#include "GfxInfo.h"

nsresult nsWidgetUIKitModuleCtor() { return nsAppShellInit(); }

void nsWidgetUIKitModuleDtor() {
  // Shutdown all XP level widget classes.
  WidgetUtils::Shutdown();

  nsLookAndFeel::Shutdown();
  nsAppShellShutdown();
}

