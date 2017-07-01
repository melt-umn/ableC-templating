#include <stdio.h>
#include <stdlib.h>

template<a>
struct ptr {
  a *contents;
};

template<a>
ptr<a> new(a x) {
  ptr<a> res = {malloc(sizeof(a))};
  *res.contents = x;
  return res;
}

template<a>
a deref(ptr<a> x) {
  return *(x.contents);
}

template<a>
void delete(ptr<a> x) {
  free(x.contents);
}

int main() {
  ptr<ptr<int>> x = new<ptr<int>>(new<int>(42));
  int res = deref<int>(deref<ptr<int>>(x));
  printf("%d\n", res);
  delete<int>(deref<ptr<int>>(x));
  delete<ptr<int>>(x);
  return res != 42;
}
