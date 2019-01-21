
template<a>
struct foo {
  a x;
};

using bar1<a> = foo<a>*;
using bar2<a> = bar1<a>*;
using bar3<a> = bar2<a>*;
using bar4<a> = bar3<a>*;
using bar5<a> = bar4<a>*;

template<a>
a baz(bar5<a> x) {
  
}

int main() {
  foo<int> *****a;
  int res = baz(a);
}
