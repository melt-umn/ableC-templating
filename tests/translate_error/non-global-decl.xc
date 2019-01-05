
int main() {
  template<a> struct foo { a x; };
  
  template<a> int bar(a x) {
    foo<a> y;
    y.x = x;
  }
  
  using baz<a> = foo<a>*;
}
