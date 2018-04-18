#include <stdio.h>
#include <math.h>

template<a>
struct loc {
  a x;
  a y;
};

template<a>
a distance(inst loc<a> p, inst loc<a> q) {
  return (a)sqrt((p.x - q.x) * (p.x - q.x) + (p.y - q.y) * (p.y - q.y));
}

int main() {
  inst loc<int> a = {1, 2};
  inst loc<int> b = {3, 4};
  inst loc<float> c = {1.2f, 3.4f};
  inst loc<float> d = {5.6f, 7.8f};

  int ab = inst distance<int>(a, b);
  float cd = inst distance<float>(c, d);

  printf("%d\n", ab);
  printf("%f\n", cd);

  if (ab != 2)
    return 1;
  if (cd != 6.222539424896240234375f)
    return 2;
}
