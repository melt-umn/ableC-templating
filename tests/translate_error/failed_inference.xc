#include <stdlib.h>

template<typename a>
a *newarray(size_t len) {
  return (a *)malloc(sizeof(a) * len);
}

template<int x>
int foo() {
  return x;
}

int main() {
  double *d = newarray(42);

  int res = foo();
}
