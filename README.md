# ggirl-examples

This repo gives small working examples of the systems that power [{ggirl}](https://github.com/jnolis/ggirl).

Examples:
* __stripe-order__ - a Shiny app that lets the user make an order through Stripe
* __stripe-fulfillment__ (coming soon) - a plumber API that listens for the Stripe webhook to fulfill a paid order
* __shiny-upload__ (coming soon) - the ability to have an R function push data to a separate Shiny app

### Setup

To use the Stripe examples you will need to have a Stripe account. Once you do fill out the `stripe_creds_template.json` file with the test API keys (or prod!). Then rename the file as `stripe_creds.json`
