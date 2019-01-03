#include <stdio.h>

template<a>
struct data {
  a val;
};

template<a>
inst data<a> makeData(a val) {
  inst data<a> result;
  result.val = val;
  return result;
}

template<a>
inst data<a> foo(inst data<a> x) {
  if (x.val <= 0)
    return inst makeData<a>(0);
  return inst makeData<a>(x.val + inst bar<a>(inst makeData<a>(x.val - 1)).val);
}

template<a>
inst data<a> bar(inst data<a> x) {
  if (x.val <= 0)
    return inst makeData<a>(0);
  return inst makeData<a>(x.val * inst foo<a>(inst makeData<a>(x.val - 1)).val);
}

int main(int argc, char **argv) {
  inst data<float> result = inst foo<float>(inst makeData<float>(3.14));
  printf("%f\n", result.val);

  return (result.val - 5.5796) * (result.val - 5.5796) > 0.001;
}

