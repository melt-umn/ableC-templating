
template<a> struct bar { a f; };

struct foo { bar<struct baz> *a; };

struct baz { int x; };

int main() {
  
}
