# jq-voronoi
Implementation of Fortune's algorithm to calculate Voronoi diagram on
[jq](https://stedolan.github.io/jq/)

<p align="center">
    <img height="600px" src="https://cdn.rawgit.com/hosuaby/jq-voronoi/develop/docs/bluejay_voronoi.jpg" />
</p>

## Run demo
To run the following demo `jq` must be installed and availbale on PATH.

```bash
$ ./gensites | ./voronoi.sh | ./2svg --argjson box '[600, 600]' > /tmp/voronoi.svg
```

Check generated `/tmp/voronoi.svg` file.

## Usage

Script `voronoi/voronoi.jq` (ou wrapper `voronoi.sh`) takes as input array of points in cartesian
coordinates. First two points are coordinates of respectively top-left & bottom-right corners of
bounding box. The rest are corrdinates of sites that must imperatively be within bounding box.
The following input describes:

```javascript
[[0, 0], [100, 100], [20, 15], [60, 10], [90, 20], [45, 40], [25, 65], [65, 80]]
```

<p align="center">
    <img src="https://cdn.rawgit.com/hosuaby/jq-voronoi/develop/docs/doc_1.svg"
        width="200px"
        height="200px" />
</p>

- Bounding box with top-left corner at `[0, 0]` and bottom-right corner at  `[100, 100]`
- Sites at `[20, 15], [60, 10], [90, 20], [45, 40], [25, 65], [65, 80]`

Script outputs following:

```javascript
[
  [
    /* Coordinates of site */
    [
      20,
      15
    ],
    
    /* Counter-clockwise ordered points forming polygon of voronoi cell of the site */
    [
      40.833333333333336,
      19.166666666666668
    ],
    [
      38.43749999999999,
      0
    ],
    [
      0,
      0
    ],
    [
      0,
      42.25000000000001
    ],
    [
      19.72222222222222,
      40.27777777777778
    ]
  ],
  
  ...   // other sites
  
]
``` 

- Script output is an array of arrays of points
- The first point of each array is a site
- The rest of array are counter-clockwise ordered points forming polygon of voronoi cell of the site

## Visualization:

### Render to SVG

Script `2svg` can render output of `voronoi.sh` (`voronoi/voronoi.jq`) into SVG file.

Usage:
```bash
$ echo '[[0, 0], [100, 100], ... ]' | ./voronoi.sh | ./2svg --argjson box '[100, 100]' > output.svg
```

`2svg` takes a single JSON argument `box`, defining bounding box. `box` can have 2 or 4 elements.

**Two elements** *(Example: [600, 600])* box starts at [0, 0]

1. box width *= 600*
2. box height *= 600*

**Four elements** *(Example: [50, 50, 150, 150])*

1. top-left corner x *= 50*
2. top-left corner y *= 50*
3. bottom-right corner x *= 150*
4. bottom-right corner y *= 150*

```bash
$ ./2svg --argjson box '[600, 600]'             # bounding box [0, 0] -> [600, 600]
$ ./2svg --argjson box '[50, 50, 150, 150]'     # bounding box [50, 50] -> [150, 150]
```

Voronoi diagram for
`[[0, 0], [100, 100], [20, 15], [60, 10], [90, 20], [45, 40], [25, 65], [65, 80]]`:

<p align="center">
    <img src="https://cdn.rawgit.com/hosuaby/jq-voronoi/develop/docs/doc_2.svg"
        width="150px"
        height="150px" />
</p>
    
### Visualization sketch

Voronoi diagram can also be displayed with sketch.

To run visualization sketch [Processing 3+](https://processing.org/) must be installed and
`processing-java` executable must be on the PATH.

To display diagram redirect output of `voronoi.sh` (`voronoi/voronoi.jq`) to `demo/display.sh`.
Script accept two or four parameters, defining bounding box.
If user supplies two arguments, they are respectively `width` & `height` of the bounding box
starting at [0, 0].

If user provides four arguments, the two first arguments are x & y coordinates of top-left corner,
and last two are x & y coordinates of bottom-right corner of bounding box.

```bash
$ demo/display.sh 600 600             # bounding box [0, 0] -> [600, 600]
$ demo/display.sh 50 50 150 150       # bounding box [50, 50] -> [150, 150]
```

<p align="center">
    <img src="https://cdn.rawgit.com/hosuaby/jq-voronoi/develop/docs/doc_3.png" />
</p>