#include <stdio.h>
#include <stdlib.h>

template<typename a>
struct ptr {
  a *contents;
};

template<typename a>
ptr<a> new(a x) {
  ptr<a> res = {malloc(sizeof(a))};
  *res.contents = x;
  return res;
}

template<typename a>
a deref(ptr<a> x) {
  return *(x.contents);
}

template<typename a>
void delete(ptr<a> x) {
  free(x.contents);
}

int main() {
  ptr<ptr<int>> x = new(new(42));
  int res = deref(deref(x));
  printf("%d\n", res);
  delete(deref(x));
  delete(x);
  return res != 42;
}
