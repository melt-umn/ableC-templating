
template<typename a>
struct foo {
  a x;
};

struct bar;

int main() {
  foo<struct bar> f;
}
