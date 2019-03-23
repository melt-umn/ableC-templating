#include <stdio.h>
#include <stdlib.h>

template<typename a, typename b>
struct ptr {
  a *contents;
};

template<typename a>
struct ptr {
  a *contents;
};

template<typename a, typename a>
ptr<a> new(a x) {
  ptr<a> res = {malloc(sizeof(a))};
  *res.contents = x;
  return res;
}

template<typename a>
a deref(ptr<a> x) {
  return &(x.contents);
  return &(x.contents);
  return &(x.contents);
}

template<typename a>
void delete(ptr<a> x) {
  free(x.contents);
}

template<int x>
struct bar {
  int items[x];
};

int asdf, qwerty;

struct baz {int x;} b;

int main() {
  ptr<ptr<int>> x = new<ptr<int>>(new<int>(42));
  printf("%d\n", deref<int>(deref<ptr<int>>(x)));
  delete<int>(deref<ptr<int>>(x));
  delete<ptr<int>>(x);

  typedef int foo;
  ptr<foo> y;
  delete<foo>(y);

  ptr<asdf> z;

  bar<qwerty> q;
  bar<asdf> p = q;

  bar<b>;
}
