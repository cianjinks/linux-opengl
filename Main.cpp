#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <glm/glm.hpp>

int main()
{
    /* Initialize the library */
    if (!glfwInit())
    {
        return -1;
    }

    /* Create a windowed mode window and its OpenGL context */
    GLFWwindow *window = glfwCreateWindow(640, 480, "Test Window", NULL, NULL);
    if (!window)
    {
        glfwTerminate();
        return -1;
    }

    /* Make the window's context current */
    glfwMakeContextCurrent(window);
    int status = gladLoadGLLoader((GLADloadproc)glfwGetProcAddress);
    if (!status)
    {
        return -1;
    }

    glClearColor(1.0f, 0.25f, 0.0f, 0.0f);

    /* Loop until the user closes the window */
    while (!glfwWindowShouldClose(window))
    {
        /* Render here */
        glClear(GL_COLOR_BUFFER_BIT);

        /* Swap front and back buffers */
        glfwSwapBuffers(window);

        /* Poll for and process events */
        glfwPollEvents();
    }

    glfwTerminate();
    return 0;
}