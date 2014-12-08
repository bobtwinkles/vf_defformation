// Basic vertex shader

uniform mat4 mvp_matrix;

attribute vec2 position;
attribute vec3 color;

varying vec3 vColor;

void main(void) {
  gl_Position = mvp_matrix * vec4(position, 0, 1);
  gl_PointSize = 2.0;
  vColor = color;
}
