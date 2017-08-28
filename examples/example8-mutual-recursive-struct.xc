
template<a> struct bar;

template<a>
struct foo {
  a x;
  template bar<a> *b;
};

template<a>
struct bar {
  a x;
  template foo<a> b;
};

int main(int argc, char **argv) {
  template bar<float> p;
  template foo<float> q = p.b;
}

