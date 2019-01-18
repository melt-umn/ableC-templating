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
  return makeData(x.val + bar(makeData(x.val - 1)).val);
}

template<a>
data<a> bar(data<a> x) {
  if (x.val <= 0)
    return makeData<a>(0);
  return makeData(x.val * foo(makeData(x.val - 1)).val);
}

int main(int argc, char **argv) {
  data<float> result = foo(makeData(3.14f));
  printf("%f\n", result.val);

  return (result.val - 5.5796) * (result.val - 5.5796) > 0.001;
}
