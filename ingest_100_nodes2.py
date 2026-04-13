import requests
import json
import time
import uuid

# ==============================================================================
# CONFIGURATION
# ==============================================================================
CMS_URL = "http://localhost:4000/api/v1/ingest"
HEADERS = {
    "Content-Type": "application/json",
    "x-agent-id": "root"
}

# ==============================================================================
# DATA: 50 CLEANED UNIQUE FACTS ON PYTHON ARCHITECTURE
# ==============================================================================

PYTHON_ARCHITECTURE_FACTS = [
    # ----------------------------------------
    # 1-10: Memory Management & Garbage Collection
    # ----------------------------------------
    {
        "agent_id": "root",
        "fact_text": "Python uses reference counting as its primary mechanism for memory management, deallocating objects immediately when their reference count drops to zero.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CPython_Internals", "trust_score": 1.0},
        "description_payloads": [{"type": "text", "content": "The primary determinist cleanup mechanism."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The Cyclic Garbage Collector runs periodically to detect and clean up reference cycles that reference counting cannot handle.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Python_GC_Docs", "trust_score": 0.98},
        "description_payloads": [{"type": "text", "content": "Handles isolated islands of objects referencing each other."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Small objects in Python are allocated using the pymalloc allocator, which uses arenas, pools, and blocks to reduce fragmentation.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Python_Memory_Design", "trust_score": 0.99},
        "description_payloads": [{"type": "text", "content": "Optimized for objects smaller than 512 bytes."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Python employs string interning for small string literals and identifiers to save memory and speed up dictionary lookups.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "String_Optimization", "trust_score": 0.95},
        "description_payloads": [{"type": "text", "content": "Identical string literals share the same memory address."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The Generational Garbage Collection strategy divides objects into three generations based on their survival time to optimize collection frequency.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "GC_Generations", "trust_score": 0.97},
        "description_payloads": [{"type": "text", "content": "Younger generations are scanned more frequently than older ones."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Python integers are arbitrary precision objects, meaning they can grow as large as the available memory allows.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Python_Types", "trust_score": 1.0},
        "description_payloads": [{"type": "text", "content": "Stored as arrays of digits in base 2 to the power of 30."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The slots mechanism reduces memory usage in classes by preventing the creation of a dynamic dictionary for instance attributes.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Python_Optimization", "trust_score": 0.96},
        "description_payloads": [{"type": "text", "content": "Restricts dynamic attribute assignment."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Python lists utilize an over-allocation strategy during resizing to achieve amortized constant time complexity for append operations.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "List_Implementation", "trust_score": 0.98},
        "description_payloads": [{"type": "text", "content": "Growth factor is approximately 1.125 plus a constant."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The free list mechanism is used for tuples and floats to quickly recycle memory blocks instead of returning them to the operating system.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CPython_Pymalloc", "trust_score": 0.95},
        "description_payloads": [{"type": "text", "content": "Reduces malloc and free system call overhead."}]
    },
    {
        "agent_id": "root",
        "fact_text": "A Python dictionary implements a hash table using open addressing with quadratic probing for collision resolution.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Dict_Internals", "trust_score": 0.99},
        "description_payloads": [{"type": "text", "content": "Recently optimized to be compact and insertion-ordered."}]
    },
    # ----------------------------------------
    # 11-20: The Global Interpreter Lock (GIL) & Concurrency
    # ----------------------------------------
    {
        "agent_id": "root",
        "fact_text": "The Global Interpreter Lock prevents multiple native threads from executing Python bytecodes at once within a single process.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "GIL_Documentation", "trust_score": 1.0},
        "description_payloads": [{"type": "text", "content": "Ensures thread safety for CPython's internal memory structures."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The GIL is released during input-output operations, allowing other threads to run while one thread waits for network or disk access.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Threading_Model", "trust_score": 0.98},
        "description_payloads": [{"type": "text", "content": "Makes threading useful for I/O bound tasks."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The check interval defines how many bytecode instructions the interpreter executes before releasing the GIL to allow thread switching.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Sys_Module_Docs", "trust_score": 0.95},
        "description_payloads": [{"type": "text", "content": "Previously tick-based, now time-based in modern Python."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The multiprocessing module bypasses the GIL by spawning separate processes, each with its own Python interpreter and memory space.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Multiprocessing_Lib", "trust_score": 0.99},
        "description_payloads": [{"type": "text", "content": "Preferred for CPU-bound parallelism."}]
    },
    {
        "agent_id": "root",
        "fact_text": "C extension modules can explicitly release the GIL when performing heavy C-level computations to allow parallelism.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "C_API_Docs", "trust_score": 0.97},
        "description_payloads": [{"type": "text", "content": "Used by NumPy for parallel array operations."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Python Asyncio uses a single-threaded event loop to handle concurrency via cooperative multitasking and coroutines.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Asyncio_Architecture", "trust_score": 0.98},
        "description_payloads": [{"type": "text", "content": "Eliminates the need for thread context switching."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The await keyword suspends the execution of a coroutine, yielding control back to the event loop until the awaited future is complete.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Async_Await_Syntax", "trust_score": 1.0},
        "description_payloads": [{"type": "text", "content": "Non-blocking execution flow."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Thread switching in Python is preemptive, meaning the operating system decides when to switch threads, unlike the cooperative nature of Asyncio.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "OS_Threading", "trust_score": 0.96},
        "description_payloads": [{"type": "text", "content": "Can lead to race conditions if not managed with locks."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Atomic operations in Python, such as appending to a list, are thread-safe by default because the GIL is not released during a single bytecode instruction.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Atomic_Operations", "trust_score": 0.94},
        "description_payloads": [{"type": "text", "content": "Simplifies some concurrent code patterns."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Subinterpreters are an experimental feature allowing multiple interpreters to run within a single process, potentially offering a way to isolate GIL instances.",
        "acls": {"read": ["system"], "write": ["root"]},
        "provenance": {"source": "PEP_554", "trust_score": 0.92},
        "description_payloads": [{"type": "text", "content": "A path toward multi-core parallelism within one process."}]
    },
    # ----------------------------------------
    # 21-30: CPython Internals & Execution
    # ----------------------------------------
    {
        "agent_id": "root",
        "fact_text": "Everything in Python is an object, represented at the C level by the PyObject structure which contains a reference count and a type pointer.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "C_Structs", "trust_score": 1.0},
        "description_payloads": [{"type": "text", "content": "The base struct for all Python entities."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Python source code is compiled into bytecode, which is a low-level, platform-independent representation stored in pyc files.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Bytecode_Compilation", "trust_score": 0.99},
        "description_payloads": [{"type": "text", "content": "Executed by the stack-based virtual machine."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The ceval loop is the infinite loop in the CPython interpreter that iterates over bytecode instructions and executes them.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "CEval_Loop", "trust_score": 0.98},
        "description_payloads": [{"type": "text", "content": "The heart of the Python runtime."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The Method Resolution Order determines the class search path for methods and is calculated using the C3 linearization algorithm.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "MRO_Algorithm", "trust_score": 0.97},
        "description_payloads": [{"type": "text", "content": "Solves the diamond problem in multiple inheritance."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Descriptors are objects that customize attribute access via the get, set, and delete magic methods, underpinning properties and static methods.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Descriptor_Protocol", "trust_score": 0.96},
        "description_payloads": [{"type": "text", "content": "Key to Python's metaprogramming capabilities."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Metaclasses are classes of classes, allowing for the interception and modification of class creation at runtime.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Metaclass_Theory", "trust_score": 0.95},
        "description_payloads": [{"type": "text", "content": "Used by ORMs to map class definitions to database tables."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The sys modules dictionary acts as a cache for imported modules, ensuring that a module is initialized only once per process.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Import_System", "trust_score": 0.99},
        "description_payloads": [{"type": "text", "content": "Modifying this dict changes what modules are visible."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Python frames represent the execution context of a function call, containing local variables and the instruction pointer.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Execution_Stack", "trust_score": 0.98},
        "description_payloads": [{"type": "text", "content": "Allocated on the heap, allowing for deep recursion."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The LEGB rule defines the scope resolution order: Local, Enclosing, Global, and Built-in scopes.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Scope_Resolution", "trust_score": 1.0},
        "description_payloads": [{"type": "text", "content": "Determines which variable is accessed when names collide."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Decorators are syntactic sugar for higher-order functions, wrapping another function or class to extend its behavior transparently.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Decorator_Pattern", "trust_score": 0.97},
        "description_payloads": [{"type": "text", "content": "Applied at definition time."}]
    },
    # ----------------------------------------
    # 31-40: Data Structure Implementations
    # ----------------------------------------
    {
        "agent_id": "root",
        "fact_text": "Python sets are implemented as dictionaries with dummy values, optimized for fast membership testing and uniqueness checks.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Set_Implementation", "trust_score": 0.96},
        "description_payloads": [{"type": "text", "content": "Uses hashing for O(1) average lookup."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Tuples are immutable sequences, which makes them hashable and suitable for use as dictionary keys.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Tuple_Immutability", "trust_score": 0.99},
        "description_payloads": [{"type": "text", "content": "Cannot change size or content after creation."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Generators maintain their state between executions, allowing for lazy evaluation and memory-efficient iteration over large datasets.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Generator_Protocol", "trust_score": 0.98},
        "description_payloads": [{"type": "text", "content": "Uses the yield statement to pause execution."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The Buffer Protocol allows Python objects to expose their raw memory buffer to other objects like NumPy arrays without copying data.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Buffer_Protocol", "trust_score": 0.97},
        "description_payloads": [{"type": "text", "content": "Critical for zero-copy high-performance computing."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Views in Python, such as dict keys or memoryviews, provide a dynamic window into the underlying data without creating a static copy.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Data_Views", "trust_score": 0.95},
        "description_payloads": [{"type": "text", "content": "Reflects changes in the source object immediately."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The default arguments in a function are evaluated only once at definition time, which causes mutable defaults to persist across calls.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Mutable_Default_Trap", "trust_score": 0.94},
        "description_payloads": [{"type": "text", "content": "Common pitfall with lists or dictionaries as defaults."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Python 3 uses Unicode by default for strings, representing characters abstractly rather than as specific byte sequences.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Unicode_Standard", "trust_score": 0.99},
        "description_payloads": [{"type": "text", "content": "Separates text from binary data."}]
    },
    {
        "agent_id": "root",
        "fact_text": "F-strings are evaluated at runtime and are faster than format method calls because they are compiled directly into efficient bytecode.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "String_Interpolation", "trust_score": 0.98},
        "description_payloads": [{"type": "text", "content": "Introduced in Python 3.6."}]
    },
    {
        "agent_id": "root",
        "fact_text": "List comprehensions are faster than equivalent for loops because the iteration is performed at C speed inside the interpreter.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Loop_Optimization", "trust_score": 0.96},
        "description_payloads": [{"type": "text", "content": "optimized bytecode generation."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The weak reference module allows references to objects that do not prevent the garbage collector from destroying the referent.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "WeakRef_Module", "trust_score": 0.95},
        "description_payloads": [{"type": "text", "content": "Useful for implementing caches without memory leaks."}]
    },
    # ----------------------------------------
    # 41-50: Advanced & Web Architecture (WSGI/ASGI)
    # ----------------------------------------
    {
        "agent_id": "root",
        "fact_text": "The Web Server Gateway Interface is the synchronous standard interface between Python web applications and web servers.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "PEP_3333", "trust_score": 1.0},
        "description_payloads": [{"type": "text", "content": "Blocking I/O model."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The Asynchronous Server Gateway Interface extends WSGI to support asynchronous, long-lived connections like WebSockets.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "ASGI_Specs", "trust_score": 0.99},
        "description_payloads": [{"type": "text", "content": "Standard for modern async frameworks."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Context managers, used with the with statement, ensure resources like file handles are properly closed even if exceptions occur.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Context_Manager", "trust_score": 1.0},
        "description_payloads": [{"type": "text", "content": "Uses enter and exit magic methods."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Pickle is the standard serialization format for Python, capable of serializing almost any object, but is insecure against malicious data.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Serialization_Docs", "trust_score": 0.93},
        "description_payloads": [{"type": "text", "content": "Can execute arbitrary code during deserialization."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Type hinting in Python is optional and generally ignored at runtime, serving primarily for static analysis tools like Mypy.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "PEP_484", "trust_score": 0.97},
        "description_payloads": [{"type": "text", "content": "Does not affect performance."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The name main idiom allows a script to determine if it is being run as the main program or imported as a module.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Script_Execution", "trust_score": 1.0},
        "description_payloads": [{"type": "text", "content": "Standard entry point pattern."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Duck typing is the core philosophy of Python, where object suitability is determined by the presence of methods rather than inheritance.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Dynamic_Typing", "trust_score": 0.98},
        "description_payloads": [{"type": "text", "content": "If it walks and quacks like a duck, it is a duck."}]
    },
    {
        "agent_id": "root",
        "fact_text": "The peephole optimizer is a compilation step that performs simple optimizations like constant folding on the bytecode.",
        "acls": {"read": ["system"], "write": ["root"]},
        "provenance": {"source": "Bytecode_Optimizer", "trust_score": 0.94},
        "description_payloads": [{"type": "text", "content": "Pre-calculates static expressions."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Virtual environments isolate Python dependencies by modifying the system path, preventing version conflicts between projects.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Venv_Docs", "trust_score": 1.0},
        "description_payloads": [{"type": "text", "content": "Creates a self-contained directory tree."}]
    },
    {
        "agent_id": "root",
        "fact_text": "Wheel files are pre-compiled binary packages that allow for faster installation by bypassing the build stage for C extensions.",
        "acls": {"read": ["public"], "write": ["root"]},
        "provenance": {"source": "Packaging_Standards", "trust_score": 0.99},
        "description_payloads": [{"type": "text", "content": "The standard distribution format."}]
    }
]

# Ensure the list is exactly 50
if len(PYTHON_ARCHITECTURE_FACTS) != 50:
    print(f"WARNING: The manual fact list has {len(PYTHON_ARCHITECTURE_FACTS)} entries. Adjusting to 50...")
    PYTHON_ARCHITECTURE_FACTS = PYTHON_ARCHITECTURE_FACTS[:50]
    while len(PYTHON_ARCHITECTURE_FACTS) < 50:
        filler_num = len(PYTHON_ARCHITECTURE_FACTS) + 1
        PYTHON_ARCHITECTURE_FACTS.append({
            "agent_id": "root", "fact_text": f"Filler Detail {filler_num}: Reserved fact to ensure 50 total entries.",
            "acls": {"read": ["public"], "write": ["root"]},
            "provenance": {"source": "System_Filler", "trust_score": 0.8},
            "description_payloads": [{"type": "text", "content": "Placeholder for consistency check."}]
        })

# ==============================================================================
# INJECTION EXECUTION FUNCTIONS
# ==============================================================================

def inject_node(payload, node_number, total_nodes):
    """
    Constructs and sends a single node injection request to the CMS API.
    """
    try:
        response = requests.post(CMS_URL, headers=HEADERS, data=json.dumps(payload), timeout=20)
        
        if response.status_code in [200, 201, 202]:
            response_data = response.json()
            node_id = response_data.get("node_id", "N/A")
            print(f"✅ Node {node_number}/{total_nodes}: Injected successfully. ID: {node_id[:8]}... Status: {response.status_code}")
            return True
        else:
            print(f"❌ Node {node_number}/{total_nodes}: FAILED. Status: {response.status_code}, Reason: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Node {node_number}/{total_nodes}: CRITICAL ERROR. An exception occurred: {e}")
        return False

# ==============================================================================
# MAIN EXECUTION BLOCK
# ==============================================================================

if __name__ == "__main__":
    total_nodes_to_inject = len(PYTHON_ARCHITECTURE_FACTS)
    print(f"--- Starting batch injection of {total_nodes_to_inject} unique nodes on Python Architecture (Cleaned for Embedding) ---")
    
    success_count = 0
    start_time = time.time()
    
    for i, node_payload in enumerate(PYTHON_ARCHITECTURE_FACTS):
        if inject_node(node_payload, i + 1, total_nodes_to_inject):
            success_count += 1
        time.sleep(0.05)
            
    end_time = time.time()
    
    print("\n--- Batch injection complete ---")
    print(f"Total time taken: {end_time - start_time:.2f} seconds")
    print(f"Total successful injections: {success_count}/{total_nodes_to_inject}")