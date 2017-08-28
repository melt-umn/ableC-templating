
template<a>
void test1() {
  
}

template<a>
void test2() {
  {template test1<a>();}
  {template test1<a>();}
}

template<a>
void test3() {
  {template test2<a>();}
  {template test2<a>();}
}

template<a>
void test4() {
  {template test3<a>();}
  {template test3<a>();}
}

template<a>
void test5() {
  {template test4<a>();}
  {template test4<a>();}
}

template<a>
void test6() {
  {template test5<a>();}
  {template test5<a>();}
}

template<a>
void test7() {
  {template test6<a>();}
  {template test6<a>();}
}

int main() {
  template test6<int>();
}
