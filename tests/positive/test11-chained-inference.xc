
template<typename a>
struct foo {
  a x;
};

using bar1<typename a> = foo<a>*;
using bar2<typename a> = bar1<a>*;
using bar3<typename a> = bar2<a>*;
using bar4<typename a> = bar3<a>*;
using bar5<typename a> = bar4<a>*;

template<typename a>
a baz(bar5<a> x) {
  
}

int main() {
  foo<int> *****a;
  int res = baz(a);
}
