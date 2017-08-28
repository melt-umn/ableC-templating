#include <stdio.h>
#include <stdlib.h>

template<a>
struct ptr {
  a *contents;
};

template<a>
template ptr<a> new(a x) {
  template ptr<a> res = {malloc(sizeof(a))};
  *res.contents = x;
  return res;
}

template<a>
a deref(template ptr<a> x) {
  return *(x.contents);
}

template<a>
void delete(template ptr<a> x) {
  free(x.contents);
}

int main() {
  template ptr<template ptr<int>> x = inst new<template ptr<int>>(inst new<int>(42));
  printf("%d\n", inst deref<int>(inst deref<template ptr<int>>(x)));
  inst delete<int>(inst deref<template ptr<int>>(x));
  inst delete<template ptr<int>>(x);
}
