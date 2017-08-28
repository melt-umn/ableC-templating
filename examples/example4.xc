#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

template<k, v>
struct treemap_s {
  k key;
  v value;
  template treemap_s<k, v> *left;
  template treemap_s<k, v> *right;
};

using treemap<k, v> = template treemap_s<k, v>*;

template<k, v>
template treemap<k, v> put(template treemap<k, v> map, k key, v value) {
  if (map == NULL) {
    template treemap<k, v> res = malloc(sizeof(template treemap_s<k, v>));
    res->key = key;
    res->value = value;
    res->left = NULL;
    res->right = NULL;
    return res;
  }
  else if (key < map->key) {
    map->left = template put<k, v>(map->left, key, value);
    return map;
  }
  else if (key > map->key) {
    map->right = template put<k, v>(map->right, key, value);
    return map;
  }
  else {
    map->key = key;
    map->value = value;
    return map;
  }
}

template<k, v>
v get(template treemap<k, v> map, k key) {
  if (map == NULL) {
    fprintf(stderr, "Key not in map\n");
    exit(1);
  }
  else if (key < map->key) {
    return template get<k, v>(map->left, key);
  }
  else if (key > map->key) {
    return template get<k, v>(map->right, key);
  }
  else {
    return map->value;
  }
}

template<k, v>
bool contains(template treemap<k, v> map, k key) {
  if (map == NULL) {
    return false;
  }
  else if (key < map->key) {
    return template contains<k, v>(map->left, key);
  }
  else if (key > map->key) {
    return template contains<k, v>(map->right, key);
  }
  else {
    return true;
  }
}

int main() {
  template treemap<int, const char*> m = NULL;
  m = template put<int, const char*>(m, 2, " ");
  m = template put<int, const char*>(m, 0, "Hello");
  m = template put<int, const char*>(m, 3, "World");
  m = template put<int, const char*>(m, 1, ",");
  m = template put<int, const char*>(m, 5, "\n");
  m = template put<int, const char*>(m, 4, "!");

  for (unsigned i = 0; i < 6; i++) {
    printf("%s", template get<int, const char*>(m, i));
  }

  if (!template contains<int, const char*>(m, 3))
    return 2;
  else if (template contains<int, const char*>(m, 17))
    return 3;
  else
    return 0;
}
