# This shows an example of receiving a stripe order. Note that it's
# probably a better idea to do this as a Plumber API, but this shows how to
# do it with a brochure Shiny app. The method is the same in both cases.

# You can run the server by using the command
# shiny::runApp("src/stripe-fulfillment", host = "0.0.0.0", port = 80L)

# For more detail about running a background process in Shiny see the blogpost
# https://jnolis.com/blog/shiny_background_processes/

library(shiny)
library(jsonlite)
library(brochure)
library(httr)
library(callr)

stripe_creds <- jsonlite::read_json("../../keys/stripe_creds.json")

validate_stripe_signature <- function(stripe_signature, raw_body){
  tolerance <- 300
  parsed_signature <-
    list(
      t = regmatches(stripe_signature, regexec("t=([a-f0-9]*)", stripe_signature))[[1]][2],
      v1 = regmatches(stripe_signature, regexec("v1=([a-f0-9]*)", stripe_signature))[[1]][2]
    )

  signed_payload <- paste0(parsed_signature$t,".",raw_body)
  signing_secret <- stripe_creds[["checkout-session-completed-webhook-signing-secret"]]

  expected_signature <- digest::hmac(signing_secret, signed_payload, algo = "sha256")
  if(parsed_signature$v1 == expected_signature){
    current_time <- as.numeric(Sys.time())
    signature_time <- as.numeric(parsed_signature$t)
    if(signature_time < current_time - tolerance){
      message(glue::glue("Webhook validation failed, timestamp too old ({current_time-signature_time})"))
      result <- FALSE
    } else {
      result <- TRUE
    }
  } else {
    message(glue::glue("Webhook validation failed, keys did not match (v1={parsed_signature$v1}, expected_signature={expected_signature})"))
    result <- FALSE
  }
  result
}

jobs <- list()

fulfill_order <- function(order_id){
  env <- environment()
  e <- evaluate::try_capture_stack({
    # Do the fulfillment thing here! This is for order `order_id`.
    TRUE
  }, env)
  if(!(is.logical(e) && e)){
    # Something went wrong with fulfillment!
    # Do the error handling here
  }
}

order_placed_endpoint <-
  page(href = "/",
       req_handlers = list(
         function(req){
           message("Recieved post request t")
           response <- tryCatch({
             if(req$REQUEST_METHOD == "POST" ){

               headers <- req[["HEADERS"]]

               raw_body <- readr::read_file(req$.bodyData)
               is_valid <- validate_stripe_signature(headers[["stripe-signature"]], raw_body)
               body <- jsonlite::fromJSON(raw_body)

               if(body$type == "checkout.session.completed"){
                 message("Request is correct type")
                 if(is_valid){
                   order_id <- body$data$object$client_reference_id
                   message(glue::glue("INFO: Order for {order_id}"))
                    order_status_set_ready_to_fulfill(token)
                     if(is.null(jobs[[order_id]])){
                       jobs[[order_id]] <<- callr::r_bg(fulfill_order,
                                                            args = list(order_id = order_id),
                                                            stdout = NULL, stderr = NULL)
                     }
                     message(glue::glue("Submitted order as separate process"))
                     response <- httpResponse(status = 200L, content = 'order-submitted')
                 } else {
                   message("ERROR: Request does not have valid signature")
                   response <- httpResponse(status=400L, content = "Invalid webhook request")
                 }
               } else {
                 message("ERROR: Incorrect event time")
                 response <- httpResponse(status = 400L, content = "Wrong event type")
               }
             } else {
               message("ERROR: Not a POST request")
               response <- httpResponse(status = 400L, content = "Requires a post request")
             }
             response
           }, error = function(error_details){
             message(glue::glue("ERROR: {as.character(error_details)}"))
             httpResponse(status = 500L, content = as.character(error_details))
           })
           return(response)
         }
       )
  )

brochureApp(
  order_placed_endpoint
)
