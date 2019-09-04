
int main() {
  template<typename a> struct foo { a x; };
  
  template<typename a> int bar(a x) {
    foo<a> y;
    y.x = x;
  }
  
  using baz<typename a> = foo<a>*;
}
