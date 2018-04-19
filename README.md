# LGenerics

LGenerics package for FPC and Lazarus, 
    contains generic algorithms and data structures
    (explosive growing mixture of generics with virtual methods :). 

System requirements: FPC 3.1.1 and higher, Lazarus 1.9.0 and higher.
   
Installation and usage:
  1. Open and compile package LGenerics/packages/LGenerics.lpk.
  2. Add LGenerics to project dependencies.

Contains:  
  1. Algorithms(mostly in unit LGArrayHelpers):
    - permutations
    - binary search
    - N-th order statistics
    - distinct values selection
    - quicksort
    - introsort
    - dual pivot quicksort
    - mergesort
    - timsort(unit LGMiscUtils)
    - counting sort
    - some non-cryptogarphic hashes(unit LGHash)

  2. Data structures:
    - stack(unit LGStack)
    - queue(unit LGQueue)
    - deque(unit LGDeque)
    - vector(unit LGVector)
    - prority queue(unit LGPriorityQueue)
    - full featured priority queue with key update and melding (unit LGQueue)
    - sorted list(unit LGSortedList)
    - hashset(unit LGHashSet)
    - sorted set(unit LGTreeSet)
    - hash multiset(unit LGHashMultiSet)
    - sorted multiset(unit LGTreeMultiSet)
    - hashmap(unit LGHashMap)
    - sorted map(unit LGTreeMap)
    - hash multimap(unit LGMultiMap)
    - tree multimap(unit LGMultiMap)
    - list miltimap(unit LGMultiMap)
    - bijective map(unit LGBiMap)
    - sparse table(unit LGSparseTable)
  
  3. Others:
    - simply command line parser (unit LGMiscUtils)
    - brief and dirty implementation of futures concept(unit LGAsync)
    - simplest blocking channel impementation (unit LGAsync)
