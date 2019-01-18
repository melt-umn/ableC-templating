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
  float y = max(2.45, 4.2);
  x<y;
  
  printf("%d\n", x);
  printf("%f\n", y);
  
}
