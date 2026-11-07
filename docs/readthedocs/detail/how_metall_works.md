# How Metall Works

This page provides an overview of Metall's internal architecture and explains how it manages memory and storage efficiently.

## Background: Virtual Memory and Physical Memory

Modern operating systems distinguish between [virtual memory](https://en.wikipedia.org/wiki/Virtual_memory) and physical memory. Virtual memory gives applications a large, contiguous address space, while physical memory is the actual RAM available on the system. The operating system maps virtual memory to physical memory, often using techniques such as [paging](https://en.wikipedia.org/wiki/Memory_paging).

When an application requests memory from an allocator or a function such as `malloc(3)`, the allocator typically requests a larger region of virtual memory from the operating system and manages it internally to fulfill individual requests. The addresses returned to the application are virtual addresses, which the operating system maps to physical memory as needed.

With *demand paging*, physical memory is not consumed until the application accesses a page.

Metall reserves a large, contiguous region of virtual memory. This reservation does not mean that physical memory is consumed immediately.

## Design Philosophy

Metall's design follows these principles, enabling efficient memory management without a complex internal architecture.

**Focus on relatively large allocations**

Metall targets large-scale data structures in HPC and data-intensive applications. It therefore does not use highly sophisticated techniques for many small allocations, such as those smaller than a page.

**Virtual memory is cheap on 64-bit machines; physical memory is dear** ([SuperMalloc](https://dl.acm.org/doi/10.1145/2887746.2754178))

Modern 64-bit Linux systems provide far more virtual address space than available physical memory.

Because of demand paging, reserving a large virtual memory region does not immediately consume physical memory.
Physical memory is allocated only when the application accesses the corresponding pages.

## Memory-Mapped File Mechanism

Metall uses memory-mapped files to allocate file-backed memory transparently to applications. By default, it uses the `mmap(2)` system call to map files into memory as needed.

The `mmap(2)` system call is a key memory-management mechanism on modern Unix-like operating systems. Using it helps Metall provide portability and stability across a wide range of systems.

Metall can also work with custom libraries that provide equivalent memory-mapping capabilities, such as [Privateer](https://github.com/LLNL/Privateer) and [Umap](https://github.com/LLNL/umap). This page focuses on Metall's default `mmap`-based memory management.

## Metall's Internal Architecture

The figure below illustrates Metall's internal architecture.

![Metall's internal architecture](../img/metall_architecture.png "Metall's Internal Architecture")

### Application Heap Segment

When a Metall manager (`metall::manager`) is constructed, Metall reserves a large, contiguous region of virtual memory, often on the order of terabytes. This region is called the *application heap segment*. Reserving it does not commit physical memory immediately. When an application requests memory, Metall returns an appropriate location within the reserved region.

Metall also reserves space for its internal management data when it reserves the application heap segment. This region is placed before the application heap segment, and both regions are reserved as one contiguous virtual memory region.

### Backing Files

Metall's default backend stores application data across multiple files. Splitting the datastore across files can improve parallel I/O performance, especially for large workloads. New files are created and mapped on demand using `mmap(2)`.

### Segments and Chunks

Metall divides the application heap segment into fixed-size chunks. The default chunk size is 2 MB. Each chunk can hold multiple small objects of the same internal allocation size. Objects larger than half a chunk are treated as large objects and occupy one or more contiguous chunks.

By default, Metall reclaims DRAM and file space at chunk granularity. As a result, freeing a small object usually does not release backing space immediately, while freeing a large object can. Metall also provides the compile-time hint `METALL_FREE_SMALL_OBJECT_SIZE_HINT=N`, which can trigger more aggressive space reclamation for deallocations at or above a specified size. See [Compile-time options](../basics/compile_time_options.md).

### Internal Allocation Size

Like other standard allocators, Metall rounds small allocations (for example, those smaller than 1 MB) up to internal size classes. These classes are influenced by ideas from [SuperMalloc](https://dl.acm.org/doi/10.1145/2887746.2754178) and [jemalloc](http://jemalloc.net/). They help bound internal fragmentation and keep size-class lookups fast. Specifically, the internal sizes are designed to keep internal fragmentation below 25%.

Large objects (for example, those larger than 1 MiB) are rounded up to the nearest power of 2. This can consume more virtual address space, but demand paging keeps the additional physical memory use negligible.

On systems with 4 KiB pages, the worst-case internal fragmentation is 0.4%. For example, when an allocation of 1 MiB + 1 B is rounded up to 2 MiB, touching the final byte commits a new 4 KiB page. If the preceding 1 MiB has also been accessed, the allocation uses 1 MiB + 4 KiB of physical memory—about 0.4% more than the requested size.

### Management Data

Metall uses three kinds of management data to track allocations:

- The *Bin Directory* stores the IDs of non-full chunks for each internal allocation size, helping speed up small allocations.
- The *Chunk Directory* tracks the state of each chunk; uses a compact multi-layer bitset to find free slots efficiently for small allocations.
- The *Name Directory* is a key-value store that maps object names to their locations.

These structures are updated frequently and involve fine-grained, random accesses, so Metall keeps them in DRAM while the datastore is open. When the datastore is opened, Metall reconstructs them from files. On a clean close or snapshot, it writes them back to files.