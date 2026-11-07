// Copyright 2019 Lawrence Livermore National Security, LLC and other Metall
// Project Developers. See the top-level COPYRIGHT file for details.
//
// SPDX-License-Identifier: (Apache-2.0 OR MIT)

#include "gtest/gtest.h"

#include <cstddef>
#include <cstdint>
#include <sys/types.h>

#include <metall/detail/mmap.hpp>

namespace {

using metall::mtlldetail::get_page_size;
using metall::mtlldetail::os_munmap;
using metall::mtlldetail::reserve_aligned_vm_region;
using metall::mtlldetail::reserve_vm_region;

// A length no process can map. mmap(2) fails with ENOMEM.
constexpr std::size_t k_unmappable_length = std::size_t(1) << 62;

TEST(MmapTest, ReserveVmRegion) {
  const ssize_t page_size = get_page_size();
  ASSERT_GT(page_size, 0);

  const std::size_t length = static_cast<std::size_t>(page_size) * 4;
  void *const addr = reserve_vm_region(length);
  ASSERT_NE(addr, nullptr);
  ASSERT_EQ(reinterpret_cast<std::uintptr_t>(addr) % static_cast<std::size_t>(page_size), 0);
  ASSERT_TRUE(os_munmap(addr, length));
}

TEST(MmapTest, ReserveVmRegionFailure) {
  ASSERT_EQ(reserve_vm_region(k_unmappable_length), nullptr);
}

TEST(MmapTest, ReserveAlignedVmRegion) {
  const ssize_t page_size = get_page_size();
  ASSERT_GT(page_size, 0);

  const std::size_t alignment = static_cast<std::size_t>(page_size) * 8;
  const std::size_t length = alignment * 4;
  void *const addr = reserve_aligned_vm_region(alignment, length);
  ASSERT_NE(addr, nullptr);
  ASSERT_EQ(reinterpret_cast<std::uintptr_t>(addr) % alignment, 0);
  ASSERT_TRUE(os_munmap(addr, length));
}

TEST(MmapTest, ReserveAlignedVmRegionFailure) {
  const ssize_t page_size = get_page_size();
  ASSERT_GT(page_size, 0);

  ASSERT_EQ(reserve_aligned_vm_region(static_cast<std::size_t>(page_size),
                                      k_unmappable_length),
            nullptr);
}

}  // namespace
