/* -*- Mode: C++; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// This file contains forward declarations for classes defined in static
// components. The appropriate headers for those types cannot be included in
// the generated static component code directly.

#include "nsID.h"

namespace mozilla::widget {
class ScreenManager;
}

class nsHTMLFormatConverter;

nsresult nsAppShellConstructor(const nsIID&, void**);

void nsWidgetUIKitModuleCtor();
void nsWidgetUIKitModuleDtor();
