#include <stdlib.h>
#include <stdio.h>

template<typename a, size_t size>
struct array {
  a contents[size];
};

template<typename a, size_t size>
a get(array<a, size> arr, size_t index) {
  if (index >= size) {
    fprintf(stderr, "Index %lu out of bounds for array of size %lu\n", index, size);
    exit(1);
  }
  return arr.contents[index];
}

template<typename a, size_t size>
void set(array<a, size> arr, size_t index, a value) {
  if (index >= size) {
    fprintf(stderr, "Index %lu out of bounds for array of size %lu\n", index, size);
    exit(1);
  }
  arr.contents[index] = value;
}


int main() {
  array<float, 3lu> a;
  set(a, 0, 3.14);
  set(a, 1, 2.27);
  set(a, 2, 12.34);
  //set(a, 3, 573.3);

  printf("%f\n", get(a, 0));
  printf("%f\n", get(a, 1));
  printf("%f\n", get(a, 2));
  //printf("%f\n", get(a, 3));
}
