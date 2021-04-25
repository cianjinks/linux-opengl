#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>

#define IMGUI_IMPL_OPENGL_LOADER_GLAD
#include "backends/imgui_impl_opengl3.cpp"
#include "backends/imgui_impl_glfw.cpp"

#include <string>
#include <fstream>
#include <iostream>
#include <vector>
#include <time.h>

#define WINDOW_WIDTH 1280
#define WINDOW_HEIGHT 720
#define ASPECT_RATIO (16.0f/9.0f)
#define MAX_DEPTH 2

void GLAPIENTRY ErrorHandleOpenGLCallback( GLenum source,
                 GLenum type,
                 GLuint id,
                 GLenum severity,
                 GLsizei length,
                 const GLchar* message,
                 const void* userParam )
{
  fprintf( stderr, "GL CALLBACK: %s type = 0x%x, severity = 0x%x, message = %s\n",
           ( type == GL_DEBUG_TYPE_ERROR ? "** GL ERROR **" : "" ),
            type, severity, message );
}

void ErrorHandleShader(GLuint& shader, GLuint& program)
{
    GLint result;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &result);
    if (result == GL_FALSE)
    {
        GLint length;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &length);
        GLchar* log = (GLchar*)malloc(length);
        glGetShaderInfoLog(shader, length, &length, log);
        std::cout << "[ERROR] Failed to compile shader" << std::endl;
        std::cout << log << std::endl;
        free(log);
        glDeleteShader(shader);
        glDeleteProgram(program);
    }
}

int ErrorHandleShaderLink(GLuint& program)
{
    GLint isLinked = 0;
    glGetProgramiv(program, GL_LINK_STATUS, &isLinked);
    if (isLinked == GL_FALSE)
    {
        GLint maxLength = 0;
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, &maxLength);

        // The maxLength includes the NULL character
        std::string infoLog;
        infoLog.resize(maxLength);
        glGetProgramInfoLog(program, maxLength, &maxLength, &infoLog[0]);

        // The program is useless now. So delete it.
        glDeleteProgram(program);

        std::cout << infoLog << std::endl;

        // Exit with failure.
        return 0;
    }
    return 1;
}

int main()
{
    /* Initialize the library */
    if (!glfwInit())
    {
        return -1;
    }

    /* Create a windowed mode window and its OpenGL context */
    GLFWwindow *window = glfwCreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Test Window", NULL, NULL);
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

    glfwSetFramebufferSizeCallback(window, [](GLFWwindow* window, int width, int height)
    {
        glViewport(0, 0, width, height);
    });

    glEnable              ( GL_DEBUG_OUTPUT );
    glDebugMessageCallback( ErrorHandleOpenGLCallback, 0 );

    const int NUM_VERTICES = 8;
    float vertices[NUM_VERTICES] = {
         -2.0f,  2.0f, // Top Left
         -2.0f, -2.0f,  // Bottom Left
          2.0f, -2.0f,  // Bottom Right
          2.0f,  2.0f   // Top Right
    };

    const int NUM_INDICES = 6;
    unsigned int indices[NUM_INDICES] = {
		0, 1, 2,
		2, 3, 0
	};

    GLuint vaoID;
    glGenVertexArrays(1, &vaoID);
    glBindVertexArray(vaoID);

    GLuint vboID;
    glGenBuffers(1, &vboID);
    glBindBuffer(GL_ARRAY_BUFFER, vboID);
    glBufferData(GL_ARRAY_BUFFER, NUM_VERTICES * sizeof(float), vertices, GL_STATIC_DRAW);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(float), 0);
    glEnableVertexAttribArray(0);

    GLuint iboID;
    glGenBuffers(1, &iboID);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, iboID);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, NUM_INDICES * sizeof(unsigned int), indices, GL_STATIC_DRAW);

    GLuint programID;
    programID = glCreateProgram();

    std::string vertexShader, line;
    std::ifstream invert("../shaders/vert.glsl");
    while(std::getline(invert, line))
    {
        vertexShader += line + '\n';
    }
    const char *vertexShaderSource = vertexShader.c_str();

    GLuint vertexShaderObj;
    vertexShaderObj = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShaderObj, 1, &vertexShaderSource, nullptr);
    glCompileShader(vertexShaderObj);
    ErrorHandleShader(vertexShaderObj, programID);
    glAttachShader(programID, vertexShaderObj);
    glDeleteShader(vertexShaderObj);


    std::string fragmentShader;
    std::ifstream infrag("../shaders/frag.glsl");
    while(std::getline(infrag, line))
    {
        fragmentShader += line + '\n';
    }
    const char *fragmentShaderSource = fragmentShader.c_str();

    GLuint fragmentShaderObj;
    fragmentShaderObj = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShaderObj, 1, &fragmentShaderSource, nullptr);
    glCompileShader(fragmentShaderObj);
    ErrorHandleShader(fragmentShaderObj, programID);
    glAttachShader(programID, fragmentShaderObj);
    glDeleteShader(fragmentShaderObj);

    glLinkProgram(programID);
    if(!ErrorHandleShaderLink(programID)) { return -1; }
    glValidateProgram(programID);
    glUseProgram(programID);

    glm::mat4 ortho = glm::ortho(-2.0f, 2.0f, -2.0f, 2.0f, -1.0f, 1.0f);
    //glm::mat4 persp = glm::perspective(45.0f, ASPECT_RATIO, -1.0f, 1.0f);

    GLuint loc = glGetUniformLocation(programID, "u_ProjectionMatrix");
    glUniformMatrix4fv(loc, 1, GL_FALSE, glm::value_ptr(ortho));
    loc = glGetUniformLocation(programID, "u_AspectRatio");
    glUniform1f(loc, ASPECT_RATIO);
    loc = glGetUniformLocation(programID, "u_MaxDepth");
    glUniform1i(loc, MAX_DEPTH);
    loc = glGetUniformLocation(programID, "u_Random");
    GLuint glfwTime = glGetUniformLocation(programID, "u_Time");

    srand(time(0));
    float r1 = static_cast <float> (rand()) / static_cast <float> (RAND_MAX);
    float r2 = static_cast <float> (rand()) / static_cast <float> (RAND_MAX);
    float r3 = static_cast <float> (rand()) / static_cast <float> (RAND_MAX);
    glUniform3f(loc, r1, r2, r3);

    ImGui::CreateContext();
    ImGui::StyleColorsDark();
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init("#version 410");

    /* Loop until the user closes the window */
    while (!glfwWindowShouldClose(window))
    {
        /* Render here */
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glClearColor(0.0f, 0.0f, 0.0f, 0.0f);

        glUniform1f(glfwTime, (float)glfwGetTime());

        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();

        //ImGui::ShowDemoWindow();

        ImGui::Render();
        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());

        /* Swap front and back buffers */
        glfwSwapBuffers(window);

        /* Poll for and process events */
        glfwPollEvents();
    }

    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();

    glfwTerminate();
    return 0;
}