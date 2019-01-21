#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

template<k, v>
struct treemap_s {
  k key;
  v value;
  treemap_s<k, v> *left;
  treemap_s<k, v> *right;
};

using treemap<k, v> = treemap_s<k, v>*;

template<k, v>
treemap<k, v> put(treemap<k, v> map, k key, v value) {
  if (map == NULL) {
    treemap<k, v> res = malloc(sizeof(treemap_s<k, v>));
    res->key = key;
    res->value = value;
    res->left = NULL;
    res->right = NULL;
    return res;
  }
  else if (key < map->key) {
    map->left = put(map->left, key, value);
    return map;
  }
  else if (key > map->key) {
    map->right = put(map->right, key, value);
    return map;
  }
  else {
    map->key = key;
    map->value = value;
    return map;
  }
}

template<k, v>
v get(treemap<k, v> map, k key) {
  if (map == NULL) {
    fprintf(stderr, "Key not in map\n");
    exit(1);
  }
  else if (key < map->key) {
    return get(map->left, key);
  }
  else if (key > map->key) {
    return get(map->right, key);
  }
  else {
    return map->value;
  }
}

template<k, v>
bool contains(treemap<k, v> map, k key) {
  if (map == NULL) {
    return false;
  }
  else if (key < map->key) {
    return contains(map->left, key);
  }
  else if (key > map->key) {
    return contains(map->right, key);
  }
  else {
    return true;
  }
}

int main() {
  treemap<int, const char*> m = NULL;
  m = put(m, 2, " ");
  m = put(m, 0, "Hello");
  m = put(m, 3, "World");
  m = put(m, 1, ",");
  m = put(m, 5, "\n");
  m = put(m, 4, "!");

  for (unsigned i = 0; i < 6; i++) {
    printf("%s", get(m, i));
  }

  if (!contains(m, 3))
    return 2;
  else if (contains(m, 17))
    return 3;
  else
    return 0;
}
