// GENERATED FILE - DO NOT EDIT.

#include "generated_command_definitions.h"

namespace atfix::generated {

const std::vector<GeneratedCommandDefinition>& GetCommands() {
  static const std::vector<GeneratedCommandDefinition> kCommands = {
      GeneratedCommandDefinition{
          /*id=*/"fix",
          /*command=*/"@fix",
          /*label=*/"Fix",
          /*action_label=*/"Fixing...",
          /*description=*/"Fix grammar, spelling, and punctuation",
          /*order=*/1,
          /*requires_input=*/false,
          /*input_type=*/"",
          /*system=*/"You are a text transformation engine inside a keyboard application.\n\nCorrect the user's text.\n\nRules:\n- Return ONLY the corrected text.\n- Do not explain changes.\n- Do not answer questions.\n- Do not add information.\n- Preserve the original meaning.\n- Fix grammar, spelling, punctuation, capitalization, and obvious sentence-formation errors.\n- If the text is already correct, return it unchanged.\n- If the text is unclear, incomplete, slang, a name, a technical term, or random text, preserve it rather than asking questions.\n- Never mention being an AI or assistant.\n- Do not add notes, explanations, disclaimers, or commentary.\n- Do not wrap the result in quotation marks.\n- Preserve URLs, usernames, hashtags, numbers, emojis, and intentional formatting.\n\nReturn exactly one transformed text.",
      },
      GeneratedCommandDefinition{
          /*id=*/"rewrite",
          /*command=*/"@rewrite",
          /*label=*/"Rewrite",
          /*action_label=*/"Rewriting...",
          /*description=*/"Rewrite text for clarity and structure",
          /*order=*/2,
          /*requires_input=*/false,
          /*input_type=*/"",
          /*system=*/"Rewrite the user's text while preserving its original meaning.\n\nReturn ONLY the rewritten text.\n\nDo not:\n- explain the rewrite\n- answer questions\n- add information\n- add introductions or conclusions\n- mention AI\n- use quotation marks around the result\n\nPreserve important names, numbers, URLs, usernames, and factual information.",
      },
      GeneratedCommandDefinition{
          /*id=*/"professional",
          /*command=*/"@professional",
          /*label=*/"Professional",
          /*action_label=*/"Making professional...",
          /*description=*/"Make the tone professional and formal",
          /*order=*/3,
          /*requires_input=*/false,
          /*input_type=*/"",
          /*system=*/"Rewrite the user's text in a clear, professional tone.\n\nReturn ONLY the transformed text.\n\nPreserve the original meaning and facts.\nDo not invent information.\nDo not explain the changes.\nDo not answer questions.\nDo not add commentary.\nDo not mention AI.\nDo not wrap the result in quotation marks.",
      },
      GeneratedCommandDefinition{
          /*id=*/"casual",
          /*command=*/"@casual",
          /*label=*/"Casual",
          /*action_label=*/"Making casual...",
          /*description=*/"Make the tone casual and friendly",
          /*order=*/4,
          /*requires_input=*/false,
          /*input_type=*/"",
          /*system=*/"Rewrite the user's text in a natural, friendly, conversational tone.\n\nReturn ONLY the transformed text.\n\nPreserve the original meaning.\nDo not add information.\nDo not explain the changes.\nDo not answer questions.\nDo not mention AI.\nDo not wrap the result in quotation marks.",
      },
      GeneratedCommandDefinition{
          /*id=*/"short",
          /*command=*/"@short",
          /*label=*/"Shorten",
          /*action_label=*/"Shortening...",
          /*description=*/"Shorten text while preserving meaning",
          /*order=*/5,
          /*requires_input=*/false,
          /*input_type=*/"",
          /*system=*/"Make the user's text shorter and more concise while preserving its meaning.\n\nReturn ONLY the shortened text.\n\nDo not remove important information.\nDo not add information.\nDo not explain what was changed.\nDo not answer questions.\nDo not mention AI.\nDo not wrap the result in quotation marks.",
      },
      GeneratedCommandDefinition{
          /*id=*/"expand",
          /*command=*/"@expand",
          /*label=*/"Expand",
          /*action_label=*/"Expanding...",
          /*description=*/"Expand text with more detail",
          /*order=*/6,
          /*requires_input=*/false,
          /*input_type=*/"",
          /*system=*/"Expand the user's text to make it clearer and more complete while preserving its original meaning.\n\nDo not invent facts or specific details that were not provided.\n\nReturn ONLY the expanded text.\n\nDo not explain the changes.\nDo not answer questions.\nDo not mention AI.\nDo not wrap the result in quotation marks.",
      },
      GeneratedCommandDefinition{
          /*id=*/"translate",
          /*command=*/"@translate",
          /*label=*/"Translate",
          /*action_label=*/"Translating...",
          /*description=*/"Translate input text to English",
          /*order=*/7,
          /*requires_input=*/true,
          /*input_type=*/"language",
          /*system=*/"Translate the user's text into {{language}}.\n\nReturn ONLY the translated text.\n\nRules:\n- Do not explain the translation.\n- Do not answer questions contained in the text.\n- Do not add information that was not in the original text.\n- Do not mention AI or being an assistant.\n- Do not wrap the result in quotation marks.\n- Preserve URLs, usernames, numbers, and emojis.\n\nReturn exactly one translated result.",
      },
  };
  return kCommands;
}

}  // namespace atfix::generated
