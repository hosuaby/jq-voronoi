import java.util.Arrays;

class VoronoiCell {
  SpherePoint site;
  SpherePoint[] vertexes;
  
  SphereTriangle[] triangles;
  color col;
  
  VoronoiCell(SpherePoint site, SpherePoint[] vertexes) {
    this.site = site;
    this.vertexes = vertexes;
    
    this.triangles = toTriangles();
    this.col = randomColor();
  }
  
  void draw() {
    drawPolygon();
    drawSite();
  }
  
  private void drawPolygon() {
    strokeWeight(1);

    if (DEBUG) {
      stroke(255);
    } else {
      noStroke();
    }

    fill(col);
    beginShape(TRIANGLES);
    
    for (int i = 0; i < triangles.length; i++) {
      triangles[i].draw();
    }

    endShape();
  }
  
  SphereTriangle[] toTriangles() {
    ArrayList<SphereTriangle> triangles = new ArrayList<SphereTriangle>(vertexes.length);
    
    for (int i = 0; i < vertexes.length; i++) {
      SpherePoint nextVertex;
      if (i < vertexes.length - 1) {
        nextVertex = vertexes[i + 1];
      } else {
        nextVertex = vertexes[0];
      }
      
      SphereTriangle triangle = new SphereTriangle(site, vertexes[i], nextVertex);

      if (!DEBUG) {
        SphereTriangle[] newTriangles = triangle.split(0.15);
        triangles.addAll(Arrays.asList(newTriangles));
      } else {
        triangles.add(triangle);
      }
    }
    
    return triangles.toArray(new SphereTriangle[triangles.size()]);
  }
  
  private void drawSite() {
    site.drawPoint();
  }
}

color randomColor() {
  float red = random(255);
  float green = random(255);
  float blue = random(255);
  return color(red, green, blue);
}

VoronoiCell[] parseVoronoiCells(String jsonText) { 
  JSONArray cellsJson = parseJSONArray(jsonText);
  VoronoiCell[] voronoiCells = new VoronoiCell[cellsJson.size()];
  
  for (int i = 0; i < cellsJson.size(); i++) {
    JSONArray cellJson = cellsJson.getJSONArray(i);
    voronoiCells[i] = parseVoronoiCell(cellJson);
  }
  
  return voronoiCells;
}

VoronoiCell parseVoronoiCell(JSONArray cellJson) {
  JSONArray siteJson = cellJson.getJSONArray(0);
  SpherePoint site = parseSpherePoint(siteJson);
  
  SpherePoint[] vertexes = new SpherePoint[cellJson.size() - 1];
  for (int i = 1; i < cellJson.size(); i++) {
    JSONArray vertexJson = cellJson.getJSONArray(i);
    SpherePoint vertex = parseSpherePoint(vertexJson);
    vertexes[i - 1] = vertex;
  }
  
  return new VoronoiCell(site, vertexes);
}
