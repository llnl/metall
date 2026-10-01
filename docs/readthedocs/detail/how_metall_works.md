# How Metall Works

On this page, we provide an overview of Metall's internal architecture and explain how it manages memory and storage efficiently.

## Background: Virtual Memory And Physical Memory

In modern operating systems, memory is divided into [virtual memory](https://en.wikipedia.org/wiki/Virtual_memory) and physical memory.

Virtual memory is an abstraction that allows applications to use a large, contiguous address space, while physical memory represents the actual RAM available on the system.
The operating system manages the mapping between virtual and physical memory, often using techniques like *[paging](https://en.wikipedia.org/wiki/Memory_paging)* to optimize memory usage.

When an application requests memory from a memory allocator or function (e.g., *malloc(3)*), the allocator typically requests a larger chunk of virtual memory from the operating system and manages it internally to satisfy individual allocation requests.
Memory addresses returned to the application are virtual addresses, which the operating system maps to physical memory as needed.

Another important background knowledge is the concept of *demand paging*. In demand paging, physical memory is not consumed until the page is actually accessed by the application.

Metall internally reserves a large contiguous region of virtual memory:
however, this does not mean that physical memory is consumed immediately.

## Design Philosophy

Metall is designed following the philosophy below, which allows us to provide efficient and fast memory management without employing complex internal architecture.

**Focus on relatively large size allocations**

Metall targets large-scale data structures in HPC and data-intensive applications.
Therefore, Metall does not employ highly sophisticated techniques for many small allocations (e.g., smaller than page sizes).

**Virtual memory is cheap in 64-bit machine, physical memory is dear [SuperMalloc](https://dl.acm.org/doi/10.1145/2887746.2754178)**

In modern 64-bit Linux systems, an application can use a way more virtual memory space than the available physical memory.

### Leverage demand paging (physical memory is not consumed until accessed)

Because of demand paging, reserving a large virtual memory region does not immediately consume physical memory. Physical memory is only allocated when the application accesses the corresponding pages.

## Memory-Mapped File Mechanism

Metall relies on the memory-mapped file technique to allocate memory in files transparently for applications.
By default, it uses the *mmap(2)* system call under the hood to map files into memory as needed.

The mmap system call is one of the key memory management mechanisms in modern Unix-like operating systems.
Leveraging mmap allows Metall to provide high portability and stability on a very wide range of systems.

Metall is designed to work with custom libraries that provide equivalent memory mapping capabilities as *mmap(2)*, such as [Privateer](https://github.com/LLNL/Privateer) and [Umap](https://github.com/LLNL/umap).
However, on this page, we focus on the default mmap version of Metall's memory management.

## Application Heap Segment

When a Metall manager ('metall::manager') object is constructed, Metall reserves a large contiguous region of virtual memory, often on the order of terabytes.
We call this reserved region the *application heap segment*.
This reservation does not mean that physical memory is committed immediately.
When applications request memory, Metall returns a proper location within the reserved virtual memory region to the application.


## Backing Files

Metall's default backend uses multiple files to store application data. Splitting the datastore
across multiple backing files can improve parallel I/O performance, especially
for large workloads. New files are created and mapped on demand.

## Segment and Chunk

Metall divides that address range into chunks. The default chunk size is 2 MB.
Each chunk can hold multiple small objects of the same internal allocation
size. Objects larger than half a chunk are treated as large objects and occupy
one or more contiguous chunks.

By default, Metall reclaims DRAM and file space at chunk granularity. As a
result, freeing a small object usually does not release backing space
immediately, while freeing a large object can. Metall also provides a compile
time hint, `METALL_FREE_SMALL_OBJECT_SIZE_HINT=N`, to try to release space more
aggressively for deallocations at or above a chosen size. See
[Compile-time options](../basics/compile_time_options.md).

## Internal Allocation Size

Like other high-performance allocators, Metall rounds small allocations up to
internal size classes. These size classes are influenced by ideas from
[SuperMalloc](https://dl.acm.org/doi/10.1145/2887746.2754178) and
[jemalloc](http://jemalloc.net/), which helps bound internal fragmentation and
keep size-class lookup fast.

Large objects are rounded up differently. This may consume more virtual address
space, but thanks to uncommitted pages it does not imply proportional physical
memory usage.

## Management Data

Metall uses three kinds of management data to manage allocations.

The figure below shows Metall's internal architecture.
![metall_architecture](../img/metall_architecture.png "Metall's Internal Architecture")

- The Bin Directory stores non-full chunk IDs for each internal allocation
  size, which makes small allocations fast.
- The Chunk Directory tracks the state of each chunk and uses a compact
  multi-layer bitset to find free slots efficiently.
- The Name Directory is a simple key-value store that maps object names to
  their locations.

Because these structures are updated frequently and involve fine-grained random
accesses, Metall keeps them in DRAM while the datastore is open. On open,
Metall reconstructs them from files, and on clean close or snapshot it writes
them back to persistent storage.
