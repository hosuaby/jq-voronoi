import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.lang.StringBuilder;

JSONArray cells;  // arry of voronoi cells

void setup() {
  final int width = Integer.parseInt(args[0]);
  final int height = Integer.parseInt(args[1]);

  surface.setSize(width, height);
    
  noLoop();
  
  textAlign(CENTER, TOP);
  ellipseMode(CENTER);
  background(0);
  
  /* Parse input */
  final BufferedReader reader = new BufferedReader(new InputStreamReader(System.in));
  final StringBuilder input = new StringBuilder();
  
  String line;
  
  try {
    while ((line = reader.readLine()) != null) {
      input.append(line);
    }
  } catch(final IOException exception) {
    println(exception.getMessage());
  }
  
  cells = parseJSONArray(input.toString());
}

void draw() {
  for (int i = 0; i < cells.size(); i++) {
    final JSONArray cell = cells.getJSONArray(i);
    final JSONArray site = cell.getJSONArray(0);
    final int siteX = site.getInt(0);
    final int siteY = site.getInt(1);
    
    /* Draw polygon of the cell */
    fill( random(255), random(255), random(255)); 
    beginShape();
    
    for (int j = 1; j < cell.size(); j++) {
      final JSONArray v = cell.getJSONArray(j);
      vertex(v.getInt(0), v.getInt(1));
    }
    
    endShape(CLOSE);
  
    /* Draw the site */
    // fill(0);
    // ellipse(siteX, siteY, 5, 5);
  }
  
  // TODO: remove it later
  for (int i = 0; i < cells.size(); i++) {
    final JSONArray cell = cells.getJSONArray(i);
    final JSONArray site = cell.getJSONArray(0);
    final int siteX = site.getInt(0);
    final int siteY = site.getInt(1);
    
    fill(255);
    ellipse(siteX, siteY, 5, 5);
    text(String.format("[%d; %d]", siteX, siteY), siteX, siteY + 6);
  }
}