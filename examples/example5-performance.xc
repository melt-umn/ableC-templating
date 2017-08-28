
template<a>
void test1() {
  
}

template<a>
void test2() {
  {inst test1<a>();}
  {inst test1<a>();}
}

template<a>
void test3() {
  {inst test2<a>();}
  {inst test2<a>();}
}

template<a>
void test4() {
  {inst test3<a>();}
  {inst test3<a>();}
}

template<a>
void test5() {
  {inst test4<a>();}
  {inst test4<a>();}
}

template<a>
void test6() {
  {inst test5<a>();}
  {inst test5<a>();}
}

template<a>
void test7() {
  {inst test6<a>();}
  {inst test6<a>();}
}

int main() {
  inst test6<int>();
}
