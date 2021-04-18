# STRIPE ORDERING THROUGH SHINY

# To use this demo, you'll need to make a Stripe account and get your test keys (or prod if you're feeling fiesty).
# Take those keys and store them in a "keys/stripe_creds.json" file in the base of this repo--you can use the template
# file as an example.

# THIS DEMO WILL NOT WORK IN THE RSTUDIO BROWSER! You'll need to open it in a full web browser like Chrome.

library(shiny)
library(glue)
library(uuid)
library(httr)

stripe_creds <- jsonlite::read_json("../../keys/stripe_creds.json")

save_order <- function(order_id, customer_email, quantity_folklore, quantity_evermore){
  # This just prints it but you really want to save it to the cloud or something!!
  message(glue("New order {order_id} from {customer_email} (folklore={quantity_folklore}, evermore={quantity_evermore})"))
}

create_stripe_session <- function(items, order_id, success_url, cancel_url, customer_email = NULL){
    # Add the base order information.
    # The client_reference_id is a string so you can keep track of the order on
    # your side. Not required but extremely helpful.
    body_form <- list(
        `success_url`= success_url,
        `cancel_url`= cancel_url,
        `payment_method_types[0]`='card',
        `client_reference_id`= order_id,
        `mode`= 'payment')

    # Add the email
    # This isn't required but if you don't have it stripe will just ask for it,
    # so might as well ask in shiny in case the order has a problem?
    if(!is.null(customer_email)){
        body_form <- c(body_form,list(`customer_email` = customer_email))
    }

    # add the items that were requested.
    for(i in 1:length(items)){
      item_entry <- items[[i]][c('unit_amount','currency','name','description','quantity')]
      names(item_entry) <- paste0(glue("line_items[{i-1}]"),
                                  c("[price_data][unit_amount]",
                                    "[price_data][currency]",
                                    "[price_data][product_data][name]",
                                    "[price_data][product_data][description]",
                                    "[quantity]"))

      body_form <- c(body_form, item_entry)

      # optional, denote the applicable taxes for this item
      for(tr in 1:length(stripe_creds$tax_rates)){
        tr_entry <- stripe_creds$tax_rates[i]
        names(tr_entry) <- glue("line_items[{i-1}][dynamic_tax_rates][{tr-1}]")
        body_form <- c(body_form,tr_entry)
      }


    }

    # # to get a better understanding of what's going on, try printing the body:
    # print(body_form)

    # send the request to stripe
    response <- POST("https://api.stripe.com/v1/checkout/sessions",
                           authenticate(user = stripe_creds$secret,
                                              password=""),
                           body = body_form,
                           encode = "form"
    )
    if(response$status_code == 200L){
      # if the creation was a success get the id of the session and return
      content(response)$id
    } else {
      stop(content(response))
    }

}

ui <- fluidPage(
    shiny::titlePanel("Shiny Stripe ordering"),

    # this is the JavaScript required to redirect the user to the session they
    # create. It (1) loads the Stripe JavaScript libraries (2) sets a custom
    # JavaScript handler to have Javascript notice when the session_id changes in Shiny
    # Then if it does change uses the Stripe "redirectToCheckout" to open a checkout page
    tags$head(      tags$script(src="https://js.stripe.com/v3/"),
                    tags$script(glue('
        Shiny.addCustomMessageHandler("session_id", function(session_id) {
        Stripe("{{stripe_creds$public}}").redirectToCheckout({ sessionId: session_id});
      });', .open = "{{", .close = "}}"))),

    numericInput("quantity_folklore","Folklore quantity", 0),
    numericInput("quantity_evermore","Evermore quantity", 0),
    textInput("customer_email","Your email (for order updates)"),
    actionButton("submit", "Checkout")
)

server <- function(input, output, session) {
    observe({
        if(input$submit >= 1){
          isolate({
            if(input$quantity_folklore + input$quantity_evermore > 0){ #Don't go to Stripe if the total is zero!
              # not required, but makes it easier to connect Stripe payments to
              # the order that made it
              order_id <- UUIDgenerate()

              # this are placeholders, but really should be "page for order complete"
              # and "page for order cancelled"
              success_url <- "https://jnolis.com"
              cancel_url <- "https://jnolis.com"

              # this list will have a row for each type type purchased
              items <- list()

              if(input$quantity_folklore > 0){
                items <- c(items, list(list(
                  name = "Folklore",
                  description = "Taylor Swift's 8th album",
                  quantity = as.character(input$quantity_folklore),
                  unit_amount = "3000",
                  currency = "USD"
                )))
              }

              if(input$quantity_evermore > 0){
                items <- c(items, list(list(
                  name = "Evermore",
                  description = "Taylor Swift's 9th album",
                  quantity = as.character(input$quantity_evermore),
                  unit_amount = "3000",
                  currency = "USD"
                )))
              }

              # Depending on what you're doing you probably want to save the order details to the cloud
              # Although much of that will also be in the Stripe metadata (in the case of ggirl the postcard image
              # needed to be saved)
              save_order(order_id, input$customer_email, input$quantity_folklore, input$quantity_evermore)

              # Actually tell Stripe to create the new session
              session_id <- create_stripe_session(items, order_id, success_url, cancel_url, input$customer_email)

              message(glue("Created Stripe session {session_id}"))

              # start the redirect process
              session$sendCustomMessage("session_id", session_id)
            }
          })
        }
    })
}

shinyApp(ui = ui, server = server)
