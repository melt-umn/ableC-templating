#include <stdio.h>
#include <math.h>

template<a>
struct loc {
  a x;
  a y;
};

using locptr<a> = inst loc<a>*;

template<a>
a distance(inst locptr<a> p, inst locptr<a> q) {
  return (a)sqrt((p->x - q->x) * (p->x - q->x) + (p->y - q->y) * (p->y - q->y));
}

int main() {
  inst loc<int> a = {1, 2};
  inst loc<int> b = {3, 4};
  inst loc<float> c = {1.2, 3.4};
  inst loc<float> d = {5.6, 7.8};

  int ab = inst distance<int>(&a, &b);
  float cd = inst distance<float>(&c, &d);

  printf("%d\n", ab);
  printf("%f\n", cd);

  if (ab != 2)
    return 1;
  if (cd != 6.222539424896240234375f)
    return 2;
}
