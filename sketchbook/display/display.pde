int minX, minY, maxX, maxY, width, height;
JSONArray cells;  // array of voronoi cells

void setup() {
  if (args.length == 2) {
    minX = minY = 0;
    width = maxX = Integer.parseInt(args[0]);
    height = maxY = Integer.parseInt(args[1]);
  } else if (args.length == 4) {
    minX = Integer.parseInt(args[0]);
    minY = Integer.parseInt(args[1]);
    maxX = Integer.parseInt(args[2]);
    maxY = Integer.parseInt(args[3]);
    width = maxX - minX;
    height = maxY - minY;
  } else {
    
    /* Affect variables to make code compile */
    minX = minY = maxX = maxY = width = height = 0;
    
    print("Invalid number of arguments");
    exit();
  }

  surface.setSize(width, height);

  noLoop();
  
  textAlign(CENTER, TOP);
  ellipseMode(CENTER);
  noStroke();
  background(0);
  
  /* Parse input */
  final BufferedReader reader = createReader(System.in);
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
  translate(-minX, -minY);
  
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
    fill(255);
    ellipse(siteX, siteY, 5, 5);
  }
}