#version 300 es

precision highp float;

// Union, subtraction, intersection, repetition, blend, sphere, box, plane functions
// from http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm  

uniform float u_Time;
uniform vec4 u_Eye;
uniform mat4 u_View;
uniform mat4 u_Proj;
uniform mat4 u_ViewProj;
uniform mat4 u_ViewProjInv;
uniform float u_Fov;
uniform vec2 u_Dimension;
uniform float u_Far;

out vec4 out_Col;

const float end = 1000.0;
const int depth = 30; 
const float epsilon = 0.01;

const vec3 lightSource = vec3(5, 5, 5);   // light position in world coordinate

// union of two objects
float unionSDF(float f1, float f2) {
	return min(f1, f2);
}

// subtraction of two objects, f1 - f2
float subtractionSDF(float f1, float f2) {
	return max(f1, -f2);
}

// intersection of two objects
float intersectionSDF(float f1, float f2) {
	return max(f1, f2);
}

// smooth function
float smin(float f1, float f2) {
	/*
	float h = clamp(0.5 + 0.5 * (f2 - f1) / 0.1, 0.0, 1.0);
	return mix(f1, f2, h) - 0.1 * h * (1.0 - h);
	*/
	f1 = pow(f1, 8.0);
	f2 = pow(f2, 8.0);
	return pow((f1 * f2) / (f1 + f2), 1.0 / 8.0);
}

// blend two objects
float blendSDF(float f1, float f2) {
	return smin(f1, f2);
}

// sdf of sphere
float sphereSDF(vec3 p, float r, mat4 m) {
	return length(vec3(inverse(m) * vec4(p, 1))) - r;
}

// sdf of box
float boxSDF(vec3 p, vec3 b, mat4 m) {
	p = vec3(inverse(m) * vec4(p, 1.0));
	vec3 d = abs(p) - b;
	return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

// sdf of round box
float roundBoxSDF(vec3 p, vec3 b, float r, mat4 m) {
	p = vec3(inverse(m) * vec4(p, 1.0));
	return length(max(abs(p) - b, 0.0)) - r;
}

// sdf of plane
float planeSDF( vec3 p, vec4 n)
{
  return dot(p,n.xyz) + n.w;
}

// transform functions
mat4 translation(vec3 t) {
	return mat4(
		1.0, 0.0, 0.0, 0.0, // first column
		0.0, 1.0, 0.0, 0.0, // second column
		0.0, 0.0, 1.0, 0.0, // third column
		t.x, t.y, t.z, 1.0 // fourth column
	);
}

mat4 rotateX(float t) {
	float cost = cos(radians(t));
	float sint = sin(radians(t));
	return mat4(
		1.0, 0.0, 0.0, 0.0,   // first column
		0.0, cost, sint, 0.0, // second column
		0.0, -sint, cost, 0.0, // third column
		0.0, 0.0, 0.0, 1.0
	);
}

mat4 rotateY(float t) {
	float cost = cos(radians(t));
	float sint = sin(radians(t));
	return mat4(
		cost, 0.0, -sint, 0.0,   // first column
		0.0, 1.0, 0.0, 0.0, // second column
		sint, 0.0, cost, 0.0, // third column
		0.0, 0.0, 0.0, 1.0
	);
}

mat4 rotateZ(float t) {
	float cost = cos(radians(t));
	float sint = sin(radians(t));
	return mat4(
		cost, sint, 0.0, 0.0,   // first column
		-sint, cost, 0.0, 0.0, // second column
		0.0, 0.0, 1.0, 0.0, // third column
		0.0, 0.0, 0.0, 1.0
	);
}

mat4 scale(vec3 s) {
	return mat4(
		s.x, 0.0, 0.0, 0.0, 
		0.0, s.y, 0.0, 0.0,
		0.0, 0.0, s.z, 0.0,
		0.0, 0.0, 0.0, 1.0
	);
}

// 2d rotate
mat2 rotate2D(float angle) {
	float cost = cos(radians(angle));
	float sint = sin(radians(angle));
	return mat2(
		cost, sint, -sint, cost
	);
}

mat4 getTransform(vec3 t, float x, float y, float z) {
	return translation(t) * rotateX(x) * rotateY(y) * rotateZ(z);
}


// sdf of one part in star
float star1(vec3 p, mat4 m, int num) {

	mat4 m1 = getTransform(vec3(0.0, 0.0, 0.0), -45.0, 45.0, 0.0);
	float cube1 = roundBoxSDF(p, vec3(1.0), 0.1, m * m1);

	mat4 m2 = getTransform(vec3(0.0, 0.0, 0.0), 45.0, 0.0, 0.0) * m1;
	m2 = getTransform(vec3(0.0, 1.15, 0.0), 0.0, 0.0, 0.0);
	float cube2 = 2.0 * boxSDF(p / 2.0, vec3(1.0),  m * m2);

	mat4 m3 = getTransform(vec3(0.0, 0.0, 1.15), 0.0, 0.0, 0.0);
	float cube3 = 2.0 * boxSDF(p / 2.0, vec3(1.0), m * m3);

	mat4 m4 = getTransform(vec3(0.0, 0.0, 0.0), 0.0, 0.0, 90.0 - 180.0 / float(num));
	m4 = m4 * translation(vec3(0.0, 1.1, 0.0));
	float cube4 = 2.0 * boxSDF(p / 2.0, vec3(1.0), m * m4);

	mat4 m5 = getTransform(vec3(0.0, 0.0, 0.0), 0.0, 0.0, -(90.0 - 180.0 / float(num)));
	m5 = m5 * translation(vec3(0.0, 1.1, 0.0));
	float cube5 = 2.0 * boxSDF(p / 2.0, vec3(1.0), m * m5);

	float dist = intersectionSDF(cube1, cube2);
	dist = intersectionSDF(dist, cube3);
	dist = intersectionSDF(dist, cube4);
	dist = intersectionSDF(dist, cube5);

	return dist;
}

// sdf of complete star
float star2(vec3 p, mat4 m, int num, float offset) {
	float s, dist;

	p = vec3(inverse(m) * vec4(p, 1.0));

	for(int i = 0; i < num; ++i) {
		mat4 mt = getTransform(vec3(0.0), 0.0, 0.0, float(i) * (360.0 / float(num)));
		mt *= translation(vec3(0.0, offset, 0.0));
		s = star1(p, mt, num);
		if(i == 0) {
			dist = s;
		} else{
			dist = unionSDF(dist, s);
		}
	}
	return dist;
}

float scene(vec3 p) {
	// used to calculate distance to nearest surface in scene
	// transform all objects to world coordinate
	mat4 m = mat4(1.0);
	mat4 anim = getTransform(vec3(sin(u_Time / 10.0), cos(u_Time / 10.0), sin(u_Time / 50.0)), u_Time, u_Time, u_Time);
	
	p = vec3(inverse(anim) * vec4(p, 1.0));
	
	float s1 = 0.25 * star2(p / 0.25, m, 5, -0.2);
	mat4 m2 = translation(vec3(0.0, 0.4, 0.1));
	float s2 = sphereSDF(p, 0.05, m * m2);

	return blendSDF(s1, s2);
}

// repetition of scene
float repetitionSDF(vec3 p, vec3 c) {
	vec3 q = mod(p, c) - 0.5 * c;
	return scene(q);
}

float rayMarching(vec3 origin, vec3 dir, float start) {
	float t = start;
	for(int i = 0; i < depth; ++i) {
		vec3 curP = origin + dir * t;
		float step = repetitionSDF(curP, vec3(5.0, 5.0, 5.0));
		t += step;
		if(step < epsilon) {
			return t;
		}
		if(t >= end){
			return end;
		}	
	}
	return end;
}

// calcuate ray direction in world space
vec3 rayDirection(vec2 coord, vec2 size, vec4 eye) {
	float sx = (2.0 * coord.x / size.x) - 1.0;
	float sy = (2.0 * coord.y / size.y) - 1.0;
	vec4 worldP = u_ViewProjInv * (vec4(sx, sy, 1.0, 1.0) * u_Far);
	return normalize(worldP.xyz - eye.xyz);
}

// calculate normal using central difference
// reference: https://www.shadertoy.com/view/4tcGDr
vec3 getNormal(vec3 p) {
    return normalize(vec3(
		scene(vec3(p.x + epsilon, p.y, p.z)) - scene(vec3(p.x - epsilon, p.y, p.z)),
		scene(vec3(p.x, p.y + epsilon, p.z)) - scene(vec3(p.x, p.y - epsilon, p.z)),
		scene(vec3(p.x, p.y, p.z + epsilon)) - scene(vec3(p.x, p.y, p.z - epsilon))
	));
}


// calculate ao and thickness, scattered color
// reference: https://www.shadertoy.com/view/Xsd3Rs
float hash( float n ){
	return fract(sin(n)*3538.5453);
}

float getAO(vec3 p, vec3 normal, float maxDist, float falloff) {
	float ao = 0.0;
	int iter = 6;
	for(int i = 0; i < iter; ++i) {
		float l = hash(float(i)) * maxDist;
		vec3 d = normal * l;
		ao += (l - scene(p + d))/ pow(1.0 + l, falloff);
	}
	return clamp(1.0 - ao / float(iter), 0.0, 1.0);
}

float thickness(vec3 p, vec3 normal, float maxDist, float falloff )
{
	float thi = 0.0;
	int iter = 6;
	for(int i = 0; i < iter; ++i)
	{
		float l = hash(float(i)) * maxDist;
		vec3 d = - normal * l;
		thi += (l + scene(p + d))/ pow(1.0 + l, falloff);
	}
	return clamp(1.0 - thi /float(iter), 0.0, 1.0);
}

vec3 getScatteredColor(vec3 p, vec3 n, vec3 direction, vec3 initColor, vec3 stepColor, vec3 lightPos) {

	// calculate ao and thickness
	float ao = getAO(p, n, 10.0, 1.2);
	float thi = thickness(p, n, 6.0, 2.0);

	vec3 pos = lightPos;
	vec3 dir = normalize(pos - p);
	float latt = pow(length(pos - p) * 0.1, 1.5);
	float trans = clamp(dot(- direction, - dir + n), 0.0, 1.0) + 1.0;
	vec3 diff = vec3(0.0, 0.5, 1.0) * max(dot(n, dir), 0.0) / latt;
	vec3 col =  diff;
	col += initColor * (trans / latt) * thi;

	for(int i = 0; i < 2; i++){

		float angle = float(i)/3.0 * 2.0 * 3.14159;
		float radius = 2.0;
		pos = vec3(cos(angle)*radius, 2.0, sin(angle)*radius);
		dir = normalize(pos - p);
		latt = length(pos - p)*(1.3);
		trans =  clamp(dot(-direction, -dir + n), 0.0, 1.0) + 1.0;
		col += stepColor * (trans / latt) * thi;
	}

	col = max(vec3(0.05), col);
	col *= ao * ao;
	return col / 40.0;
}

vec3 repetitionColor(vec3 p, vec3 n, vec3 direction, vec3 initColor, vec3 stepColor, vec3 lightPos, vec3 c) {
	
	vec3 q = mod(p, c) - 0.5 * c;

	mat4 anim = getTransform(vec3(0.8 * sin(u_Time / 10.0), 0.8 * cos(u_Time / 10.0), 0.8 * sin(u_Time / 50.0)), u_Time, u_Time, u_Time);
	
	q = vec3(inverse(anim) * vec4(q, 1.0));
	//lightPos = vec3(translation(vec3(0.0, 0.0, u_Time / 50.0)) * vec4(lightPos, 1.0));
	return getScatteredColor(q, n, direction, initColor, stepColor, lightPos);
}



void main() {

	vec4 eye = u_Eye;

	vec2 coord = gl_FragCoord.xy;
	vec3 dir = rayDirection(coord, u_Dimension, eye);

	float final_t = rayMarching(vec3(eye), dir, 0.1);

	if(final_t >= end) { // hit nothing
		out_Col = vec4(vec3(max((fract(dot(sin(coord), coord)) - 0.99) * 180.0, 0.0)), 1.0);
	} else {
			vec3 hitPoint = vec3(eye) + final_t * dir;
			vec3 normal = getNormal(hitPoint);

			out_Col = vec4(repetitionColor(hitPoint, normal, dir, vec3(0.3, 0.2, 0.05), vec3(0.1, 0.1, 0.2), vec3(0.0, 0.0, 0.1), vec3(5.0, 5.0, 5.0)), 1.0);
			//out_Col = vec4(getScatteredColor(hitPoint, normal, dir, vec3(0.3, 0.2, 0.05), vec3(0.1, 0.1, 0.2), vec3(0.0, 0.0, 0.1)), 1.0);
	
	}
}
