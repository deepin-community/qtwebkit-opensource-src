/*
 * Copyright (C) 2006, 2007 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer. 
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution. 
 * 3.  Neither the name of Apple Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission. 
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "GlyphPage.h"

#include "CoreGraphicsSPI.h"
#include "CoreTextSPI.h"
#include "Font.h"
#include "FontCascade.h"
#include "WebCoreSystemInterface.h"
#if !PLATFORM(IOS)
#include <ApplicationServices/ApplicationServices.h>
#endif

namespace WebCore {

static bool shouldUseCoreText(const UChar* buffer, unsigned bufferLength, const Font& fontData)
{
    // This needs to be kept in sync with GlyphPage::fill(). Currently, the CoreText paths are not able to handle
    // every situtation. Returning true from this function in a new situation will require you to explicitly add
    // handling for that situation in the CoreText paths of GlyphPage::fill().
    if (fontData.platformData().isSystemFont())
        return true;
    if (fontData.platformData().isForTextCombine() || fontData.hasVerticalGlyphs()) {
        // Ideographs don't have a vertical variant or width variants.
        for (unsigned i = 0; i < bufferLength; ++i) {
            if (!FontCascade::isCJKIdeograph(buffer[i]))
                return true;
        }
    }

    return false;
}

bool GlyphPage::fill(UChar* buffer, unsigned bufferLength)
{
    ASSERT(bufferLength == GlyphPage::size || bufferLength == 2 * GlyphPage::size);

    const Font& font = this->font();
    Vector<CGGlyph, 512> glyphs(bufferLength);
    unsigned glyphStep;
    if (!shouldUseCoreText(buffer, bufferLength, font)) {
        // We pass in either 256 or 512 UTF-16 characters: 256 for U+FFFF and less, 512 (double character surrogates)
        // for U+10000 and above. It is indeed possible to get back 512 glyphs back from the API, so the glyph buffer
        // we pass in must be 512. If we get back more than 256 glyphs though we'll ignore all the ones after 256,
        // this should not happen as the only time we pass in 512 characters is when they are surrogates.
        CGFontGetGlyphsForUnichars(font.platformData().cgFont(), buffer, glyphs.data(), bufferLength);
        glyphStep = 1;
    } else {
        // Because we know the implementation of shouldUseCoreText(), if the font isn't for text combine and it isn't a system font,
        // we know it must have vertical glyphs.
        if (font.platformData().isForTextCombine() || font.platformData().isSystemFont())
            CTFontGetGlyphsForCharacters(font.platformData().ctFont(), buffer, glyphs.data(), bufferLength);
        else
            CTFontGetVerticalGlyphsForCharacters(font.platformData().ctFont(), buffer, glyphs.data(), bufferLength);

        // When buffer consists of surrogate pairs, CTFontGetVerticalGlyphsForCharacters and CTFontGetGlyphsForCharacters
        // place the glyphs at indices corresponding to the first character of each pair.
        glyphStep = bufferLength / GlyphPage::size;
    }

    bool haveGlyphs = false;
    for (unsigned i = 0; i < GlyphPage::size; ++i) {
        if (glyphs[i * glyphStep]) {
            setGlyphForIndex(i, glyphs[i * glyphStep]);
            haveGlyphs = true;
        }
    }
    return haveGlyphs;
}

} // namespace WebCore
