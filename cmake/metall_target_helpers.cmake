## Add include directories to a target for this build only.
## Inputs: target_name is the target to update; ARGN contains include paths.
## Output: adds BUILD_INTERFACE include entries; no output variable is set.
function(metall_add_build_interface_include_dirs target_name)
  foreach(include_dir IN LISTS ARGN)
    if(include_dir)
      target_include_directories(${target_name} INTERFACE $<BUILD_INTERFACE:${include_dir}>)
    endif()
  endforeach()
endfunction()

## Add compile definitions to a target for this build only.
## Inputs: target_name is the target to update; ARGN contains definitions.
## Output: adds BUILD_INTERFACE compile definitions; no output variable is set.
function(metall_add_build_interface_compile_definitions target_name)
  foreach(compile_definition IN LISTS ARGN)
    if(compile_definition)
      target_compile_definitions(${target_name} INTERFACE $<BUILD_INTERFACE:${compile_definition}>)
    endif()
  endforeach()
endfunction()

## Resolve an alias to the real target before reading its properties.
## Inputs: output_var receives the result; target_name is an alias or target.
## Output: sets output_var in the caller's scope to the real target name, or
##         target_name unchanged when it is not a known alias.
function(metall_resolve_target_name output_var target_name)
  if(TARGET ${target_name})
    get_target_property(aliased_target ${target_name} ALIASED_TARGET)
    if(aliased_target)
      set(${output_var} ${aliased_target} PARENT_SCOPE)
    else()
      set(${output_var} ${target_name} PARENT_SCOPE)
    endif()
  else()
    set(${output_var} ${target_name} PARENT_SCOPE)
  endif()
endfunction()

## Convert local library targets to linker-file references safe for exports.
## Inputs: output_var receives the result; ARGN contains targets or link items.
## Output: imported targets and plain items are preserved, local compiled targets
##         become TARGET_LINKER_FILE expressions, and local interface targets
##         are omitted.
function(metall_convert_local_targets_to_link_items output_var)
  set(link_items "")
  foreach(link_item IN LISTS ARGN)
    if(TARGET ${link_item})
      metall_resolve_target_name(target_to_check ${link_item})

      get_target_property(link_item_imported ${target_to_check} IMPORTED)
      get_target_property(link_item_type ${target_to_check} TYPE)
      if(link_item_imported)
        list(APPEND link_items ${link_item})
      elseif(link_item_type STREQUAL "INTERFACE_LIBRARY")
        continue()
      else()
        list(APPEND link_items "$<TARGET_LINKER_FILE:${target_to_check}>")
      endif()
    else()
      list(APPEND link_items ${link_item})
    endif()
  endforeach()
  set(${output_var} ${link_items} PARENT_SCOPE)
endfunction()

## Collect local library targets needed before linker-file references can be used.
## Inputs: output_var receives the result; ARGN contains targets or link items.
## Output: sets output_var to unique, non-imported, non-interface targets.
function(metall_collect_local_target_dependencies output_var)
  set(local_target_dependencies "")
  foreach(link_item IN LISTS ARGN)
    if(TARGET ${link_item})
      metall_resolve_target_name(target_to_check ${link_item})

      get_target_property(link_item_imported ${target_to_check} IMPORTED)
      get_target_property(link_item_type ${target_to_check} TYPE)
      if(NOT link_item_imported AND NOT link_item_type STREQUAL "INTERFACE_LIBRARY")
        list(APPEND local_target_dependencies ${target_to_check})
      endif()
    endif()
  endforeach()
  list(REMOVE_DUPLICATES local_target_dependencies)
  set(${output_var} ${local_target_dependencies} PARENT_SCOPE)
endfunction()

## Gather one interface property from a list of existing targets.
## Inputs: output_var receives the result; property_name is queried on each
##         target in ARGN.
## Output: sets output_var to unique property values, skipping missing targets
##         and unset properties.
function(metall_collect_target_interface_property output_var property_name)
  set(collected_values "")
  foreach(link_item IN LISTS ARGN)
    if(TARGET ${link_item})
      metall_resolve_target_name(target_to_check ${link_item})

      get_target_property(property_values ${target_to_check} ${property_name})
      if(property_values AND NOT property_values STREQUAL "${property_name}-NOTFOUND")
        list(APPEND collected_values ${property_values})
      endif()
    endif()
  endforeach()
  list(REMOVE_DUPLICATES collected_values)
  set(${output_var} ${collected_values} PARENT_SCOPE)
endfunction()

## Copy include directories and compile definitions onto a build target.
## Inputs: target_name is the target to update; ARGN contains dependency targets.
## Output: mirrors their include directories and compile definitions as
##         BUILD_INTERFACE requirements; no output variable is set.
function(metall_mirror_target_usage_to_build_interface target_name)
  metall_collect_target_interface_property(interface_include_dirs INTERFACE_INCLUDE_DIRECTORIES ${ARGN})
  metall_collect_target_interface_property(interface_compile_definitions INTERFACE_COMPILE_DEFINITIONS ${ARGN})
  metall_add_build_interface_include_dirs(${target_name} ${interface_include_dirs})
  metall_add_build_interface_compile_definitions(${target_name} ${interface_compile_definitions})
endfunction()

## Link dependencies while keeping local targets out of exported interfaces.
## Inputs: target_name is the target to update, visibility is PRIVATE/PUBLIC/
##         INTERFACE, and ARGN contains link dependencies.
## Output: uses BUILD_LOCAL_INTERFACE on CMake 3.26+; older versions use
##         export-safe linker-file references. No output variable is set.
function(metall_link_build_local_targets target_name visibility)
  if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.26")
    foreach(link_item IN LISTS ARGN)
      if(link_item)
        target_link_libraries(${target_name} ${visibility}
          "$<BUILD_LOCAL_INTERFACE:${link_item}>")
      endif()
    endforeach()
  else()
    metall_convert_local_targets_to_link_items(export_safe_link_items ${ARGN})
    if(export_safe_link_items)
      target_link_libraries(${target_name} ${visibility} ${export_safe_link_items})
    endif()
  endif()
endfunction()

## Find the Boost targets that are already available in this build.
## Inputs: output_component_targets and output_all_targets name result variables.
## Output: the first contains matching Metall component targets; the second also
##         includes Boost::headers or Boost::boost when available.
function(metall_get_boost_targets output_component_targets output_all_targets)
  set(component_targets "")
  foreach(boost_component IN LISTS METALL_BOOST_COMPONENTS)
    if(TARGET Boost::${boost_component})
      list(APPEND component_targets Boost::${boost_component})
    endif()
  endforeach()

  set(all_targets ${component_targets})
  if(TARGET Boost::headers)
    list(APPEND all_targets Boost::headers)
  elseif(TARGET Boost::boost)
    list(APPEND all_targets Boost::boost)
  endif()
  list(REMOVE_DUPLICATES all_targets)

  set(${output_component_targets} ${component_targets} PARENT_SCOPE)
  set(${output_all_targets} ${all_targets} PARENT_SCOPE)
endfunction()

## Attach Boost usage requirements to Metall for same-build consumers only.
## Inputs: target_name is the interface target; ARGN contains Boost targets.
## Output: adds build-only links, avoids attaching duplicates, and records local
##         targets for legacy export handling; no output variable is set.
function(metall_attach_build_tree_boost_usage target_name)
  get_property(attached_boost_targets GLOBAL PROPERTY METALL_ATTACHED_BOOST_TARGETS)
  foreach(boost_target IN LISTS ARGN)
    if(NOT TARGET ${boost_target})
      continue()
    endif()

    list(FIND attached_boost_targets ${boost_target} attached_index)
    if(NOT attached_index EQUAL -1)
      continue()
    endif()

    metall_resolve_target_name(real_boost_target ${boost_target})
    if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.26")
      target_link_libraries(${target_name} INTERFACE
        "$<BUILD_LOCAL_INTERFACE:${boost_target}>")
    else()
      target_link_libraries(${target_name} INTERFACE
        "$<BUILD_INTERFACE:${boost_target}>")
      get_target_property(boost_target_imported ${real_boost_target} IMPORTED)
      if(NOT boost_target_imported)
        add_dependencies(${target_name} ${real_boost_target})
        set_property(GLOBAL APPEND PROPERTY METALL_LOCAL_BOOST_TARGETS ${real_boost_target})
      endif()
    endif()

    list(APPEND attached_boost_targets ${boost_target})
    set_property(GLOBAL PROPERTY METALL_ATTACHED_BOOST_TARGETS "${attached_boost_targets}")
  endforeach()
endfunction()

## Export Metall targets for consumers using this build directory.
## Inputs: uses PROJECT_NAME and CMAKE_CURRENT_BINARY_DIR from the caller.
## Output: writes <PROJECT_NAME>Targets.cmake unless old CMake plus local Boost
##         targets make that export unsafe; then it reports the skip.
function(metall_export_build_tree_targets)
  get_property(local_boost_targets GLOBAL PROPERTY METALL_LOCAL_BOOST_TARGETS)
  if(CMAKE_VERSION VERSION_LESS "3.26" AND local_boost_targets)
    message(STATUS
      "Skipping Metall build-tree export: this CMake version cannot export locally fetched Boost targets safely")
  else()
    export(EXPORT ${PROJECT_NAME}Targets
      FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Targets.cmake")
  endif()
endfunction()
