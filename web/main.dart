library vf_deformation;

import 'dart:async';
import 'dart:html';
import 'dart:math';
//import 'dart:mirrors';
import 'dart:typed_data';
import 'dart:web_gl';
import 'package:vector_math/vector_math.dart';

part 'util/debug.dart';
part 'util/geometry.dart';
part 'util/resources.dart';
part 'approximation/function.dart';

CanvasElement canvas = query('#render_target');
RenderingContext gl;
Viewport view;
num last = 0;

UniformLocation position_view_matrix;
Program basic;
VertexBuffer vectors;
VertexBuffer simulationPoints;
VertexBuffer path;

Matrix4 mvMatrix;

var resources = ["shaders/base.vert", "shaders/base.frag"];

void render(num ts) {
  num delta = ts - last;
  last = ts;
  gl.clear(RenderingContext.COLOR_BUFFER_BIT);

  gl.useProgram(basic);
  gl.uniformMatrix4fv(position_view_matrix, false, mvMatrix.storage);

  gl.enableVertexAttribArray(POSITION_POSITION);
  gl.enableVertexAttribArray(POSITION_COLOR);

  vectors.render();
  simulationPoints.render();
  path.render();

  gl.disableVertexAttribArray(POSITION_POSITION);
  gl.disableVertexAttribArray(POSITION_COLOR);
}

void mainLoop(num ts) {
  render(ts);
  for (int i = 0; i < 5; ++i) {
    advanceBuffer(simulationPoints, 0.001);
  }
  window.animationFrame.then(mainLoop);
}

void main() {
  print("science");
  gl = canvas.getContext3d();

  if (gl == null) {
    print ("couldn't initialize gl!");
    return;
  }

  print("starting loop!");

  last = 0;

  fetchResources(resources)
    .then(init_gl)
    .then((_) => window.animationFrame.then(mainLoop));
}

VertexBuffer createGrid(npoints) {
  int numPoints = npoints * npoints;
  VertexBuffer out = new VertexBuffer(gl, numPoints, RenderingContext.LINES);
  for (int x = 0; x < npoints; ++x) {
    for (int y = 0; y < npoints; ++y) {
      num xr = 2 * (x / npoints) - 1.0;
      num yr = 2 * (y / npoints) - 1.0;
      num xx = xr * view.width;
      num yy = yr * view.height;
      out[x + y * npoints] = new Vertex(xx, yy, 0.0, 0.0, 0.0);
    }
  }
  return out;
}

VertexBuffer createRect(int npoints, Vector2 min, Vector2 max) {
  // 6 * npoints verts per row for the quads
  // npoints - 1 rows
  int numindicies = 6 * npoints * (npoints - 1) - 6; // I'm not 100% sure why we need to subtrack 6 here...
  int numpoints = npoints * npoints;
  double xdiff = max.x - min.x;
  double ydiff = max.y - min.y;
  IndexedVertexBuffer out = new IndexedVertexBuffer(gl, numpoints, numindicies, TRIANGLES);
  int index_index = 0;
  for (int y = 0; y < npoints; ++y) {
    for (int x = 0; x < npoints; ++x) {
      double xx = xdiff * (x / npoints) + min.x;
      double yy = ydiff * (y / npoints) + min.y;
      int idx = x + y * npoints;

      out[idx] = new Vertex(xx, yy, 0.0, 1.0, 0.0);

      if (index_index < numindicies) {
        out.setIndex(index_index + 0, idx);
        out.setIndex(index_index + 1, idx + 1);
        out.setIndex(index_index + 2, idx + npoints);
        out.setIndex(index_index + 3, idx + 1);
        out.setIndex(index_index + 4, idx + npoints);
        out.setIndex(index_index + 5, idx + 1 + npoints);
        index_index += 6;
      }
    }
  }
  print(out._indicies);
  out.printData();
  return out;
}

VertexBuffer renderPath(Vector2 initial, int numPoints) {
  VertexBuffer out = new VertexBuffer(gl, numPoints, RenderingContext.LINE_STRIP);
  for (int i = 0; i < numPoints; ++i) {
    double f = i / numPoints;
    out[i] = new Vertex(initial.x, initial.y, 0.0, f, 1 - f);
    initial = advancePoint(initial, 0.01);
  }
  return out;
}

void init_gl(Map<String, HttpRequest> loaded) {
  num aspect_ratio = gl.drawingBufferHeight / gl.drawingBufferWidth;
  view = new Viewport(-1.0, -aspect_ratio, 2.0, 2 * aspect_ratio, 21);
  mvMatrix = view.createProjection();
  print(view);

  gl.clearColor(1.0, 1.0, 1.0, 1.0);

  Shader vert = gl.createShader(RenderingContext.VERTEX_SHADER);
  Shader frag = gl.createShader(RenderingContext.FRAGMENT_SHADER);

  gl.shaderSource(vert, loaded["shaders/base.vert"].responseText);
  gl.shaderSource(frag, loaded["shaders/base.frag"].responseText);

  gl.compileShader(vert);
  if (!gl.getShaderParameter(vert, RenderingContext.COMPILE_STATUS)) {
    print("vert failed to compile: ");
    print(gl.getShaderInfoLog(vert));
  }

  gl.compileShader(frag);
  if (!gl.getShaderParameter(frag, RenderingContext.COMPILE_STATUS)) {
    print("frag failed to compile: ");
    print(gl.getShaderInfoLog(frag));
  }

  basic = gl.createProgram();

  gl.attachShader(basic, vert);
  gl.attachShader(basic, frag);

  gl.bindAttribLocation(basic, POSITION_POSITION, "position");
  gl.bindAttribLocation(basic, POSITION_COLOR   , "color");

  gl.linkProgram(basic);
  if (!gl.getProgramParameter(basic, RenderingContext.LINK_STATUS)) {
    print("Failed to link program");
    print(gl.getProgramInfoLog(basic));
  }
  gl.useProgram(basic);
  position_view_matrix = gl.getUniformLocation(basic, "mvp_matrix");

  vectors = generateVectorFieldGeometry(gl, view, 0.03);
  //simulationPoints = createGrid(32);
  simulationPoints = createRect(64, new Vector2(0.3, 0.3), new Vector2(0.4, 0.4));
  path = renderPath(new Vector2(0.0, 0.2), 128);
}
