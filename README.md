# jq-voronoi
Implementation of Voronoi with jq

## Lunch tests
```bash
$ echo '[[0, 0], [10, 10], [2, 1.5], [6, 1], [9, 2], [4.5, 4], [2.5, 6.5], [6.5, 8]]' | ./voronoi.jq
$ echo '[[0, 0], [100, 100], [20, 15], [60, 10], [90, 20], [45, 40], [25, 65], [65, 80]]' | ./voronoi.jq
```

echo '[[0, 0], [10, 10], [3, 3], [6, 3], [3, 8], [6, 8]]' | ./voronoi.jq
echo '[[0, 0], [6, 6], [3, 1], [3, 2], [3, 3], [3, 4]]' | ./voronoi.jq
echo '[[0,0], [4,4], [1,1], [2,1], [3,1], [1,2], [2,2], [3,2], [1,3], [2,3], [3,3]]' | ./voronoi.jq
