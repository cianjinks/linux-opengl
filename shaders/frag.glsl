#version 430 core

out vec4 FragColor;
in vec3 v_Pos;

struct Ray
{
    vec3 origin;
    vec3 direction;
};

// http://jcgt.org/published/0007/03/04/
bool slabs(vec3 position, float scale, vec3 rayOrigin, vec3 invRaydir) 
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

bool hit_sphere(vec3 center, float radius, Ray ray) {
    vec3 oc = ray.origin - center;
    float a = dot(ray.direction, ray.direction);
    float b = 2.0 * dot(oc, ray.direction);
    float c = dot(oc, oc) - radius*radius;
    float discriminant = b*b - 4*a*c;
    return (discriminant > 0);
}

vec4 calculateColor(Ray ray)
{
    vec3 position = vec3(0.0f);
    float scale = 0.1f;
    // if(slabs(position, scale, ray.origin, 1.0f/ray.direction))
    // {
    //     return vec4(0.0f, 1.0f, 0.0f, 1.0f);
    // }
    if (hit_sphere(vec3(0.0f, 0.0f, -1.0f), 0.5f, ray))
    {
        return vec4(0.0f, 1.0f, 0.0f, 1.0f);
    }
    vec3 unit = normalize(ray.direction);
    float t = 0.5*(unit.y + 1.0);
    vec3 color = mix(vec3(1.0, 1.0, 1.0), vec3(0.1, 0.2, 1.0), t);
    return vec4(color, 1.0f);
}

void main()
{
    Ray ray;
    ray.origin = vec3(0.0f);
    ray.direction = v_Pos - vec3(0.0f, 0.0f, 1.0f);
    FragColor = calculateColor(ray);
    //FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
}