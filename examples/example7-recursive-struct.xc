
template<a>
struct foo {
  a x;
  template foo<int> *b;
};

int main(int argc, char **argv) {
  template foo<float> q;
}
