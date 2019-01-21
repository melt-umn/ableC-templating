#include <stdlib.h>

template<a>
a *newarray(size_t len) {
  return (a *)malloc(sizeof(a) * len);
}

int main() {
  double *d = newarray(42);
}
