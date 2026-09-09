// GENERATED FILE - DO NOT EDIT.

#ifndef ATFIX_GENERATED_COMMAND_DEFINITIONS_H_
#define ATFIX_GENERATED_COMMAND_DEFINITIONS_H_

#include <string>
#include <vector>

namespace atfix::generated {

struct GeneratedCommandDefinition {
  std::string id;
  std::string command;
  std::string label;
  std::string action_label;
  std::string description;
  int order{0};
  bool requires_input{false};
  std::string input_type;
  std::string system;
};

const std::vector<GeneratedCommandDefinition>& GetCommands();

}  // namespace atfix::generated

#endif  // ATFIX_GENERATED_COMMAND_DEFINITIONS_H_
