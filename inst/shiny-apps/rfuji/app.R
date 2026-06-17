# rfuji Shiny app: assess the FAIRness of a research data object or research
# software, and explore the results, license reusability, access/sensitivity,
# and identifier hygiene. Launched via rfuji::launch_rfuji().

library(shiny)
library(bslib)
library(rfuji)

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0L) y else x

CAT_COLORS <- c(F = "#118AB2", A = "#06D6A0", I = "#FFD166", R = "#EF476F", FAIR = "#073B4C")
CAT_NAMES <- c(F = "Findable", A = "Accessible", I = "Interoperable", R = "Reusable")
MATURITY_LEVELS <- c("incomplete", "initial", "moderate", "advanced")  # 0..3
MATURITY_COLORS <- c(incomplete = "#fb923c", initial = "#eab308",
                     moderate = "#84cc16", advanced = "#10b981")

maturity_label <- function(m) MATURITY_LEVELS[pmin(pmax(as.integer(m), 0L), 3L) + 1L]

metric_label <- function(v) {
  labels <- c(
    "0.8" = "FsF v0.8 - Domain agnostic",
    "0.5" = "FsF v0.5 - Domain agnostic",
    "0.5ssv2" = "FsF v0.5 - Social Sciences full (beta)",
    "0.5ss" = "FsF v0.5 - Social Sciences part (beta)",
    "0.5env" = "FsF v0.5 - Earth & Environmental (alpha)",
    "0.7_software" = "FRSM v0.7 - Software",
    "0.7_software_cessda" = "FRSM v0.7 - Software CESSDA",
    "0.6a2a" = "FsF v0.6 A2A draft",
    "0.4" = "FsF v0.4 legacy",
    "0.3" = "FsF v0.3 legacy",
    "0.2" = "FsF v0.2 legacy"
  )
  unname(labels[[v]] %||% paste("Metric", v))
}

# Group the available metric versions for the selector (data / software / legacy).
metric_version_choices <- function() {
  vers <- rfuji_metric_versions()
  is_sw <- grepl("software", vers)
  is_legacy <- vers %in% c("0.5", "0.5ss", "0.5ssv2", "0.5env", "0.6a2a", "0.4", "0.3", "0.2")
  grp <- function(keys) {
    keys <- keys[keys %in% vers]
    stats::setNames(as.list(keys), vapply(keys, metric_label, character(1)))
  }
  out <- list()
  if (any(!is_sw & !is_legacy)) out[["FAIR data"]] <- grp(vers[!is_sw & !is_legacy])
  if (any(is_sw)) out[["Research software"]] <- grp(vers[is_sw])
  if (any(is_legacy)) out[["Legacy data versions"]] <- grp(vers[is_legacy])
  out
}

service_type_choices <- c(
  "OAI-PMH" = "oai_pmh", "OGC CSW" = "ogc_csw", "SPARQL" = "sparql",
  "DCAT catalog/document" = "dcat", "schema.org JSON-LD" = "schema_org",
  "DataCite API/content negotiation" = "datacite", "Crossref API" = "crossref",
  "Signposting" = "signposting", "Typed links" = "typed_links",
  "RO-Crate metadata" = "ro_crate", "CKAN API" = "ckan", "Other metadata document" = "other"
)

EXAMPLES <- c(
  "Zenodo (data)" = "https://doi.org/10.5281/zenodo.8347772",
  "PANGAEA (data)" = "https://doi.org/10.1594/PANGAEA.908011",
  "GitHub (software)" = "https://github.com/pangaea-data-publisher/fuji"
)

badge <- function(text, color) {
  sprintf('<span style="display:inline-block;padding:.2em .6em;border-radius:1rem;color:#fff;background:%s;font-weight:600;font-size:.8em">%s</span>',
          color, text)
}

cat_card <- function(cat, row) {
  pct <- row$percent %||% 0
  ml <- maturity_label(row$maturity)
  div(class = "card border-0 shadow-sm h-100",
      style = sprintf("border-left:4px solid %s !important", CAT_COLORS[[cat]]),
      div(class = "card-body py-2 px-3",
          div(class = "d-flex justify-content-between align-items-center",
              tags$span(class = "fw-semibold", style = sprintf("color:%s", CAT_COLORS[[cat]]),
                        CAT_NAMES[[cat]]),
              tags$span(class = "fs-4 fw-bold", sprintf("%.0f%%", pct))),
          div(class = "text-muted small", sprintf("%g of %g points", row$earned %||% 0, row$total %||% 0)),
          div(class = "mt-1", HTML(badge(ml, MATURITY_COLORS[[ml]])))))
}

ui <- page_sidebar(
  title = tags$span(tags$b("rfuji"), tags$span(class = "text-muted", " - FAIR assessment")),
  theme = bs_theme(version = 5, primary = "#118AB2", success = "#06D6A0",
                   "border-radius" = "0.6rem"),
  sidebar = sidebar(
    width = 360,
    textInput("pid", "Research object (DOI / PID / URL / repo)",
              placeholder = "https://doi.org/10.5281/zenodo.8347772"),
    div(class = "mb-2",
        tags$small(class = "text-muted d-block mb-1", "Examples:"),
        lapply(seq_along(EXAMPLES), function(i)
          actionLink(paste0("ex", i), names(EXAMPLES)[i], class = "badge bg-light text-primary me-1 mb-1 text-decoration-none"))),
    selectInput("metric", "Metric set", choices = metric_version_choices(), selected = "0.8"),
    accordion(
      open = FALSE,
      accordion_panel(
        "Advanced", icon = icon("sliders"),
        textInput("service_url", "Metadata service endpoint",
                  placeholder = "(Optional) endpoint or document URL"),
        selectInput("service_type", "Metadata service type",
                    choices = service_type_choices, selected = "oai_pmh"),
        checkboxInput("datacite", "Use DataCite", TRUE),
        checkboxInput("debug", "Collect debug log", FALSE))),
    actionButton("go", "Assess FAIRness", class = "btn-primary w-100", icon = icon("play")),
    tags$hr(class = "my-2"),
    tags$small(class = "text-muted",
               "Native R implementation of the F-UJI / FRSM metrics. No external server required.")
  ),
  uiOutput("results")
)

server <- function(input, output, session) {
  lapply(seq_along(EXAMPLES), function(i)
    observeEvent(input[[paste0("ex", i)]], updateTextInput(session, "pid", value = unname(EXAMPLES[i]))))

  assessment <- eventReactive(input$go, {
    req(nzchar(trimws(input$pid)))
    withProgress(message = "Harvesting metadata and scoring...", value = 0.5, {
      tryCatch(
        assess_fair(trimws(input$pid), metric_version = input$metric,
                    use_datacite = input$datacite,
                    metadata_service_endpoint = trimws(input$service_url),
                    metadata_service_type = input$service_type,
                    test_debug = input$debug),
        error = function(e) structure(list(error = conditionMessage(e)), class = "rfuji_error"))
    })
  })

  output$results <- renderUI({
    a <- assessment()
    if (inherits(a, "rfuji_error")) {
      return(div(class = "alert alert-danger mt-3", tags$b("Assessment failed: "), a$error))
    }
    s <- summary(a)
    fair <- s[s$category == "FAIR", ]
    cats <- intersect(c("F", "A", "I", "R"), s$category)
    tagList(
      layout_columns(
        col_widths = c(3, 3, 6), class = "mb-1",
        value_box("FAIR score", sprintf("%.0f%%", fair$percent %||% 0),
                  showcase = icon("award"), theme = "primary"),
        value_box("Maturity", maturity_label(fair$maturity),
                  showcase = icon("layer-group"),
                  theme = value_box_theme(bg = MATURITY_COLORS[[maturity_label(fair$maturity)]], fg = "#fff")),
        value_box("Resolved", tags$small(a$resolved_url %||% a$id),
                  showcase = icon("link"), theme = "light")
      ),
      do.call(layout_columns, c(
        list(col_widths = rep(3, length(cats)), class = "mb-1"),
        lapply(cats, function(c) cat_card(c, s[s$category == c, ])))),
      layout_columns(
        col_widths = c(6, 6),
        card(card_header("FAIR sunburst"), card_body(plotOutput("sunburst", height = "340px"))),
        navset_card_tab(
          nav_panel("Scores", tableOutput("cattable")),
          nav_panel("Scorecard", plotOutput("scorecard", height = "320px"))
        )
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

  output$sunburst <- renderPlot({
    a <- assessment()
    if (inherits(a, "rfuji_error")) return(invisible())
    plot(a, type = "sunburst", main = NULL)
  }, res = 96)

  output$scorecard <- renderPlot({
    a <- assessment()
    if (inherits(a, "rfuji_error")) return(invisible())
    plot(a, type = "metric", main = NULL)
  }, res = 96)

  output$cattable <- renderTable({
    s <- summary(assessment())
    data.frame(
      Principle = ifelse(s$category %in% names(CAT_NAMES), CAT_NAMES[s$category], s$category),
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
        tags$b(l$license), " -> ", l$category,
        if (isFALSE(l$is_open)) tags$span(class = "text-danger", " (not open for reuse)")))
    } else list(tags$li(class = "text-muted", "No license detected."))
    acc <- a$access
    hyg <- a$identifier_hygiene
    tagList(
      card(card_header("License reusability"), card_body(tags$ul(reuse_html))),
      card(card_header("Access & sensitivity"), card_body(
        tags$p(HTML(paste0("Access level: ", badge(acc$access %||% "unknown", "#073B4C")))),
        if (isTRUE(acc$controlled_access)) tags$p(HTML(badge("controlled access", "#fb923c"))),
        if (isTRUE(acc$sensitive)) tags$p(HTML(badge("sensitive", "#EF476F"))),
        tags$small(class = "text-muted", acc$note))),
      card(card_header("Identifier hygiene"), card_body(
        if (isTRUE(hyg$hygiene_ok)) tags$p(HTML(badge("no issues", "#10b981")))
        else tags$ul(lapply(hyg$issues, tags$li)))),
      card(card_header("FAIR-TLC (Traceable - Licensed - Connected)"), card_body(
        {
          tlc <- fair_tlc(a)
          rows <- lapply(seq_len(nrow(tlc)), function(i) tags$tr(
            tags$td(tlc$dimension[i]), tags$td(tlc$indicator[i]),
            tags$td(HTML(badge(if (tlc$met[i]) "yes" else "no",
                               if (tlc$met[i]) "#10b981" else "#fb923c")))))
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
