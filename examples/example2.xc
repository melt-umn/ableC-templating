#include <stdio.h>
#include <math.h>

template<a>
struct loc {
  a x;
  a y;
};

template<a>
a distance(template loc<a> p, template loc<a> q) {
  return (a)sqrt((p.x - q.x) * (p.x - q.x) + (p.y - q.y) * (p.y - q.y));
}

int main() {
  template loc<int> a = {1, 2};
  template loc<int> b = {3, 4};
  template loc<float> c = {1.2, 3.4};
  template loc<float> d = {5.6, 7.8};

  printf("%d\n", template distance<int>(a, b));
  printf("%f\n", template distance<float>(c, d));
}
