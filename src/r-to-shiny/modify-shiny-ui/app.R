# This app lets you POST numbers to the Shiny server and shows the list
# of numbers recieved. It works by adding special code to the UI part of the
# shiny app.

# This solution was first proposed by Joe Cheng:
# https://gist.github.com/jcheng5/2aaff19e67079840350d08361fe7fb20

# You can run the app with
# shiny::runApp('src/r-to-shiny/shiny-post-handler', host = '0.0.0.0', port = 80L)
# and test the app with httr::POST('http://127.0.0.1', body = '{"number": 3}', encode = 'json')

library(shiny)
library(jsonlite)

number_vector <- numeric(0)

ui <- function(req) {
  if (identical(req$REQUEST_METHOD, "GET")) {
    fluidPage(
      h2("Numbers received:", textOutput("number_vector", inline = TRUE, container = span))
    )
  } else if (identical(req$REQUEST_METHOD, "POST")) {
    data <- req$rook.input$read(-1)
    data <- jsonlite::fromJSON(rawToChar(data))

    message(paste0("Received post request with number: ", data$number))
    number_vector <<- c(number_vector, data$number)
    return(httpResponse(200, "text/plain", "OK\n"))
  }
}
attr(ui, "http_methods_supported") <- c("GET", "POST")

server <- function(input, output, session) {
  recheck <- reactiveTimer(500)

  output$number_vector <- renderText({
    recheck() #this causes the number_total to get polled again
    paste0(number_vector, collapse = ", ")
  })
}

shinyApp(ui, server)
