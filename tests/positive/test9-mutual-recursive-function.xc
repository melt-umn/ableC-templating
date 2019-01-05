#include <stdio.h>

template<a>
struct data {
  a val;
};

template<a>
data<a> makeData(a val) {
  data<a> result;
  result.val = val;
  return result;
}

template<a>
data<a> bar(data<a> x);

template<a>
data<a> foo(data<a> x) {
  if (x.val <= 0)
    return makeData<a>(0);
  return makeData<a>(x.val + bar<a>(makeData<a>(x.val - 1)).val);
}

template<a>
data<a> bar(data<a> x) {
  if (x.val <= 0)
    return makeData<a>(0);
  return makeData<a>(x.val * foo<a>(makeData<a>(x.val - 1)).val);
}

int main(int argc, char **argv) {
  data<float> result = foo<float>(makeData<float>(3.14));
  printf("%f\n", result.val);

  return (result.val - 5.5796) * (result.val - 5.5796) > 0.001;
}
