library(shiny)

sigmoide <- function(z) 1 / (1 + exp(-z))
relu <- function(z) pmax(0, z)

ui <- fluidPage(
  titlePanel("Laboratorio interactivo: neurona artificial"),
  sidebarLayout(
    sidebarPanel(
      sliderInput("x1", "Entrada x1", -5, 5, 0.8, 0.1),
      sliderInput("x2", "Entrada x2", -5, 5, 0.4, 0.1),
      sliderInput("w1", "Peso w1", -5, 5, 1.2, 0.1),
      sliderInput("w2", "Peso w2", -5, 5, -0.7, 0.1),
      sliderInput("b", "Sesgo b", -5, 5, 0.1, 0.1),
      selectInput("activacion", "Funcion de activacion",
                  c("Sigmoide"="sigmoide", "Tangente hiperbolica"="tanh",
                    "ReLU"="relu", "Escalon"="escalon", "Lineal"="lineal")),
      sliderInput("umbral", "Umbral", 0, 1, 0.5, 0.05)
    ),
    mainPanel(
      textOutput("formula"),
      verbatimTextOutput("resultado"),
      plotOutput("grafica")
    )
  )
)

server <- function(input, output, session) {
  z <- reactive(input$w1*input$x1 + input$w2*input$x2 + input$b)
  salida <- reactive(switch(input$activacion,
                            sigmoide=sigmoide(z()), tanh=tanh(z()),
                            relu=relu(z()), escalon=ifelse(z()>=0,1,0),
                            lineal=z()))
  output$formula <- renderText(paste("z =", round(z(), 4)))
  output$resultado <- renderText(paste("Salida =", round(salida(), 4)))
  output$grafica <- renderPlot({
    zz <- seq(-6,6,length.out=400)
    yy <- switch(input$activacion,
                 sigmoide=sigmoide(zz), tanh=tanh(zz), relu=relu(zz),
                 escalon=ifelse(zz>=0,1,0), lineal=zz)
    plot(zz, yy, type="l", lwd=3, xlab="z", ylab="Salida")
    grid(); points(z(), salida(), pch=19, cex=1.8)
  })
}

shinyApp(ui, server)
