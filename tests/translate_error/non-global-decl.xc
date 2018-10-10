
int main() {
  template<a> struct foo { a x; };
  
  template<a> int bar(a x) {
    inst foo<a> y;
    y.x = x;
  }
  
  using baz<a> = inst foo<a>*;
}
