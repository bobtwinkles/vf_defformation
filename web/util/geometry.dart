part of vf_deformation;

const int POSITION_POSITION = 0;
const int POSITION_COLOR    = 1;

const int NUM_VERTEX_COMPONENTS = 5;

class Vertex {
  double x, y, r, g, b;

  Vertex(this.x, this.y, this.r, this.g, this.b);
}

class VertexBuffer {
  Float32List _data;
  Buffer _buffer;
  int _length;
  int _mode;
  bool _upToDate;

  VertexBuffer(RenderingContext ctx, int numVerts, int mode) {
    _data = new Float32List(numVerts * NUM_VERTEX_COMPONENTS);
    _buffer = ctx.createBuffer();
    _length = numVerts;
    _mode = mode;
    _upToDate = false;
  }

  void sync() {
    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, _buffer);
    gl.bufferData(RenderingContext.ARRAY_BUFFER, _data, STATIC_DRAW);
    _upToDate = true;
  }

  void render() {
    if (!_upToDate) {
      sync();
    }
    gl.bindBuffer(ARRAY_BUFFER, _buffer);

    gl.vertexAttribPointer(POSITION_POSITION, 2, RenderingContext.FLOAT, false, 20, 0);
    gl.vertexAttribPointer(POSITION_COLOR, 3, RenderingContext.FLOAT, false, 20, 8);

    gl.drawArrays(_mode, 0, _length);
  }

  void printData() {
    for (int i = 0; i < _length; ++i) {
      int idx = i * NUM_VERTEX_COMPONENTS;
      double x = _data[idx + 0];
      double y = _data[idx + 1];
      double r = _data[idx + 2];
      double g = _data[idx + 3];
      double b = _data[idx + 4];
      print("$x $y $r $g $b");
    }
  }

  Vertex operator [] (int index) {
    int idx = index * NUM_VERTEX_COMPONENTS;
    return new Vertex(
          _data[idx + 0],
          _data[idx + 1],
          _data[idx + 2],
          _data[idx + 3],
          _data[idx + 4]
        );
  }

  void operator []=(int index, Vertex vert) {
    int idx = index * NUM_VERTEX_COMPONENTS;
    _data[idx + 0] = vert.x;
    _data[idx + 1] = vert.y;
    _data[idx + 2] = vert.r;
    _data[idx + 3] = vert.g;
    _data[idx + 4] = vert.b;
    _upToDate = false;
  }
}

class IndexedVertexBuffer extends VertexBuffer {
  Uint16List _indicies;
  Buffer _index_buffer;
  int _num_indicies;

  IndexedVertexBuffer(RenderingContext ctx, int numVerts, int numIndicies, int mode) : super (ctx, numVerts, mode) {
    _num_indicies = numIndicies;
    _indicies = new Uint16List(numIndicies);
    _index_buffer = gl.createBuffer();
  }

  void sync() {
    gl.bindBuffer(RenderingContext.ELEMENT_ARRAY_BUFFER, _index_buffer);
    gl.bufferData(RenderingContext.ELEMENT_ARRAY_BUFFER, _indicies, STATIC_DRAW);
    super.sync();
  }

  void setIndex(int idx, int val) {
    _indicies[idx] = val;
  }

  void render() {
    if (!_upToDate) {
      sync();
    }
    gl.bindBuffer(ARRAY_BUFFER, _buffer);
    gl.bindBuffer(ELEMENT_ARRAY_BUFFER, _index_buffer);

    gl.vertexAttribPointer(POSITION_POSITION, 2, RenderingContext.FLOAT, false, 20, 0);
    gl.vertexAttribPointer(POSITION_COLOR, 3, RenderingContext.FLOAT, false, 20, 8);

    gl.drawElements(_mode, _num_indicies, UNSIGNED_SHORT, 0);
  }
}

// this function breaks all kinds of encapsulation, but I wanna get this working
void advanceBuffer(VertexBuffer buff, double step) {
  int idx;
  for (int i = 0; i < buff._length; ++i) {
    idx = NUM_VERTEX_COMPONENTS * i;
    Vector2 n = advancePoint(new Vector2(buff._data[idx + 0], buff._data[idx + 1]), step);
    buff._data[idx + 0] = n.x;
    buff._data[idx + 1] = n.y;
  }
  buff._upToDate = false;
}

class Viewport {
  double minX;
  double minY;
  double width;
  double height;

  int subdivisions;

  num get maxX => minX + width;
  num get maxY => minY + height;

  Viewport(this.minX, this.minY, this.width, this.height, this.subdivisions);

  Matrix4 createProjection() {
    return makeOrthographicMatrix(minX, maxX, minY, maxY, -1, 1);
  }

  String toString() {
    return "[Viewport: ($minX, $minY) -> ($maxX, $maxY) [$width $height]]";
  }
}

