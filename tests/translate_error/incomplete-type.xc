
template<a>
struct foo {
  a x;
};

struct bar;

int main() {
  inst foo<struct bar> f;
}
