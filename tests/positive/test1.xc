#include <stdio.h>

template<a>
a max(a x, a y) {
  if (x > y)
    return x;
  else
    return y;
}

int main() {
  int x = max<int>(2, 4);
  float y = max<float>(2.45f, 4.2f);

  printf("%d\n", x);
  printf("%f\n", y);

  if (x != 4)
    return 1;
  if (y != 4.2f)
    return 2;
  return 0;
}
