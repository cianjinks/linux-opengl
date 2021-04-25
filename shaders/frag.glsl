#version 430 core

out vec4 FragColor;
in vec3 v_Pos;
uniform float u_AspectRatio;
uniform float u_Time;
uniform int u_MaxDepth;

// Random Numbers
uint hash( uint x ) {
    x += ( x << 10u );
    x ^= ( x >>  6u );
    x += ( x <<  3u );
    x ^= ( x >> 11u );
    x += ( x << 15u );
    return x;
}

float randomfloat(float f) {
    const uint mantissaMask = 0x007FFFFFu;
    const uint one          = 0x3F800000u;
   
    uint h = hash(floatBitsToUint(f));
    h &= mantissaMask;
    h |= one;
    
    float  r2 = uintBitsToFloat(h);
    return r2 - 1.0;
}

vec3 random()
{
    return (2*vec3(randomfloat(u_Time), randomfloat(u_Time+1), randomfloat(u_Time+2)))-1;
}

vec3 randomInUnitSphere()
{
    while(true)
    {
        vec3 p = random();
        float plength = length(p);
        if (plength*plength >= 1) { continue; }
        return p;
    }
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

bool hit_sphere(vec3 center, float radius, Ray ray, inout HitRecord rec) {
    vec3 oc = ray.origin - center;
    float dirlength = length(ray.direction);
    float a = dirlength * dirlength;
    float b = dot(oc, ray.direction);
    float oclength = length(oc);
    float c = (oclength*oclength) - (radius*radius);
    float discriminant = b*b - a*c;

    if(discriminant < 0) { return false; }
    
    float sqrtd = sqrt(discriminant);
    rec.t = (-b - sqrtd) / a;
    rec.p = ray.origin + rec.t*ray.direction;
    vec3 outward_normal = (rec.p - center) / radius;
    rec.set_face_normal(ray, outward_normal);

    return true;
}

vec3 calculateColor(Ray ray, int depth)
{
    // vec3 position = vec3(0.0f, 0.0f, -1.0f);
    // float scale = 0.5f;
    // if(hitAABB(position, scale, ray.origin, 1.0f/ray.direction))
    // {
    //     return vec3(0.0f, 1.0f, 0.0f);
    // }
    if(depth <= 0)
    {
        return vec3(0.0f);
    }

    // Small sphere
    vec3 center = vec3(0.0f, 0.0f, -1.0f);
    float radius = 0.5f;
    HitRecord rec;
    if(hit_sphere(center, radius, ray, rec))    
    {
        //vec3 pos = ray.origin + t*ray.direction; // Ray's hitpoint on edge of sphere
        //vec3 n = normalize(pos - center); // Invert the direction and normalize (this is the normal itself)
        //return 0.5*(n+1); // Move between 0.0f and 1.0f for colors
        vec3 target = rec.p + rec.normal + randomInUnitSphere();
        //return 0.5 * calculateColor(Ray(rec.p, target - rec.p), depth-1);
        return 0.5 * (rec.normal + vec3(1.0f));
    }

    // Large floor sphere
    // center = vec3(0.0f, -100.5f, -1.0f);
    // t = hit_sphere(center, 100.0f, ray);
    // if(t > 0.0f)    
    // {
    //     vec3 pos = ray.origin + t*ray.direction;
    //     vec3 n = normalize(pos - center); 
    //     return 0.5*(n+1);
    // }

    vec3 unit = normalize(ray.direction);
    float t = 0.5*(unit.y + 1.0);
    vec3 color = mix(vec3(1.0, 1.0, 1.0), vec3(0.1, 0.2, 1.0), t);
    return color;
}

void main()
{
    Ray ray;
    ray.origin = vec3(0.0f);
    ray.direction = vec3(v_Pos.x*u_AspectRatio, v_Pos.y, v_Pos.z) - vec3(0.0f, 0.0f, 1.0f);
    FragColor = vec4(calculateColor(ray, u_MaxDepth), 1.0f);
    //FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
}