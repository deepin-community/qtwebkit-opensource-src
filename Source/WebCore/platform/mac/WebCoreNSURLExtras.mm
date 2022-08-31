/*
 * Copyright (C) 2005, 2007, 2014 Apple Inc. All rights reserved.
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

#import "config.h"
#import "WebCoreObjCExtras.h"
#import "WebCoreNSStringExtras.h"
#import "WebCoreNSURLExtras.h"
#import "WebCoreSystemInterface.h"
#import <functional>
#import <wtf/ObjcRuntimeExtras.h>
#import <wtf/RetainPtr.h>
#import <wtf/Vector.h>
#import <unicode/uchar.h>
#import <unicode/uidna.h>
#import <unicode/uscript.h>

// Needs to be big enough to hold an IDN-encoded name.
// For host names bigger than this, we won't do IDN encoding, which is almost certainly OK.
#define HOST_NAME_BUFFER_LENGTH 2048
#define URL_BYTES_BUFFER_LENGTH 2048

typedef void (* StringRangeApplierFunction)(NSString *string, NSRange range, void *context);

static pthread_once_t IDNScriptWhiteListFileRead = PTHREAD_ONCE_INIT;
static uint32_t IDNScriptWhiteList[(USCRIPT_CODE_LIMIT + 31) / 32];


@interface NSURLProtocol (WKNSURLProtocolInternal)
+ (Class)_protocolClassForRequest:(NSURLRequest *)request;
@end

namespace WebCore {

static BOOL isLookalikeCharacter(UChar32 charCode)
{
    // This function treats the following as unsafe, lookalike characters:
    // any non-printable character, any character considered as whitespace,
    // any ignorable character, and emoji characters related to locks.
    
    // We also considered the characters in Mozilla's blacklist <http://kb.mozillazine.org/Network.IDN.blacklist_chars>.

    // Some of the characters here will never appear once ICU has encoded.
    // For example, ICU transforms most spaces into an ASCII space and most
    // slashes into an ASCII solidus. But one of the two callers uses this
    // on characters that have not been processed by ICU, so they are needed here.
    
    if (!u_isprint(charCode) || u_isUWhiteSpace(charCode) || u_hasBinaryProperty(charCode, UCHAR_DEFAULT_IGNORABLE_CODE_POINT))
        return YES;
    
    switch (charCode) {
        case 0x00BC: /* VULGAR FRACTION ONE QUARTER */
        case 0x00BD: /* VULGAR FRACTION ONE HALF */
        case 0x00BE: /* VULGAR FRACTION THREE QUARTERS */
        case 0x00ED: /* LATIN SMALL LETTER I WITH ACUTE */
        case 0x01C3: /* LATIN LETTER RETROFLEX CLICK */
        case 0x0251: /* LATIN SMALL LETTER ALPHA */
        case 0x0261: /* LATIN SMALL LETTER SCRIPT G */
        case 0x02D0: /* MODIFIER LETTER TRIANGULAR COLON */
        case 0x0335: /* COMBINING SHORT STROKE OVERLAY */
        case 0x0337: /* COMBINING SHORT SOLIDUS OVERLAY */
        case 0x0338: /* COMBINING LONG SOLIDUS OVERLAY */
        case 0x0589: /* ARMENIAN FULL STOP */
        case 0x05B4: /* HEBREW POINT HIRIQ */
        case 0x05BC: /* HEBREW POINT DAGESH OR MAPIQ */
        case 0x05C3: /* HEBREW PUNCTUATION SOF PASUQ */
        case 0x05F4: /* HEBREW PUNCTUATION GERSHAYIM */
        case 0x0609: /* ARABIC-INDIC PER MILLE SIGN */
        case 0x060A: /* ARABIC-INDIC PER TEN THOUSAND SIGN */
        case 0x0660: /* ARABIC INDIC DIGIT ZERO */
        case 0x066A: /* ARABIC PERCENT SIGN */
        case 0x06D4: /* ARABIC FULL STOP */
        case 0x06F0: /* EXTENDED ARABIC INDIC DIGIT ZERO */
        case 0x0701: /* SYRIAC SUPRALINEAR FULL STOP */
        case 0x0702: /* SYRIAC SUBLINEAR FULL STOP */
        case 0x0703: /* SYRIAC SUPRALINEAR COLON */
        case 0x0704: /* SYRIAC SUBLINEAR COLON */
        case 0x1735: /* PHILIPPINE SINGLE PUNCTUATION */
        case 0x2024: /* ONE DOT LEADER */
        case 0x2027: /* HYPHENATION POINT */
        case 0x2039: /* SINGLE LEFT-POINTING ANGLE QUOTATION MARK */
        case 0x203A: /* SINGLE RIGHT-POINTING ANGLE QUOTATION MARK */
        case 0x2041: /* CARET INSERTION POINT */
        case 0x2044: /* FRACTION SLASH */
        case 0x2052: /* COMMERCIAL MINUS SIGN */
        case 0x2153: /* VULGAR FRACTION ONE THIRD */
        case 0x2154: /* VULGAR FRACTION TWO THIRDS */
        case 0x2155: /* VULGAR FRACTION ONE FIFTH */
        case 0x2156: /* VULGAR FRACTION TWO FIFTHS */
        case 0x2157: /* VULGAR FRACTION THREE FIFTHS */
        case 0x2158: /* VULGAR FRACTION FOUR FIFTHS */
        case 0x2159: /* VULGAR FRACTION ONE SIXTH */
        case 0x215A: /* VULGAR FRACTION FIVE SIXTHS */
        case 0x215B: /* VULGAR FRACTION ONE EIGHT */
        case 0x215C: /* VULGAR FRACTION THREE EIGHTHS */
        case 0x215D: /* VULGAR FRACTION FIVE EIGHTHS */
        case 0x215E: /* VULGAR FRACTION SEVEN EIGHTHS */
        case 0x215F: /* FRACTION NUMERATOR ONE */
        case 0x2215: /* DIVISION SLASH */
        case 0x2216: /* SET MINUS */
        case 0x2236: /* RATIO */
        case 0x233F: /* APL FUNCTIONAL SYMBOL SLASH BAR */
        case 0x23AE: /* INTEGRAL EXTENSION */
        case 0x244A: /* OCR DOUBLE BACKSLASH */
        case 0x2571: /* BOX DRAWINGS LIGHT DIAGONAL UPPER RIGHT TO LOWER LEFT */
        case 0x2572: /* BOX DRAWINGS LIGHT DIAGONAL UPPER LEFT TO LOWER RIGHT */
        case 0x29F6: /* SOLIDUS WITH OVERBAR */
        case 0x29F8: /* BIG SOLIDUS */
        case 0x2AFB: /* TRIPLE SOLIDUS BINARY RELATION */
        case 0x2AFD: /* DOUBLE SOLIDUS OPERATOR */
        case 0x2FF0: /* IDEOGRAPHIC DESCRIPTION CHARACTER LEFT TO RIGHT */
        case 0x2FF1: /* IDEOGRAPHIC DESCRIPTION CHARACTER ABOVE TO BELOW */
        case 0x2FF2: /* IDEOGRAPHIC DESCRIPTION CHARACTER LEFT TO MIDDLE AND RIGHT */
        case 0x2FF3: /* IDEOGRAPHIC DESCRIPTION CHARACTER ABOVE TO MIDDLE AND BELOW */
        case 0x2FF4: /* IDEOGRAPHIC DESCRIPTION CHARACTER FULL SURROUND */
        case 0x2FF5: /* IDEOGRAPHIC DESCRIPTION CHARACTER SURROUND FROM ABOVE */
        case 0x2FF6: /* IDEOGRAPHIC DESCRIPTION CHARACTER SURROUND FROM BELOW */
        case 0x2FF7: /* IDEOGRAPHIC DESCRIPTION CHARACTER SURROUND FROM LEFT */
        case 0x2FF8: /* IDEOGRAPHIC DESCRIPTION CHARACTER SURROUND FROM UPPER LEFT */
        case 0x2FF9: /* IDEOGRAPHIC DESCRIPTION CHARACTER SURROUND FROM UPPER RIGHT */
        case 0x2FFA: /* IDEOGRAPHIC DESCRIPTION CHARACTER SURROUND FROM LOWER LEFT */
        case 0x2FFB: /* IDEOGRAPHIC DESCRIPTION CHARACTER OVERLAID */
        case 0x3002: /* IDEOGRAPHIC FULL STOP */
        case 0x3008: /* LEFT ANGLE BRACKET */
        case 0x3014: /* LEFT TORTOISE SHELL BRACKET */
        case 0x3015: /* RIGHT TORTOISE SHELL BRACKET */
        case 0x3033: /* VERTICAL KANA REPEAT MARK UPPER HALF */
        case 0x3035: /* VERTICAL KANA REPEAT MARK LOWER HALF */
        case 0x321D: /* PARENTHESIZED KOREAN CHARACTER OJEON */
        case 0x321E: /* PARENTHESIZED KOREAN CHARACTER O HU */
        case 0x33AE: /* SQUARE RAD OVER S */
        case 0x33AF: /* SQUARE RAD OVER S SQUARED */
        case 0x33C6: /* SQUARE C OVER KG */
        case 0x33DF: /* SQUARE A OVER M */
        case 0xA789: /* MODIFIER LETTER COLON */
        case 0xFE14: /* PRESENTATION FORM FOR VERTICAL SEMICOLON */
        case 0xFE15: /* PRESENTATION FORM FOR VERTICAL EXCLAMATION MARK */
        case 0xFE3F: /* PRESENTATION FORM FOR VERTICAL LEFT ANGLE BRACKET */
        case 0xFE5D: /* SMALL LEFT TORTOISE SHELL BRACKET */
        case 0xFE5E: /* SMALL RIGHT TORTOISE SHELL BRACKET */
        case 0xFF0E: /* FULLWIDTH FULL STOP */
        case 0xFF0F: /* FULL WIDTH SOLIDUS */
        case 0xFF61: /* HALFWIDTH IDEOGRAPHIC FULL STOP */
        case 0xFFFC: /* OBJECT REPLACEMENT CHARACTER */
        case 0xFFFD: /* REPLACEMENT CHARACTER */
        case 0x1F50F: /* LOCK WITH INK PEN */
        case 0x1F510: /* CLOSED LOCK WITH KEY */
        case 0x1F511: /* KEY */
        case 0x1F512: /* LOCK */
        case 0x1F513: /* OPEN LOCK */
            return YES;
        default:
            return NO;
    }
}

static BOOL readIDNScriptWhiteListFile(NSString *filename)
{
    if (!filename)
        return NO;

    FILE *file = fopen([filename fileSystemRepresentation], "r");
    if (!file)
        return NO;
    
    // Read a word at a time.
    // Allow comments, starting with # character to the end of the line.
    while (1) {
        // Skip a comment if present.
        if (fscanf(file, " #%*[^\n\r]%*[\n\r]") == EOF)
            break;
        
        // Read a script name if present.
        char word[33];
        int result = fscanf(file, " %32[^# \t\n\r]%*[^# \t\n\r] ", word);
        if (result == EOF)
            break;
        
        if (result == 1) {
            // Got a word, map to script code and put it into the array.
            int32_t script = u_getPropertyValueEnum(UCHAR_SCRIPT, word);
            if (script >= 0 && script < USCRIPT_CODE_LIMIT) {
                size_t index = script / 32;
                uint32_t mask = 1 << (script % 32);
                IDNScriptWhiteList[index] |= mask;
            }
        }
    }
    fclose(file);
    return YES;
}

static void readIDNScriptWhiteList(void)
{
    // Read white list from library.
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
    int numDirs = [dirs count];
    for (int i = 0; i < numDirs; i++) {
        if (readIDNScriptWhiteListFile([[dirs objectAtIndex:i] stringByAppendingPathComponent:@"IDNScriptWhiteList.txt"]))
            return;
    }
    
    // Fall back on white list inside bundle.
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.apple.WebCore"];
    
    if (!readIDNScriptWhiteListFile([bundle pathForResource:@"IDNScriptWhiteList" ofType:@"txt"]))
        CRASH();
}

static BOOL allCharactersInIDNScriptWhiteList(const UChar *buffer, int32_t length)
{
    pthread_once(&IDNScriptWhiteListFileRead, readIDNScriptWhiteList);
    
    int32_t i = 0;
    while (i < length) {
        UChar32 c;
        U16_NEXT(buffer, i, length, c)
        UErrorCode error = U_ZERO_ERROR;
        UScriptCode script = uscript_getScript(c, &error);
        if (error != U_ZERO_ERROR) {
            LOG_ERROR("got ICU error while trying to look at scripts: %d", error);
            return NO;
        }
        if (script < 0) {
            LOG_ERROR("got negative number for script code from ICU: %d", script);
            return NO;
        }
        if (script >= USCRIPT_CODE_LIMIT)
            return NO;

        size_t index = script / 32;
        uint32_t mask = 1 << (script % 32);
        if (!(IDNScriptWhiteList[index] & mask))
            return NO;
        
        if (isLookalikeCharacter(c))
            return NO;
    }
    return YES;
}

static bool isSecondLevelDomainNameAllowedByTLDRules(const UChar* buffer, int32_t length, const std::function<bool(UChar)>& characterIsAllowed)
{
    ASSERT(length > 0);

    for (int32_t i = length - 1; i >= 0; --i) {
        UChar ch = buffer[i];
        
        if (characterIsAllowed(ch))
            continue;
        
        // Only check the second level domain. Lower level registrars may have different rules.
        if (ch == '.')
            break;
        
        return false;
    }
    return true;
}

#define CHECK_RULES_IF_SUFFIX_MATCHES(suffix, function) \
    { \
        static const int32_t suffixLength = sizeof(suffix) / sizeof(suffix[0]); \
        if (length > suffixLength && 0 == memcmp(buffer + length - suffixLength, suffix, sizeof(suffix))) \
            return isSecondLevelDomainNameAllowedByTLDRules(buffer, length - suffixLength, function); \
    }

static bool isRussianDomainNameCharacter(UChar ch)
{
    // Only modern Russian letters, digits and dashes are allowed.
    return (ch >= 0x0430 && ch <= 0x044f) || ch == 0x0451 || (ch >= '0' && ch <= '9') || ch == '-';
}

static BOOL allCharactersAllowedByTLDRules(const UChar* buffer, int32_t length)
{
    // Skip trailing dot for root domain.
    if (buffer[length - 1] == '.')
        length--;

    // http://cctld.ru/files/pdf/docs/rules_ru-rf.pdf
    static const UChar cyrillicRF[] = {
        '.',
        0x0440, // CYRILLIC SMALL LETTER ER
        0x0444  // CYRILLIC SMALL LETTER EF
    };
    CHECK_RULES_IF_SUFFIX_MATCHES(cyrillicRF, isRussianDomainNameCharacter);

    // http://rusnames.ru/rules.pl
    static const UChar cyrillicRUS[] = {
        '.',
        0x0440, // CYRILLIC SMALL LETTER ER
        0x0443, // CYRILLIC SMALL LETTER U
        0x0441  // CYRILLIC SMALL LETTER ES
    };
    CHECK_RULES_IF_SUFFIX_MATCHES(cyrillicRUS, isRussianDomainNameCharacter);

    // http://ru.faitid.org/projects/moscow/documents/moskva/idn
    static const UChar cyrillicMOSKVA[] = {
        '.',
        0x043C, // CYRILLIC SMALL LETTER EM
        0x043E, // CYRILLIC SMALL LETTER O
        0x0441, // CYRILLIC SMALL LETTER ES
        0x043A, // CYRILLIC SMALL LETTER KA
        0x0432, // CYRILLIC SMALL LETTER VE
        0x0430  // CYRILLIC SMALL LETTER A
    };
    CHECK_RULES_IF_SUFFIX_MATCHES(cyrillicMOSKVA, isRussianDomainNameCharacter);

    // http://www.dotdeti.ru/foruser/docs/regrules.php
    static const UChar cyrillicDETI[] = {
        '.',
        0x0434, // CYRILLIC SMALL LETTER DE
        0x0435, // CYRILLIC SMALL LETTER IE
        0x0442, // CYRILLIC SMALL LETTER TE
        0x0438  // CYRILLIC SMALL LETTER I
    };
    CHECK_RULES_IF_SUFFIX_MATCHES(cyrillicDETI, isRussianDomainNameCharacter);

    // http://corenic.org - rules not published. The word is Russian, so only allowing Russian at this time,
    // although we may need to revise the checks if this ends up being used with other languages spoken in Russia.
    static const UChar cyrillicONLAYN[] = {
        '.',
        0x043E, // CYRILLIC SMALL LETTER O
        0x043D, // CYRILLIC SMALL LETTER EN
        0x043B, // CYRILLIC SMALL LETTER EL
        0x0430, // CYRILLIC SMALL LETTER A
        0x0439, // CYRILLIC SMALL LETTER SHORT I
        0x043D  // CYRILLIC SMALL LETTER EN
    };
    CHECK_RULES_IF_SUFFIX_MATCHES(cyrillicONLAYN, isRussianDomainNameCharacter);

    // http://corenic.org - same as above.
    static const UChar cyrillicSAYT[] = {
        '.',
        0x0441, // CYRILLIC SMALL LETTER ES
        0x0430, // CYRILLIC SMALL LETTER A
        0x0439, // CYRILLIC SMALL LETTER SHORT I
        0x0442  // CYRILLIC SMALL LETTER TE
    };
    CHECK_RULES_IF_SUFFIX_MATCHES(cyrillicSAYT, isRussianDomainNameCharacter);

    // http://pir.org/products/opr-domain/ - rules not published. According to the registry site,
    // the intended audience is "Russian and other Slavic-speaking markets".
    // Chrome appears to only allow Russian, so sticking with that for now.
    static const UChar cyrillicORG[] = {
        '.',
        0x043E, // CYRILLIC SMALL LETTER O
        0x0440, // CYRILLIC SMALL LETTER ER
        0x0433  // CYRILLIC SMALL LETTER GHE
    };
    CHECK_RULES_IF_SUFFIX_MATCHES(cyrillicORG, isRussianDomainNameCharacter);

    // http://cctld.by/rules.html
    static const UChar cyrillicBEL[] = {
        '.',
        0x0431, // CYRILLIC SMALL LETTER BE
        0x0435, // CYRILLIC SMALL LETTER IE
        0x043B  // CYRILLIC SMALL LETTER EL
    };
    CHECK_RULES_IF_SUFFIX_MATCHES(cyrillicBEL, [](UChar ch) {
        // Russian and Byelorussian letters, digits and dashes are allowed.
        return (ch >= 0x0430 && ch <= 0x044f) || ch == 0x0451 || ch == 0x0456 || ch == 0x045E || ch == 0x2019 || (ch >= '0' && ch <= '9') || ch == '-';
    });

    // http://www.nic.kz/docs/poryadok_vnedreniya_kaz_ru.pdf
    static const UChar cyrillicKAZ[] = {
        '.',
        0x049B, // CYRILLIC SMALL LETTER KA WITH DESCENDER
        0x0430, // CYRILLIC SMALL LETTER A
        0x0437  // CYRILLIC SMALL LETTER ZE
    };
    CHECK_RULES_IF_SUFFIX_MATCHES(cyrillicKAZ, [](UChar ch) {
        // Kazakh letters, digits and dashes are allowed.
        return (ch >= 0x0430 && ch <= 0x044f) || ch == 0x0451 || ch == 0x04D9 || ch == 0x0493 || ch == 0x049B || ch == 0x04A3 || ch == 0x04E9 || ch == 0x04B1 || ch == 0x04AF || ch == 0x04BB || ch == 0x0456 || (ch >= '0' && ch <= '9') || ch == '-';
    });

    // http://uanic.net/docs/documents-ukr/Rules%20of%20UKR_v4.0.pdf
    static const UChar cyrillicUKR[] = {
        '.',
        0x0443, // CYRILLIC SMALL LETTER U
        0x043A, // CYRILLIC SMALL LETTER KA
        0x0440  // CYRILLIC SMALL LETTER ER
    };
    CHECK_RULES_IF_SUFFIX_MATCHES(cyrillicUKR, [](UChar ch) {
        // Russian and Ukrainian letters, digits and dashes are allowed.
        return (ch >= 0x0430 && ch <= 0x044f) || ch == 0x0451 || ch == 0x0491 || ch == 0x0404 || ch == 0x0456 || ch == 0x0457 || (ch >= '0' && ch <= '9') || ch == '-';
    });

    // http://www.rnids.rs/data/DOKUMENTI/idn-srb-policy-termsofuse-v1.4-eng.pdf
    static const UChar cyrillicSRB[] = {
        '.',
        0x0441, // CYRILLIC SMALL LETTER ES
        0x0440, // CYRILLIC SMALL LETTER ER
        0x0431  // CYRILLIC SMALL LETTER BE
    };
    CHECK_RULES_IF_SUFFIX_MATCHES(cyrillicSRB, [](UChar ch) {
        // Serbian letters, digits and dashes are allowed.
        return (ch >= 0x0430 && ch <= 0x0438) || (ch >= 0x043A && ch <= 0x0448) || ch == 0x0452 || ch == 0x0458 || ch == 0x0459 || ch == 0x045A || ch == 0x045B || ch == 0x045F || (ch >= '0' && ch <= '9') || ch == '-';
    });

    // http://marnet.mk/doc/pravilnik-mk-mkd.pdf
    static const UChar cyrillicMKD[] = {
        '.',
        0x043C, // CYRILLIC SMALL LETTER EM
        0x043A, // CYRILLIC SMALL LETTER KA
        0x0434  // CYRILLIC SMALL LETTER DE
    };
    CHECK_RULES_IF_SUFFIX_MATCHES(cyrillicMKD, [](UChar ch) {
        // Macedonian letters, digits and dashes are allowed.
        return (ch >= 0x0430 && ch <= 0x0438) || (ch >= 0x043A && ch <= 0x0448) || ch == 0x0453 || ch == 0x0455 || ch == 0x0458 || ch == 0x0459 || ch == 0x045A || ch == 0x045C || ch == 0x045F || (ch >= '0' && ch <= '9') || ch == '-';
    });

    // https://www.mon.mn/cs/
    static const UChar cyrillicMON[] = {
        '.',
        0x043C, // CYRILLIC SMALL LETTER EM
        0x043E, // CYRILLIC SMALL LETTER O
        0x043D  // CYRILLIC SMALL LETTER EN
    };
    CHECK_RULES_IF_SUFFIX_MATCHES(cyrillicMON, [](UChar ch) {
        // Mongolian letters, digits and dashes are allowed.
        return (ch >= 0x0430 && ch <= 0x044f) || ch == 0x0451 || ch == 0x04E9 || ch == 0x04AF || (ch >= '0' && ch <= '9') || ch == '-';
    });

    // Not a known top level domain with special rules.
    return NO;
}

// Return value of nil means no mapping is necessary.
// If makeString is NO, then return value is either nil or self to indicate mapping is necessary.
// If makeString is YES, then return value is either nil or the mapped string.
static NSString *mapHostNameWithRange(NSString *string, NSRange range, BOOL encode, BOOL makeString, BOOL *error)
{
    if (range.length > HOST_NAME_BUFFER_LENGTH)
        return nil;
    
    if (![string length])
        return nil;
    
    UChar sourceBuffer[HOST_NAME_BUFFER_LENGTH];
    UChar destinationBuffer[HOST_NAME_BUFFER_LENGTH];
    
    if (encode && [string rangeOfString:@"%" options:NSLiteralSearch range:range].location != NSNotFound) {
        NSString *substring = [string substringWithRange:range];
        substring = CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapes(NULL, (CFStringRef)substring, CFSTR("")));
        if (substring) {
            string = substring;
            range = NSMakeRange(0, [string length]);
        }
    }
    
    int length = range.length;
    [string getCharacters:sourceBuffer range:range];
    
    UErrorCode uerror = U_ZERO_ERROR;
    int32_t numCharactersConverted = (encode ? uidna_IDNToASCII : uidna_IDNToUnicode)(sourceBuffer, length, destinationBuffer, HOST_NAME_BUFFER_LENGTH, UIDNA_ALLOW_UNASSIGNED, NULL, &uerror);
    if (U_FAILURE(uerror)) {
        *error = YES;
        return nil;
    }
    
    if (numCharactersConverted == length && !memcmp(sourceBuffer, destinationBuffer, length * sizeof(UChar)))
        return nil;
    
    if (!encode && !allCharactersInIDNScriptWhiteList(destinationBuffer, numCharactersConverted) && !allCharactersAllowedByTLDRules(destinationBuffer, numCharactersConverted))
        return nil;
    
    return makeString ? [NSString stringWithCharacters:destinationBuffer length:numCharactersConverted] : string;
}

BOOL hostNameNeedsDecodingWithRange(NSString *string, NSRange range, BOOL *error)
{
    return mapHostNameWithRange(string, range, NO, NO, error) != nil;
}
 
BOOL hostNameNeedsEncodingWithRange(NSString *string, NSRange range, BOOL *error)
{
    return mapHostNameWithRange(string, range, YES,  NO, error) != nil;
}

NSString *decodeHostNameWithRange(NSString *string, NSRange range)
{
    BOOL error = NO;
    NSString *host = mapHostNameWithRange(string, range, NO, YES, &error);
    if (error)
        return nil;
    return !host ? string : host;
}

NSString *encodeHostNameWithRange(NSString *string, NSRange range)
{
    BOOL error = NO;
    NSString *host = mapHostNameWithRange(string, range, YES, YES, &error);
    if (error)
        return nil;
    return !host ? string : host;
}

NSString *decodeHostName(NSString *string)
{
    BOOL error = NO;
    NSString *host = mapHostNameWithRange(string, NSMakeRange(0, [string length]), NO, YES, &error);
    if (error)
        return nil;
    return !host ? string : host;
}

NSString *encodeHostName(NSString *string)
{
    BOOL error = NO;
    NSString *host = mapHostNameWithRange(string, NSMakeRange(0, [string length]), YES, YES, &error);
    if (error)
        return nil;
    return !host ? string : host;
}

static void collectRangesThatNeedMapping(NSString *string, NSRange range, void *context, BOOL encode)
{
    // Generally, we want to optimize for the case where there is one host name that does not need mapping.
    // Therefore, we use nil to indicate no mapping here and an empty array to indicate error.

    BOOL error = NO;
    BOOL needsMapping = encode ? hostNameNeedsEncodingWithRange(string, range, &error) : hostNameNeedsDecodingWithRange(string, range, &error);
    if (!error && !needsMapping)
        return;
    
    NSMutableArray **array = (NSMutableArray **)context;
    if (!*array)
        *array = [[NSMutableArray alloc] init];
    
    if (!error)
        [*array addObject:[NSValue valueWithRange:range]];
}

static void collectRangesThatNeedEncoding(NSString *string, NSRange range, void *context)
{
    return collectRangesThatNeedMapping(string, range, context, YES);
}

static void collectRangesThatNeedDecoding(NSString *string, NSRange range, void *context)
{
    return collectRangesThatNeedMapping(string, range, context, NO);
}

static inline NSCharacterSet *retain(NSCharacterSet *charset)
{
    CFRetain(charset);
    return charset;
}

static void applyHostNameFunctionToMailToURLString(NSString *string, StringRangeApplierFunction f, void *context)
{
    // In a mailto: URL, host names come after a '@' character and end with a '>' or ',' or '?' character.
    // Skip quoted strings so that characters in them don't confuse us.
    // When we find a '?' character, we are past the part of the URL that contains host names.
    
    static NSCharacterSet *hostNameOrStringStartCharacters = retain([NSCharacterSet characterSetWithCharactersInString:@"\"@?"]);
    static NSCharacterSet *hostNameEndCharacters = retain([NSCharacterSet characterSetWithCharactersInString:@">,?"]);
    static NSCharacterSet *quotedStringCharacters = retain([NSCharacterSet characterSetWithCharactersInString:@"\"\\"]);
    
    unsigned stringLength = [string length];
    NSRange remaining = NSMakeRange(0, stringLength);
    
    while (1) {
        // Find start of host name or of quoted string.
        NSRange hostNameOrStringStart = [string rangeOfCharacterFromSet:hostNameOrStringStartCharacters options:0 range:remaining];
        if (hostNameOrStringStart.location == NSNotFound)
            return;

        unichar c = [string characterAtIndex:hostNameOrStringStart.location];
        remaining.location = NSMaxRange(hostNameOrStringStart);
        remaining.length = stringLength - remaining.location;
        
        if (c == '?')
            return;
        
        if (c == '@') {
            // Find end of host name.
            unsigned hostNameStart = remaining.location;
            NSRange hostNameEnd = [string rangeOfCharacterFromSet:hostNameEndCharacters options:0 range:remaining];
            BOOL done;
            if (hostNameEnd.location == NSNotFound) {
                hostNameEnd.location = stringLength;
                done = YES;
            } else {
                remaining.location = hostNameEnd.location;
                remaining.length = stringLength - remaining.location;
                done = NO;
            }
            
            // Process host name range.
            f(string, NSMakeRange(hostNameStart, hostNameEnd.location - hostNameStart), context);
            
            if (done)
                return;
        } else {
            // Skip quoted string.
            ASSERT(c == '"');
            while (1) {
                NSRange escapedCharacterOrStringEnd = [string rangeOfCharacterFromSet:quotedStringCharacters options:0 range:remaining];
                if (escapedCharacterOrStringEnd.location == NSNotFound)
                    return;

                c = [string characterAtIndex:escapedCharacterOrStringEnd.location];
                remaining.location = NSMaxRange(escapedCharacterOrStringEnd);
                remaining.length = stringLength - remaining.location;
                
                // If we are the end of the string, then break from the string loop back to the host name loop.
                if (c == '"')
                    break;
                
                // Skip escaped character.
                ASSERT(c == '\\');
                if (!remaining.length)
                    return;

                remaining.location += 1;
                remaining.length -= 1;
            }
        }
    }
}

static void applyHostNameFunctionToURLString(NSString *string, StringRangeApplierFunction f, void *context)
{
    // Find hostnames. Too bad we can't use any real URL-parsing code to do this,
    // but we have to do it before doing all the %-escaping, and this is the only
    // code we have that parses mailto URLs anyway.
    
    // Maybe we should implement this using a character buffer instead?
    
    if (hasCaseInsensitivePrefix(string, @"mailto:")) {
        applyHostNameFunctionToMailToURLString(string, f, context);
        return;
    }
    
    // Find the host name in a hierarchical URL.
    // It comes after a "://" sequence, with scheme characters preceding.
    // If ends with the end of the string or a ":", "/", or a "?".
    // If there is a "@" character, the host part is just the part after the "@".
    NSRange separatorRange = [string rangeOfString:@"://"];
    if (separatorRange.location == NSNotFound)
        return;
    
    // Check that all characters before the :// are valid scheme characters.
    static NSCharacterSet *nonSchemeCharacters = retain([[NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-."] invertedSet]);
    if ([string rangeOfCharacterFromSet:nonSchemeCharacters options:0 range:NSMakeRange(0, separatorRange.location)].location != NSNotFound)
        return;
    
    unsigned stringLength = [string length];
    
    static NSCharacterSet *hostTerminators = retain([NSCharacterSet characterSetWithCharactersInString:@":/?#"]);
    
    // Start after the separator.
    unsigned authorityStart = NSMaxRange(separatorRange);
    
    // Find terminating character.
    NSRange hostNameTerminator = [string rangeOfCharacterFromSet:hostTerminators options:0 range:NSMakeRange(authorityStart, stringLength - authorityStart)];
    unsigned hostNameEnd = hostNameTerminator.location == NSNotFound ? stringLength : hostNameTerminator.location;
    
    // Find "@" for the start of the host name.
    NSRange userInfoTerminator = [string rangeOfString:@"@" options:0 range:NSMakeRange(authorityStart, hostNameEnd - authorityStart)];
    unsigned hostNameStart = userInfoTerminator.location == NSNotFound ? authorityStart : NSMaxRange(userInfoTerminator);
    
    f(string, NSMakeRange(hostNameStart, hostNameEnd - hostNameStart), context);
}

static NSString *mapHostNames(NSString *string, BOOL encode)
{
    // Generally, we want to optimize for the case where there is one host name that does not need mapping.
    
    if (encode && [string canBeConvertedToEncoding:NSASCIIStringEncoding])
        return string;
    
    // Make a list of ranges that actually need mapping.
    NSMutableArray *hostNameRanges = nil;
    StringRangeApplierFunction f = encode ? collectRangesThatNeedEncoding : collectRangesThatNeedDecoding;
    applyHostNameFunctionToURLString(string, f, &hostNameRanges);
    if (!hostNameRanges)
        return string;

    if (![hostNameRanges count])
        return nil;
    
    // Do the mapping.
    NSMutableString *mutableCopy = [string mutableCopy];
    unsigned i = [hostNameRanges count];
    while (i--) {
        NSRange hostNameRange = [[hostNameRanges objectAtIndex:i] rangeValue];
        NSString *mappedHostName = encode ? encodeHostNameWithRange(string, hostNameRange) : decodeHostNameWithRange(string, hostNameRange);
        [mutableCopy replaceCharactersInRange:hostNameRange withString:mappedHostName];
    }
    [hostNameRanges release];
    return [mutableCopy autorelease];
}

static BOOL isHexDigit(char c)
{
    return (c >= '0' && c <= '9') || (c >= 'A' && c <= 'F') || (c >= 'a' && c <= 'f');
}

static char hexDigit(int i)
{
    if (i < 0 || i > 16)
        return '0';

    return (i >= 10) ? i - 10 + 'A' : i += '0'; 
}

static int hexDigitValue(char c)
{
    if (c >= '0' && c <= '9')
        return c - '0';

    if (c >= 'A' && c <= 'F')
        return c - 'A' + 10;

    if (c >= 'a' && c <= 'f')
        return c - 'a' + 10;

    LOG_ERROR("illegal hex digit");
    return 0;
}

static NSString *stringByTrimmingWhitespace(NSString *string)
{
    NSMutableString *trimmed = [[string mutableCopy] autorelease];
    CFStringTrimWhitespace((CFMutableStringRef)trimmed);
    return trimmed;
}

NSURL *URLByTruncatingOneCharacterBeforeComponent(NSURL *URL, CFURLComponentType component)
{
    if (!URL)
        return nil;
    
    CFRange fragRg = CFURLGetByteRangeForComponent((CFURLRef)URL, component, NULL);
    if (fragRg.location == kCFNotFound)
        return URL;
    
    UInt8 *urlBytes, buffer[2048];
    CFIndex numBytes = CFURLGetBytes((CFURLRef)URL, buffer, 2048);
    if (numBytes == -1) {
        numBytes = CFURLGetBytes((CFURLRef)URL, NULL, 0);
        urlBytes = static_cast<UInt8*>(malloc(numBytes));
        CFURLGetBytes((CFURLRef)URL, urlBytes, numBytes);
    } else
        urlBytes = buffer;
        
    NSURL *result = (NSURL *)CFURLCreateWithBytes(NULL, urlBytes, fragRg.location - 1, kCFStringEncodingUTF8, NULL);
    if (!result)
        result = (NSURL *)CFURLCreateWithBytes(NULL, urlBytes, fragRg.location - 1, kCFStringEncodingISOLatin1, NULL);
        
    if (urlBytes != buffer)
        free(urlBytes);
    return result ? [result autorelease] : URL;
}

static NSURL *URLByRemovingResourceSpecifier(NSURL *URL)
{
    return URLByTruncatingOneCharacterBeforeComponent(URL, kCFURLComponentResourceSpecifier);
}

NSURL *URLWithData(NSData *data, NSURL *baseURL)
{
    if (!data)
        return nil;
    
    NSURL *result = nil;
    size_t length = [data length];
    if (length > 0) {
        // work around <rdar://4470771>: CFURLCreateAbsoluteURLWithBytes(.., TRUE) doesn't remove non-path components.
        baseURL = URLByRemovingResourceSpecifier(baseURL);
        
        const UInt8 *bytes = static_cast<const UInt8*>([data bytes]);
        
        // CFURLCreateAbsoluteURLWithBytes would complain to console if we passed a path to it.
        if (bytes[0] == '/' && !baseURL)
            return nil;
        
        // NOTE: We use UTF-8 here since this encoding is used when computing strings when returning URL components
        // (e.g calls to NSURL -path). However, this function is not tolerant of illegal UTF-8 sequences, which
        // could either be a malformed string or bytes in a different encoding, like shift-jis, so we fall back
        // onto using ISO Latin 1 in those cases.
        result = CFBridgingRelease(CFURLCreateAbsoluteURLWithBytes(NULL, bytes, length, kCFStringEncodingUTF8, (CFURLRef)baseURL, YES));
        if (!result)
            result = CFBridgingRelease(CFURLCreateAbsoluteURLWithBytes(NULL, bytes, length, kCFStringEncodingISOLatin1, (CFURLRef)baseURL, YES));
    } else
        result = [NSURL URLWithString:@""];

    return result;
}
static NSData *dataWithUserTypedString(NSString *string)
{
    NSData *userTypedData = [string dataUsingEncoding:NSUTF8StringEncoding];
    ASSERT(userTypedData);
    
    const UInt8* inBytes = static_cast<const UInt8 *>([userTypedData bytes]);
    int inLength = [userTypedData length];
    if (!inLength)
        return nil;
    
    char* outBytes = static_cast<char *>(malloc(inLength * 3)); // large enough to %-escape every character
    char* p = outBytes;
    int outLength = 0;
    for (int i = 0; i < inLength; i++) {
        UInt8 c = inBytes[i];
        if (c <= 0x20 || c >= 0x7f) {
            *p++ = '%';
            *p++ = hexDigit(c >> 4);
            *p++ = hexDigit(c & 0xf);
            outLength += 3;
        } else {
            *p++ = c;
            outLength++;
        }
    }
    
    return [NSData dataWithBytesNoCopy:outBytes length:outLength]; // adopts outBytes
}

NSURL *URLWithUserTypedString(NSString *string, NSURL *URL)
{
    if (!string)
        return nil;

    string = mapHostNames(stringByTrimmingWhitespace(string), YES);
    if (!string)
        return nil;

    NSData *data = dataWithUserTypedString(string);
    if (!data)
        return [NSURL URLWithString:@""];

    return URLWithData(data, URL);
}

NSURL *URLWithUserTypedStringDeprecated(NSString *string, NSURL *URL)
{
    if (!string)
        return nil;

    NSURL *result = URLWithUserTypedString(string, URL);
    if (!result) {
        NSData *resultData = dataWithUserTypedString(string);
        if (!resultData)
            return [NSURL URLWithString:@""];
        result = URLWithData(resultData, URL);
    }

    return result;
}

static BOOL hasQuestionMarkOnlyQueryString(NSURL *URL)
{
    CFRange rangeWithSeparators;
    CFURLGetByteRangeForComponent((CFURLRef)URL, kCFURLComponentQuery, &rangeWithSeparators);
    if (rangeWithSeparators.location != kCFNotFound && rangeWithSeparators.length == 1)
        return YES;

    return NO;
}

#define completeURL (CFURLComponentType)-1

NSData *dataForURLComponentType(NSURL *URL, CFURLComponentType componentType)
{
    static const int URLComponentTypeBufferLength = 2048;
    
    UInt8 staticAllBytesBuffer[URLComponentTypeBufferLength];
    UInt8 *allBytesBuffer = staticAllBytesBuffer;
    
    CFIndex bytesFilled = CFURLGetBytes((CFURLRef)URL, allBytesBuffer, URLComponentTypeBufferLength);
    if (bytesFilled == -1) {
        CFIndex bytesToAllocate = CFURLGetBytes((CFURLRef)URL, NULL, 0);
        allBytesBuffer = static_cast<UInt8 *>(malloc(bytesToAllocate));
        bytesFilled = CFURLGetBytes((CFURLRef)URL, allBytesBuffer, bytesToAllocate);
    }
    
    CFRange range;
    if (componentType != completeURL) {
        range = CFURLGetByteRangeForComponent((CFURLRef)URL, componentType, NULL);
        if (range.location == kCFNotFound)
            return nil;
    } else {
        range.location = 0;
        range.length = bytesFilled;
    }
    
    NSData *componentData = [NSData dataWithBytes:allBytesBuffer + range.location length:range.length]; 
    
    const unsigned char *bytes = static_cast<const unsigned char *>([componentData bytes]);
    NSMutableData *resultData = [NSMutableData data];
    // NOTE: add leading '?' to query strings non-zero length query strings.
    // NOTE: retain question-mark only query strings.
    if (componentType == kCFURLComponentQuery) {
        if (range.length > 0 || hasQuestionMarkOnlyQueryString(URL))
            [resultData appendBytes:"?" length:1];    
    }
    for (int i = 0; i < range.length; i++) {
        unsigned char c = bytes[i];
        if (c <= 0x20 || c >= 0x7f) {
            char escaped[3];
            escaped[0] = '%';
            escaped[1] = hexDigit(c >> 4);
            escaped[2] = hexDigit(c & 0xf);
            [resultData appendBytes:escaped length:3];    
        } else {
            char b[1];
            b[0] = c;
            [resultData appendBytes:b length:1];    
        }               
    }
    
    if (staticAllBytesBuffer != allBytesBuffer)
        free(allBytesBuffer);
    
    return resultData;
}

static NSURL *URLByRemovingComponentAndSubsequentCharacter(NSURL *URL, CFURLComponentType component)
{
    CFRange range = CFURLGetByteRangeForComponent((CFURLRef)URL, component, 0);
    if (range.location == kCFNotFound)
        return URL;
    
    // Remove one subsequent character.
    range.length++;

    Vector<UInt8, 2048> buffer(2048);
    CFIndex numBytes = CFURLGetBytes((CFURLRef)URL, buffer.data(), 2048);
    if (numBytes == -1) {
        numBytes = CFURLGetBytes((CFURLRef)URL, NULL, 0);
        buffer.grow(numBytes);
        CFURLGetBytes((CFURLRef)URL, buffer.data(), numBytes);
    }
    UInt8* urlBytes = buffer.data();
        
    if (numBytes < range.location)
        return URL;
    if (numBytes < range.location + range.length)
        range.length = numBytes - range.location;
        
    memmove(urlBytes + range.location, urlBytes + range.location + range.length, numBytes - range.location + range.length);
    
    NSURL *result = (NSURL *)CFURLCreateWithBytes(NULL, urlBytes, numBytes - range.length, kCFStringEncodingUTF8, NULL);
    if (!result)
        result = (NSURL *)CFURLCreateWithBytes(NULL, urlBytes, numBytes - range.length, kCFStringEncodingISOLatin1, NULL);
                
    return result ? [result autorelease] : URL;
}

NSURL *URLByRemovingUserInfo(NSURL *URL)
{
    return URLByRemovingComponentAndSubsequentCharacter(URL, kCFURLComponentUserInfo);
}

NSURL *URLByCanonicalizingURL(NSURL *URL)
{
    RetainPtr<NSURLRequest> request = adoptNS([[NSURLRequest alloc] initWithURL:URL]);
    Class concreteClass = [NSURLProtocol _protocolClassForRequest:request.get()];
    if (!concreteClass) {
        return URL;
    }
    
    // This applies NSURL's concept of canonicalization, but not URL's concept. It would
    // make sense to apply both, but when we tried that it caused a performance degradation
    // (see 5315926). It might make sense to apply only the URL concept and not the NSURL
    // concept, but it's too risky to make that change for WebKit 3.0.
    NSURLRequest *newRequest = [concreteClass canonicalRequestForRequest:request.get()];
    NSURL *newURL = [newRequest URL]; 
    return [[newURL retain] autorelease];
}

NSData *originalURLData(NSURL *URL)
{
    UInt8 *buffer = (UInt8 *)malloc(URL_BYTES_BUFFER_LENGTH);
    CFIndex bytesFilled = CFURLGetBytes((CFURLRef)URL, buffer, URL_BYTES_BUFFER_LENGTH);
    if (bytesFilled == -1) {
        CFIndex bytesToAllocate = CFURLGetBytes((CFURLRef)URL, NULL, 0);
        buffer = (UInt8 *)realloc(buffer, bytesToAllocate);
        bytesFilled = CFURLGetBytes((CFURLRef)URL, buffer, bytesToAllocate);
        ASSERT(bytesFilled == bytesToAllocate);
    }
    
    // buffer is adopted by the NSData
    NSData *data = [NSData dataWithBytesNoCopy:buffer length:bytesFilled freeWhenDone:YES];
    
    NSURL *baseURL = (NSURL *)CFURLGetBaseURL((CFURLRef)URL);
    if (baseURL)
        return originalURLData(URLWithData(data, baseURL));
    return data;
}

static CFStringRef createStringWithEscapedUnsafeCharacters(CFStringRef string)
{
    CFIndex length = CFStringGetLength(string);
    Vector<UChar, 2048> sourceBuffer(length);
    CFStringGetCharacters(string, CFRangeMake(0, length), sourceBuffer.data());
    
    Vector<UChar, 2048> outBuffer;
    
    CFIndex i = 0;
    while (i < length) {
        UChar32 c;
        U16_NEXT(sourceBuffer, i, length, c)
        
        if (isLookalikeCharacter(c)) {
            uint8_t utf8Buffer[4];
            CFIndex offset = 0;
            UBool failure = false;
            U8_APPEND(utf8Buffer, offset, 4, c, failure)
            ASSERT(!failure);
            
            for (CFIndex j = 0; j < offset; ++j) {
                outBuffer.append('%');
                outBuffer.append(hexDigit(utf8Buffer[j] >> 4));
                outBuffer.append(hexDigit(utf8Buffer[j] & 0xf));
            }
        } else {
            UChar utf16Buffer[2];
            CFIndex offset = 0;
            UBool failure = false;
            U16_APPEND(utf16Buffer, offset, 2, c, failure)
            ASSERT(!failure);
            for (CFIndex j = 0; j < offset; ++j)
                outBuffer.append(utf16Buffer[j]);
        }
    }
    
    return CFStringCreateWithCharacters(NULL, outBuffer.data(), outBuffer.size());
}

NSString *userVisibleString(NSURL *URL)
{
    NSData *data = originalURLData(URL);
    const unsigned char *before = static_cast<const unsigned char*>([data bytes]);
    int length = [data length];
    
    bool mayNeedHostNameDecoding = false;
    
    const unsigned char *p = before;
    int bufferLength = (length * 3) + 1;
    char *after = static_cast<char *>(malloc(bufferLength)); // large enough to %-escape every character
    char *q = after;
    for (int i = 0; i < length; i++) {
        unsigned char c = p[i];
        // unescape escape sequences that indicate bytes greater than 0x7f
        if (c == '%' && (i + 1 < length && isHexDigit(p[i + 1])) && i + 2 < length && isHexDigit(p[i + 2])) {
            unsigned char u = (hexDigitValue(p[i + 1]) << 4) | hexDigitValue(p[i + 2]);
            if (u > 0x7f) {
                // unescape
                *q++ = u;
            } else {
                // do not unescape
                *q++ = p[i];
                *q++ = p[i + 1];
                *q++ = p[i + 2];
            }
            i += 2;
        } else {
            *q++ = c;
            
            // Check for "xn--" in an efficient, non-case-sensitive, way.
            if (c == '-' && i >= 3 && !mayNeedHostNameDecoding && (q[-4] | 0x20) == 'x' && (q[-3] | 0x20) == 'n' && q[-2] == '-')
                mayNeedHostNameDecoding = true;
        }
    }
    *q = '\0';
    
    // Check string to see if it can be converted to display using UTF-8  
    NSString *result = [NSString stringWithUTF8String:after];
    if (!result) {
        // Could not convert to UTF-8.
        // Convert characters greater than 0x7f to escape sequences.
        // Shift current string to the end of the buffer
        // then we will copy back bytes to the start of the buffer 
        // as we convert.
        int afterlength = q - after;
        char *p = after + bufferLength - afterlength - 1;
        memmove(p, after, afterlength + 1); // copies trailing '\0'
        char *q = after;
        while (*p) {
            unsigned char c = *p;
            if (c > 0x7f) {
                *q++ = '%';
                *q++ = hexDigit(c >> 4);
                *q++ = hexDigit(c & 0xf);
            } else
                *q++ = *p;
            p++;
        }
        *q = '\0';
        result = [NSString stringWithUTF8String:after];
    }
    
    free(after);
    
    if (mayNeedHostNameDecoding) {
        // FIXME: Is it good to ignore the failure of mapHostNames and keep result intact?
        NSString *mappedResult = mapHostNames(result, NO);
        if (mappedResult)
            result = mappedResult;
    }

    result = [result precomposedStringWithCanonicalMapping];
    return CFBridgingRelease(createStringWithEscapedUnsafeCharacters((CFStringRef)result));
}

BOOL isUserVisibleURL(NSString *string)
{
    BOOL valid = YES;
    // get buffer
    
    char static_buffer[1024];
    const char *p;
    BOOL success = CFStringGetCString((CFStringRef)string, static_buffer, 1023, kCFStringEncodingUTF8);
    p = success ? static_buffer : [string UTF8String];
    
    int length = strlen(p);
    
    // check for characters <= 0x20 or >=0x7f, %-escape sequences of %7f, and xn--, these
    // are the things that will lead _web_userVisibleString to actually change things.
    for (int i = 0; i < length; i++) {
        unsigned char c = p[i];
        // escape control characters, space, and delete
        if (c <= 0x20 || c == 0x7f) {
            valid = NO;
            break;
        } else if (c == '%' && (i + 1 < length && isHexDigit(p[i + 1])) && i + 2 < length && isHexDigit(p[i + 2])) {
            unsigned char u = (hexDigitValue(p[i + 1]) << 4) | hexDigitValue(p[i + 2]);
            if (u > 0x7f) {
                valid = NO;
                break;
            }
            i += 2;
        } else {
            // Check for "xn--" in an efficient, non-case-sensitive, way.
            if (c == '-' && i >= 3 && (p[i - 3] | 0x20) == 'x' && (p[i - 2] | 0x20) == 'n' && p[i - 1] == '-') {
                valid = NO;
                break;
            }
        }
    }
    
    return valid;
}

NSRange rangeOfURLScheme(NSString *string)
{
    NSRange colon = [string rangeOfString:@":"];
    if (colon.location != NSNotFound && colon.location > 0) {
        NSRange scheme = {0, colon.location};
        static NSCharacterSet *InverseSchemeCharacterSet = nil;
        if (!InverseSchemeCharacterSet) {
            /*
             This stuff is very expensive.  10-15 msec on a 2x1.2GHz.  If not cached it swamps
             everything else when adding items to the autocomplete DB.  Makes me wonder if we
             even need to enforce the character set here.
            */
            NSString *acceptableCharacters = @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+.-";
            InverseSchemeCharacterSet = [[[NSCharacterSet characterSetWithCharactersInString:acceptableCharacters] invertedSet] retain];
        }
        NSRange illegals = [string rangeOfCharacterFromSet:InverseSchemeCharacterSet options:0 range:scheme];
        if (illegals.location == NSNotFound)
            return scheme;
    }
    return NSMakeRange(NSNotFound, 0);
}

BOOL looksLikeAbsoluteURL(NSString *string)
{
    // Trim whitespace because _web_URLWithString allows whitespace.
    return rangeOfURLScheme(stringByTrimmingWhitespace(string)).location != NSNotFound;
}

} // namespace WebCore