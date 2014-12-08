part of vf_deformation;

Vector2 advancePoint(Vector2 start, num advance) {
  Vector2 k1 = evaluateFunction(start.x, start.y);
  Vector2 k2 = evaluateFunction(
        start.x + k1.x * advance * 0.5,
        start.y + k1.y * advance * 0.5
      );
  Vector2 k3 = evaluateFunction(
        start.x + k2.x * advance * 0.5,
        start.y + k2.x * advance * 0.5
      );
  Vector2 k4 = evaluateFunction(
        start.x + k3.x * advance,
        start.y + k3.x * advance
      );
  Vector2 ret =  start + (k1 + (k2 + k3) * 2.0 + k4) * (advance / 6);
  return ret;
}

Vector2 evaluateFunction(num x, num y) {
  double r = sqrt(x * x + y * y);
  return new Vector2(y / r, -x / r);
}

VertexBuffer generateVectorFieldGeometry(RenderingContext ctx, Viewport view, num vectorScale) {
  // Add enough space for 2 lines, where we will place the axies
  int numPoints = view.subdivisions * view.subdivisions * 2;
  VertexBuffer out = new VertexBuffer(ctx, numPoints + 4, RenderingContext.LINES);
  for (int x = 0; x < view.subdivisions; ++x) {
    for (int y = 0; y < view.subdivisions; ++y) {
      num xr = 2 * (x / view.subdivisions) - 1.0;
      num yr = 2 * (y / view.subdivisions) - 1.0;
      num xx = xr * view.width;
      num yy = yr * view.height;
      Vector2 val = evaluateFunction(xx, yy);
      double mag = val.x * val.x + val.y * val.y;
      val.x /= mag;
      val.y /= mag;
      int base_index = (x + y * view.subdivisions) * 2;
      // center point of vector
      Vertex center = new Vertex(xr, yr, mag, 0.0, 0.0);
      // Offset point
      Vertex offset = new Vertex(xr + vectorScale * val.x, yr + vectorScale * val.y, 1.0, 0.0, 0.0);
      out[base_index + 0] = center;
      out[base_index + 1] = offset;
    }
  }
  out[numPoints + 0] = new Vertex(0.0, view.minY, 0.2, 0.2, 0.2);
  out[numPoints + 1] = new Vertex(0.0, view.maxY, 0.2, 0.2, 0.2);
  out[numPoints + 2] = new Vertex(view.minX, 0.0, 0.2, 0.2, 0.2);
  out[numPoints + 3] = new Vertex(view.maxX, 0.0, 0.2, 0.2, 0.2);
  return out;
}
