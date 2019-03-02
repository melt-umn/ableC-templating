#include <stdio.h>
#include <math.h>

template<typename a>
struct loc {
  a x;
  a y;
};

template<typename a>
a distance(loc<a> p, loc<a> q) {
  return (a)sqrt((p.x - q.x) * (p.x - q.x) + (p.y - q.y) * (p.y - q.y));
}

int main() {
  loc<int> a = {1, 2};
  loc<int> b = {3, 4};
  loc<float> c = {1.2f, 3.4f};
  loc<float> d = {5.6f, 7.8f};

  int ab = distance(a, b);
  float cd = distance(c, d);

  printf("%d\n", ab);
  printf("%f\n", cd);

  if (ab != 2)
    return 1;
  if (cd != 6.222539424896240234375f)
    return 2;
}
