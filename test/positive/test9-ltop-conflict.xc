#include <stdio.h>

template<a>
a max(a x, a y) {
  if (y<x)
    return x;
  else
    return y;
}

int main() {
  int x = inst max<int>(2, 4);
  float y = inst max<float>(2.45f, 4.2f);

  printf("%d\n", x);
  printf("%f\n", y);

  if (x != 4)
    return 1;
  if (y != 4.2f)
    return 2;
  return 0;
}
