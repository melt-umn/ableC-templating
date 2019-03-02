#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

template<typename k, typename v, int (*cmp)(k, k)>
struct treemap_s {
  k key;
  v value;
  treemap_s<k, v, cmp> *left;
  treemap_s<k, v, cmp> *right;
};

using treemap<typename k, typename v, int (*cmp)(k, k)> = treemap_s<k, v, cmp>*;

template<typename k, typename v, int (*cmp)(k, k)>
treemap<k, v, cmp> put(treemap<k, v, cmp> map, k key, v value) {
  if (map == NULL) {
    treemap<k, v, cmp> res = malloc(sizeof(treemap_s<k, v, cmp>));
    res->key = key;
    res->value = value;
    res->left = NULL;
    res->right = NULL;
    return res;
  } else {
    int diff = cmp(key, map->key);
    if (diff < 0) {
      map->left = put(map->left, key, value);
      return map;
    } else if (diff > 0) {
      map->right = put(map->right, key, value);
      return map;
    } else {
      map->key = key;
      map->value = value;
      return map;
    }
  }
}

template<typename k, typename v, int (*cmp)(k, k)>
v get(treemap<k, v, cmp> map, k key) {
  if (map == NULL) {
    fprintf(stderr, "Key not in map\n");
    exit(1);
  } else {
    int diff = cmp(key, map->key);
    if (diff < 0) {
      return get(map->left, key);
    } else if (diff > 0) {
      return get(map->right, key);
    } else {
      return map->value;
    }
  }
}

template<typename k, typename v, int (*cmp)(k, k)>
bool contains(treemap<k, v, cmp> map, k key) {
  if (map == NULL) {
    return false;
  } else {
    int diff = cmp(key, map->key);
    if (diff < 0) {
      return contains(map->left, key);
    } else if (diff > 0) {
      return contains(map->right, key);
    } else {
      return true;
    }
  }
}

int intcmp(int x, int y) {
  return x - y;
}

int main() {
  treemap<int, const char*, intcmp> m = NULL;
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
