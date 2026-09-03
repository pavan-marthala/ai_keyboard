cmake_minimum_required(VERSION 3.22.1)

project("latinime" C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include_directories(
    aosp_latinime/src
)

add_library(
    latinime
    SHARED
    latinime/latinime_jni.cpp
    aosp_latinime/src/dictionary/header/header_policy.cpp
    aosp_latinime/src/dictionary/header/header_read_write_utils.cpp
    aosp_latinime/src/dictionary/property/ngram_context.cpp
    aosp_latinime/src/dictionary/structure/dictionary_structure_with_buffer_policy_factory.cpp
    aosp_latinime/src/dictionary/structure/pt_common/bigram/bigram_list_read_write_utils.cpp
    aosp_latinime/src/dictionary/structure/pt_common/dynamic_pt_gc_event_listeners.cpp
    aosp_latinime/src/dictionary/structure/pt_common/dynamic_pt_reading_helper.cpp
    aosp_latinime/src/dictionary/structure/pt_common/dynamic_pt_reading_utils.cpp
    aosp_latinime/src/dictionary/structure/pt_common/dynamic_pt_updating_helper.cpp
    aosp_latinime/src/dictionary/structure/pt_common/dynamic_pt_writing_utils.cpp
    aosp_latinime/src/dictionary/structure/pt_common/patricia_trie_reading_utils.cpp
    aosp_latinime/src/dictionary/structure/pt_common/shortcut/shortcut_list_reading_utils.cpp
    aosp_latinime/src/dictionary/structure/v2/patricia_trie_policy.cpp
    aosp_latinime/src/dictionary/structure/v2/ver2_patricia_trie_node_reader.cpp
    aosp_latinime/src/dictionary/structure/v2/ver2_pt_node_array_reader.cpp
    aosp_latinime/src/dictionary/structure/v4/ver4_dict_buffers.cpp
    aosp_latinime/src/dictionary/structure/v4/ver4_dict_constants.cpp
    aosp_latinime/src/dictionary/structure/v4/ver4_patricia_trie_node_reader.cpp
    aosp_latinime/src/dictionary/structure/v4/ver4_patricia_trie_node_writer.cpp
    aosp_latinime/src/dictionary/structure/v4/ver4_patricia_trie_policy.cpp
    aosp_latinime/src/dictionary/structure/v4/ver4_patricia_trie_reading_utils.cpp
    aosp_latinime/src/dictionary/structure/v4/ver4_patricia_trie_writing_helper.cpp
    aosp_latinime/src/dictionary/structure/v4/ver4_pt_node_array_reader.cpp
    aosp_latinime/src/dictionary/structure/v4/content/dynamic_language_model_probability_utils.cpp
    aosp_latinime/src/dictionary/structure/v4/content/language_model_dict_content.cpp
    aosp_latinime/src/dictionary/structure/v4/content/language_model_dict_content_global_counters.cpp
    aosp_latinime/src/dictionary/structure/v4/content/shortcut_dict_content.cpp
    aosp_latinime/src/dictionary/structure/v4/content/sparse_table_dict_content.cpp
    aosp_latinime/src/dictionary/structure/v4/content/terminal_position_lookup_table.cpp
    aosp_latinime/src/dictionary/utils/buffer_with_extendable_buffer.cpp
    aosp_latinime/src/dictionary/utils/byte_array_utils.cpp
    aosp_latinime/src/dictionary/utils/dict_file_writing_utils.cpp
    aosp_latinime/src/dictionary/utils/file_utils.cpp
    aosp_latinime/src/dictionary/utils/forgetting_curve_utils.cpp
    aosp_latinime/src/dictionary/utils/format_utils.cpp
    aosp_latinime/src/dictionary/utils/mmapped_buffer.cpp
    aosp_latinime/src/dictionary/utils/multi_bigram_map.cpp
    aosp_latinime/src/dictionary/utils/probability_utils.cpp
    aosp_latinime/src/dictionary/utils/sparse_table.cpp
    aosp_latinime/src/dictionary/utils/trie_map.cpp
    aosp_latinime/src/suggest/core/suggest.cpp
    aosp_latinime/src/suggest/core/dicnode/dic_node.cpp
    aosp_latinime/src/suggest/core/dicnode/dic_node_utils.cpp
    aosp_latinime/src/suggest/core/dicnode/dic_nodes_cache.cpp
    aosp_latinime/src/suggest/core/dictionary/dictionary.cpp
    aosp_latinime/src/suggest/core/dictionary/dictionary_utils.cpp
    aosp_latinime/src/suggest/core/dictionary/digraph_utils.cpp
    aosp_latinime/src/suggest/core/dictionary/error_type_utils.cpp
    aosp_latinime/src/suggest/core/layout/additional_proximity_chars.cpp
    aosp_latinime/src/suggest/core/layout/proximity_info.cpp
    aosp_latinime/src/suggest/core/layout/proximity_info_params.cpp
    aosp_latinime/src/suggest/core/layout/proximity_info_state.cpp
    aosp_latinime/src/suggest/core/layout/proximity_info_state_utils.cpp
    aosp_latinime/src/suggest/core/policy/weighting.cpp
    aosp_latinime/src/suggest/core/session/dic_traverse_session.cpp
    aosp_latinime/src/suggest/core/result/suggestion_results.cpp
    aosp_latinime/src/suggest/core/result/suggestions_output_utils.cpp
    aosp_latinime/src/suggest/policyimpl/gesture/gesture_suggest_policy_factory.cpp
    aosp_latinime/src/suggest/policyimpl/typing/scoring_params.cpp
    aosp_latinime/src/suggest/policyimpl/typing/typing_scoring.cpp
    aosp_latinime/src/suggest/policyimpl/typing/typing_suggest_policy.cpp
    aosp_latinime/src/suggest/policyimpl/typing/typing_traversal.cpp
    aosp_latinime/src/suggest/policyimpl/typing/typing_weighting.cpp
    aosp_latinime/src/utils/autocorrection_threshold_utils.cpp
    aosp_latinime/src/utils/char_utils.cpp
    aosp_latinime/src/utils/jni_data_utils.cpp
    aosp_latinime/src/utils/log_utils.cpp
    aosp_latinime/src/utils/time_keeper.cpp
    aosp_latinime/src/dictionary/structure/backward/v402/ver4_dict_buffers.cpp
    aosp_latinime/src/dictionary/structure/backward/v402/ver4_dict_constants.cpp
    aosp_latinime/src/dictionary/structure/backward/v402/ver4_patricia_trie_node_reader.cpp
    aosp_latinime/src/dictionary/structure/backward/v402/ver4_patricia_trie_node_writer.cpp
    aosp_latinime/src/dictionary/structure/backward/v402/ver4_patricia_trie_policy.cpp
    aosp_latinime/src/dictionary/structure/backward/v402/ver4_patricia_trie_reading_utils.cpp
    aosp_latinime/src/dictionary/structure/backward/v402/ver4_patricia_trie_writing_helper.cpp
    aosp_latinime/src/dictionary/structure/backward/v402/ver4_pt_node_array_reader.cpp
    aosp_latinime/src/dictionary/structure/backward/v402/content/bigram_dict_content.cpp
    aosp_latinime/src/dictionary/structure/backward/v402/content/probability_dict_content.cpp
    aosp_latinime/src/dictionary/structure/backward/v402/content/shortcut_dict_content.cpp
    aosp_latinime/src/dictionary/structure/backward/v402/content/sparse_table_dict_content.cpp
    aosp_latinime/src/dictionary/structure/backward/v402/content/terminal_position_lookup_table.cpp
    aosp_latinime/src/dictionary/structure/backward/v402/bigram/ver4_bigram_list_policy.cpp
)

find_library(
    log-lib
    log
)

target_link_libraries(
    latinime
    ${log-lib}
)
