# ggirl-examples

This repo gives small working examples of the systems that power [{ggirl}](https://github.com/jnolis/ggirl).

Examples:
* __stripe-order__ - a Shiny app that lets the user make an order through Stripe
* __stripe-fulfillment__ (coming soon) - a plumber API that listens for the Stripe webhook to fulfill a paid order
* __shiny-upload__ - the ability to have an R function push data to a separate Shiny app. This provides three separate solutions:
  * Add a HTTP request handler to Shiny (first shown by [Garrick Aden-Buie](https://gist.github.com/gadenbuie/c19cf997467930729ec9acaf98a150fb))
  * Add the POST handling to the UI function of Shiny (first shown by [Joe Cheng](https://gist.github.com/jcheng5/2aaff19e67079840350d08361fe7fb20))
  * Use the [{brochure}](https://github.com/ColinFay/brochure) package by Colin Fay.

### Setup

To use the Stripe examples you will need to have a Stripe account. Once you do fill out the `stripe_creds_template.json` file with the test API keys (or prod!). Then rename the file as `stripe_creds.json`. The R project includes an renv file so you can install the right packages.
