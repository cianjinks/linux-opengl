#version 430 core
#define PI 3.14159265359

out vec4 FragColor;
in vec3 v_Pos;

uniform float u_AspectRatio;
uniform float u_Time;
uniform int u_MaxDepth;
uniform vec3 u_Random;

const float infinity = 1.0f / 0.0f;

// Random Numbers
/**
 * http://www.jcgt.org/published/0009/03/02/
 */
uvec3 pcg3d(uvec3 v) {
  v = v * 1664525u + 1013904223u;
  v.x += v.y * v.z;
  v.y += v.z * v.x;
  v.z += v.x * v.y;
  v ^= v >> 16u;
  v.x += v.y * v.z;
  v.y += v.z * v.x;
  v.z += v.x * v.y;
  return v;
}

vec3 random3(vec3 f) {
  return uintBitsToFloat((pcg3d(floatBitsToUint(f)) & 0x007FFFFFu) | 0x3F800000u) - 1.0;
}

vec3 randomSpherePoint(vec3 rand) {
  float ang1 = (rand.x + 1.0) * PI; // [-1..1) -> [0..2*PI)
  float u = rand.y; // [-1..1), cos and acos(2v-1) cancel each other out, so we arrive at [-1..1)
  float u2 = u * u;
  float sqrt1MinusU2 = sqrt(1.0 - u2);
  float x = sqrt1MinusU2 * cos(ang1);
  float y = sqrt1MinusU2 * sin(ang1);
  float z = u;
  return vec3(x, y, z);
}
///////////////////////

struct Ray
{
    vec3 origin;
    vec3 direction;
};

struct HitRecord
{
    vec3 p;
    vec3 normal;
    float t;
    bool frontface;

    void set_face_normal(Ray r, vec3 outward_normal) {
        frontface = dot(r.direction, outward_normal) < 0;
        normal = frontface ? outward_normal : -outward_normal;
    }
};

// http://jcgt.org/published/0007/03/04/
bool hitAABB(vec3 position, float scale, vec3 rayOrigin, vec3 invRaydir) 
{
    vec3 bmin = position - scale;
	vec3 bmax = position + scale;

    vec3 t0 = (bmin - rayOrigin) * invRaydir;
    vec3 t1 = (bmax - rayOrigin) * invRaydir;
    vec3 tmin = min(t0,t1), tmax = max(t0,t1);

    float maxComponent = max(max(tmin.x, tmin.y), tmin.z);
	float minComponent = min(min(tmax.x, tmax.y), tmax.z);

    return maxComponent <= minComponent;
}

bool hit_sphere(vec3 center, float radius, float tmin, float tmax, Ray ray, inout HitRecord rec) {
    vec3 oc = ray.origin - center;
    float dirlength = length(ray.direction);
    float a = dirlength * dirlength;
    float b = dot(oc, ray.direction);
    float oclength = length(oc);
    float c = (oclength*oclength) - (radius*radius);
    float discriminant = b*b - a*c;

    if(discriminant < 0) { return false; }
    
    float sqrtd = sqrt(discriminant);

    float root = (-b - sqrtd) / a;
    if (root < tmin || tmax < root) {
        root = (-b + sqrtd) / a;
        if (root < tmin || tmax < root)
        {
            return false;
        }
    }

    rec.t = root;
    rec.p = ray.origin + rec.t*ray.direction;
    vec3 outward_normal = (rec.p - center) / radius;
    rec.set_face_normal(ray, outward_normal);

    return true;
}

vec3 calculateTraceColor(Ray ray)
{
    const int numSpheres = 2;
    vec3 centers[numSpheres] = {vec3(0.0f, 0.0f, -1.0f), vec3(0.0f, -100.5f, -1.0f)};
    float radaii[numSpheres] = {0.5f, 100.0f};

    // Ray trace
    Ray newray = ray;
    float frac = 1.0f;
    int bounce;
    for(bounce = u_MaxDepth; bounce > 0; bounce--)
    {
        HitRecord rec;
        HitRecord temprec;
        bool hitAnything = false;
        float closest = infinity;
        for(int i = 0; i < numSpheres; i++)
        {
            if(hit_sphere(centers[i], radaii[i], 0, closest, newray, temprec))    
            {
                hitAnything = true;
                closest = temprec.t;
                rec = temprec;
            }
        }

        if(hitAnything)
        {
            newray.origin = rec.p;
            newray.direction = rec.normal + randomSpherePoint(u_Random);
            frac = 0.5f * frac;
        }
        else
        {
            break;
        }
    }
    //return 0.5*vec3(bounce+1);
    //if(bounce == 0) { return vec3(0.0f, 1.0f, 0.0f); }

    vec3 unit = normalize(newray.direction);
    float t = 0.5*(unit.y + 1.0);
    vec3 color = mix(vec3(1.0, 1.0, 1.0), vec3(0.5, 0.7, 1.0), t);
    return sqrt(frac*color);
}

void main()
{
    Ray ray;
    ray.origin = vec3(0.0f);
    ray.direction = vec3(v_Pos.x*u_AspectRatio, v_Pos.y, v_Pos.z) - vec3(0.0f, 0.0f, 1.0f);
    FragColor = vec4(calculateTraceColor(ray), 1.0f);
    //FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
}

// vec3 calculateColor(Ray ray)
// {
//     // vec3 position = vec3(0.0f, 0.0f, -1.0f);
//     // float scale = 0.5f;
//     // if(hitAABB(position, scale, ray.origin, 1.0f/ray.direction))
//     // {
//     //     return vec3(0.0f, 1.0f, 0.0f);
//     // }
//     HitRecord rec;

//     // Small sphere
//     vec3 center = vec3(0.0f, 0.0f, -1.0f);
//     float radius = 0.5f;
//     if(hit_sphere(center, radius, 0, infinity, ray, rec))    
//     {
//         //vec3 pos = ray.origin + t*ray.direction; // Ray's hitpoint on edge of sphere
//         //vec3 n = normalize(pos - center); // Invert the direction and normalize (this is the normal itself)
//         //return 0.5*(n+1); // Move between 0.0f and 1.0f for colors
//         return 0.5 * (rec.normal + vec3(1.0f));
//     }

//     // Large floor sphere
//     // center = vec3(0.0f, -100.5f, -1.0f);
//     // t = hit_sphere(center, 100.0f, ray);
//     // if(t > 0.0f)    
//     // {
//     //     vec3 pos = ray.origin + t*ray.direction;
//     //     vec3 n = normalize(pos - center); 
//     //     return 0.5*(n+1);
//     // }

//     vec3 unit = normalize(ray.direction);
//     float t = 0.5*(unit.y + 1.0);
//     vec3 color = mix(vec3(1.0, 1.0, 1.0), vec3(0.1, 0.2, 1.0), t);
//     return color;
// }