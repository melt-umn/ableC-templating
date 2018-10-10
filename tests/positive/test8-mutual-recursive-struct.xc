
//template<a> struct bar;

template<a>
struct foo {
  a x;
  inst bar<a> *b;
};

template<a>
struct bar {
  a x;
  inst foo<a> b;
};

int main(int argc, char **argv) {
  inst bar<float> p;
  inst foo<float> q = p.b;
}

