#version 300 es

precision highp float;

uniform mat4 u_View;
uniform mat4 u_Proj;
uniform mat4 u_ViewProj;
uniform mat4 u_ViewProjInv;

in vec4 vs_Pos;

void main() {
	// TODO: Pass relevant info to fragment
	gl_Position = vs_Pos;
}
