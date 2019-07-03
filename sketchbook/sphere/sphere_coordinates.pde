import java.util.Arrays;

final float SPHERE_RADIUS = 250;

float haversine(float angle) {
  return pow(sin(angle / 2), 2);
}

class SpherePoint {
  float azimuth;
  float zenith;
  
  SpherePoint(float azimuth, float zenith) {   
    this.azimuth = azimuth;
    this.zenith = zenith;
  }
  
  private float toX() {
    return SPHERE_RADIUS * sin(zenith) * sin(azimuth);
  }

  private float toY() {
    return SPHERE_RADIUS * cos(zenith) * -1;
  }
  
  private float toZ() {
    return SPHERE_RADIUS * sin(zenith) * cos(azimuth);
  }
  
  float[] toXYZ() {
    float x = toX();
    float y = toY();
    float z = toZ();
    
    return new float[]{ x, y, z };
  }
  
  float distanceFrom(SpherePoint origin) {
    float deltaAzimuth = this.azimuth - origin.azimuth;
    float deltaZenith = this.zenith - origin.zenith;
    
    float orgZenith = origin.zenith - HALF_PI;
    float destZenith = this.zenith - HALF_PI;
    
    float a = haversine(deltaZenith);
    float b = cos(orgZenith) * cos(destZenith) * haversine(deltaAzimuth);
    
    return asin(sqrt(a + b));
  }
  
  /**
   * @see https://www.movable-type.co.uk/scripts/latlong.html
   */
  SpherePoint middle(SpherePoint other) {
    float deltaAzimuth = other.azimuth - this.azimuth;
    float thisZenith = this.zenith - HALF_PI;
    float otherZenith = other.zenith - HALF_PI;
    
    float bx = cos(otherZenith) * cos(deltaAzimuth);
    float by = cos(otherZenith) * sin(deltaAzimuth);
    
    float alpha = sin(thisZenith) + sin(otherZenith);
    float beta = sqrt(pow(cos(thisZenith) + bx, 2) + pow(by, 2));
    float zenithMid = atan2(alpha, beta) + HALF_PI;

    float gamma = cos(thisZenith) + bx;
    float azimuthMid = this.azimuth + atan2(by, gamma);

    return new SpherePoint(azimuthMid, zenithMid);
  }
  
  void drawVertex() {
    float[] xyz = this.toXYZ();
    vertex(xyz[0], xyz[1], xyz[2]);
  }
  
  void drawPoint() {
    float[] xyz = this.toXYZ();
    pushMatrix();
    translate(xyz[0], xyz[1], xyz[2]);
    stroke(255);
    fill(255);
    sphereDetail(6);
    sphere(2);
    popMatrix();
  }
}

class SphereTriangle {
  SpherePoint first, second, third;
  
  SphereTriangle(SpherePoint first, SpherePoint second, SpherePoint third) {
    this.first = first;
    this.second = second;
    this.third = third;
  }
  
  float perimeter() {
    float first2second = second.distanceFrom(first);
    float second2third = third.distanceFrom(second);
    float third2first = first.distanceFrom(third);
    return first2second + second2third + third2first;
  }
  
  SphereTriangle[] split(float maxPerimeter) {
    if (this.perimeter() <= maxPerimeter) {
      return new SphereTriangle[] { this };
    } else {
      SpherePoint fs = first.middle(second);
      SpherePoint st = second.middle(third);
      SpherePoint tf = third.middle(first);
      
      SphereTriangle t1 = new SphereTriangle(first, fs, tf);
      SphereTriangle t2 = new SphereTriangle(second, st, fs);
      SphereTriangle t3 = new SphereTriangle(third, tf, st);
      SphereTriangle t4 = new SphereTriangle(fs, st, tf);

      ArrayList<SphereTriangle> triangles = new ArrayList<SphereTriangle>();
      triangles.addAll(Arrays.asList(t1.split(maxPerimeter)));
      triangles.addAll(Arrays.asList(t2.split(maxPerimeter)));
      triangles.addAll(Arrays.asList(t3.split(maxPerimeter)));
      triangles.addAll(Arrays.asList(t4.split(maxPerimeter)));
      return triangles.toArray(new SphereTriangle[triangles.size()]);
    }
  }
  
  void draw() {
    first.drawVertex();
    second.drawVertex();
    third.drawVertex();
  }
}

SpherePoint parseSpherePoint(JSONArray json) {
  float azimuth = json.getFloat(0);
  float zenith = json.getFloat(1);
  return new SpherePoint(azimuth, zenith);
}
