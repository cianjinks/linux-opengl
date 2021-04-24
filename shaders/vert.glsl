#version 430 core

layout (location = 0) in vec3 aPos;

uniform mat4 u_ProjectionMatrix;

out vec3 v_Pos;

void main()
{
    gl_Position = u_ProjectionMatrix * vec4(aPos, 1.0);
    v_Pos = aPos;
}