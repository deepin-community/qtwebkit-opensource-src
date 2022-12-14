/*
 * Copyright (C) 2015 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <WebKit/WKFoundation.h>

#if WK_API_ENABLED

#import <Foundation/Foundation.h>
#import <WebKit/WKDeclarationSpecifiers.h>

WK_EXPORT extern NSString * const _WKMenuItemIdentifierCopy WK_AVAILABLE(WK_MAC_TBA, WK_IOS_TBA);
WK_EXPORT extern NSString * const _WKMenuItemIdentifierCopyImage WK_AVAILABLE(WK_MAC_TBA, WK_IOS_TBA);
WK_EXPORT extern NSString * const _WKMenuItemIdentifierCopyLink WK_AVAILABLE(WK_MAC_TBA, WK_IOS_TBA);
WK_EXPORT extern NSString * const _WKMenuItemIdentifierDownloadImage WK_AVAILABLE(WK_MAC_TBA, WK_IOS_TBA);
WK_EXPORT extern NSString * const _WKMenuItemIdentifierDownloadLinkedFile WK_AVAILABLE(WK_MAC_TBA, WK_IOS_TBA);
WK_EXPORT extern NSString * const _WKMenuItemIdentifierGoBack WK_AVAILABLE(WK_MAC_TBA, WK_IOS_TBA);
WK_EXPORT extern NSString * const _WKMenuItemIdentifierGoForward WK_AVAILABLE(WK_MAC_TBA, WK_IOS_TBA);
WK_EXPORT extern NSString * const _WKMenuItemIdentifierInspectElement WK_AVAILABLE(WK_MAC_TBA, WK_IOS_TBA);
WK_EXPORT extern NSString * const _WKMenuItemIdentifierLookUp WK_AVAILABLE(WK_MAC_TBA, WK_IOS_TBA);
WK_EXPORT extern NSString * const _WKMenuItemIdentifierOpenFrameInNewWindow WK_AVAILABLE(WK_MAC_TBA, WK_IOS_TBA);
WK_EXPORT extern NSString * const _WKMenuItemIdentifierOpenImageInNewWindow WK_AVAILABLE(WK_MAC_TBA, WK_IOS_TBA);
WK_EXPORT extern NSString * const _WKMenuItemIdentifierOpenLink WK_AVAILABLE(WK_MAC_TBA, WK_IOS_TBA);
WK_EXPORT extern NSString * const _WKMenuItemIdentifierOpenLinkInNewWindow WK_AVAILABLE(WK_MAC_TBA, WK_IOS_TBA);
WK_EXPORT extern NSString * const _WKMenuItemIdentifierPaste WK_AVAILABLE(WK_MAC_TBA, WK_IOS_TBA);
WK_EXPORT extern NSString * const _WKMenuItemIdentifierReload WK_AVAILABLE(WK_MAC_TBA, WK_IOS_TBA);
WK_EXPORT extern NSString * const _WKMenuItemIdentifierSearchWeb WK_AVAILABLE(WK_MAC_TBA, WK_IOS_TBA);
WK_EXPORT extern NSString * const _WKMenuItemIdentifierShowHideMediaControls WK_AVAILABLE(WK_MAC_TBA, WK_IOS_TBA);
WK_EXPORT extern NSString * const _WKMenuItemIdentifierToggleFullScreen WK_AVAILABLE(WK_MAC_TBA, WK_IOS_TBA);

WK_EXPORT extern NSString * const _WKMenuItemIdentifierShareMenu WK_AVAILABLE(WK_MAC_TBA, WK_IOS_TBA);
WK_EXPORT extern NSString * const _WKMenuItemIdentifierSpeechMenu WK_AVAILABLE(WK_MAC_TBA, WK_IOS_TBA);

#endif
