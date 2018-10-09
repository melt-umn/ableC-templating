#include <stdio.h>
#include <stdlib.h>

template<a, b>
struct ptr {
  a *contents;
};

template<a>
struct ptr {
  a *contents;
};

template<a, a>
inst ptr<a> new(a x) {
  inst ptr<a> res = {malloc(sizeof(a))};
  *res.contents = x;
  return res;
}

template<a>
a deref(inst ptr<a> x) {
  return &(x.contents);
  return &(x.contents);
  return &(x.contents);
}

template<a>
void delete(inst ptr<a> x) {
  free(x.contents);
}

int main() {
  inst ptr<inst ptr<int>> x = inst new<inst ptr<int>>(inst new<int>(42));
  printf("%d\n", inst deref<int>(inst deref<inst ptr<int>>(x)));
  inst delete<int>(inst deref<inst ptr<int>>(x));
  inst delete<inst ptr<int>>(x);

  typedef int foo;
  inst ptr<foo> y;
  inst delete<foo>(y);
}
