class Site {
  public final int x;
  public final int y;
  
  public Site(int x, int y) {
    this.x = x;
    this.y = y;
  }
  
  @Override
  public int hashCode() {
    return x + y;
  }
  
  @Override
  public boolean equals(Object obj) {
    if (this == obj) {
      return true;
    }
    
    if (obj.getClass() != Site.class) {
      return false;
    }
    
    Site other = (Site) obj;
    
    return x == other.x && y == other.y;
  }
}