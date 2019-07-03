import java.io.FileInputStream;
import peasy.*;

PeasyCam camera;
VoronoiCell[] cells = new VoronoiCell[]{};
boolean DEBUG;

void setup() {
  size(600, 600, P3D);
  camera = new PeasyCam(this, 600);
  DEBUG = isDebug();
  
  try {
    if (System.in.available() == 0) {
      selectInput("Select a file with voronoi diagram:", "readCells");
    } else {
      readCells(null);
    }
  } catch (IOException ioException) {
    println(ioException.getMessage());
  }
}

void draw() {
  background(0);
  drawCells();
}

boolean isDebug() {
  if (args == null) {
    return false;
  }

  for (String arg : args) {
    if (arg.equals("--debug")) {
      return true;
    }
  }

  return false;
}

void drawCells() {
  for (int i = 0; i < cells.length; i++) {
    cells[i].draw();
  }
}

void readCells(File file) throws IOException {
  InputStream inputStream;
  
  if (file != null) {
    inputStream = new FileInputStream(file);
  } else {
    inputStream = System.in;
  }
  
  String jsonText = readInput(inputStream);
  cells = parseVoronoiCells(jsonText);
}

String readInput(InputStream inputStream) throws IOException {
  BufferedReader reader = createReader(inputStream);
  StringBuilder input = new StringBuilder();
  
  String line;
  while ((line = reader.readLine()) != null) {
    input.append(line);
  }

  return input.toString();
}
