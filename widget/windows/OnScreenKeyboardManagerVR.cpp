/* -*- Mode: C++; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* vim:set ts=2 sts=2 sw=2 et cin: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "OnScreenKeyboardManagerVR.h"

#include "FxRWindowManager.h"
#include "VRShMem.h"
#include "moz_external_vr.h"

namespace mozilla {
namespace widget {

// static
void OnScreenKeyboardManagerVR::Show() {
  mozilla::gfx::VRShMem shmem(nullptr, true /*aRequiresMutex*/);
  shmem.SendIMEState(FxRWindowManager::GetInstance()->GetWindowID(),
                     mozilla::gfx::VRFxEventState::FOCUS);
}

// static
void OnScreenKeyboardManagerVR::Dismiss() {
  mozilla::gfx::VRShMem shmem(nullptr, true /*aRequiresMutex*/);
  shmem.SendIMEState(FxRWindowManager::GetInstance()->GetWindowID(),
                     mozilla::gfx::VRFxEventState::BLUR);
}

void OnScreenKeyboardManagerVR::IsVisible() {
  // Unknown
  return false;
}

}  // namespace widget
}  // namespace mozilla
