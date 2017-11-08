import java.util.Map;
import java.util.List;
import java.util.ArrayList;

final int MIN_X = 331;
final int MIN_Y = 0;
final int MAX_X = 662;
final int MAX_Y = 915;
final int NB_SITES = 700;

/**
 * Euclidean distance between points p1 and p2.
 */
float distance(int[] p1, int[] p2) {
  return sqrt(sq(p1[0]-p2[0]) + sq(p1[1]-p2[1]));
}

void setup() {
  size(662, 915);

  /* Load image */
  PImage bluejay = loadImage("bluejay.jpg");
  image(bluejay, 0, 0);

  /* Generate random sites */
  int[][] sites = new int[NB_SITES][2];

  for (int s = 0; s < NB_SITES; s++) {
    sites[s][0] = (int) random(MIN_X, MAX_X);
    sites[s][1] = (int) random(MIN_Y, MAX_Y);
  }
  
  /* Site id -> nearest points */
  Map<Integer, List<int[]>> voronoi = new HashMap<Integer, List<int[]>>();
  
  for (int s = 0; s < NB_SITES; s++) {
    voronoi.put(s, new ArrayList<int[]>());
  }
  
  for (int y = MIN_Y; y <= MAX_Y; y++) {
    for (int x = MIN_X; x <= MAX_X; x++) {
      int[] point = {x, y};
      
      float minDistance = Float.MAX_VALUE;
      int nearestSiteId = 0;
      
      for (int s = 0; s < NB_SITES; s++) {
        float dist = distance(sites[s], point);
        
        if (dist < minDistance) {
          minDistance = dist;
          nearestSiteId = s;
        }
      }
      
      voronoi.get(nearestSiteId).add(point);
    }
  }
  
  for (int s = 0; s < NB_SITES; s++) {
    List<int[]> points = voronoi.get(s);
    int nbPoints = points.size();
    float red = 0;
    float green = 0;
    float blue = 0;
    
    /* Calculate mean color of cell */
    for (int i = 0; i < nbPoints; i++) {
      int[] point = points.get(i);
      color c = get(point[0], point[1]);
      red += red(c);
      green += green(c);
      blue += blue(c);
    }
    
    red /= nbPoints;
    green /= nbPoints;
    blue /= nbPoints;
    
    color meanColor = color(red, green, blue);
    
    /* Color all cell with mean color */
    for (int i = 0; i < nbPoints; i++) {
      int[] point = points.get(i);
      set(point[0], point[1], meanColor);
    }
  }
  
  /* Save image */
  save("bluejay_voronoi.jpg");
}