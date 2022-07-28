# This app lets you POST numbers to the Shiny server and shows the list
# of numbers recieved. It works by using the brochure package. You can install
# it via remotes::install_github("ColinFay/brochure")

# Learn more about brochure on the github page: https://github.com/ColinFay/brochure

# You can run the app with
# shiny::runApp('src/r-to-shiny/brochure', host = '0.0.0.0', port = 80L)
# and test the app with httr::POST('http://127.0.0.1', body = '{"number": 3}', encode = 'json')

library(shiny)
library(jsonlite)
library(brochure)

number_vector <- numeric(0)

main_page <- page(
  href = "/",
  req_handlers = list(
    function(req){
      if (identical(req$REQUEST_METHOD, "POST")) {
        return(httpResponse(200, "text/plain", "OK\n"))
        data <- req$rook.input$read(-1)

        data <- jsonlite::fromJSON(rawToChar(data))

        message(paste0("Received post request with number: ", data$number))
        number_vector <<- c(number_vector, data$number)
        return(httpResponse(200, "text/plain", "OK\n"))
      } else {
        return(req)
      }
    }
  ),
  ui = h2("Numbers received:", textOutput("number_vector", inline = TRUE, container = span)),
  server = function(input, output, session) {
    recheck <- reactiveTimer(500)

    output$number_vector <- renderText({
      recheck() #this causes the number_total to get polled again
      paste0(number_vector, collapse = ", ")
    })
  }
)

brochureApp(
  main_page
)
