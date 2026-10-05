// Copyright 2023 Lawrence Livermore National Security, LLC and other Metall
// Project Developers. See the top-level COPYRIGHT file for details.
//
// SPDX-License-Identifier: (Apache-2.0 OR MIT)

#ifndef METALL_CONTAINER_UNORDERED_NODE_MAP_HPP
#define METALL_CONTAINER_UNORDERED_NODE_MAP_HPP

#include <functional>

#include <boost/unordered/unordered_node_map.hpp>
#if defined(BOOST_VERSION) && BOOST_VERSION < 108400
#warning "Boost 1.84.0 or higher supports fancy pointers"
#endif

#include <metall/metall.hpp>

namespace metall::container {

/// \brief An unordered_node_map container that uses Metall as its default
/// allocator.
template <class Key, class T, class Hash = std::hash<Key>,
          class KeyEqual = std::equal_to<Key>,
          class Allocator = manager::allocator_type<std::pair<const Key, T>>>
using unordered_node_map =
    boost::unordered_node_map<Key, T, Hash, KeyEqual, Allocator>;

}  // namespace metall::container

#endif  // METALL_CONTAINER_UNORDERED_NODE_MAP_HPP
