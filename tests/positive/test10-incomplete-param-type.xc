
template<a> struct bar { a f; };

struct foo { inst bar<struct baz> *a; };

struct baz { int x; };

int main() {
  
}
