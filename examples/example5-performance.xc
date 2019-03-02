
template<typename a>
void test1() {
  
}

template<typename a>
void test2() {
  {test1<a>();}
  {test1<a>();}
}

template<typename a>
void test3() {
  {test2<a>();}
  {test2<a>();}
}

template<typename a>
void test4() {
  {test3<a>();}
  {test3<a>();}
}

template<typename a>
void test5() {
  {test4<a>();}
  {test4<a>();}
}

template<typename a>
void test6() {
  {test5<a>();}
  {test5<a>();}
}

template<typename a>
void test7() {
  {test6<a>();}
  {test6<a>();}
}

int main() {
  test6<int>();
}
