import java.util.List;
import java.util.LinkedList;
import java.util.Map;
import java.util.HashMap;

final int WIDTH = 600;
final int HEIGHT = 600;

String PROCESS_FOLDER;
String VORONOI_SCRIPT;

final List<Site> sites = new LinkedList<Site>();
final Map<Site, Integer> colors = new HashMap<Site, Integer>();
JSONArray cells = new JSONArray();  // array of voronoi cells

void setup() {
  PROCESS_FOLDER = sketchPath() + "/../../";
  VORONOI_SCRIPT = PROCESS_FOLDER + "voronoi.sh";
  
  size(600, 600);
  noStroke();
  noLoop();
}

void draw () {
  background(0);
  
  for (int i = 0; i < cells.size(); i++) {
    final JSONArray cell = cells.getJSONArray(i);
    final JSONArray siteJson = cell.getJSONArray(0);
    final Site site = new Site(siteJson.getInt(0), siteJson.getInt(1));
    
    /* Draw polygon of the cell */
    int c = colors.get(site);
    fill(c);
    beginShape();
    
    for (int j = 1; j < cell.size(); j++) {
      final JSONArray v = cell.getJSONArray(j);
      vertex(v.getInt(0), v.getInt(1));
    }
    
    endShape(CLOSE);
  
    /* Draw the site */
    fill(255);
    ellipse(site.x, site.y, 5, 5);
  }
}

void mouseClicked() {
  final Site newSite = new Site(mouseX, mouseY);
  sites.add(newSite);
  colors.put(newSite, color(random(255), random(255), random(255)));
  
  JSONArray json = serialize(sites);
  cells = voronoi(json);
  
  redraw();
}

JSONArray serialize(List<Site> sites) {
  JSONArray array = new JSONArray();
  
  /* Add bounding box */
  array.append(new JSONArray().append(0).append(0));
  array.append(new JSONArray().append(WIDTH).append(HEIGHT));
  
  /* Add sites */
  for (Site site : sites) {
    array.append(new JSONArray().append(site.x).append(site.y));
  }
  
  return array;
}

JSONArray voronoi(JSONArray sitesJson) {
  ProcessBuilder processBuilder = new ProcessBuilder(VORONOI_SCRIPT)
    .directory(new File(PROCESS_FOLDER))
    .redirectErrorStream(true);
  
  try {
    Process process = processBuilder.start();
    OutputStream out = process.getOutputStream();
    InputStream in = process.getInputStream();
    
    /* Send sites JSON to process */
    PrintWriter writer = createWriter(out);
    writer.println(sitesJson.toString());
    writer.flush();
    writer.close();
 
    /* Read response from process */
    BufferedReader reader = createReader(in);
    
    StringBuilder response = new StringBuilder();
    String line;
    
    while ((line = reader.readLine()) != null) {
      response.append(line);
    }
    
    return parseJSONArray(response.toString());
  } catch (Exception exception) {
    println("ERROR: " + exception.getMessage());
  }
  
  return new JSONArray();
}