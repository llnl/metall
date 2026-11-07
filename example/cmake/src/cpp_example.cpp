// Copyright 2021 Lawrence Livermore National Security, LLC and other Metall
// Project Developers. See the top-level COPYRIGHT file for details.
//
// SPDX-License-Identifier: (Apache-2.0 OR MIT)

#include <metall/metall.hpp>

int main() {
  metall::manager manager(metall::create_only, "/tmp/dir");
  manager.construct<int>("my_int")(123);
  int* my_int_ptr = manager.find<int>("my_int").first;
  if (my_int_ptr) {
    std::cout << "my_int: " << *my_int_ptr << std::endl;
  } else {
    std::cerr << "ERROR: my_int not found" << std::endl;
    std::abort();
  }

  return 0;
}