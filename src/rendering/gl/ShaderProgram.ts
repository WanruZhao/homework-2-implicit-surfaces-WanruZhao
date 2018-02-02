import {vec2, vec4, mat4} from 'gl-matrix';
import Drawable from './Drawable';
import {gl} from '../../globals';

var activeProgram: WebGLProgram = null;

export class Shader {
  shader: WebGLShader;

  constructor(type: number, source: string) {
    this.shader = gl.createShader(type);
    gl.shaderSource(this.shader, source);
    gl.compileShader(this.shader);

    if (!gl.getShaderParameter(this.shader, gl.COMPILE_STATUS)) {
      throw gl.getShaderInfoLog(this.shader);
    }
  }
};

class ShaderProgram {
  prog: WebGLProgram;

  attrPos: number;

  unifView: WebGLUniformLocation;
  unifProj: WebGLUniformLocation;
  unifTime: WebGLUniformLocation;
  unifEye: WebGLUniformLocation;
  unifViewProj: WebGLUniformLocation;
  unifViewProjInv: WebGLUniformLocation;
  unifFOV: WebGLUniformLocation;
  unifFar: WebGLUniformLocation;
  unifDimension: WebGLUniformLocation;

  constructor(shaders: Array<Shader>) {
    this.prog = gl.createProgram();

    for (let shader of shaders) {
      gl.attachShader(this.prog, shader.shader);
    }
    gl.linkProgram(this.prog);
    if (!gl.getProgramParameter(this.prog, gl.LINK_STATUS)) {
      throw gl.getProgramInfoLog(this.prog);
    }

    // Raymarcher only draws a quad in screen space! No other attributes
    this.attrPos = gl.getAttribLocation(this.prog, "vs_Pos");

    // TODO: add other attributes here
    this.unifView   = gl.getUniformLocation(this.prog, "u_View");
    this.unifView   = gl.getUniformLocation(this.prog, "u_Proj");
    this.unifViewProj    = gl.getUniformLocation(this.prog, "u_ViewProj"); // view proj matrix for camera
    this.unifTime        = gl.getUniformLocation(this.prog, "u_Time");
    this.unifViewProjInv = gl.getUniformLocation(this.prog, "u_ViewProjInv"); // inverse of view proj matrix for camera
    this.unifEye         = gl.getUniformLocation(this.prog, "u_Eye");
    this.unifFOV         = gl.getUniformLocation(this.prog, "u_Fov");
    this.unifDimension   = gl.getUniformLocation(this.prog, "u_Dimension");
    this.unifFar         = gl.getUniformLocation(this.prog, "u_Far");

  }

  use() {
    if (activeProgram !== this.prog) {
      gl.useProgram(this.prog);
      activeProgram = this.prog;
    }
  }

  // TODO: add functions to modify uniforms
  setView(v: mat4) {
    this.use();
    if(this.unifView != -1) {
      gl.uniformMatrix4fv(this.unifView, false, v);
    }
  }

  setProj(p: mat4) {
    this.use();
    if(this.unifProj != -1) {
      gl.uniformMatrix4fv(this.unifProj, false, p);
    }
  }

  setViewProjMatrix(vp: mat4) {
    this.use();
    if (this.unifViewProj !== -1) {
      gl.uniformMatrix4fv(this.unifViewProj, false, vp);
    }
    if (this.unifViewProjInv != -1) {
      let vpi : mat4 = mat4.create();
      mat4.invert(vpi, vp);
      gl.uniformMatrix4fv(this.unifViewProjInv, false, vpi);
    }
  }

  setTime(t: number) {
    this.use();
    if(this.unifTime != -1) {
      gl.uniform1f(this.unifTime, t);
    }
  }

  setEye(e: vec4) {
    this.use();
    if(this.unifEye != -1) {
      gl.uniform4fv(this.unifEye, e);
    }
  }

  setFov(f: number) {
    this.use();
    if(this.unifFOV != -1) {
      gl.uniform1f(this.unifFOV, f);
    }
  }

  setDimension(d: vec2) {
    this.use();
    if(this.unifDimension != -1) {
      gl.uniform2fv(this.unifDimension, d);
    }
  }

  setFar(f: number) {
    this.use();
    if(this.unifFar != -1) {
      gl.uniform1f(this.unifFar, f);
    }
  }

  draw(d: Drawable) {
    this.use();

    if (this.attrPos != -1 && d.bindPos()) {
      gl.enableVertexAttribArray(this.attrPos);
      gl.vertexAttribPointer(this.attrPos, 4, gl.FLOAT, false, 0, 0);
    }

    d.bindIdx();
    gl.drawElements(d.drawMode(), d.elemCount(), gl.UNSIGNED_INT, 0);

    if (this.attrPos != -1) gl.disableVertexAttribArray(this.attrPos);

  }
};

export default ShaderProgram;
