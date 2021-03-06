Template extension
==================

This extension provides templated types and functions, similar to C++.
The purpose of this extension is:
* For end-users of ableC, to provide a general mechanism of type polymorphism
* For extension writers, to allow for extensions (e.g. vector) that utilize a large amount of static,
type-dependant code to be able to write this in a header file
* As a demonstration of the the use of lifting, substitution, and extension of the env with new
namespaces.  

### Template struct declaration
```c++
template<typename a, typename b>
struct pair {
  a fst;
  b snd;
};
```
Note here that, as in C++, the struct is 'typedefed' automaticly, to be referenced as
`pair<int, float>` and not `struct pair<int, float>`.

### Template function declaration
```c++
template<typename a>
a max(a x, a y) {
  return x > y? x : y;
}
```
Note that all templated functions are implicitly static.  

### Template alias
```c++
using triple<typename a, typename b, typename c> = pair<a, pair<b, c>>;
```
This syntax is inspired by C++11.

### Template type instantiation
```c++
pair<int, float> foo = {1, 2.4};
foo.snd = 3.14;
```

### Template function instantiation
```c++
int x = max<int>(3, 4);
```
If the template type arguments can be inferred from the function arguments types, then they may be
omitted, as in C++:
```c++
int x = max(3, 4);
```

## Implementation
Templated definitions of types or values are placed in a new environment namespace.  When an
instantiation is performed, the template item is looked up and the ableC substitution mechanism is
used to construct the templated decl, with a mangled name based on the type arguments.  This is then
lifted to the global scope via the ableC lifting mechanism.
A templated decl is actually implemented as its own forwarding a production that does the duplicate
check itself, so that other extensions that want to make use of a template instantiation within a type
can lift templateTypeExprInstDecl and refer to the mangled struct name directly.  
Note that this means that all instantation arguments must be defined globally; i.e. a typedef'ed type
local to a function cannot be used as an argument in an instantiation.

## Future work
* Explicit global instantiations? Would be easy to implement, just need concrete syntax for
templateExprInstDecl or templateTypeExprInstDecl.
* Allow linking behavior of templated functions to be explicitly specified, if desired. Currently
these are just static, to avoid redefinitions. Maybe allow an option to emit duplicates and use the
C++ linker?
