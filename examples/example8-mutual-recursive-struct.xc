template<typename a> struct bar;

template<typename a>
struct foo {
  a x;
  bar<a> *b;
};

template<typename a>
struct bar {
  a x;
  foo<a> b;
};

int main(int argc, char **argv) {
  bar<float> p;
  foo<float> q = p.b;
}

