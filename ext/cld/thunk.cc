#include <stdio.h>
#include <string.h>
#include <string>
#include <vector>
#include "internal/lang_script.h"
#include "public/compact_lang_det.h"
#include "public/encodings.h"
using namespace CLD2;

typedef struct {
  Language lang;
  int percent;
  double score;
} LanguageResult;

// Conveys the same information as CLD::ResultChunk
typedef struct {
  Language lang;
  int offset;
  uint16 bytes;
} ReturnChunk;

typedef struct {
  Language lang;
  bool reliable;
  LanguageResult *langresults;
  int num_chunks;
  ReturnChunk *returnchunksptr;
} SUMMARY_RESULT;

typedef struct {
  Language lang;
  bool reliable;
} RESULT;

extern "C" {
  Language languageFromName(const char* src) {
    return GetLanguageFromName(src);
  }

  const char* codeFromLanguage(Language lang) {
      return LanguageCode(lang);
  }

  const char* nameFromLanguage(Language lang) {
      return LanguageName(lang);
  }

  RESULT detectLanguageExt(
                      const char * src,
                      bool is_plain_text,
                      const char* tld_hint,
                      int encoding_hint,
                      Language language_hint) {
    bool is_reliable;
    double normalized_score3[3];
    Language language3[3];
    int percent3[3];
    int text_bytes;

    // Note there isn't an ExtDetectLanguage function,
    // so we'll use ExtDetectLanguageSummar instead.
    Language lang;
    lang = ExtDetectLanguageSummary(
                          src,
                          strlen(src),
                          is_plain_text,
                          tld_hint,
                          encoding_hint,
                          language_hint,
                          language3,
                          percent3,
                          normalized_score3,
                          &text_bytes,
                          &is_reliable);

    RESULT res;
    res.lang = lang;
    res.reliable = is_reliable;
    return res;
  }


  SUMMARY_RESULT* detectLanguageSummaryExt(
                              const char * src,
                              bool is_plain_text,
                              const char* content_language_hint,
                              const char* tld_hint,
                              int encoding_hint,
                              Language language_hint) {
    const int flags = 0;  // no flags
    const CLDHints cldhints = {content_language_hint, tld_hint, encoding_hint, language_hint};
    Language language3[3];
    int percent3[3];
    double normalized_score3[3];
    ResultChunkVector resultchunkvector;
    int text_bytes;
    bool is_reliable;
    Language lang;

    lang = ExtDetectLanguageSummary(
                          src,
                          strlen(src),
                          is_plain_text,
                          &cldhints,
                          flags,
                          language3,
                          percent3,
                          normalized_score3,
                          &resultchunkvector,
                          &text_bytes,
                          &is_reliable);

    // Construct language results to return
    LanguageResult *langresults = new LanguageResult[3];
    for (int i = 0; i < 3; i++) {
      langresults[i].lang = language3[i];
      langresults[i].percent = percent3[i];
      langresults[i].score = normalized_score3[i];
    }

    // Constructs individual chunk results to return
    int num_chunks = static_cast<int>(resultchunkvector.size());
    ReturnChunk *returnchunkptr = new ReturnChunk [num_chunks];
    for (int i = 0; i < num_chunks; i++) {
      ResultChunk rc = resultchunkvector[i];
      returnchunkptr[i].offset = rc.offset;
      returnchunkptr[i].bytes = rc.bytes;
      returnchunkptr[i].lang = static_cast<Language>(rc.lang1);
    }

    SUMMARY_RESULT* res = new SUMMARY_RESULT;
    res->lang = lang;
    res->reliable = is_reliable;
    res->langresults = langresults;
    res->num_chunks = num_chunks;
    res->returnchunksptr = returnchunkptr;
    return res;
  }

  void freeSummaryResult(SUMMARY_RESULT *result) {
    delete[] result->langresults;
    delete[] result->returnchunksptr;
    delete result;
  }
}

int main(int argc, char **argv) {
}
