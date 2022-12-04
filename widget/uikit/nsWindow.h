/* -*- Mode: C++; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef NSWINDOW_H_
#define NSWINDOW_H_

#include "InputData.h"
#include "gfxPoint.h"
#include "nsBaseWidget.h"

#include "nsTArray.h"

@class UIWindow;
@class UIView;
@class GeckoWebView;
class gfxASurface;

class nsWindow final : public nsBaseWidget {
  typedef nsBaseWidget Inherited;

 public:
  nsWindow();

  NS_INLINE_DECL_REFCOUNTING_INHERITED(nsWindow, Inherited)

  //
  // nsIWidget
  //

  [[nodiscard]] virtual nsresult Create(nsIWidget* aParent, nsNativeWidget aNativeParent,
                                        const LayoutDeviceIntRect& aRect,
                                        nsWidgetInitData* aInitData = nullptr) override;
  virtual void Destroy() override;
  virtual void Show(bool aState) override;
  virtual void Enable(bool aState) override {}
  virtual nsIWidget* GetParent() override { return mParent; }
  virtual bool IsEnabled() const override { return true; }
  virtual bool IsVisible() const override { return mVisible; }
  virtual void SetFocus(Raise, mozilla::dom::CallerType aCallerType) override;
  virtual LayoutDeviceIntPoint WidgetToScreenOffset() override;

  virtual void SetBackgroundColor(const nscolor& aColor) override;
  virtual void* GetNativeData(uint32_t aDataType) override;
  virtual void SetNativeData(uint32_t aDataType, uintptr_t aVal) override;

  virtual void ConstrainPosition(bool aAllowSlop, int32_t* aX, int32_t* aY) override {}
  virtual void Move(double aX, double aY) override;
  virtual nsSizeMode SizeMode() override { return mSizeMode; }
  virtual void SetSizeMode(nsSizeMode aMode) override;
  void EnteredFullScreen(bool aFullScreen);
  virtual void Resize(double aWidth, double aHeight, bool aRepaint) override;
  virtual void Resize(double aX, double aY, double aWidth, double aHeight, bool aRepaint) override;
  virtual LayoutDeviceIntRect GetScreenBounds() override { return mBounds; }
  void ReportMoveEvent();
  void ReportSizeEvent();
  void ReportSizeModeEvent(nsSizeMode aMode);
  virtual nsresult MakeFullScreen(bool aFullScreen) override;

  CGFloat BackingScaleFactor();
  void BackingScaleFactorChanged();
  virtual float GetDPI() override {
    // XXX: terrible
    return 326.0f;
  }
  virtual double GetDefaultScaleInternal() override { return BackingScaleFactor(); }
  virtual int32_t RoundsWidgetCoordinatesTo() override;

  virtual nsresult SetTitle(const nsAString& aTitle) override { return NS_OK; }

  virtual void Invalidate(const LayoutDeviceIntRect& aRect) override {}
  virtual nsresult DispatchEvent(mozilla::WidgetGUIEvent* aEvent, nsEventStatus& aStatus) override;

  bool HasModalDescendents() { return false; }

  virtual void SetInputContext(const InputContext& aContext,
                               const InputContextAction& aAction) override;
  virtual InputContext GetInputContext() override;

  void ConfigureAPZControllerThread() override;

  void DispatchTouchInput(mozilla::MultiTouchInput& aInput);

  void NativeViewDestroyed();

  void InsertText(const char* aText);
  void DeleteCharacter();

 protected:
  virtual ~nsWindow();
  void BringToFront();
  nsWindow* FindTopLevel();
  bool IsTopLevel();
  nsresult GetCurrentOffset(uint32_t& aOffset, uint32_t& aLength);
  nsresult DeleteRange(int aOffset, int aLen);

  GeckoWebView* mNativeView;
  bool mIsFullScreen;
  bool mVisible;
  nsSizeMode mSizeMode;
  nsTArray<nsWindow*> mChildren;
  nsWindow* mParent;
  InputContext mInputContext;
  mozilla::widget::PlatformCompositorWidgetDelegate* mCompositorWidgetDelegate;

  static void DumpWindows();
  static void DumpWindows(const nsTArray<nsWindow*>& wins, int indent = 0);
  static void LogWindow(nsWindow* win, int index, int indent);
};

#endif /* NSWINDOW_H_ */
