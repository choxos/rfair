# rfuji Shiny app: assess the FAIRness of a research data object and explore the
# results, license reusability, access/sensitivity, and identifier hygiene.
# Launched via rfuji::launch_rfuji().

library(shiny)
library(bslib)
library(rfuji)

CAT_COLORS <- c(F = "#118AB2", A = "#06D6A0", I = "#FFD166", R = "#EF476F", FAIR = "#073B4C")
MATURITY_LEVELS <- c("incomplete", "initial", "moderate", "advanced")  # 0..3
MATURITY_COLORS <- c(incomplete = "#fe7d37", initial = "#dfb317",
                     moderate = "#97ca00", advanced = "#4c1")

maturity_label <- function(m) MATURITY_LEVELS[pmin(pmax(as.integer(m), 0L), 3L) + 1L]

badge <- function(text, color) {
  sprintf('<span style="display:inline-block;padding:.25em .6em;border-radius:.5rem;color:#fff;background:%s;font-weight:600">%s</span>',
          color, text)
}

draw_fair_donut <- function(s) {
  cats <- s[s$category %in% c("F", "A", "I", "R"), ]
  fair <- s[s$category == "FAIR", ]
  if (!nrow(cats) || all(is.na(cats$total))) { plot.new(); return(invisible()) }
  cols <- vapply(seq_len(nrow(cats)), function(i) {
    a <- if (is.na(cats$percent[i])) 0.15 else max(0.15, cats$percent[i] / 100)
    grDevices::adjustcolor(CAT_COLORS[[cats$category[i]]], alpha.f = a)
  }, character(1))
  op <- graphics::par(mar = c(0, 0, 0, 0)); on.exit(graphics::par(op))
  graphics::pie(cats$total, labels = cats$category, col = cols, border = "white",
                radius = 1, init.angle = 90, clockwise = TRUE)
  graphics::symbols(0, 0, circles = 0.6, inches = FALSE, add = TRUE, bg = "white", fg = "white")
  graphics::text(0, 0.08, sprintf("%.0f%%", fair$percent %||% 0), cex = 2.6, font = 2)
  graphics::text(0, -0.2, "FAIR", cex = 1.1, col = "grey40")
}
`%||%` <- function(x, y) if (is.null(x) || length(x) == 0L) y else x

ui <- page_sidebar(
  title = tags$span(tags$b("rfuji"), " — FAIR data assessment"),
  theme = bs_theme(version = 5, primary = "#118AB2"),
  sidebar = sidebar(
    width = 360,
    textInput("pid", "Research data object (DOI / PID / URL)",
              placeholder = "https://doi.org/10.5281/zenodo.8347772"),
    selectInput("metric", "Metric version", choices = rfuji_metric_versions(), selected = "0.8"),
    checkboxInput("datacite", "Use DataCite", TRUE),
    checkboxInput("debug", "Collect debug log", FALSE),
    actionButton("go", "Assess FAIRness", class = "btn-primary", icon = icon("play")),
    tags$hr(),
    tags$small(class = "text-muted",
               "Native R implementation of the F-UJI metrics. No external server required.")
  ),
  uiOutput("results")
)

server <- function(input, output, session) {
  assessment <- eventReactive(input$go, {
    req(nzchar(trimws(input$pid)))
    withProgress(message = "Harvesting metadata and scoring...", value = 0.5, {
      tryCatch(
        assess_fair(trimws(input$pid), metric_version = input$metric,
                    use_datacite = input$datacite, test_debug = input$debug),
        error = function(e) structure(list(error = conditionMessage(e)), class = "rfuji_error"))
    })
  })

  output$results <- renderUI({
    a <- assessment()
    if (inherits(a, "rfuji_error")) {
      return(div(class = "alert alert-danger mt-3", tags$b("Assessment failed: "), a$error))
    }
    s <- summary(a); fair <- s[s$category == "FAIR", ]
    tagList(
      layout_columns(
        col_widths = c(3, 3, 6),
        value_box("FAIR score", sprintf("%.0f%%", fair$percent),
                  showcase = icon("award"), theme = "primary"),
        value_box("Maturity", maturity_label(fair$maturity),
                  showcase = icon("layer-group"),
                  theme = value_box_theme(bg = MATURITY_COLORS[[maturity_label(fair$maturity)]], fg = "#fff")),
        value_box("Resolved", tags$small(a$resolved_url %||% a$id),
                  showcase = icon("link"), theme = "light")
      ),
      layout_columns(
        col_widths = c(5, 7),
        card(card_header("FAIR overview"), card_body(plotOutput("donut", height = "260px"))),
        card(card_header("Scores by principle"), card_body(tableOutput("cattable")))
      ),
      navset_card_tab(
        nav_panel("Metrics", DT::DTOutput("metrics")),
        nav_panel("Reuse & access", uiOutput("reuse")),
        nav_panel("Harvested metadata", DT::DTOutput("harvested")),
        nav_panel("Log", verbatimTextOutput("log"))
      ),
      div(class = "my-3", downloadButton("download", "Download results (F-UJI JSON)", class = "btn-success"))
    )
  })

  output$donut <- renderPlot(draw_fair_donut(summary(assessment())))

  output$cattable <- renderTable({
    s <- summary(assessment())
    data.frame(
      Principle = s$category,
      Score = sprintf("%g / %g", s$earned, s$total),
      Percent = sprintf("%.1f%%", s$percent),
      Maturity = maturity_label(s$maturity)
    )
  }, striped = TRUE, width = "100%")

  output$metrics <- DT::renderDT({
    df <- as.data.frame(assessment())
    df$maturity <- maturity_label(df$maturity)
    df <- df[, c("metric_identifier", "metric_name", "earned", "total", "maturity", "status")]
    names(df) <- c("Metric", "Name", "Earned", "Total", "Maturity", "Status")
    DT::datatable(df, rownames = FALSE, options = list(pageLength = 20, dom = "t"),
                  selection = "none") |>
      DT::formatStyle("Status", target = "row",
                      backgroundColor = DT::styleEqual(c("pass", "fail"), c("#eaf7ee", "#fdeef0")))
  })

  output$reuse <- renderUI({
    a <- assessment()
    reuse_html <- if (!is.null(a$reuse) && length(a$reuse$licenses)) {
      lapply(a$reuse$licenses, function(l) tags$li(
        tags$b(l$license), " → ", l$category,
        if (isFALSE(l$is_open)) tags$span(class = "text-danger", " (not open for reuse)")))
    } else list(tags$li(class = "text-muted", "No license detected."))
    acc <- a$access
    hyg <- a$identifier_hygiene
    tagList(
      card(card_header("License reusability"), card_body(tags$ul(reuse_html))),
      card(card_header("Access & sensitivity"), card_body(
        tags$p(HTML(paste0("Access level: ", badge(acc$access %||% "unknown", "#073B4C")))),
        if (isTRUE(acc$controlled_access)) tags$p(HTML(badge("controlled access", "#fe7d37"))),
        if (isTRUE(acc$sensitive)) tags$p(HTML(badge("sensitive", "#EF476F"))),
        tags$small(class = "text-muted", acc$note))),
      card(card_header("Identifier hygiene"), card_body(
        if (isTRUE(hyg$hygiene_ok)) tags$p(HTML(badge("no issues", "#4c1")))
        else tags$ul(lapply(hyg$issues, tags$li)))),
      card(card_header("FAIR-TLC (Traceable · Licensed · Connected)"), card_body(
        {
          tlc <- fair_tlc(a)
          rows <- lapply(seq_len(nrow(tlc)), function(i) tags$tr(
            tags$td(tlc$dimension[i]), tags$td(tlc$indicator[i]),
            tags$td(HTML(badge(if (tlc$met[i]) "yes" else "no",
                               if (tlc$met[i]) "#4c1" else "#fe7d37")))))
          tagList(
            tags$table(class = "table table-sm", tags$tbody(rows)),
            tags$small(class = "text-muted",
                       "FAIR+ extension (Haendel et al., doi:10.5281/zenodo.203295)."))
        }))
    )
  })

  output$harvested <- DT::renderDT({
    md <- assessment()$metadata
    flat <- data.frame(
      Field = names(md),
      Value = vapply(md, function(v) {
        v <- unlist(v, use.names = FALSE)
        x <- paste(utils::head(as.character(v), 5), collapse = "; ")
        if (nchar(x) > 300) paste0(substr(x, 1, 300), "...") else x
      }, character(1)),
      row.names = NULL, stringsAsFactors = FALSE)
    DT::datatable(flat, rownames = FALSE, options = list(pageLength = 30, dom = "t"))
  })

  output$log <- renderText({
    a <- assessment()
    if (length(a$log)) paste(unlist(a$log), collapse = "\n") else "Enable 'Collect debug log' and re-run to see messages."
  })

  output$download <- downloadHandler(
    filename = function() paste0("rfuji-", digest::digest(assessment()$id, algo = "crc32"), ".json"),
    content = function(file) writeLines(as_fuji_json(assessment()), file)
  )
}

shinyApp(ui, server)
