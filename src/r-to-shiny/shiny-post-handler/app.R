# This app lets you POST numbers to the Shiny server and shows the list
# of numbers recieved. It works by adding a HTTP handler to Shiny that
# catches the request before it gets to the main HTML rendering part.

# This this solution was first proposed by Garrick Aden-Buie:
# https://gist.github.com/gadenbuie/c19cf997467930729ec9acaf98a150fb

# You can run the app with
# shiny::runApp('src/r-to-shiny/shiny-post-handler', host = '0.0.0.0', port = 80L)
# and test the app with httr::POST('http://127.0.0.1', body = '{"number": 3}', encode = 'json')

library(shiny)
library(jsonlite)

number_vector <- numeric(0)

post_handler <- function(req, response) {
  # warning, this may conflict with build in Shiny request handling. Use caution
  if (identical(req$REQUEST_METHOD, "POST")) {
    data <- req$rook.input$read(-1)
    data <- jsonlite::fromJSON(rawToChar(data))

    message(paste0("Received post request with number: ", data$number))
    number_vector <<- c(number_vector, data$number)
    return(httpResponse(200, "text/plain", "OK\n"))
  }
  # return regular shiny response
  response
}

options(shiny.http.response.filter = post_handler)

ui <- fluidPage(
  h2("Numbers received:", textOutput("number_vector", inline = TRUE, container = span))
)

server <- function(input, output, session) {
  recheck <- reactiveTimer(500)

  output$number_vector <- renderText({
    recheck() #this causes the number_total to get polled again
    paste0(number_vector, collapse = ", ")
  })
}

shinyApp(ui, server)
