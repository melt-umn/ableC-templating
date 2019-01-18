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
  ptr<ptr<int>> x = new(new(42));
  printf("%d\n", deref(deref(x)));
  delete(deref(x));
  delete(x);
}
